#!/usr/bin/env ruby
# Authenticates against Simutronics SGE using Lich's existing EAccess module
# and prints JSON game credentials suitable for proxying through Lich.
#
# Usage:
#   sge_auth.rb <account> <password> <character> <game_code>
#
# Output (stdout, on success):
#   {"host":"...","port":N,"key":"..."}
#
# Exit codes:
#   0   success
#   1   bad arguments
#   2   authentication rejected by Simu
#   3   any other error

require 'json'

# Lich install location. Override with LICH_DIR env var if needed.
LICH_DIR = ENV['LICH_DIR'] || File.expand_path('~/Gemstone')
LIB_DIR  = File.join(LICH_DIR, 'lib')
DATA_DIR = File.join(LICH_DIR, 'data')

# eaccess.rb references `DATA_DIR` and `Lich.log`. The former is a top-level
# constant in a normal Lich session; the latter is a no-op without a real
# Lich session. Provide both.
module Lich
  def self.log(*); end
end

require File.join(LIB_DIR, 'common', 'authentication', 'eaccess.rb')

account, password, character, game_code = ARGV
if [account, password, character, game_code].any? { |v| v.nil? || v.empty? }
  STDERR.puts 'usage: sge_auth.rb <account> <password> <character> <game_code>'
  exit 1
end

begin
  info = Lich::Common::Authentication::EAccess.auth(
    account: account,
    password: password,
    character: character,
    game_code: game_code
  )
  puts JSON.generate(
    host: info['gamehost'],
    port: info['gameport'].to_i,
    key:  info['key']
  )
rescue Lich::Common::Authentication::EAccess::AuthenticationError => e
  STDERR.puts "auth: #{e.error_code}"
  exit 2
rescue StandardError => e
  STDERR.puts "error: #{e.message}"
  exit 3
end
