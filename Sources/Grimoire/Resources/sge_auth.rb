#!/usr/bin/env ruby
# Authenticates against Simutronics SGE using Lich's existing EAccess module
# and prints JSON game credentials suitable for proxying through Lich.
#
# This is OUR script (a thin wrapper); it loads Lich's EAccess library to do
# the actual SGE handshake. It ships inside Grimoire.app's resource bundle
# (declared in Package.swift) and is resolved at runtime via Bundle.module,
# so it works on any user's Mac regardless of where the source lives.
#
# Usage:
#   sge_auth.rb <account> <character> <game_code>
#
# The account PASSWORD is read from stdin (one line), NOT passed as an
# argument, so it never appears in the process table (`ps`).
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

# Lich install location. Override with LICH_DIR env var (Grimoire sets this).
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

account, character, game_code = ARGV
# Password arrives on stdin (one line) so it stays out of argv / `ps`.
password = STDIN.gets
password = password.chomp if password

if [account, character, game_code].any? { |v| v.nil? || v.empty? } ||
   password.nil? || password.empty?
  STDERR.puts 'usage: sge_auth.rb <account> <character> <game_code>  (password on stdin)'
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
