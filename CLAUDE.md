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
box from the simulation state, the boxes are drawn, then the overlays (plasma discs, repair
bars, speech bubbles, hover outlines) and the HUD.

Known coupling to remove before a headless mode: speech bubbles expire inside
`drawBubbles()`, so a run without drawing never clears them. Randomness is
`Math.random()` throughout, so runs are not reproducible yet.

## Rendering

- The whole scene is axis-aligned boxes `{x0, y0, z0, x1, y1, z1, c, ...}` made by `B()`.
  A box's outline on screen is a hexagon: the intersection of three slabs in
  u = x − y, v = x − z, w = y − z.
- `paintOrder(boxes, opts)` sweeps pairs in u order, orders each overlapping pair along an
  axis that separates them (EPS 1e-4) and sorts topologically (Kahn), all on typed arrays
  kept between frames (`PO`). Boxes that intersect get no order: either is valid. So
  boxes that must show one in front of the other never overlap: a wrapped pallet's film
  stands clear of its load (`FILM_E`), labels hidden under a carton aren't built, and the
  labeller's post stops under its head (and see Clearances below).
- Paint on the floor (lines, spots, scorch marks, the compass, the break room's floor, the
  alcoves' glow) is built with `decal()`, sunk just below the floor: whatever stands on it
  only touches it, so is always drawn over it. Layer 1 is painted over layer 0.
- Repair bars are drawn flat over the rendered scene (`drawRepairBars`), like the speech
  bubbles; hovering one reads its text from where it was drawn. As boxes they ran into
  whatever stood near and could be drawn behind it.
- The alcoves' plasma discs are drawn over the scene too, as true circles on the back
  panel, clipped by every box in front of them by the paint order's rule (`drawDisc`). Seen
  along (1, 1, 1), the back panel shows only through the side openings, so the canopy over
  each alcove is shallow: deeper, it hid the disc, and a list of only some occluders drew
  the disc over the canopy and the next alcove instead.
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

## Clearances

Nothing solid passes through anything else: not machines through what they carry or what
goes by them, and not people (see Traffic).
- Footbridge C's deck is 2.0 up (the others 1.8): a full pallet on the output track stands
  1.82 to the tops of its labels.
- The track sections' beacons stand on the floor beside the track, and the yellow joints
  between its drives are on the frame's sides. On the track, either would catch a
  pallet's deck.
- The palletizer's shoulder is 1.9 up on a column, and its wrist is long, so its upper arm
  passes over the hard hats (1.92 at the top) of people on the walk between it and the
  track even reaching down to the bottom layer, and it reaches every slot on the pallet.
  It lifts a carton to `PZ_UP`, turns about its base with it tucked in to `PZ_TURN`
  (`turns`, `turnLerp`), and lowers it straight down into its slot. Carried straight
  across, a carton would go through the column, over the walk at head height and through
  track 2's e-stop. Its hand takes a carton by suction from above: fingers at its sides
  would hit the cartons beside its slot.
- The depalletizers lift by suction too, widgets by the nub on top: fingers can't fit
  between widgets packed 2 cm apart on a pallet, or past the lane dividers on the belt.
  Their hand is sized for what it is going for (`forBoard`).
- The wrapper's boom carries its mast round the pallet at `WR_R`, with the film roll (at most
  `WR_ROLL` either side of its spindle) beside it a little behind (`WR_LAG`). That fits
  between the load and the frame's posts, and clears footbridge C and a pallet at the
  labeller; a bigger roll, or the roll outside the mast, would not. The posts, the floor
  the boom sweeps either side of the track, and the control pedestal (`WR_PEDESTAL`, off the
  walk from TN to MT4 and east of the sweep) are obstacles to walkers, and the wrapper's
  repair spot (WF) stands clear of the sweep.
- Belt rails are cut down to the belt where something goes through them (`conveyor`'s
  cuts): belt A's at both pushers, which push their widget ahead of them out over the far
  rail; belt B's at the diverter, whose paddle pushes the held carton across, the way it
  stood, onto the reject conveyor. That one's rails are thin and its north one stops where
  footbridge B's stairs begin. The flap detector stands up the belt, clear of the gap.
- Guides stand outside the widgets they guide: A1's lane dividers stop short of the
  singulator, whose steps follow the widgets steered in; A3's dividers start only where a
  widget steered to a side lane has cleared the line of one going straight on.
- Each e-stop is fixed to its machine (`ESTOPS`): its front, plinth, frame or beacon post,
  out of reach of the hands of whoever works at its service spot (the low ones below
  them). The infeed's and tracks 1, 2 and 4's beacons stand on posts beside the track,
  below hand height, with the e-stop on the post; track 3's stays on the floor, under the
  wrapper's mast. The other beacons stand clear of their machine's parts and of the
  repairer's hands too: belt A1's on the far rail, the testers' on top of the arch, the
  depalletizers' (smaller, `lamp`) on the corner of the plinth beside the pedestal.
- The break room's walls and furniture (`BRK`) are obstacles to walkers. Someone on a break
  stands at BRIN facing the table, clear of the sofa against the back wall and the stools
  at the table's ends; the counter runs under everything on it, and the vending machine
  stands beside it, not in it.
- Lifts: the forks are 0.95 long (`FORK_TIP`), as long as a bin is deep, so their tips
  never reach past a bin into what stands behind it (a station's chute, the de-strapper).
  Pallets and bins stand on blocks, not stringers, so forks go in under them from either
  side, and loads sit square to the building whichever way a lift faces (turning them with
  it would make a loaded lift wider than the lane). A lift sets its forks on the lane
  before it drives into a bay and after it backs out (`bay`'s pre and post): to just under
  the deck of a load on the floor or a track (`FORK_FLOOR`, `FORK_TRACK`), or over the
  compactor or shredder before tipping a bin (`BIN_TIP`). It carries a bin at `BIN_CARRY`,
  over a full one standing in its spot. A load comes up on the forks from where it stood (a
  pick's `on` runs as the forks start to lift) and is set all the way down before it is
  let go. A lift backs out of its parking spot, down to the charger's approach, and along
  the lane to a bay by the west wall: nose first, its forks would go into the paint store,
  out over the dock track, or through the wall. The mast, carriage and scanners are within
  its outline.
- No pallet rolls across forks: the dock track holds a pallet set on it until the lift has
  its forks out from under it, the junction is busy while any lift's outline covers it,
  and a lift is sent for a pallet at the junction only once it has rolled back there. The
  compactor's ram comes down only once no lift's forks are over its hopper.
- The roof columns (`ROOF_COLUMNS`) stand clear of the transfer leg, the break room and the
  depalletizers' reach (an elbow folds back 2.1 m), and are obstacles to walkers. The cardboard bin is narrow enough to clear the final
  reject bin's pallet. The dock door's posts stand inside the opening, clear of the track,
  and it is tall enough for a robot's crate on the track (`DOCK_DOOR_H`: the lid is 2.77 up); the shipping dock's threshold stops either
  side of the track. The junction guides stand either side of the transfer leg, clear of
  pallets going straight on along the main line.
- The shredder's hopper is open, walled round, with its rollers inside, and its service
  spot (MSH) stands back far enough that hands don't reach into it.
- The operator's windmill sweeps 1.2 m round: it is done on the compass rose (WM, a spur
  off TN), clear of everything and off the routes, and books that floor (`WINDMILL_R`) once
  it is free. A robot on standby dances to the tech's set, arms out, only where there is
  room all round (`DANCE_R`: nothing solid, not in a charging alcove), and books that floor
  while it does.
- On the stairs each foot comes down on the highest tread under it (`stairZ` at the foot's
  corners) and the knee bends to suit (two-bone IK in `buildActorBoxes`); so does a new unit's
  foot on its pallet's deck as it steps off. Its crate stands open round it (lid off, the
  front panel down) until it has stepped off, and only then lies flattened on the pallet. Climbing, arms
  hang at the sides: swung forward, a hand goes into the riser ahead.
- At work or carrying something, hands reach no further than whatever solid stands ahead
  (`roomAhead`, against the obstacles to walkers): the shoulder swings less and the forearm
  rises, and a carried thing is pulled in towards the body, as far as there is room
  between the two. Carried things are held clear of the body.
- The charging alcoves' back panel and side walls are obstacles to walkers. A robot charges
  at `ALC_DOCK`, far enough out from the back panel that the foot it walks in on (0.56
  ahead at full stride) stops short of it.

## Line flow

The line never locks up by itself. Rework is a loop: open-flap cartons go off belt B onto the
reject conveyor, are unpacked at the rework table, and their widgets go back onto A3, which
feeds the packer, whose cartons pass the flap detector on belt B. With A3 backed up, the
packer can't put a carton on belt B, belt B is held behind an open-flap carton the diverter
can't push off a full reject conveyor, and only rework empties that. So:
- a reworked widget goes onto A3 ahead of the dryer's: the single file holds back short of
  the fan while a reworker waits;
- a reworker who has waited `SET_DOWN_T` for A3 while more rejects are waiting sets the
  carton down on the shelf under the rework table (`REWORK_SHELF` at most) and goes for the
  next. A carton on the shelf is fetched back to the table once A3 has room.

Reject bins: one lift takes a bin from its station to the compactor and tips it (`forkBinOut`);
the other, if it is free, brings the spare to the bare station meanwhile, not once the
station's own bin is on its way home and not to both stations at once. Where the emptied bin
goes is settled as it leaves the compactor (`binNext`): onto the spare spot once the spare has
gone onto the station or is on its way there; back to its own station (`binHome`) if the spare
is still on its spot, calling off the lift sent for it, unless that one is already in the
spare's bay about to lift it (then it waits a moment in the compactor's bay, off the lane and
out of the way). Settled earlier, or waiting for the spare spot in its own bay, where the other
lift had to drive in for the spare, each lift undid the other's move after a timeout, for a
quarter of all bin trips. Emptying at 8 of 12 is kept: at 10 there were fewer trips but the
line held at a pusher again, for no more painted.

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
  instead. It leaves no earlier than booked and plans again if it falls 0.3 s behind;
  `feetBlocked` stops it if someone is in the way all the same, and `walkBlocked` if a lift
  is (one running late). Given a new job part-way along a route edge that the new way runs
  straight on along, it carries on rather than first going back to the node behind it: half
  way up a flight of stairs, that would turn it round into whoever is following. Not from the
  floor: a spot partly over a bottom step can't be walked back to once stepped off (aside, say),
  so a walk that ends at one ends at the foot of the stairs instead.
- Nobody waits on the lane (as far east as a lift can reach, `LANE_END_X`), on a
  footbridge or on its stairs (`noWaitAt`): a walker steps onto a bridge only when it can
  cross all the way, and waits before the lane rather than on it.
- When a plan runs into someone:
  - someone idle, waiting to walk themselves, at a repair only waiting for the other half
    of the crew (the one they wait for may be the one they are in the way of; for a crew
    once per fault, or the two step aside for each other for ever; for anyone else every
    time, or someone let into a dead end, a refill at the wrapper say, is shut in, and a lift
    in a bay waits until the tech is back from whatever else they are mending), at the
    rework table only
    waiting for room on the belt (it may be backed up behind a machine whose repairer they
    shut in), or unpacking a pallet by hand (that spot is on the way to the depalletizers)
    steps aside (`askAside`): to a free spot close by, or back along the routes to a node
    off the way, clear too of where any lift waiting to set off wants to go where there is
    room (or two lifts would send them back and forth between them); waits there a moment
    for the walker to get by; then goes back the way they came.
    Someone idle in the way of that steps aside too, two deep at most. If they can't, and
    are waiting too, the walker backs off for them instead. Someone on the way to a repair
    doesn't step aside for anyone on foot who isn't (`toRepair`): the two would step aside
    for each other at once and both come back, for ever where the way to a robot that is
    down is shut by someone waiting to get past it. Someone on the floor partly over the
    bottom step of a flight (they had started up it) first steps straight back off it
    (`offStairs`): every other way out would cross the stairs.
  - someone busy, or anyone who couldn't step aside: after 3 s held up (counted once per
    hold-up, whoever is in the way) the walker goes round them across open floor (`detour`:
    A* on a 0.1 grid, drawn straight where it can be) or another way along the routes
    (`reroute`), round everyone standing still and not only them, so it can't go round one
    into another and back for ever. Failing both, it tries again past anyone idle (`firm`):
    they step aside when it gets to them. A lift broken down across the way, with the only
    other way past someone idle at their stand, held the tech for 15 minutes before that.
    If the node it was making for is taken, it makes for a
    free one near the spot it goes to next. Where they stand at the end of the walk it ends
    beside them (`shiftEnd`) or as near the end as it can (`settleNear`), off the routes
    where it can: on one it would be in the way of whoever comes next, into a dead end like
    the rework table. A broken-down robot or a lift standing still is gone round at once.
  - failing all of that, it walks as far as it can, waits where waiting is allowed, and
    tries again.
- Walks from off the routes (after a step aside, say) go round anything solid or a flight
  of stairs in between first (`walkPoint`, `giveJob`, and any walking step that starts off
  the routes or makes for a node's spot moved beside someone busy there, or for a node that
  isn't at an end of the route edge it starts on (`onEdgeTo`: from a spot short of a node,
  moved off it for someone there, on to the node after it), looked at again whenever the
  step starts afresh from somewhere else). With no
  way round just now (a lift passing) the walker holds where it is and looks again, never
  walking the straight way through. `walkPoint` goes round anyone standing still too, where
  it can. A change like that to an idle loop goes into a copy of it (`ownPath`), so ways
  round don't pile up in the loop.
- A lift's outline is `liftShape`: its body, its forks, and whatever they carry. Every
  step that picks something up is marked `gets` (and one that puts it down on the lane
  `puts`), so the outline after it is known. A lift picks up off the lane only when the
  floor the load will cover is free of bookings.
- A lift books the same way (`driveOf`, `planLift`): the outline swept by every leg at
  1.6 m/s until it next stops off the lane, stops on the lane (the break-down area, the
  robot crate) included, and a hold where it stops (`holdLift`). Until it can book, it
  waits, asks anyone idle in the way to step aside, and its hover text says who it is
  giving way to. While driving, a scanner (`liftScan`) still checks each step against the
  other lift and people. Held up by it, the lift is behind its booked drive, so it books
  where it stands a second ahead for as long as it waits (`holdNow`).
- A lift stopped mid-drive by a network outage keeps its drive (`freezeLift`): meanwhile
  only where it stands is held, and afterwards the rest goes on as booked, later by the
  length of the outage (`resumeLifts`). The other lift, stopped as long, is later by as
  much, so the two still never meet; planning again instead would let whichever went
  first take the other's way, and two lifts can shut each other in like that. A lift
  running late shifts the rest of its drive the same way (`shiftedDrive`), unless that
  would meet the other lift or someone busy, when it plans again. Planning again, it holds
  where it stands until it can book; if the other lift then does the same, the two are nose
  to nose on the lane, each held by the other. Then the one with less far to go backs out
  the way it came to where it was last clear of the lane (`backOff`, `clear`), waits a
  moment, and comes back once the other is by.
- A lift's fault waits until it stands off the lane and clear of every walking route, so a
  broken-down lift never shuts anyone in. The other lift carries on: only a job into the bay
  the broken one stands in waits for the repair (`blockedAt`), no bin goes to be emptied while
  it stands in the compactor's, and a lift already on its way there with a full bin takes it
  home and is free to bring the spare to the station whose bin is on the broken one. A lift halted by a network outage can, so if
  nobody has reached the rack to reset it within two minutes, IT is called anyway; they
  come in at the back door, clear of the lane.
- A robot's fault (random or injected) waits until it is off the footbridges and their
  stairs and, for a minute at most, until it can stop out of the way (`stopsClear`: at a
  stair foot there may be nowhere off the routes close by until it has gone on a bit); then
  it steps off the walking routes to a clear spot within 1.8 m (by a short way round if
  need be, `shortWay`; neither way goes through a lift) where there is one, out of the
  floor a lift drives through into its bays where it can (`bayFloor`: a lift sent into that
  bay would wait until it was mended), and stops there (`stopRobot`). Held up on the lane on the way there, it picks somewhere else from where it
  is, three times at most, before stopping. Losing
  the network, a robot walking somewhere carries on along the way it knows until it can
  stop like that, for a minute at most; one standing off the routes, idle, or held up
  stops where it is (`netStop`). Going again, it walks back to where it was. One that
  still holds someone up (or a lift), or whose contractor waiting at it does, is mended
  with the line machines (`faultPrio`), and the tech is never pulled off it. The tech, tools
  in hand, held up by one, or by its contractor, or waiting at a repair for a contractor
  held up by one, sees to it first, from their side of it. Repair crews take a way round
  the robot they are coming to (`routeAround`).
- A robot stopped only by the network still has its own controls: someone on foot held up
  by it drives it a few steps aside by hand, off their way (`jogAside`). One stopped for
  good in someone's way with no way round it, they move by hand (`pushAside`): brakes off,
  a few steps clear, walking with it behind, in front or at a side, whichever there is room
  for. Either way, off the routes and out of the lifts' bays where they can; a broken one only while nobody is yet on the way to mend it, and it is mended where
  it ends up.
- Someone stranded where nobody may wait (part way over the lane when a lift's plans
  changed, say) steps off it first, out of everyone's way.
- The dock is claimed when an outbound job is given out, so no delivery arrives while that
  lift is on its way. Otherwise it would wait at the dock pick, in the way of the lift sent
  to collect the delivery.
- Nobody refills a machine that is down (`REFILLS`): its hatch is where the crew mending it
  stands, and at the wrapper that is a dead end.
- Visitors (IT, contractors, deliveries) come in at the back door only when it is clear,
  and are on the table the moment they arrive. One worker at a time breaks down a delivery:
  the way to the shelves is one robot wide. A replacement robot's crate is sent for only
  once the robot has stepped off its pallet (or blown up before it could), since the forks
  go in under it.

Layout rules this depends on. Check them statically, sampling every route edge and every
lift corridor against the outline of a lift at each place it stops:
- The back and west walls are obstacles to walkers (the personnel door and the board
  outfeed door are the gaps), so no step aside, way round or stop ends up outside. The
  back aisle along them is one robot wide, and the only way to the paint hatch and the
  network rack: a robot stopped there shuts those off until it moves.
- The flights of stairs are solid steps from the floor up (`BRIDGES`, `STAIR_FEET`). No
  route edge on the floor crosses one (the physics check's route audit includes them),
  and stands, step-aside spots and searches keep off them (`underStairs`,
  `crossesStairs`). Feet may come 0.05 inside a flight's outline, the same allowance in
  every test (`STAIR_SOLID`), or a robot stopped at a stair foot in the back aisle could
  find no way out. A walk that starts partly over a flight (stopped as it started up)
  may back straight off it, and nothing else: in `crossesStairs` only a look no further
  out than the one before counts. Feet follow the treads (`stairZ`). Each stair foot node is at least
  0.3 off its flight. Footbridge B is three steps on the west, so a robot fits between its
  foot and a lift at the reject-bin pick; the front aisle goes round the north foot of
  footbridge C, and the walk along the front edge passes the south one.
- The palletizer's plinth and the track's beacons are obstacles to walkers. The plinth and
  column stop short of the walk between the palletizer and the track (MT to E1), clear of
  the feet and hands of someone on it, which reach further than the 0.2 the routes are
  planned for: feet 0.23 to the side and 0.31 ahead or behind mid-stride, hands 0.37 to
  the side.
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
  - Each picks from the most downstream pallet it can reach first: Rocky the far stop at
    the east end of branch A, then the near stop; Bullwinkle the stop at the top of branch
    B, the most northerly, then the slot below it; either one the lowest waiting slot on
    the leg last. The front pallet empties first and leaves first, and the queue moves up.
  - If each is waiting for the other, that deadlock is detected and one, chosen at random,
    moves out of the way.
  - Putting boards on the board pile at the same time counts as blocking.
  - An idle Bullwinkle may stack boards when a board pallet is waiting.
  - The conveyors leading to Bullwinkle may be pipelined.
- Branch B's exit is one square further north, giving Bullwinkle an extra adjacent
  conveyor square. Rocky's widget pallet conveyor extends one more segment east.
- Both branches are queues: when the front pallet leaves (branch A's far stop taken by a
  lift and the lift clear of it, or branch B's top stop rolled out with its boards), the
  ones behind move up and the next comes in at the back.
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
  anything else is a deadlock. Look too for a repair still not done after 90 minutes (a
  crew that can't get together), a replacement robot not come after an hour, and half an
  hour with nothing painted: none of those shows as anyone stuck. Compare throughput with
  main too: the table costs a few percent (about 3% over sixteen eight-hour runs at 4×),
  since people now queue for one another where they used to walk through. Single seeds
  swing by hundreds of widgets an hour either way, as any change reshuffles the random
  draws, so compare means over many seeds. The jams found so far were nearly all round a
  robot stopped at a footbridge foot or in the back aisle, or a repair crew in each
  other's way: look there first.
- Render cache changes have been checked in headless Chromium on every cached frame:
  the screen equals the layer plus that frame's live tiles, the layer equals a fresh
  drawing of the cached set, and the cached frame differs from a full render by no more
  than a full render differs from itself with its boxes shuffled.
- Clearances are checked by building the scene (every frame while the part in question
  moves, or sweeping a robot arm through every move it makes) and testing every box
  against every other, overlapping by more than paintOrder's EPS in all three axes. People's
  limbs reach past what the routes plan for, so expect a few hits on fixed things beside
  the routes, and on e-stops, which stand in front of each machine where its repairer
  faces.
