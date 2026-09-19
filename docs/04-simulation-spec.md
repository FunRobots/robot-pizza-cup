# Robotics Pizza Hackathon — Simulation Specification

Version 0.1

Companion document: [Technical Competition Spec](03-technical-spec.md) covers sections 1–15 of the
original combined spec (physical hardware, challenges, evaluation protocol).

---

## 16. What Simulation Is For

Simulation should not become a second robotics project that delays the hackathon. For V1 it has four
purposes:

1. validate task geometry;
2. validate reset and scoring logic;
3. allow participants to learn the workflow before touching hardware;
4. test randomized evaluation configurations cheaply.

Simulation is **not** required to solve sim-to-real for the first event.

## 17. Recommended Simulation Stack

**Primary recommendation: LeIsaac + Isaac Lab + LeRobot EnvHub**

Reason: existing SO-101 support, existing manipulation tasks, LeRobot integration, teleoperation
examples, Gym-style environment, ability to reuse patterns from pick-object environments.

Do not create your own physics engine or SO-101 model.

## 18. Beginner Path

If you have no simulator experience, use this sequence.

**Step 1 — Run an existing SO-101 environment.** Do not modify anything. Run *lift cube* or
*pick orange*. Goal: see SO-101 in simulation; understand reset, observations, and the action API.
Acceptance: you can launch and reset the existing environment.

**Step 2 — Change the object.** Replace the orange/cube asset with a pepperoni cylinder. Do not
change the robot. Do not add AI. Goal: pick a red disk. Acceptance: teleoperation can grasp and move
the object.

**Step 3 — Add pizza target.** Create a large flat cylinder representing pizza. Success condition:
`pepperoni center is inside pizza radius AND pepperoni is below height threshold`. Acceptance:
simulator detects successful placement.

**Step 4 — Add multiple toppings.** Spawn six pepperoni props. Track state separately for each
object. Acceptance: environment reports `placed = 4 / 6`.

**Step 5 — Add second ingredient type.** Create a second rigid geometry/color, e.g. pepperoni = red
cylinder, mushroom = beige rounded block. Acceptance: Recipe Assembly can be represented.

**Step 6 — Add randomization.** Randomize topping XY positions, pizza XY position, recipe, and
number of toppings. Store a seed. Acceptance: the same seed reproduces the identical scene.

## 19. Simulation Scene

```
World
│
├── Table
├── SO101
├── Front Camera
│
├── Pizza
│
├── Pepperoni Bin
│   ├── Pepperoni_01
│   ├── Pepperoni_02
│   └── ...
│
└── Mushroom Bin
    ├── Mushroom_01
    └── ...
```

## 20. Robot

Use the available SO-101 URDF/model. Do not manually recreate kinematics, joint axes, link
dimensions, or meshes. Simulation and real robot should use compatible joint ordering.

## 21. Action Space

Keep the first environment close to the physical robot interface.

Suggested action:

```
[
    joint_1,
    joint_2,
    joint_3,
    joint_4,
    joint_5,
    gripper
]
```

Do not introduce Cartesian control unless needed.

## 22. Observations

**Minimum:**

```json
{
    "front_rgb": "image",
    "joint_positions": "[...]",
    "task": "place six pepperoni on the pizza"
}
```

**Optional:** gripper state, wrist camera, simulation-only object state for evaluation.

**Important:** do not expose ground-truth object coordinates to the participant policy if the real
robot will only receive camera observations. They may be used internally by the simulator for
scoring.

## 23. Challenge 1 Success Function

Per object:

```
success =
    object center inside pizza boundary
    AND object resting on pizza
```

Episode success: `number_correct >= required_count`.

## 24. Challenge 2 Success Function

For recipe "4 pepperoni, 2 mushrooms," success requires:

```
pepperoni_on_pizza == 4
AND mushrooms_on_pizza == 2
AND incorrect_objects == 0
```

Partial score allowed.

## 25. Domain Randomization

For V1 use only physically meaningful bounded randomization.

**Recommended:** object XY ±30 mm; pizza XY ±20 mm; object yaw; small camera pose perturbation;
small brightness variation.

**Do not initially randomize:** robot dimensions; actuator dynamics heavily; friction across
unrealistic ranges; camera viewpoint radically; object geometry dramatically.

The objective is benchmark validation, not publishing a sim-to-real paper.

## 26. Simulation Assets

Keep all food assets primitive.

- **Pizza:** cylinder.
- **Pepperoni:** small cylinder.
- **Mushroom:** rounded cube / simple mesh.
- **Bins:** boxes.

This allows a working simulator before spending time on visual realism. Photorealistic pizza assets
can be added later for marketing renders, not for physics validation.

## 27. Simulation Repository Structure

```
simulator/
│
├── README.md
├── environments/
│   ├── precision_topping.py
│   ├── recipe_assembly.py
│   └── mystery_pizza.py
│
├── assets/
│   ├── pizza/
│   ├── pepperoni/
│   └── mushroom/
│
├── configs/
│   ├── robot.yaml
│   ├── camera.yaml
│   └── randomization.yaml
│
├── scoring/
│   └── metrics.py
│
├── tests/
│   ├── test_reset.py
│   ├── test_scoring.py
│   └── test_determinism.py
│
└── scripts/
    ├── teleoperate.py
    ├── random_policy.py
    └── generate_dataset.py
```

## 28. Simulation Acceptance Criteria

Simulation V1 is complete when:

**Environment:** SO-101 loads; robot moves; gripper works; camera renders; scene resets.

**Challenge 1:** six toppings can be spawned; topping can be grasped; placement is detected
correctly.

**Challenge 2:** two ingredient types exist; recipes can be generated; recipe score works.

**Challenge 3:** environment accepts random seed; seed reproduces configuration; bounded
randomization works.

**Integration:** demonstrations can be recorded; observation/action structure is compatible with the
intended LeRobot workflow.

## 29. Simulation vs. Real-World Validation

The simulator is considered useful only if physical results remain the source of truth.

| Feature | Simulation | Physical |
|---|---|---|
| Reachability | Validate | Validate |
| Task geometry | Validate | Validate |
| Scoring | Validate | Validate |
| Reset procedure | Prototype | Final |
| Camera pose | Approximate | Final |
| Grasp reliability | Indicative | Final |
| Policy performance | Indicative | Final |
| Sim-to-real transfer | Optional | Measure |

## 30. Most Important Simulation Rule

Do not spend September trying to perfect simulation while the physical reference pipeline is broken.

**Priority order:**

1. Working physical teleoperation
2. Working physical dataset
3. Working physical training
4. Working physical inference
5. Working evaluation
6. Simulation
7. Sim-to-real optimization

Simulation exists to reduce risk. It must not become the main risk.

---

The recommended simulation route is grounded in current LeRobot capabilities: LeIsaac exposes SO-101
tasks such as picking oranges and lifting cubes, and LeRobot has an official SO-101 URDF retrieval
path. There is also a LeRobot MuJoCo/HIL path, but its documented reference environment is currently
Franka-based, so it is less direct for this hackathon. See
[References & Next Steps](09-references-and-next-steps.md) for source notes.
