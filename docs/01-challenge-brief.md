# Robotics Pizza Hackathon 2026 — Challenge Brief

**Teach a Robot to Make Pizza in 48 Hours**

October 30 – November 1, 2026
Location: [Venue / City]
Teams: 8–12 teams, 2–4 participants per team
Platform: SO-101 + LeRobot
Format: Teleoperate → Collect Data → Fine-Tune → Deploy → Compete

---

## 1. The Challenge

Can you teach a low-cost robot a new physical skill in a weekend?

At the Robotics Pizza Hackathon, teams will use real SO-101 robotic arms to collect demonstrations,
create robotics datasets, train or fine-tune robot policies, deploy them to real hardware, and
compete on a standardized pizza-assembly benchmark.

There is no hard-coded trajectory to reproduce. The robot has to learn from data.

Over 48 hours, your team will:

1. Teleoperate a robot.
2. Record demonstrations.
3. Build a LeRobot dataset.
4. Train or fine-tune a policy.
5. Deploy the policy to a physical robot.
6. Run standardized evaluations.
7. Compete on the PizzaBench leaderboard.

Pizza is the theme. Physical AI is the challenge.

## 2. Why Pizza?

Pizza turns abstract robotics research into a task everyone immediately understands.

The competition tests several fundamental embodied-AI capabilities: visual perception, grasping,
precise pick-and-place, multi-object manipulation, language-conditioned behavior, sequencing,
robustness to variation, and generalization to configurations not seen during training.

The same underlying capabilities apply to warehouse automation, laboratory robotics, manufacturing,
food automation, home robotics, retail, and logistics.

## 3. Competition Philosophy

The first Robotics Pizza Hackathon intentionally does not require robots to:

- knead dough;
- manipulate sticky dough;
- spread liquid sauce;
- use ovens;
- cut cooked pizza;
- perform dangerous operations around heat.

The pizza base is placed by organizers before each run. Competition ingredients use standardized
reusable physical props during benchmarking. Real ingredients may be used in the showcase final
after the benchmark has been completed.

This keeps the competition focused on robot learning rather than kitchen engineering.

## 4. The Three Challenges

### Challenge 1 — Precision Topping

**Mission:** Teach the robot to pick individual pepperoni pieces and place them accurately on a
pizza. The robot starts from a standard home position. A pizza base is fixed in the workspace.
Pepperoni pieces are located inside a designated pickup zone. The pizza contains marked target
areas.

**Robot objective:** Place as many toppings as possible correctly within the time limit.

**Tests:** grasping · visual localization · pick-and-place · motion consistency · placement
precision.

**Example evaluation**
- Input: 6 pepperoni pieces.
- Goal: place all 6 inside the designated pizza area.

**Scoring — Maximum 30 points.** Points are awarded for successfully picked toppings, correct
placement, placement precision, task completion, and speed. Dropped or incorrectly placed
ingredients reduce the score.

### Challenge 2 — Recipe Assembly

**Mission:** The robot receives a recipe and must assemble the correct pizza.
Example: *"Make a pizza with four pepperoni and three mushrooms."*

The workspace contains multiple ingredient classes. The robot must:

1. identify the requested ingredients;
2. select the correct quantities;
3. pick the appropriate pieces;
4. place them on the pizza;
5. stop when the recipe is complete.

**Tests:** visual discrimination · language-conditioned behavior · multi-object manipulation ·
counting · sequencing · long-horizon execution.

**Scoring — Maximum 40 points.** Points are awarded for correct ingredient type, correct ingredient
count, successful placement, task completion, and execution efficiency. Incorrect ingredients
receive a penalty.

### Challenge 3 — Mystery Pizza (Championship Generalization Challenge)

The most important test happens after training is finished. Teams receive an evaluation
configuration they have not seen exactly during training. Possible changes include ingredient
positions, ingredient-bin positions, recipe, topping quantities, and pizza position within an
allowed region. Teams cannot collect new demonstrations after the final configuration is revealed.

**Example**
- Training: 4 pepperoni + 2 mushrooms.
- Final: 3 mushrooms + 5 pepperoni, with ingredient positions changed.

**Tests:** robustness · generalization · VLA performance · resistance to memorizing trajectories.

**Scoring — Maximum 30 points.** The Mystery Pizza challenge determines the final leaderboard among
qualifying teams.

## 5. Overall Scoring

| Challenge | Points |
|---|---|
| Precision Topping | 30 |
| Recipe Assembly | 40 |
| Mystery Pizza | 30 |
| **Total** | **100** |

**Tie-breaker (in order):**

1. Higher Mystery Pizza score.
2. Higher overall task-success rate.
3. Lower execution time.

## 6. Additional Awards

The event can award prizes beyond the main leaderboard:

- **Grand Champion** — highest overall PizzaBench score.
- **Best Generalization** — strongest Mystery Pizza performance.
- **Best Dataset** — highest-quality demonstrations and dataset documentation.
- **Best VLA** — best-performing language-conditioned policy.
- **Best Technical Innovation** — most interesting improvement in data collection, training, policy
  architecture, or deployment.
- **People's Choice** — best live demonstration or presentation.

## 7. What Teams Receive

Organizers provide: SO-101 robot hardware, teleoperation hardware, standardized camera, competition
workspace, reusable pizza and topping props, LeRobot environment, starter repository, baseline
policy, example dataset, GPU access or cloud credits, evaluation software, mentors, and technical
documentation.

## 8. What Participants Bring

Participants should bring: laptop, charger, GitHub account, Hugging Face account, and curiosity.

Recommended experience: Python, machine learning, computer vision, robotics, PyTorch. Previous
robotics experience is useful but not required.

Teams may include a mix of ML engineers, robotics engineers, software engineers, researchers,
students, designers, and product builders.

## 9. Models

Teams may experiment with supported robot-learning approaches including SmolVLA, ACT, Diffusion
Policy, other LeRobot-compatible policies, or custom approaches approved by organizers.

The organizer will provide at least one known-working reference pipeline so every team has a path to
a functioning autonomous policy.

## 10. Schedule

### Friday — Build the Pipeline

| Time | Activity |
|---|---|
| 18:00 | Registration and hardware assignment |
| 19:00 | Opening session |
| 19:30 | Robot and LeRobot workshop |
| 20:30 | Teleoperation and dataset collection starts |
| 23:00 | First dataset milestone |

### Saturday — Train the Robot

| Time | Activity |
|---|---|
| 09:00 | Technical office hours |
| 10:00 | Training and fine-tuning |
| 13:00 | First autonomous runs |
| 15:00 | Challenge 1 practice evaluation |
| 18:00 | Recipe Assembly development |
| 21:00 | Leaderboard checkpoint |

### Sunday — Competition

| Time | Activity |
|---|---|
| 09:00 | Final training window |
| 11:00 | Models frozen |
| 12:00 | Challenge 1 and Challenge 2 official evaluation |
| 14:30 | Finalists announced |
| 15:00 | Mystery Pizza configuration revealed |
| 16:00 | Championship evaluation |
| 17:00 | Final demos |
| 17:30 | Awards |
| 18:00 | Pizza party |

## 11. Dataset and Open Research

One objective of the event is to create reusable embodied-AI research data. Each team generates:
demonstration episodes, camera observations, robot states, actions, task descriptions, and
evaluation results.

The event will publish a clear dataset and intellectual-property policy before registration.
Recommended policy:

- participants retain ownership of their own code;
- model licensing remains the responsibility of each team;
- organizer access to demonstration data is explicitly defined in the registration agreement;
- public dataset contribution is opt-in unless a separate contributor agreement states otherwise;
- commercial reuse or resale of participant-generated data requires explicit rights rather than
  being implied by participation.

## 12. Safety

The competition intentionally avoids hazardous food-processing operations. Robot workspaces are
supervised. Participants must follow: hardware operating limits, organizer reset procedures,
emergency-stop procedures, and workspace access rules.

No participant may modify electrical or mechanical safety limits without organizer approval.

## 13. The Bigger Idea

The Robotics Pizza Hackathon is not really about pizza. The goal is to build a repeatable platform
for learning how robots acquire real-world skills.

**Today:** PizzaBench.
**Tomorrow:** warehouse packing, retail fulfillment, laboratory manipulation, household tasks,
industrial assembly.

The long-term vision is a distributed Physical AI competition where communities around the world
collect data, train policies, and evaluate robots using standardized tasks.


## 14. References

- [LeRobot](https://lerobot.ai)
- [SmolVLA](https://github.com/lerobot/smolvla)
- [ACT](https://github.com/lerobot/act)
- [LeIsaac](https://github.com/lerobot/leisaac)
- [Isaac Lab](https://github.com/NVIDIA-Isaac/isaac-lab)
- [LeRobot EnvHub](https://github.com/lerobot/lerobot-envhub)

Hackathon references:

-  https://www.xpizzaday.com/?utm_source=chatgpt.com 
-  https://embodied-ai-hackathon-spc.replit.app/?utm_source=chatgpt.com 
-  https://robothon.ff.com/?utm_source=chatgpt.com
-  https://europe-embodied.com/?utm_source=chatgpt.com
-  https://hacklabrobotics.com/?utm_source=chatgpt.com
-  https://www.seeedstudio.com/blog/embodied-ai-hackathon/?utm_source=chatgpt.com 
-  
