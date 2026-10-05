# Porting Line 4: a Rust simulation, a TypeScript renderer and Phoenix

Planning only: nothing has been ported. Written in October 2026 against main at `f28bdeb`.
The figures were measured headless in Chromium on that build; the last section says how.

## In short

- Move the simulation to Rust and the drawing to TypeScript. Put Elixir and Phoenix around
  them, not under them: the simulation is one tightly coupled step function, which the BEAM
  gains nothing from running.
- First separate simulation from drawing inside the current page. It is the biggest single
  piece of work, it pays off whichever way the port goes, and the jam harness keeps working
  while it is done.
- Build the simulation as one Rust crate with two hosts: WebAssembly in the browser, which
  keeps a static build possible, and a Rustler NIF on the server, for a shared factory that
  runs all the time and for batch runs without a browser.
- Streaming from Phoenix costs 2.4–5.6 KB/s per viewer at 20 updates a second, compressed,
  with the browser smoothing in between. Bandwidth needn't shape the design.

## What there is now

`line-4/index.html` is 6,132 lines, nearly all of it one script in marked sections.

| Part | Sections | Lines |
|---|---|---|
| Simulation | layout constants, simulation state, robot arms, items, forklifts, reservations, walking workers, route graph, line simulation, fault injection, speech, physics check, stall watchdog, OEE | about 4,500 |
| Drawing | projection, colours, boxes, render cache, floor, scenery, hover, HUD, main loop | about 1,400 |

The line between them isn't clean yet (see step 1). Measured half an hour into a run:

- One frame of simulation (1/60 s at 1×, sub-stepped as `frame()` does): 0.12 ms in V8.
  Speed in the browser is no reason to port it.
- `buildScene()`: 1.1 ms, for about 2,250 boxes.
- Those boxes as JSON, seven numbers each to 1 cm: about 95 KB.

## What a port gives up

CLAUDE.md's rules for a factory page: one file with nothing loaded from elsewhere, no build
step, running from `file://` and as a claude.ai artifact, and static hosting on GitHub Pages,
whose workflow copies the pages as they are.

A Phoenix app needs a server. A WebAssembly build of the simulation with a bundled
TypeScript renderer can still be served statically, but not as one file without a build
step. Whether a claude.ai artifact can run WebAssembly hasn't been checked.

CLAUDE.md, the README and the Pages workflow would need rewriting for the new layout. The
rules in CLAUDE.md about how the line behaves carry over unchanged, and so does the way a
change is checked.

## Where each part goes

| Part | Goes to | Because |
|---|---|---|
| Simulation | a Rust crate | typed, fast, deterministic, and it builds for both hosts |
| Drawing | TypeScript | it is already JavaScript; mostly a translation |
| Serving, viewers, history, controls | Elixir and Phoenix | supervision, fan-out, persistence |

Why not the simulation in Elixir: every sub-step needs one consistent view of the whole
floor. Bookings are checked against every mover's, and lifts and walkers change their plans
in reply to one another within the same step. One process per actor would turn that into a
coordination problem and give up determinism. One process holding the whole world gains
little from the BEAM and pays for immutable updates of a large world every 0.034 s.

## Step 1: separate simulation from drawing, in place

Done in the current page, in JavaScript, with the jam harness and physics check running
throughout.

- **Steps carry code.** Lift and walker steps hold closures: 80 `on:`, 13 `wait:`, 9
  `fallback:`, 7 `dyn:` and 2 `until:`. Turn them into data: a step kind with its
  arguments, run by one dispatcher. In Rust, closures that capture the world fight the
  borrow checker; an enum doesn't.
- **Objects point at each other.** People and lifts refer to one another (`blockedBy`,
  `heldBy`, `busyBy`, shared `repair` objects), and `RES` is keyed by mover objects. Give
  everything an id and look things up by it.
- **Iteration order.** JavaScript `Map`s iterate in insertion order, and the simulation
  depends on it (`RES` in `resHit` and `downIn`, say). Keep that order explicitly.
- **Randomness.** The 49 `Math.random()` calls become one seeded generator, so a run repeats
  without the harness's override.
- **Speech bubbles** expire in `drawBubbles()`. Move that into the simulation; CLAUDE.md
  already lists it as coupling to remove.
- **Poses.** Building the scene uses simulation geometry: feet on the treads (`stairZ`) and
  the knee IK, hands stopping at whatever stands ahead (`roomAhead`), where carried things
  are held. Have the simulation work out poses (joint positions, held items), so the scene
  builder only turns poses into boxes.
- **A snapshot.** `snapshot()` returns plain data, and `buildScene(snapshot)` reads nothing
  else. Hover text reads simulation state too (who a lift is giving way to), so what it
  needs goes in the snapshot.

Done when the jam suite (16 seeds × 8 hours at 4×, 16 × 4 hours at 1×) shows no deadlocks,
no physics violations and throughput level with main, as means over seeds, and the render
cache checks still pass.

## Step 2: the simulation in Rust

- One crate with no I/O: `World::new(seed)`, `step(dt)`, `snapshot()`, and commands in
  (pause, speed, fault injection, depalletizer speed).
- Everything in arenas with ids (a `Vec` or a slot map). Ordered maps (`IndexMap`,
  `BTreeMap`) wherever order matters, never `HashMap`, whose order is random.
- Port in order of dependence: geometry and layout, items and belts, arms, line simulation,
  faults, then reservations, lifts, walkers and routes. The last four (forklifts 1,093
  lines, route graph 1,120, reservations 288, walking 88: about 2,600) are the hardest:
  dense, full of callbacks, and where nearly every deadlock so far has been found.
- Floating point: Rust's maths functions aren't guaranteed to match V8's bit for bit, so
  runs drift apart from the JavaScript over time. Check the port as changes are checked now:
  statistically, over many seeds, not frame by frame.
- The jam suite and physics check become native Rust tests. Batch runs across all cores
  without a browser should be much faster than now (3–4 minutes of wall time per 8-hour seed
  at 4× in headless Chromium, several at once on four cores); not yet measured.

Two hosts for the same crate:

- **WebAssembly** (`wasm32-unknown-unknown` with wasm-bindgen): the simulation runs in the
  browser beside the renderer, with no server.
- **A Rustler NIF:** the world in a `ResourceArc<Mutex<World>>`, owned by one GenServer per
  factory. A NIF shouldn't run longer than about 1 ms on a normal scheduler, so step in
  chunks, or mark the step `#[rustler::nif(schedule = "DirtyCpu")]`. A Rust panic comes back
  as an Elixir exception, but anything that aborts takes the whole VM down. A Port (the
  crate as a separate OS process, talking over stdin and stdout) is the safer alternative,
  at the cost of copying snapshots between processes.

## Step 3: the drawing in TypeScript

Mostly a translation. Keep everything the rendering rules in CLAUDE.md depend on: the paint
order's typed arrays, the render cache drawing whole tiles on a scratch canvas with no
clipping, `rcOverlay`, and the note on 31-bit small integers (TypeScript compiles to the
same JavaScript).

New work:

- Types for boxes, snapshots and poses.
- The building and fixed machinery built once in the browser from the layout; only the
  snapshot changes from frame to frame.
- Interpolation between snapshots that arrive from a server less often than the frame rate.
- The clearance checks build the scene and test every box against every other, so the scene
  builder must run headless under Node: no DOM or canvas in it.
- Check against the current page with the render cache checks, and by drawing the same
  snapshot with both renderers and comparing pixels.
- Phoenix's esbuild strips TypeScript types without checking them; run `tsc --noEmit` in CI.

## Step 4: Phoenix around it

- One supervised process per factory, holding the world and stepping it on a timer.
- LiveView for the page. HUD values stay `<output>` elements and the controls stay real
  buttons and fieldsets, so the semantic HTML and accessibility carry over. The canvas is a
  LiveView hook written in TypeScript.
- Snapshots reach the hook over a Channel as binary payloads, or are made in the browser by
  the WebAssembly build.
- Several people can watch one factory, with Phoenix PubSub fanning the frames out.
- Run history, fault logs and OEE in Postgres or SQLite, as Ash resources.
- Batch jam runs from Elixir with `Task.async_stream` over seeds, or from a plain Rust CLI.
- A fault-injection API.
- A Nix flake for development: Erlang and Elixir, Rust with the wasm32 target, and Node for
  esbuild and `tsc`.

## Bandwidth between browser and Phoenix

With the simulation on the server, the browser needs the state it draws from, not boxes.

**Joining:** the full state is 1,200–1,350 values: 27–42 KB as JSON, 6–8 KB compressed.
The building and fixed machinery aren't sent; the browser builds them from the layout.

**Streaming:** typically 30–50 values change per message. In one 4× window, one message in
twenty carried 280 or more, probably a load arriving.

| Updates per second | Raw JSON | Compressed WebSocket | Binary |
|---|---|---|---|
| 60 | 35–65 KB/s | 6.6–11 KB/s | 10–17 KB/s |
| 20, smoothed in the browser | 12–38 KB/s | 2.4–5.6 KB/s | 3.4–8.6 KB/s |

- Compressed means per-message compression on the Phoenix socket
  (`websocket: [compress: true]`).
- Binary means 6 bytes per changed value (a 2-byte id and a 4-byte float) and an 8-byte
  header per message.
- At 4× the 60-per-second rate hardly changes: the same things move, further each frame.
- 20 updates a second compressed is 20–46 kbit/s, or about 9–20 MB per hour of watching.
- Streaming boxes instead would be about 95 KB a frame: around 5.6 MB/s at 60 a second.
- Upstream, browser to server, is button presses and hover requests: a few bytes each.

**Going lower.** Much of what changes each update could be worked out in the browser. Items
on a belt move at its speed, a stride follows from the distance walked, lifts and walkers
already book their routes with times, and arm moves are scripted segments. Sending only
events and booked plans should come to about 1 KB/s or less; not measured. The cost is that
the browser then runs part of the simulation, the very code the port moves to Rust.

**A shared factory.** Outbound traffic grows with the number of viewers: 100 viewers at
4 KB/s is about 3 Mbit/s. Per-message compression runs separately for each connection, so
its CPU cost grows with viewers too. One simulation frame costs 0.12 ms in JavaScript today,
so encoding and sending will cost more than stepping.

**Recommendation:** 20 updates a second, compressed, with the browser interpolating: 2.4–5.6
KB/s per viewer.

## Decisions to make

- Who runs the simulation: one shared factory on the server that everyone watches (controls
  are then global), one per viewer on the server, or each browser running its own through
  WebAssembly, with the server only serving pages and storing runs?
- Keep a static GitHub Pages build alongside, through WebAssembly?
- Is the claude.ai artifact still a target? If so, can it run WebAssembly?
- Does the single-file page stay as the reference until the port matches it?

## How the figures were measured

Headless Chromium with the hook described in CLAUDE.md under "Checking a change": a seeded
`Math.random`, frames stepped as `frame()` does, expired speech bubbles cleared.

- **Sizes:** lines between the section markers in `line-4/index.html`; closures and
  `Math.random()` calls counted with grep.
- **Costs:** seed 7, after 30 simulated minutes: 1,800 frames of simulation timed together,
  and 100 calls of `buildScene()`.
- **Bandwidth:** seeds 7 and 11, a 20-second window after 30 simulated minutes at 1× and
  another after a further hour at 4×.
  - Each frame, the state a renderer needs was flattened to one value per path:
    - people: pose, animation, what they carry, speech bubble; not their paths, plans or
      bookings;
    - lifts: position, heading, forks, load, repair state; not their steps or drives;
    - the two depalletizers' arms and the palletizer's, without their job lists;
    - the machines' own fields;
    - `sim`, without the OEE history and the violation list.
  - Numbers were rounded to 1 mm, and references to people, lifts and machines became ids.
  - A message is the values changed since the last one, sized three ways: as JSON; through
    one deflate stream with a sync flush per message, which is what per-message compression
    with context takeover sends; and as binary.

Which fields a renderer needs is a judgement, and the windows are short, so treat the
figures as estimates.
