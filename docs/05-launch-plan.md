# Launch Plan

Event: October 30 – November 1, 2026

## Part I — Project Objective

Launch the first Robotics Pizza Hackathon as a technically credible pilot that proves four things:

1. teams can learn the SO-101/LeRobot workflow quickly;
2. robot-learning policies can be trained during a weekend;
3. physical evaluation can produce a meaningful leaderboard;
4. the format is repeatable at future locations.

**Primary KPI:** at least 70% of participating teams successfully deploy one autonomous learned
policy to a real robot.

**Secondary KPIs:**

- ≥50% complete Challenge 1
- ≥30% complete Challenge 2
- at least several teams produce meaningful Mystery Pizza attempts
- zero serious safety incidents
- evaluation completed on schedule
- publishable datasets and video footage produced
- sponsors receive credible technical and media exposure

## Part II — Launch Strategy

Current date: **August 27, 2026**. Time to event: **approximately 9 weeks.**

The critical path is technical validation, not marketing. Do not open a large public registration
campaign until the organizers have completed at least: teleoperation → 30+ demonstrations →
training → autonomous deployment, on the intended hardware.

### Phase 1 — Technical Proof (Aug 27 – Sep 6)

**Objectives:** lock Challenge 1; assemble first SO-101 pair; establish camera/workspace; collect
first dataset; run first autonomous policy; select physical toppings; run an existing SO-101
simulation.

**Deliverables:** working teleoperation; physical benchmark prototype; first dataset; first
autonomous video; technical risk register; hardware BOM; simulation "Hello World."

**Go/No-Go (by September 6):** GO if autonomous topping pick/place works at least intermittently.
NO-GO / simplify if the basic manipulation pipeline remains unreliable.

### Phase 2 — Reference System (Sep 7 – Sep 13)

**Objectives:** repeat training from a clean environment; implement scoring; build Challenge 1
simulator prototype; order full hardware inventory; develop starter repository; shoot first
authentic robot footage.

**Deliverables:** reference ACT policy; initial SmolVLA fine-tuning test; evaluation script;
published technical architecture (internal); first 10–20 second teaser footage.

### Phase 3 — Blind User Test (Sep 14 – Sep 20)

Invite 2–4 people who did not build the system. Give them quick-start documentation, a robot, and
the starter repo. Do not guide them unless they become blocked.

**Measure:** setup time; calibration time; teleoperation learning time; dataset collection time;
training friction; deployment friction; questions asked.

**Exit criteria:** a new participant can open the project → operate the robot → record data → start
training, without continuous organizer support.

### Phase 4 — Public Launch (Sep 21 – Sep 27)

**Launch — publish:** landing page; application form; teaser video; challenge overview; sponsor
announcement; technical FAQ.

**Marketing message**
- Primary: *Teach a robot to make pizza in 48 hours.*
- Secondary: *Collect real robot data, fine-tune a VLA and compete on a physical benchmark.*

Do not lead with detailed model architecture. Lead with the robot and the pizza.

### Phase 5 — Recruitment + Pilot (Sep 28 – Oct 4)

**Marketing:** university outreach; robotics communities; ML communities; LinkedIn; X; Discord;
local AI meetups; LeRobot/Hugging Face community outreach; founder communities.

**Technical:** run an internal or invite-only mini competition with approximately 4 teams. Test:
mentor load; hardware concurrency; compute concurrency; reset time; evaluation throughput;
documentation.

### Phase 6 — Competition Freeze (Oct 5 – Oct 11)

**Freeze:** physical props; robot configuration; camera position; challenge definitions; scoring;
software version; baseline models; simulator V1.

Changes after this date require Technical Lead approval.

**Publish:** Participant Handbook V1; starter repository; simulation practice environment; challenge
scoring; hardware overview.

### Phase 7 — Participant Onboarding (Oct 12 – Oct 18)

**Online workshop (60–90 minutes).** Topics: what SO-101 is; teleoperation; LeRobot dataset
structure; policies; evaluation; simulator; event rules.

**Participant pre-work (before arrival):** install required client software; authenticate accounts;
clone starter repo; run environment health check; watch teleoperation video; optionally run
simulator.

Do not require participants to install an entire unstable robotics stack at the venue.

### Phase 8 — Full Dress Rehearsal (Oct 19 – Oct 25)

Run the entire event in compressed form.

**Test:** check-in; robot assignment; participant environment; data recording; cloud training;
inference; evaluation submission; leaderboard; judging; AV; livestream; emergency procedures.

**Failure injection — intentionally simulate:** dead robot; broken USB cable; unavailable GPU; bad
checkpoint; camera disconnect; lost calibration; submission failure. Verify that staff knows what to
do.

### Phase 9 — Final Preparation (Oct 26 – Oct 29)

No experimental changes.

**Tasks:** charge/test hardware; label all equipment; prepare spare stations; pre-stage accounts;
test network; verify GPU quotas; clean/reset datasets; verify evaluation robot; install signage;
assemble media station; print runbooks.

### Phase 10 — Event (Oct 30 – Nov 1)

Run the published schedule (see [Challenge Brief](01-challenge-brief.md#10-schedule)).

**Key operational rule:** protect the technical team from general event interruptions. The people
fixing robots should not also be managing catering, speakers, or sponsors.

### Phase 11 — Post-Event (Nov 2 – Nov 8)

**Within 72 hours, publish:** winners; leaderboard; photos; highlight video; initial metrics;
sponsor thank-you posts.

**Within 1–2 weeks, publish:** datasets approved for publication; winning approaches; technical
retrospective; benchmark repository; event impact report.

---

See [Team Structure](06-team-structure.md) for role ownership across these phases, and
[Marketing Plan](07-marketing-plan.md) for the campaign detail behind Phases 4–5.
