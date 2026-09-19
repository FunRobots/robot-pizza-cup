# References & Next Steps

## Technical references behind the platform decisions

The current official SO-101 guide confirms the leader/follower architecture and Feetech-based
hardware stack.

LeRobot's current real-robot workflow supports dataset-driven training and deployment, while LeLab
now provides a GUI covering SO-101 calibration, teleoperation, recording, local/cloud training and
policy execution — potentially useful for organizer testing or beginner onboarding.

For the VLA path, SmolVLA is a 450M open model designed for LeRobot data, supports SO-100/SO-101,
and its current documentation recommends about 50 episodes as a starting point while emphasizing
demonstrations for each task variation.

For simulation, LeIsaac is the most direct current starting point because it already exposes
single-arm SO-101 manipulation environments and LeRobot integration; the official tooling also
includes an SO-101 URDF path.

These references informed the platform decisions recorded in the [README](../README.md#key-decisions-locked-for-planning-purposes):
SO-101 + LeRobot as the standardized platform, SmolVLA as the headline VLA path, ACT retained as the
organizer's fallback/reference baseline, and LeIsaac + Isaac Lab + LeRobot EnvHub as the simulation
stack.

*Note: these are living, fast-moving open-source projects. Re-verify exact commit/version numbers,
supported hardware, and recommended demonstration counts against current LeRobot/SmolVLA/LeIsaac
documentation before the Competition Freeze (see [Launch Plan, Phase 6](05-launch-plan.md#phase-6--competition-freeze-oct-5--oct-11)).*

## Recommended next artifact

The next artifact to build from this documentation set is the **organizer's technical validation
checklist**, with explicit pass/fail gates for the next 2–3 weeks. That is now the critical path:
before sponsorship or marketing scales, the organizing team needs hard measurements for:

- demonstration count (how many episodes to reliable autonomous success);
- training duration (on the actual sponsor GPU configuration);
- task success rate (per challenge, per baseline policy);
- reset time (physical + software, per station);
- robot failure rate (hardware faults per N episodes).

This maps directly onto [Phase 1 — Technical Proof](05-launch-plan.md#phase-1--technical-proof-aug-27--sep-6)
and the five validation gates (A–E) in the [Technical Spec](03-technical-spec.md#14-pre-event-technical-validation).
Building that checklist as a standalone, trackable document (with dates, owners, and measured
numbers filled in as they come off the bench) is the recommended immediate follow-up to this package.
