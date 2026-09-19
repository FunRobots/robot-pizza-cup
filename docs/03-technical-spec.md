# Robotics Pizza Hackathon — Technical Competition Specification

Version 0.1

Companion document: [Simulation Specification](04-simulation-spec.md) covers sections 16–30 of the
original combined spec.

---

## 1. Technical Objective

The inaugural hackathon must prove that inexperienced-to-intermediate teams can complete the full
learning loop:

```
Teleoperate
    ↓
Record demonstrations
    ↓
Create dataset
    ↓
Train / fine-tune policy
    ↓
Deploy
    ↓
Run autonomous physical evaluation
```

The event should optimize for **pipeline reliability**, not maximum manipulation complexity.

## 2. Standard Competition Platform

**Robot — per team:**

- 1 × SO-101 follower arm
- 1 × SO-101 leader arm for teleoperation
- standard gripper
- fixed table mount
- fixed power supply
- USB connection

**Recommended inventory for 8 teams:**

- 8 working robot pairs
- 2 complete spare pairs or enough components to rebuild two stations
- spare motor controllers
- spare motors
- spare gripper parts
- spare power supplies
- spare USB cables

## 3. Vision

**Required:** 1 × fixed front RGB camera per station.

**Target configuration:**

- 640 × 480 minimum
- 30 FPS
- fixed focal length if practical
- fixed physical mount
- same approximate viewpoint on every station

Avoid participant-controlled camera placement during the first event.

**Optional future extension:** wrist-mounted RGB camera. Do not add this to the inaugural benchmark
unless the pilot proves that the second view materially improves policy performance without
increasing support burden.

## 4. Workspace

Each station uses the same table, robot mounting location, camera mounting location, printed
competition mat, fixed pizza location, ingredient pickup zones, ingredient containers, and lighting
configuration.

The printed mat should contain alignment markers for fast resets.

Suggested usable workspace: approximately 600 × 600 mm. Exact dimensions must be determined during
physical prototyping.

## 5. Competition Props

For scored evaluation, use standardized rigid props.

**Pizza**
- rigid circular disk
- approximately 200–250 mm diameter
- non-reflective
- washable
- fixed or constrained during evaluation

**Pepperoni**
- approximately 35–45 mm diameter
- 4–8 mm thickness
- consistent mass
- high visual contrast

**Mushroom / secondary topping** — use a mechanically reliable geometry rather than a realistic
floppy mushroom. Options: mushroom-shaped rigid token, differently colored circular token, or
rounded block.

**Recommendation:** prototype both (1) visually realistic silicone pieces and (2) simple
3D-printed rigid tokens. Choose whichever gives the more reliable grasp. Technical benchmark
consistency is more important than visual realism.

## 6. Software Environment

Organizer-maintained environment:

- Linux reference platform
- NVIDIA GPU path for training
- Python environment
- LeRobot
- Feetech support
- PyTorch
- Hugging Face Hub integration
- optional Weights & Biases
- starter repository
- pinned dependency lockfile

Do not run the event on unpinned latest packages.

**Before the public participant workshop, freeze:** LeRobot commit/version, Python version, PyTorch
version, CUDA version, camera stack, baseline checkpoints.

Keep one golden disk image or container image capable of rebuilding a participant machine.

## 7. Reference Policies

Two organizer reference paths should exist.

**Baseline A — ACT.** Purpose: technical fallback, prove hardware and dataset pipeline, easier
diagnostic reference.

**Baseline B — SmolVLA.** Purpose: headline Physical AI/VLA workflow, language-conditioned recipes,
demonstrate pretraining + fine-tuning.

Participants can use other compatible approaches. The event is successful even if teams use ACT for
initial success and move to VLA for higher-level challenges.

## 8. Common Dataset Format

Every episode records: timestamp, front RGB observation, robot joint state, gripper state, robot
action, task instruction, episode ID, success/failure metadata.

Recommended metadata fields:

```
team_id:
station_id:
robot_id:
task_id:
recipe:
environment_seed:
camera_config:
software_version:
operator_id:
episode_outcome:
notes:
```

## 9. Challenge 1 — Precision Topping

**Objective:** Pick pepperoni tokens and place them on the pizza.

**Initial state:** robot in standard home pose; pizza fixed; 6 pepperoni tokens in pickup area; no
other toppings.

**Time limit:** target 60–90 seconds. Finalize after pilot testing.

**Demonstration target:** initial participant recommendation of 30–60 high-quality episodes. Teams
may collect more.

**Procedure**

1. Reset robot to home pose.
2. Reset pepperoni tokens.
3. Start episode.
4. Robot autonomously attempts the task.
5. Evaluation software records output.
6. Stop when: all toppings are placed, time expires, or a safety stop occurs.

**Metrics** — for each topping: successfully grasped, released, landed on pizza, placement
coordinates, dropped outside workspace.

**Example score (30 points maximum)**

- 3 points × 6 correctly placed toppings = 18
- up to 8 points for placement precision
- up to 4 points for speed

Scoring should remain understandable from watching the run.

**Equipment:** SO-101 pair, front camera, pizza prop, 6+ pepperoni props, printed alignment mat,
computer, GPU training access.

**Organizer preparation (before event):** calibrate robot; test gripper; mark camera position;
verify camera index; verify home pose; verify all topping pieces; test emergency stop; run
reference policy.

**Validation gate.** Challenge 1 is ready only when the organizer's reference system achieves:

- ≥80% successful individual topping placements over at least 10 test episodes;
- no recurring hardware fault;
- reset time ≤60 seconds;
- evaluation result reproducible by two different organizers.

## 10. Challenge 2 — Recipe Assembly

**Objective:** Follow a natural-language recipe using two topping classes.
Example: *"Put four pepperoni and three mushrooms on the pizza."*

**Initial state:** pizza fixed; two topping classes in separate pickup regions; robot at home;
recipe displayed/provided digitally.

**Recommended recipe set (training examples):**

- 3 pepperoni + 2 mushrooms
- 4 pepperoni + 2 mushrooms
- 4 pepperoni + 3 mushrooms
- 5 pepperoni + 1 mushroom

Official evaluation recipes must be declared in the rules, except for the Mystery Pizza final.

**Procedure**

1. Evaluation server sends recipe.
2. Robot starts from home pose.
3. Policy receives observations and task instruction.
4. Robot selects and places toppings.
5. Policy declares completion or time expires.

**Time limit:** target 120 seconds.

**Scoring (40 points maximum)**

- 15 points — correct ingredient classes
- 10 points — correct ingredient counts
- 10 points — successful placement on pizza
- 5 points — execution efficiency

**Penalties:** wrong topping, topping outside pizza, physical intervention, safety violation.

**Equipment:** same as Challenge 1 plus a second topping type, second ingredient zone/bin, and
recipe display/API. No additional robot hardware should be required.

**Validation gate.** Organizer reference system must achieve:

- ≥60% full-recipe success across 10+ evaluation episodes;
- ≥80% correct ingredient selection;
- reliable scoring;
- reset time ≤90 seconds.

If this threshold cannot be achieved before the event, simplify recipe counts rather than adding
more participant support.

## 11. Challenge 3 — Mystery Pizza

**Objective:** Measure generalization after model freeze.

**Model freeze** — before Challenge 3: team submits checkpoint; team submits inference
configuration; checksum recorded; no additional data collection; no additional training.

**Allowed randomization** — must be bounded and reproducible.

- **Pizza:** translation within approximately ±20–30 mm X, ±20–30 mm Y.
- **Ingredient zones:** move within marked legal regions.
- **Ingredient counts:** change within previously declared ranges.
- **Recipe:** use a novel combination of known ingredients.

**Avoid in V1** — do not randomly change: camera model, camera height substantially, lighting
dramatically, gripper, table, or unknown topping categories. Those test infrastructure differences
more than useful model generalization.

**Evaluation seed** — generate a hidden seed before the final. All finalists receive equivalent
configurations. Store:

```
challenge_seed:
pizza_position:
ingredient_positions:
ingredient_counts:
recipe:
```

**Scoring (30 points maximum)**

- 15 — task completion
- 5 — correct recipe
- 5 — placement quality
- 5 — speed

**Validation gate.** The organizer reference VLA does not need to achieve 80% here. A useful final
should differentiate teams. Target organizer success range: 30–60%. If reference success is close to
0%, the final is probably too difficult. If reference success is near 100%, increase bounded
variation.

## 12. Official Evaluation Protocol

For each core challenge: 5 official runs per team; same number of attempts; same time limit;
standardized reset; standardized randomization distribution.

**Recommended metric:** final task score = mean(score across official episodes).

Never allow teams to select their best episode.

## 13. Evaluation Station

Centralize official evaluation rather than evaluating independently at every team table.

**Advantages:** consistent robot, consistent camera, consistent lighting, consistent props, easier
livestreaming, easier judging.

Teams develop on team robots. Submitted policies run on one or two golden evaluation robots. This
also tests transfer between nominally identical SO-101 units.

## 14. Pre-Event Technical Validation

**Gate A — Hardware.** Pass when: 30 consecutive teleoperation episodes can be recorded; no motor
overheats or repeatable communication faults appear; camera connection survives extended operation;
gripper performs repeated grasps consistently.

**Gate B — Dataset.** Pass when: dataset can be recorded, replayed, inspected, uploaded, downloaded,
and trained from a clean machine.

**Gate C — Training.** Pass when: reference training completes using intended event compute;
checkpoint saves correctly; checkpoint can be resumed; training can be launched by a participant
using a documented command. Do not publicly promise a training duration until this benchmark has
been measured on the exact sponsor GPU configuration.

**Gate D — Deployment.** Pass when: fresh checkpoint can be loaded; inference starts from a clean
environment; robot executes without organizer code changes.

**Gate E — Evaluation.** Pass when: two organizers independently score the same run identically;
automated and human judging agree; reset time is acceptable; 12 teams can be evaluated within the
published schedule.

## 15. Required Organizer Reference Solution

Repository should include:

```
pizza-hackathon/
│
├── README.md
├── environment.lock
│
├── hardware/
│   ├── calibration/
│   ├── camera_setup.md
│   └── troubleshooting.md
│
├── datasets/
│   └── sample/
│
├── training/
│   ├── act/
│   └── smolvla/
│
├── inference/
│
├── evaluation/
│   ├── challenge_1.py
│   ├── challenge_2.py
│   └── challenge_3.py
│
├── simulator/
│
└── docs/
    ├── participant_quickstart.md
    ├── mentor_runbook.md
    └── organizer_runbook.md
```

A clean clone must reproduce the reference pipeline.

---

See [Simulation Specification](04-simulation-spec.md) for the `simulator/` directory contents and
the simulation build path.
