# iso-factories

Animated isometric factory simulations, each a single self-contained HTML page. There is
no build step and nothing to install: open a page in a browser, or browse them at
<https://rellen.github.io/iso-factories/>.

## Northside Works, Line 4

[`line-4/index.html`](line-4/index.html)

A packaging line drawn from about 2,700 boxes a frame. Two depalletizing robots lift whole
layers of blank widgets onto a shared conveyor without ever crossing; the widgets are
singulated, painted, dried, tested and packed six to a carton, cartons are stacked on pallets and shrink-wrapped, and autonomous forklifts
move pallets between the line and the dock. Machines break down and a tech fixes them in
priority order, the crew takes tea breaks, robots recharge, and physically impossible
moves are flagged as they happen. Forklifts, robots and people reserve the floor ahead of
them in space and time, so none of them ever walks or drives through another.

Controls: pause, speed (½× to 4×), the line's settings (depalletizer speed, how often things
break down and how many widgets are rejected, starting at world-class OEE), paint-order
labels, and a table of every machine, lift and robot for injecting faults. Zoom with the wheel, a pinch or the
buttons, and drag to pan. Hover over anything to identify it, click it to select it, and
right-click a machine (or long-press it) for its actions. The status panel can be put away;
on a phone the view fills the screen and the panel opens as a sheet.

## Talks

[`talks/line-4/index.html`](talks/line-4/index.html)

*Line 4: a factory in one file*, a talk about how Line 4 works, as one HTML file with the
running factory inside it. Open it in a browser and press `?` for the keys. The deck is
`talks/line-4/deck.exs`, a Mix project with [Expresso](https://github.com/rellen/expresso)
as a dev dependency; its code slides read their excerpts from `line-4/index.html`. To
render it again:

```sh
cd talks/line-4
mix deps.get
mix expresso deck.exs index.html
```

## License

Apache 2.0, see [LICENSE](LICENSE).
