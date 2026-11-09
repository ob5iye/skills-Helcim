#!/usr/bin/env python3
"""List all Twilio TaskRouter workers with their extensions.

Reads TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN (or TWILIO_API_KEY/TWILIO_API_SECRET)
from the environment or from ../../.env. Writes a table to stdout and a CSV next
to this script (workers.csv) unless --no-csv is passed.
"""
import base64, csv, json, os, sys, urllib.parse, urllib.request
from pathlib import Path

ENV_FILE = Path(__file__).resolve().parents[2] / ".env"


def load_env():
    if ENV_FILE.exists():
        for line in ENV_FILE.read_text().splitlines():
            if "=" in line and not line.startswith("#"):
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip())


def auth_header():
    user = os.environ.get("TWILIO_API_KEY") or os.environ["TWILIO_ACCOUNT_SID"]
    pw = os.environ.get("TWILIO_API_SECRET") or os.environ["TWILIO_AUTH_TOKEN"]
    return "Basic " + base64.b64encode(f"{user}:{pw}".encode()).decode()


def get(url):
    req = urllib.request.Request(url, headers={"Authorization": auth_header()})
    with urllib.request.urlopen(req) as r:
        return json.load(r)


def paged(url, key):
    while url:
        data = get(url)
        yield from data[key]
        url = data.get("meta", {}).get("next_page_url")


def main():
    load_env()
    base = "https://taskrouter.twilio.com/v1/Workspaces"
    workspaces = list(paged(f"{base}?PageSize=50", "workspaces"))
    rows = []
    for ws in workspaces:
        for w in paged(f"{base}/{ws['sid']}/Workers?PageSize=1000", "workers"):
            a = json.loads(w.get("attributes") or "{}")
            rows.append({
                "workspace": ws["friendly_name"],
                "worker": w["friendly_name"],
                "full_name": a.get("full_name", ""),
                "ext": str(a.get("ext", "")),
                "email": a.get("email", ""),
                "activity": w.get("activity_name", ""),
                "sid": w["sid"],
            })
    rows.sort(key=lambda r: (r["workspace"], r["ext"] == "", r["ext"], r["worker"]))

    cols = ["ext", "worker", "full_name", "activity", "workspace", "sid"]
    widths = {c: max(len(c), *(len(r[c]) for r in rows)) for c in cols}
    print("  ".join(c.ljust(widths[c]) for c in cols))
    for r in rows:
        print("  ".join(r[c].ljust(widths[c]) for c in cols))
    print(f"\n{len(rows)} workers, {sum(1 for r in rows if r['ext'])} with an extension")

    if "--no-csv" not in sys.argv:
        out = Path(__file__).with_name("workers.csv")
        with out.open("w", newline="") as f:
            wr = csv.DictWriter(f, fieldnames=cols + ["email"])
            wr.writeheader()
            wr.writerows(rows)
        print(f"CSV written to {out}")


if __name__ == "__main__":
    main()
