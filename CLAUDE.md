# iso-factories

Animated isometric factory simulations. Each factory is one self-contained HTML page:
markup, CSS and script inline, no build step, no external requests. Open the file in a
browser to run it.

- `line-4/index.html`: Northside Works, Line 4.
- `index.html`: the front page, listing and linking every factory. Same rules as a factory
  page: one file, nothing loaded from elsewhere. It follows the system light/dark setting
  with Rosé Pine Dawn and Moon; colours come only from that palette, and every text pair
  meets WCAG AA (4.5:1), which is why some roles differ from the palette's usual ones.
- `.github/workflows/pages.yml`: publishes the front page and every top-level directory
  with an `index.html` to GitHub Pages on each push to main. Pull requests run the same
  build without deploying. The repo's own docs are not published.

## Adding a factory

Give it its own top-level directory with an `index.html`, and link it from the front page
as `dir/index.html` (not `dir/`, which doesn't open the page from `file://`). The Pages
build fails if a factory isn't linked. List it in this file and the README too.

## Working on a factory page

- Keep it one file with nothing loaded from elsewhere. It has to run from `file://` and as
  a claude.ai artifact, whose content security policy blocks external images, fetches and
  most scripts.
- Semantic HTML and accessibility are part of the work, not polish: the canvas is
  `role="img"` with a written description, HUD values are `<output>` elements, controls
  are real buttons and fieldsets with a visible focus ring. The page starts paused under
  `prefers-reduced-motion`.
- Comments explain why, in plain sentences.
- Physical correctness matters more than anything visual. When a layout or behaviour rule
  below changes, update this file in the same commit.

## How the Line 4 script is organised

One IIFE, in sections marked `// ---------- name ----------`: projection, colours, boxes,
render cache, floor, layout constants, simulation state, robot arms, items, forklifts,
reservations, walking workers, route graph, line simulation, scenery, fault injection,
hover, speech, physics check, stall watchdog, OEE, HUD, main loop.

Each frame, `frame()` sub-steps the simulation (`updateLine`, `updateActor`, steps of at
most 0.034 s, so fast speeds keep gates and pick-ups exact), `buildScene()` rebuilds every
box from the simulation state, the boxes are drawn, then the overlays (plasma discs,
speech bubbles, hover outlines) and the HUD.

Known coupling to remove before a headless mode: speech bubbles expire inside
`drawBubbles()`, so a run without drawing never clears them. Randomness is
`Math.random()` throughout, so runs are not reproducible yet.

## Rendering

- The whole scene is axis-aligned boxes `{x0, y0, z0, x1, y1, z1, c, ...}` made by `B()`.
  A box's outline on screen is a hexagon: the intersection of three slabs in
  u = x − y, v = x − z, w = y − z.
- `paintOrder(boxes, opts)` sweeps pairs in u order, orders each overlapping pair along an
  axis that separates them (EPS 1e-4) and sorts topologically (Kahn), all on typed arrays
  kept between frames (`PO`). Boxes that intersect get no order: either is valid.
- The order can contain cycles: behind-relations along different axes that no order
  satisfies. One is permanent (the break room's window strip, a wall end and two
  machines). The sort walks back to find a cycle and releases the member whose broken
  orders share the least screen area. It never releases a box that is merely waiting
  behind a cycle; drawing that early shows as see-through panels.
- The render cache (`RC`, `S`):
  - A box is recognised by a hash of how it looks. Unchanged for 45 frames, it joins the
    cached layer, drawn once in an order worked out once. Nothing in the scene code marks
    anything static.
  - Each frame redraws only the 32 device-px tiles that something live touches (live
    boxes and shadows): everything in those tiles, cached or not, in one merged order.
    Pairs the layer drew in a free order are pinned (soft orders) so redrawn tiles agree
    with the layer around them.
  - Tiles are drawn whole on a scratch canvas and copied as rectangles. Do not draw
    through a clip instead: canvases anti-alias differently inside clip regions, which
    shows as seams at tile edges.
  - The screen keeps its pixels between frames; tiles are put back from the layer where
    last frame's live tiles or overlays were. Anything drawn over the boxes after the
    render must report its bounds with `rcOverlay(x0, y0, x1, y1)` (CSS px), or it will
    smear.
  - Promotion keeps the cached boxes' existing order and redraws only tiles that gained a
    box or changed order.
  - The full path runs while paint-order labels are shown, or when more than half the
    tiles are live.
  - A box built with extra fields other than `a`, `ns` and `stripes` is never cached.
- Hot loops: do not keep 32-bit values in variables shared between functions. Chrome's
  small integers are 31-bit, so every store boxes a number; keep them in locals or typed
  arrays.

## Traffic

The two lifts share a lane one lift wide at y = 10; people and robots cross it and walk
along it, and one-wide footbridges carry them over the conveyors. Everyone books floor
before moving, so nobody moves through anybody else. The table is in the reservations
section; the lifts' bookings are in the forklifts section after `forkReturn`, followed by
the ways round things that walkers use.

- `RES` is the reservation table: for each mover, boxes of floor, each with a level (1 the
  floor, 2 a footbridge deck, 3 the stairs, which are both) and a window of time, plus a
  box round them all for a quick reject. `FOREVER` ends a hold with no end in sight. No
  two movers' bookings meet in space, level and time; `resHit` finds one that would.
- A walker books its next legs (up to 10) before setting off (`planWalk`, `walkReady`):
  each leg as 0.25 m pieces with the time it is on each (0.15 s either side), any wait at a
  leg's start, and a hold where the walk ends. Each leg leaves at the earliest time it is
  clear; a wait that would sit in someone's booking makes the leg before it leave later
  instead. It leaves no earlier than booked and plans again if it falls 0.3 s behind, and
  `feetBlocked` stops it if someone is in the way all the same.
- Nobody waits on the lane (as far east as a lift can reach, `LANE_END_X`), on a
  footbridge or on its stairs (`noWaitAt`): a walker steps onto a bridge only when it can
  cross all the way, and waits before the lane rather than on it.
- When a plan runs into someone:
  - someone idle, waiting to walk themselves, or unpacking a pallet by hand (that spot is
    on the way to the depalletizers) steps aside (`askAside`): to a free spot close by, or
    back along the routes to a node off the way; waits there a moment for the walker to
    get by; then goes back the way they came. Someone idle in the way of that steps aside
    too, two deep at most. If they can't, and are waiting too, the walker backs off for
    them instead.
  - someone busy, or anyone who couldn't step aside: after 3 s held up (counted once per
    hold-up, whoever is in the way) the walker goes round them across open floor (`detour`:
    A* on a 0.1 grid, drawn straight where it can be) or another way along the routes
    (`reroute`), round everyone standing still and not only them, so it can't go round one
    into another and back for ever. If the node it was making for is taken, it makes for a
    free one near the spot it goes to next. Where they stand at the end of the walk it ends
    beside them (`shiftEnd`) or as near the end as it can (`settleNear`). A broken-down
    robot or a lift standing still is gone round at once.
  - failing all of that, it walks as far as it can, waits where waiting is allowed, and
    tries again.
- Walks from off the routes (after a step aside, say) go round anything solid or a flight
  of stairs in between first (`walkPoint`, `giveJob`, and any walking step that starts off
  the routes). A change like that to an idle loop goes into a copy of it (`ownPath`), so
  ways round don't pile up in the loop.
- A lift's outline is `liftShape`: its body, its forks, and whatever they carry. Every
  step that picks something up is marked `gets` (and one that puts it down on the lane
  `puts`), so the outline after it is known. A lift picks up off the lane only when the
  floor the load will cover is free of bookings.
- A lift books the same way (`driveOf`, `planLift`): the outline swept by every leg at
  1.6 m/s until it next stops off the lane, stops on the lane (the break-down area, the
  robot crate) included, and a hold where it stops (`holdLift`). Until it can book, it
  waits, asks anyone idle in the way to step aside, and its hover text says who it is
  giving way to. While driving, a scanner (`liftScan`) still checks each step against the
  other lift and people.
- A lift stopped mid-drive by a network outage keeps its drive (`freezeLift`): meanwhile
  only where it stands is held, and afterwards the rest goes on as booked, later by the
  length of the outage (`resumeLifts`). The other lift, stopped as long, is later by as
  much, so the two still never meet; planning again instead would let whichever went
  first take the other's way, and two lifts can shut each other in like that. A lift
  running late shifts the rest of its drive the same way (`shiftedDrive`), unless that
  would meet the other lift or someone busy, when it plans again.
- A lift's fault waits until it stands off the lane and clear of every walking route, so a
  broken-down lift never shuts anyone in. A lift halted by a network outage can, so if
  nobody has reached the rack to reset it within two minutes, IT is called anyway; they
  come in at the back door, clear of the lane.
- A robot's fault (random or injected) waits until it is off the footbridges and their
  stairs; then it steps off the walking routes to a clear spot within 1.8 m where there is
  one, and stops there (`stopRobot`), and does the same when the network goes. Going again,
  it walks back to where it was. One that still holds someone up (or a lift) is mended with
  the line machines (`faultPrio`), and the tech is never pulled off it; the tech, tools in
  hand, held up by one sees to it first, from their side of it.
- The dock is claimed when an outbound job is given out, so no delivery arrives while that
  lift is on its way. Otherwise it would wait at the dock pick, in the way of the lift sent
  to collect the delivery.
- Visitors (IT, contractors, deliveries) come in at the back door only when it is clear,
  and are on the table the moment they arrive. One worker at a time breaks down a delivery:
  the way to the shelves is one robot wide. A replacement robot's crate is sent for only
  once the robot has stepped off its pallet, since the forks go in under it.

Layout rules this depends on. Check them statically, sampling every route edge and every
lift corridor against the outline of a lift at each place it stops:
- The flights of stairs are solid steps from the floor up (`BRIDGES`, `STAIR_FEET`). No
  route edge on the floor crosses one (the physics check's route audit includes them),
  and stands, step-aside spots and searches keep off them (`underStairs`,
  `crossesStairs`). Feet follow the treads (`stairZ`). Each stair foot node is at least
  0.3 off its flight. Footbridge B is three steps on the west, so a robot fits between its
  foot and a lift at the reject-bin pick; the front aisle goes round the north foot of
  footbridge C, and the walk along the front edge passes the south one.
- Walking routes keep clear of the places a lift stops off the lane, or people queue at a
  lift that can't reserve its way out past them. A few edges still graze a lift's body at
  one (C2–R3 the reject-bin pick, HW–T3 and T3–T2 the strap dump); people held up there
  step aside or walk round. Don't add more, and never let a route graze a load a lift
  picks up: picking it up would grow the lift over whoever is there. That is why the bale
  spot sits where it does: a robot just fits along the front edge past a lift picking it
  up.
- A lift stopped at one place doesn't stick into another lift's corridor, or the two wait
  on each other. The one exception is harmless: a lift at the strap pick sticks 0.08 into
  the way out of the charger, which only makes a lift leaving the charger wait.
- The parking spots sit off the lane and clear of every bay a lift drives into with a
  pallet, which is why both are in the west.
- The front aisle by the maintenance bench reaches the rest of the floor only across the
  lane, so it has two crossings, LK and LM, 3.05 apart: more than a lift with its forks
  and a robot beside it, so one lift halted on the lane can't shut anyone in.
- The walk to a lift's repair stand keeps clear of the parking spots, the charger and any
  other lift that is down, since nobody waits behind a lift that isn't going to move.

## Line 4 rules

Rules Rob has set. Keep them true.

Depalletizing
- An arm can't pass through a pallet or the destrapper. After the destrapper the conveyor
  splits in two.
- Two depalletizers work at once: Rocky and Bullwinkle.
  - They never cross over each other; if one needs to, the other stops. They stay
    interlocked.
  - Each picks only from conveyor segments adjacent to it (any adjacent segment) and never
    reaches over the other.
  - If each is waiting for the other, that deadlock is detected and one, chosen at random,
    moves out of the way.
  - Putting boards on the board pile at the same time counts as blocking.
  - An idle Bullwinkle may stack boards when a board pallet is waiting.
  - The conveyors leading to Bullwinkle may be pipelined.
- Branch B's exit is one square further north, giving Bullwinkle an extra adjacent
  conveyor square. Rocky's widget pallet conveyor extends one more segment east.
- When two empty pallets are blocked west and north-west of Rocky, the conveyor reverses
  so a forklift can pick them up at the junction south-west of Rocky.

Pallets and waste
- Board pallets go only on the depalletizer outfeeds, never on the dock track. They are
  stacked 12 high. There is one outfeed of board pallets out of the building, and a
  pallet never leaves empty.
- The recycling compactor fills up and ejects a compacted cube onto a waiting pallet; a
  forklift takes it to the dock and the pallet is replaced.
- A replacement robot's crate leaves on the pallet it came on.
- Forklifts never pass through conveyors.

Line
- The output track is four separate machines.
- A testing and rejection station sits between the dryer and the tripleizer. It rejects
  widgets that weren't dried in time (waited too long between painter and dryer) and
  widgets that fail the quality check.
- The MCC is on the north wall. There is no MCC box on the west wall and no wireless
  network box.

Power and faults
- A switchboard failure cuts power, which also takes the MCC down. The MCC going down
  stops the machines but doesn't cut power.
- The tech fixes by priority: MCC and switchboard, then line machines, then waste
  processing. A lower-priority repair is paused for a higher-priority fault. A robot down
  where it holds someone up counts as a line machine.
- After a diagnostic assessment (random duration) each fault shows a progress bar. The
  estimate is 100%; the real repair can finish early or blow out.

People
- Tea or coffee, with optional sugar, which boosts the effect a little. Spoons get dirty
  and need cleaning like cups, and sometimes go missing and need resupplying.
- Speech bubbles in a blocky font follow the speaker:
  - a robot going to recharge: "I'll be back"; sometimes after charging: "Resistance is
    futile"
  - the tech starting to DJ: "wikka wikka waah"
  - the operator in the break room while a robot is charging: "Creepy"
  - the tech or operator, now and then: "Work Work"
  - the IT guy arriving: "Hello IT. Have you tried turning off and on again?"
  - occasionally, a human taking fresh cartons to the packer: "This cardboard smells like
    butts"

Scene
- A compass, and a spinning block-model lightning bolt on the forklift charging station.

## Checking a change

- Impossible moves are flagged, never prevented: they are logged in `sim.viol.list` and
  counted in the HUD's Physics row. A change to layout or routing should leave that at
  zero over a long run.
- A long run is quickest headless. The script is one closed IIFE, so serve a copy of the
  page with a line before `new ResizeObserver(resize).observe(canvas)` that puts `sim`,
  `actors`, `forklifts`, `updateLine` and `updateActor` on `window`; stub
  `requestAnimationFrame`, replace `Math.random` with a seeded generator so a run can be
  repeated, and step frames as `frame()` does, clearing expired speech bubbles yourself.
  Grind many seeds for hours, at 4× and 1× (the sub-step size differs) and at each
  depalletizer speed. Watch the wall time too: a run that slows down is piling something up.
- The physics check covers lifts against each other and against people on foot, using
  the same outlines as the traffic rules; people (robots included) against each other on
  the same level; and feet against the treads of the stairs.
- Traffic changes need a jam check as well as the physics check: in a long run, look for
  a lift with work to do, or a person walking somewhere, that hasn't moved for over a
  minute. Waiting for a repair (a lift or robot down, a crew at work in a bay) or through
  a network outage (robots frozen where they stand, on a footbridge too) is expected;
  anything else is a deadlock. Compare throughput with main on the same seeds too: the
  table costs a few percent, since people now queue for one another where they used to
  walk through.
- Render cache changes have been checked in headless Chromium on every cached frame:
  the screen equals the layer plus that frame's live tiles, the layer equals a fresh
  drawing of the cached set, and the cached frame differs from a full render by no more
  than a full render differs from itself with its boxes shuffled.
