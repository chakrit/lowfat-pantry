# Triaging an issue — fix the class, not the instance

Every bug report names one plugin. That plugin is almost never the bug — it is the one place
the bug happened to get noticed. 64 filters were written from the same conventions by the
same process, so a mistake in one is a mistake in the mould, and it is sitting in the others
too.

**Never close an issue having only fixed the plugin it named.** The report is a sample; the
job is to find the population it was drawn from.

## The loop

### 1. Reproduce and root-cause the instance

Get the raw-vs-filtered diff, find the rule that did the damage. `lowfat filter <path>.lf
--sub <s> --level <l> --exit <n> --explain` over the sample. Stop at the *mechanism*, not
the symptom: not "terraform truncated my list" but "a `*:` catch-all ending in `head auto`
truncates without a marker."

### 2. Name the bug class

State it as a property of filters in general, with the plugin name removed. If you cannot
say it without naming the plugin, keep digging — you have a symptom.

    instance:  terraform-compact drops resources from `state list`
    class:     a catch-all ending in bare head/tail cuts invisibly, so a truncated
               listing is indistinguishable from a short one

### 3. Measure the blast radius

Grep the population before choosing a fix. The count decides the shape of the response.

    # how many catch-alls end in a truncating op?
    for f in plugins/*/*/filter.lf; do
      sed -n '/^\*:/,$p' "$f" | grep -vE '^\s*(#|$)' | tail -1
    done | sort | uniq -c

One hit is an instance. Five is a pattern. Forty is a convention defect — the mould is
wrong, and fixing the instances without fixing the mould guarantees the next plugin
reintroduces it.

### 4. Fix at the widest level that makes sense

Work down; take the first tier that is actually available to you.

| Tier | When | Artifact |
|-------------------|--------------------------------------------------|---------------------------------------|
| **Upstream** | The defect is in lowfat itself — a builtin op, the pipeline, the CLI | Issue on `zdk/lowfat`; note it here |
| **Convention** | Our authoring guidance produces the bug | `docs/spec/output-philosophy.md` invariant + `SKILL.md` decision tree |
| **Sweep** | The bad shape is already in N filters | One commit across all of them, goldens re-locked |
| **Instance** | Genuinely specific to one tool's output | The single plugin |

Upstream and convention are not alternatives to the sweep — an upstream fix ships on
someone else's schedule, and a convention only governs filters written *after* it. Filed
upstream, codified, and swept is the complete response.

**A convention change without a sweep is a lie**, and a sweep without a convention change
just resets the clock until the next plugin reintroduces the shape.

### 5. Prove the class is gone

Re-run the step-3 grep. It should return zero, and be cheap enough that anyone can re-run
it later. Where the invariant is mechanically checkable, that grep belongs in the test
suite, not in this guide.

## Filing upward

When the root cause is lowfat's, file it on `zdk/lowfat` with the same evidence standard we
ask of our own reporters (see the troubleshooting page in the Outline collection), and link
the upstream issue from the decision record. Then ship the in-repo mitigation anyway. We do
not ship a known silent-loss bug while waiting on someone else's release.

## Worked example

Issue #1 — `tofu state list` returned 15 of 36 resources with no marker.

1. **Instance:** `state` fell to `*:` → `head auto`.
2. **Class:** bare `head`/`tail` cuts invisibly; and line-per-item inventories should never
   have been compaction candidates at all — two classes, from one report.
3. **Radius:** 40 of 64 catch-alls ended in a silent truncator.
4. **Fix:** invariants 6 and 7 + [decision](../decisions/2026-07-26-visible-truncation.md)
   (convention), `head-auto-marked` and inventory `raw` rules across every affected filter
   (sweep). The marker-in-builtin fix belongs upstream on `zdk/lowfat` and is not yet
   filed — the in-repo mitigation shipped without waiting for it.
5. **Proof:** the radius grep returns zero.

One report, two bug classes, 40 plugins fixed. That ratio is the point of this guide.
