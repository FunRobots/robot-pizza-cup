# Scope Validation, Requirements Refinement, Virality Plan & Global Vision

Companion to [docs 01–09](.). This document revises the original plan against real-world precedent
(web research, Aug 2026) and proposes concrete adjustments. It does not replace docs 01–09 — it
flags what to change in them, and adds the global-scale thinking that wasn't there before.

**On the shared link:** the pasted `claude.ai/share/...` URL returned only page metadata (no
conversation content) when fetched — it's a client-side-rendered share page WebFetch can't execute
JS against, and per policy this session doesn't route around that with curl or similar. "Previous
findings" below means the full doc set already in `docs/01–09` (which was built from the same
material you pasted into this project), cross-checked against fresh web research.

---

## 1. What already exists — the competitive/comparable landscape

The core assumption behind this hackathon — "give people SO-101 + LeRobot for 48 hours and they'll
train a working policy" — is not a bet. It has already happened, repeatedly, in 2025–2026. That's
good news (the loop is proven) and a flag (you are not the first LeRobot hackathon, and the bar for
attention is a real, running community, not a greenfield one).

| Event | When | Scale | Hardware | Format | Food/cooking theme? | Formal scoring? |
|---|---|---|---|---|---|---|
| **LeRobot Worldwide Hackathon** (Hugging Face) | Jun 14–15, 2025 | Thousands of participants, **100+ physical locations** worldwide + online track; crashed HF's own infra from demand | SO-101 (50+ arms at some sites) | Teleoperate → dataset → train (ACT/SmolVLA) → deploy, "hello world" style | No | No — per-site demos, HF-curated "Winners" showcase; 190 datasets, 12 models published |
| **AMD Open Robotics Hackathon** | 2025 | Tokyo: 100 participants / 36 teams. Paris: 72 / 25 teams | SO-101 + AMD Instinct MI300X (cloud train) + Ryzen AI laptops (inference) | 2-phase: 1-day "hello world" workshop, then 2-day freestyle build | Yes — teams built donut packing, pasta making, sushi delivery, burger cooking | No — freestyle judged, not a shared benchmark |
| **Seeed 2025 Embodied AI Hackathon** | Oct 2025 | 700+ registered, 30+ teams (15 per site), Shenzhen + Mountain View simultaneous | SO-ARM101, StarAI arms, XLeRobot dual-arm, NVIDIA Jetson Thor | Full pipeline: assembly → 150+ episode datasets → ACT/Diffusion/VLA → deploy on Jetson | Yes — home/cooking tasks: matcha prep, sugar sprinkling, cloth folding | No — freestyle judged |
| **GOSIM Paris 2026 (OpenArm Hackathon)** | May 5–6, 2026 | ~50 participants, teams of 3–5 | OpenArm (7-DoF humanoid arm, not SO-101) | General manipulation: bin picking, pouring, table setting, cloth folding | No | Not specified |
| **RoboCup@Home / FIRST Robotics** | Ongoing, decades-old | Thousands of teams globally | Varies (mature circuits) | Formal, standardized, judged scoring with generalization tests | No | **Yes** — the only precedents with real benchmark rigor |

**The upshot:** every LeRobot-class hackathon so far is a *build weekend* — teleoperate, train,
demo, done. None of them run a standardized, scored, multi-challenge benchmark with a centralized
evaluation station and a frozen-model generalization round. That combination only exists in mature,
multi-year competitive robotics (RoboCup, FIRST). **PizzaBench's actual innovation is not "robot +
LeRobot hackathon" (that's now a known format) — it's "hackathon with RoboCup-grade scoring
rigor, on day one."** That's a genuinely good differentiator, but it's also where nearly all of your
execution risk lives, and where you have zero direct precedent to lean on.

---

## 2. Is the scope doable in 9 weeks? — Verdict

**The build loop: yes, well-validated.** Teleoperate → dataset → train (ACT or SmolVLA) → deploy has
been done, repeatedly, by hackathon-level teams (many first-time) inside 48 hours, across three
independent 2025 events above. Challenge 1 (Precision Topping) is squarely inside what's already
been demonstrated in the wild. Treat it as low technical risk.

**The scoring/benchmark layer: this is the real risk, not the robotics.** No comparable event has
attempted a centralized golden-evaluation-station + 5-official-runs-per-team + frozen-model
Mystery Pizza generalization round inside a single first-time weekend. Your own docs already build
in the right safety valve for this (validation gates A–E, the Challenge 3 success-rate target of
30–60%, the Phase 1 Go/No-Go) — **the adjustment is to make the de-scope path explicit and
pre-committed, not implicit.**

**Recommended explicit contingency (add to [Launch Plan](05-launch-plan.md)):**

- If Phase 1 Go/No-Go (Sep 6) passes only for basic pick/place, not recipe-following: keep
  Challenge 1 fully scored, run Challenge 2 as **exhibition/practice only** (not leaderboard-deciding)
  for this edition, and say so in the Participant Handbook before onboarding — don't cut it silently
  the week of the event.
- If the Challenge 3 validation gate (organizer reference success 30–60%) isn't hit by the Oct 5–11
  freeze: run Mystery Pizza as a **live showcase final** (real theater, real stakes for the crowd)
  scored qualitatively by judges rather than the strict rubric, and hold the strict version for the
  next edition once you have a season of centralized-evaluation data.
- Either downgrade is a fine outcome — it protects "zero serious safety incidents" and "evaluation
  completed on schedule" (your own top KPIs) over shipping every rule exactly as drafted.

**Timeline pressure point the original plan underweights:** the 2025 precedent events were backed by
multi-organization sponsor coalitions from day one (Seeed's event alone: NVIDIA, Hugging Face,
K-Scale Labs, XLeRobot, Lightwheel, Solo Tech, Fashion Star, Circuit Launch — eight named partners).
Your [Team Structure](06-team-structure.md) assumes a 6-person core team building most of this from
scratch. **Adjustment:** move sponsor/technical-partner recruitment (Hugging Face, Seeed, WowRobo —
see §5) into **Phase 1**, not Phase 9. Their tooling, tutorials, and community goodwill are the
fastest way to close the gap between "6 organizers, 9 weeks" and "8 organizations, months of
runway" that the precedent events had.

**Team size: 8–12 teams is right, don't scale it up for V1.** It's smaller than AMD's Tokyo cohort
(36 teams) and in line with Seeed's per-site count (15). For an inaugural event carrying the added
overhead of centralized scoring (which none of those events had to run), staying conservative on
team count while the judging pipeline is unproven is the correct call — resist any pressure to grow
the roster before Gate E (evaluation) is proven at Phase 8 dress rehearsal.

---

## 3. Requirements — refined with real pricing and sourcing

### Robot hardware (verified pricing, Aug 2026)

| Item | Cost | Source/notes |
|---|---|---|
| SO-101 arm, DIY (motors + electronics only, you 3D-print the rest) | **~$130** | Hugging Face's own BOM estimate; Apache 2.0, SO-ARM100 GitHub repo |
| SO-101 arm, pre-assembled incl. 3D-printed parts | **~$255** ($220 motor kit + $35 printed parts) | Seeed Studio |
| Follower + leader pair, assembled | **~$500–520/pair** | Derived from the above; DIY route can cut this substantially if you have printer capacity |

For 8–12 teams + 2 spare pairs (per your original inventory recommendation): **10–14 pairs**, i.e.
roughly **$5,000–$7,300** at assembled pricing, or well under half that if organizers 3D-print
in-house (worth doing — several precedent events, including yours, already assume it).

### Team/scale sourcing sanity check

AMD's Tokyo hackathon ran 36 teams with roughly 3 participants/team on a 2-day build after a 1-day
workshop, with sponsor-funded cloud GPU (AMD Instinct MI300X) and sponsor-loaned laptops. That's a
useful proof point that your GPU/compute line item is realistically an **in-kind sponsorship ask**
(AMD, NVIDIA, or Hugging Face compute credits), not a cash budget line — worth pursuing before
assuming you'll pay retail cloud pricing.

### Budget model (planning estimate — replace with real venue-specific quotes)

| Category | Estimate | Notes |
|---|---|---|
| Robot hardware (10–14 pairs + cameras + mounts) | $5,500–$8,000 | See above; camera ~$30–50 × 12–14 |
| Compute (GPU training) | $0–$3,000 | Target $0 via sponsor in-kind credits (AMD/NVIDIA/HF); budget a cash fallback only if sponsorship falls through |
| Venue (2.5 days, 8–12 stations + evaluation station + AV) | $5,000–$20,000 | Highly city-dependent; university/maker-space partnerships can bring this toward $0 |
| Food/catering (30–50 people × 3 days) | $3,000–$6,000 | Typical hackathon per-person catering benchmark scaled to a 3-day, not 1-day, event |
| Prizes (6 award categories) | $5,000–$15,000 | Cash + sponsor product; scale to what sponsorship actually closes |
| Media production (video, photo, livestream) | $3,000–$8,000 | Or largely in-kind if Media Lead + volunteers cover it |
| Props/materials (pizza disks, tokens, mats, printing) | $500–$1,500 | Low-cost given rigid/reusable prop strategy already in the [Technical Spec](03-technical-spec.md) |
| Insurance/safety/contingency | $1,000–$3,000 | Robot-arm-around-people liability; confirm with venue |
| **Total planning range** | **~$23,000–$65,000** | Wide range reflects venue and sponsorship-in-kind variance — narrow it once venue and 2–3 anchor sponsors are confirmed |

This is materially higher than a typical software-only hackathon (which the general benchmarking
data puts at roughly $50–150/participant for venue+food+swag alone) because of the hardware CAPEX —
that's expected and is the correct place to push hardest for **in-kind sponsorship** (robots,
compute, venue) rather than cash.

### Materials/props — no change needed

The rigid, reusable prop strategy (200–250mm pizza disk, 35–45mm pepperoni tokens, rigid
mushroom/secondary-topping tokens) already in the [Technical Spec §5](03-technical-spec.md#5-competition-props)
holds up well against precedent — Seeed's cooking tasks (matcha, sugar) and AMD's food builds (donut
packing, pasta) both leaned on simplified, controllable materials rather than realistic messy ones
for exactly the reliability reasons your doc gives. No adjustment needed here, just confirmation
you're already making the right call.

### On-site robot count — confirmed formula

`(number of teams × 1 pair) + 2 spare pairs`, i.e. 10 pairs for 8 teams up to 14 pairs for 12 teams,
plus one or two additional **golden evaluation robots** kept separate from team development
stations (per [Technical Spec §13](03-technical-spec.md#13-evaluation-station)) — unchanged from the
original plan, now priced above.

---

## 4. Making it viral and popular

Two hard data points from 2025–2026 should directly shape the marketing plan:

**1. Demand for this exact niche is currently very high — higher than the organizers can fully
serve.** The June 2025 LeRobot Worldwide Hackathon drew enough simultaneous interest to knock
Hugging Face's own infrastructure offline. That's a signal to *plug into* existing community
channels rather than build an audience from zero: the Hugging Face LeRobot community, and
robotics-focused newsletters that covered these events (e.g. *Robots & Startups*), are already
primed for exactly this content. **Adjustment to [Marketing Plan](07-marketing-plan.md):** add a
specific outreach line to the Hugging Face LeRobot team and to `robotsandstartups.substack.com`
(and similar robotics-beat newsletters) in the T-5/T-6 week window — earned media in an
already-warm community beats cold-audience acquisition for a niche like this.

**2. "Robot fails at cooking" content is independently, virally proven.** Two real, unrelated 2025
examples: a Unitree humanoid losing its grip on a pan went viral, and a robot chef's stir-fry
disaster was widely covered asking "what does it really tell us?" This validates — with real
evidence, not just intuition — the [Media Spec's Asset 8 "Failure Reel"](08-media-spec.md#asset-8--failure-reel)
concept. **Adjustment:** lean harder into this than the original spec does. Don't just capture
failures opportunistically; plan for them as headline content from day one of Phase 1 technical
proof (Aug 27), not just event-week b-roll. "Day 0: 0/6 → Week 3: 5/6" style progression content,
grounded in your own real numbers, is a stronger hook than any generated concept art.

**3. A real commercial pizza-robot exists — use it for contrast, not competition.** Nala Robotics
(Arlington Heights, IL) builds "Pizzaiola," a fully autonomous pizza system — arm picks dough, adds
sauce/cheese/toppings, cooks in a partner Ovention oven — commercialized with Hatco Corp. This is
useful two ways: (a) as a technical-credibility narrative hook ("a $250 open-source arm attempting
in a weekend what a funded commercial system took years to productize" is a strong, honest framing —
avoid implying you're competing with or replacing them), and (b) as a potential sponsor/advisor
relationship (see §5) — commercial food-robotics companies have obvious PR and pipeline interest in
a hackathon feeding them talent and open data.

**Adjustment to campaign pillars:** add a sixth pillar — **"Community, not cold start."** Frame
outreach as joining/extending the existing LeRobot hackathon wave (100+ locations proven in 2025)
rather than announcing a brand-new, unaffiliated event competing for the same attention.

---

## 5. Global vision: from 10 teams to 1,000 teams

**The headline finding: the distribution mechanism you'd need to reach 1,000+ teams already exists
and is proven at scale — you don't have to invent it.** The June 2025 LeRobot Worldwide Hackathon
ran "thousands of participants across more than 100 physical locations worldwide, plus a simulation
track" in a single weekend, using local-chapter organizers (Munich, NYC, LA, Seattle, Mountain View,
San Francisco, and dozens more) each running the same starter kit and rules. **PizzaBench's job is
not to build 1,000-team logistics from scratch — it's to become the benchmarked, scored, franchisable
competitive layer that this already-proven grassroots distribution model is missing.** That reframes
the "10 → 1,000" question from "how do we scale operations 100×" to "how do we become the standard
ruleset that existing chapters adopt."

**Be realistic about the timeline, though.** FIRST Robotics is the closest long-run precedent for
"small event → thousands of teams globally," and it took **~32 years** to go from one high-school
gym in 1992 to 3,468 teams across 28 countries in 2024, via a deliberate regional/district/championship
qualification structure (62 regionals + 98 district qualifiers + 11 district championships feeding
~600 teams into one final championship). A 10 → 1,000 jump is a multi-year program, not a
second-edition goal — plan the roadmap accordingly rather than promising hypergrowth in year two.

### Proposed staged roadmap

| Stage | Timeframe | Scale | What changes | Precedent it mirrors |
|---|---|---|---|---|
| **V1 — Prove the format** | 2026 (this event) | 1 venue, 8–12 teams | Validate the scored 3-challenge benchmark end-to-end; publish PizzaBench v1 dataset + ruleset | — |
| **V2 — Multi-city chapters** | 2027 | 3–6 cities, ~15–35 teams/site | License the ruleset + starter kit to partner-run local chapters (each runs its own local evaluation station); unify scoring/leaderboard format across sites | AMD Open Robotics Hackathon (Tokyo + Paris, same kit, separate local judging) |
| **V3 — Federated global season** | 2028+ | Dozens–100+ chapters, online + local track | Partner with Hugging Face's LeRobot Worldwide Hackathon as PizzaBench's official benchmarked companion track; regional leaderboards feed a global championship/showcase final | LeRobot Worldwide Hackathon (100+ simultaneous sites) + FIRST Robotics' regional→championship structure |
| **V4 — Standing competitive circuit** | Multi-year | Hundreds–1,000+ teams, recurring seasons | Franchise/license model for regional organizers; PizzaBench becomes a recognized "Physical AI benchmark season," not a one-off event | FIRST Robotics' mature district/regional model |

### Commercial & sponsorship opportunities

| Category | Candidates | Angle |
|---|---|---|
| Hardware sponsors | Hugging Face (SO-101/LeRobot), Seeed Studio, WowRobo | They already run near-identical events — natural in-kind hardware/credit partners, not cold outreach |
| Compute sponsors | AMD, NVIDIA (Jetson/Isaac ecosystem) | Both have directly funded comparable 2025 robotics hackathons with GPU hardware/credits |
| Community/platform | Hugging Face LeRobot community, GOSIM | Cross-promotion and shared participant funnel; GOSIM's OpenArm hackathon (Paris, May 2026) is a natural sister-event to co-market with, even though it's a different arm |
| Commercial food-robotics | Nala Robotics (Pizzaiola), Hatco/Ovention | Advisor/judge/prize-sponsor role; strong "hobbyist kit → industry" narrative; potential hiring/dataset-licensing pipeline for them |
| Media/earned coverage | Robots & Startups newsletter and similar robotics-beat outlets that already covered LeRobot/AMD/Seeed hackathons | Warm audience, proven interest in exactly this content |
| Data licensing | Research labs / robotics companies wanting real pick-and-place demonstration data | Ken Goldberg (UC Berkeley) and HF's Thomas Wolf have both publicly framed real-world manipulation data as a current bottleneck for robotics AI — PizzaBench's dataset output is a legitimate research asset, not just a hackathon souvenir; this supports the dataset opt-in policy already drafted in the [Challenge Brief §11](01-challenge-brief.md#11-dataset-and-open-research) |
| Franchise/licensing revenue (V3–V4) | Regional organizers paying for the ruleset, starter kit, and "PizzaBench Certified Event" branding | Longer-horizon revenue path once the format is proven — not a V1 consideration |

---

## 6. Concrete adjustments — changelog against docs 01–09

- **[03-technical-spec.md](03-technical-spec.md)** — update the implicit hardware cost assumption
  with real pricing: ~$130 DIY / ~$255 assembled per SO-101 arm, ~$500–520/pair; revise the
  8-team/10-pair inventory budget line to $5,000–$7,300 (assembled) with a lower-cost DIY/3D-print
  path noted explicitly.
- **[05-launch-plan.md](05-launch-plan.md)** — add an explicit, pre-committed de-scope contingency:
  Challenge 2 drops to exhibition-only if the Sep 6 Go/No-Go only clears basic pick/place; Challenge
  3 drops to a qualitatively-judged showcase final if the Oct 5–11 freeze can't hit the 30–60%
  reference success target. Move sponsor/technical-partner recruitment (Hugging Face, Seeed, WowRobo,
  AMD/NVIDIA) into Phase 1 rather than treating it as a later-phase task.
- **[06-team-structure.md](06-team-structure.md)** — note explicitly that comparable 2025 events ran
  on multi-organization sponsor coalitions (Seeed's event had 8 named partners); the 6-person core
  team should treat "close 2–3 technical-partner relationships" as a Phase 1 deliverable owned by the
  Sponsorship/Partnerships Lead, not a Phase-9 nice-to-have.
- **[07-marketing-plan.md](07-marketing-plan.md)** — add a sixth campaign pillar, "Community, not
  cold start": direct outreach to the Hugging Face LeRobot community and robotics-beat newsletters
  that covered the 2025 LeRobot/AMD/Seeed hackathons, positioned in the T-5/T-6 week window.
- **[08-media-spec.md](08-media-spec.md)** — elevate Asset 8 (Failure Reel) from an event-week
  capture item to a Phase-1-onward content thread, citing real 2025 viral precedent (Unitree
  cooking-fail video, robot stir-fry disaster coverage) as evidence this format performs.
- **New, this document** — the staged global-scale roadmap (§5) and sponsorship/collaboration map
  did not exist before; treat this as the seed of a future standalone "PizzaBench Global Roadmap"
  document once V1 ships and V2 planning begins.

---

## Sources

- [LeRobot Worldwide Hackathon — Hugging Face](https://huggingface.co/LeRobot-worldwide-hackathon)
- [LeRobot Worldwide Hackathon Munich chapter](https://robotics.growbotics.ai/community/events/local/lerobot-hackathon-munich-2026)
- [Roboto Hosts Hugging Face LeRobot Hackathon](https://www.roboto.ai/blog/roboto-hosts-hugging-face-lerobot-hackathon/)
- ["sad face we broke hugging face" — Robots & Startups](https://robotsandstartups.substack.com/p/sad-face-we-broke-hugging-face)
- [AMD Open Robotics Hackathon Recap](https://www.amd.com/en/developer/resources/technical-articles/2025/amd-open-robotics-hackathon-recap.html)
- [2025 Embodied AI Hackathon Recap — Seeed](https://www.seeed.cc/post/2025-embodied-ai-hackathon-recap)
- [GOSIM Paris 2026 — OpenArm Hackathon](https://paris2026.gosim.org/unaite-hackathon/)
- [Hugging Face Launches the SO-101 — Hackster.io](https://www.hackster.io/news/hugging-face-launches-the-so-101-an-upgraded-low-cost-3d-printable-autonomous-robot-arm-532360f441eb)
- [FIRST Robotics Competition — Wikipedia](https://en.wikipedia.org/wiki/FIRST_Robotics_Competition)
- [Nala Robotics teams up with Hatco Corp. — Robotics 24/7](https://www.robotics247.com/article/nala_robotics_teams_up_with_hatco_corp_to_develop_new_pizza_system_designed_for_commercial_markets/news)
- [Robot chef's stir-fry disaster goes viral — Robotics & Automation News](https://roboticsandautomationnews.com/2025/11/06/robot-chefs-stir-fry-disaster-goes-viral-but-what-does-it-really-tell-us/96307/)
- [Unitree humanoid robot chef loses grip on pan — Interesting Engineering](https://interestingengineering.com/innovation/video-robot-chef-loses-grip-on-pan-in)
- [Hackathon Sponsorship & Prize Guide](https://guptadeepak.com/hackathon-sponsorship-guide/)
