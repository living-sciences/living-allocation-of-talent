"""Parse HHJK HowMuchPoorer / SolveEqmBasic Octave diary logs into tidy records.

HowMuchPoorer block format (per counterfactual call):
    ... with <BASEYEAR> values of <WhatUnchanged>[, for <GroupName>]
    <16-col header: Y Ymkt Ywkr LFP Earn Cons EarnY gdpY GapWW GapBM GapBW EarnWM EarnWW EarnBM EarnBW Util>
    -- <y0> --   <levels>
    <alt>        <levels>
    -- <y1> --   <levels>
    Growth(alt)  ...
    Growth(tru)  ...
    Difference   ...
    // Share //  <16 share values>

Our generalized living driver ALSO prints a marker line before each call:
    @@CF t0=<i> t1=<j> what=<W> group=<g>@@
so blocks can be tagged unambiguously regardless of the (ungated) header text.
"""
import re, json, sys, pathlib

COLS = ["Y","Ymkt","Ywkr","LFP","Earn","Cons","EarnY","gdpY",
        "GapWW","GapBM","GapBW","EarnWM","EarnWW","EarnBM","EarnBW","Util"]

def _nums(line):
    # pull all floats from a row that starts with a label
    return [float(x) for x in re.findall(r"-?\d+\.\d+|-?\d+", line.split("//")[-1] if "//" in line else line)]

def parse_howmuchpoorer(text):
    """Return list of dicts: {marker..., what, group, baseyear, share:{col:val}, growth_alt, growth_tru}."""
    lines = text.splitlines()
    out = []
    cur = {}
    for i, ln in enumerate(lines):
        m = re.search(r"@@CF\s+t0=(\d+)\s+t1=(\d+)\s+what=(\S+)\s+group=(\S+)@@", ln)
        if m:
            cur = {"t0": int(m.group(1)), "t1": int(m.group(2)),
                   "what": m.group(3), "group": m.group(4)}
            continue
        hm = re.search(r"with (\d+) values of (\w\+?\w*)(?:, for (.+))?\s*$", ln)
        if hm:
            cur = dict(cur)  # keep any marker already seen
            cur["baseyear_hdr"] = int(hm.group(1))
            cur.setdefault("what", hm.group(2))
            cur["group_name"] = (hm.group(3) or "").strip()
        if ln.strip().startswith("// Share //"):
            vals = [float(x) for x in re.findall(r"-?\d+\.\d+", ln)]
            rec = dict(cur)
            rec["share"] = {c: v for c, v in zip(COLS, vals)}
            out.append(rec)
            cur = {k: v for k, v in cur.items() if k in ("t0", "t1", "what", "group")}
    return out

def parse_remaining_gain(text):
    """SolveEqmBasic OVERALL table: Year NoTauH NoTauW NoTauH/W -> list of dicts."""
    out = []
    m = re.search(r"OVERALL: Additional output gain over baseline with no frictions \(percent\):(.+?)(?:\n\s*\n|GDPYoung)",
                  text, re.S)
    if not m:
        return out
    for ln in m.group(1).splitlines():
        p = ln.split()
        if len(p) == 4 and re.match(r"\d{4}$", p[0]):
            out.append({"year": int(p[0]), "NoTauH": float(p[1]),
                        "NoTauW": float(p[2]), "NoTauHW": float(p[3])})
    return out

if __name__ == "__main__":
    # quick self-test on the replication Benchmark logs
    rep = pathlib.Path("/workspace/eval/replication/codebase")
    hmp = parse_howmuchpoorer((rep / "HowMuchPoorer_Benchmark.log").read_text())
    shares = [r for r in hmp if not r.get("group_name")]
    print("HowMuchPoorer blocks:", len(hmp), "| first 3 aggregate TauWTauH-ish Ymkt:",
          [round(r["share"]["Ymkt"], 1) for r in hmp[:3]])
    rg = parse_remaining_gain((rep / "SolveEqmBasic_Benchmark.log").read_text())
    print("remaining gain:", [(r["year"], r["NoTauHW"]) for r in rg])
