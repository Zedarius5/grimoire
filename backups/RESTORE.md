# Restoring a highlight backup

Each `highlights-backup-*.json` is the full Grimoire highlight config
(groups + rules) as stored under the `grimoire.highlights.v1` key.

To restore one (quit Grimoire first, then):

```bash
python3 - <<'PY'
import json, plistlib, subprocess
cfg = json.load(open("backups/highlights-backup-<STAMP>.json"))
dom = plistlib.loads(subprocess.run(["defaults","export","com.zedarius.Grimoire","-"],capture_output=True).stdout)
dom["grimoire.highlights.v1"] = json.dumps(cfg, ensure_ascii=False, separators=(",",":")).encode("utf-8")
plistlib.dump(dom, open("/tmp/restore.plist","wb"))
import os; os.system("defaults import com.zedarius.Grimoire /tmp/restore.plist")
PY
```
