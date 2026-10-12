# A talk about Line 4, the factory in `line-4/index.html`, made with Expresso
# (https://github.com/rellen/expresso). The code on the slides comes from the
# page itself, found by its text, so the slides follow the page as it changes.
#
# Render it from this directory:
#
#     mix deps.get
#     mix expresso deck.exs index.html
#
# The slides fit a window of 1920 × 1080. Add `?check` to the address of the
# rendered page to list any element that does not fit.

defmodule Line4Talk.Frame do
  use Expresso.Template.Deck

  def header(_assigns) do
    temple do
      div do
        span class: "header" do
          "Northside Works · Line 4"
        end
      end
    end
  end

  def footer(_assigns) do
    temple do
      div do
        span class: "footer" do
          "rellen.github.io/iso-factories · line-4/index.html"
        end
      end
    end
  end
end

defmodule Line4Talk.Deck do
  use Expresso

  # The factory page, from the directory of this file. The code slides read
  # their excerpts from it, and the cover puts it into the deck.
  @page "../../line-4/index.html"

  name "Line 4: a factory in one file"
  # The page and its comments are in British English.
  lang "en-GB"
  root __DIR__
  template Line4Talk.Frame
  duration 40
  slide_numbers true
  progress true
  transition :slide
  handout :last
  print_notes true
  effect :fade
  easing :ease_out

  # The colours of the page: its background and ink, the safety yellow of the
  # floor lines, and the colours of its status lights.
  theme %{
    base00: "#1b232c",
    base01: "#222c37",
    base02: "#33404d",
    base03: "#acbac8",
    base04: "#acbac8",
    base05: "#e6ebf0",
    base06: "#f0f4f7",
    base07: "#ffffff",
    base08: "#fe9e99",
    base09: "#ffb13b",
    base0A: "#f0d12a",
    base0B: "#5cf58a",
    base0C: "#9dc4d6",
    base0D: "#e8b83a",
    base0E: "#8fbafe",
    base0F: "#c8a061"
  }

  css ~S"""
  /* Expresso dims a role of text to 3:1. Text under 24 px needs 4.5:1 (WCAG
     1.4.3), so each dimmed colour here is its role blended on its background at
     the smallest multiple of 0.05 that keeps 4.5:1. */
  :root {
    --text-dim: #8b9198;
    --muted-dim: #808d99;
    --accent-dim: #aa8b36;
    --warning-dim: #bb8636;
    --danger-dim: #ba7978;
    --success-dim: #42a164;
    --emphasis-dim: #6c8dbf;
    --code-text-dim: #8e959d;
    --code-comment-dim: #8a96a4;
    --code-tag-dim: #c78280;
    --code-number-dim: #bd893a;
    --code-type-dim: #a8972f;
    --code-string-dim: #45a569;
    --code-support-dim: #7896a6;
    --code-function-dim: #ad8e39;
    --code-keyword-dim: #7496cc;
  }
  .code pre {
    font-size: 0.42rem;
  }
  /* The class of a slide whose code has the page's longest lines. */
  .dense .code pre {
    font-size: 0.34rem;
  }
  .table {
    font-size: 0.55rem;
  }
  .list,
  .text-area {
    font-size: 0.7rem;
  }
  .math {
    font-size: 0.8rem;
  }
  .callout {
    font-size: 0.6rem;
  }
  """

  # ------------------------------------------------------------------ the cover
  slide "cover" do
    heading "Line 4: a factory in one file"

    notes """
    The factory on this slide is the page itself, put into the deck, and it runs during
    the talk with no network. The handout and paper show a still of it.
    """

    embed @page do
      title "Line 4, the running factory: belts, robot arms, a paint booth, lifts and the status panel"
      fallback "screen.jpg"
      width "64%"
      aspect "16/9"
      effect :blur
      speed :slow
    end
  end

  slide "agenda" do
    heading "The route through the talk"
    notes "Each entry is a link to the start of its section."

    toc do
      reveal true
      dim true
    end
  end

  # ------------------------------------------------------------------ one file
  slide "what it is" do
    section "One file"
    heading "One page, no build, nothing from elsewhere"

    notes """
    The figures are from the page as it is today. The boxes are counted each frame: the
    status panel shows the number under the view.
    """

    columns do
      column do
        stat 6983 do
          label "lines in one HTML file"
          count true
          morph "lines"
        end
      end

      column do
        stat 2400 do
          prefix "~"
          label "boxes drawn each frame"
          count true
          at from: 2
        end
      end

      column do
        stat 0 do
          label "libraries, requests or build steps"
          at from: 3
        end
      end
    end
  end

  slide "the rules" do
    heading "One page, no build, nothing from elsewhere"

    columns do
      column do
        width "40%"

        stat 6983 do
          label "lines in one HTML file"
          morph "lines"
        end
      end

      column do
        callout :important do
          title "The rules of a factory page"

          text_area(
            text:
              "It runs from file://, on GitHub Pages and as a claude.ai artifact, whose content security policy blocks every request to elsewhere."
          )
        end

        callout :note do
          at from: 2
          title "Accessibility is part of the work"

          text_area(
            text:
              "The canvas is an image with a written description, the figures are output elements, and the table of machines is the keyboard route to every action."
          )
        end

        callout :tip do
          at from: 3
          title "Physical correctness first"

          text_area(
            text:
              "Nothing passes through anything else. An impossible move is flagged and counted, never hidden."
          )
        end
      end
    end
  end

  # ------------------------------------------------------------------ the picture
  slide "boxes" do
    section "The picture"
    heading "Every thing is a box"
    class "dense"

    notes """
    The scene is axis-aligned boxes and nothing else: about 2,400 each frame. B() makes
    one. The render cache recognises a box by how it looks, so a box with extra fields
    is drawn live.
    """

    code "js" do
      src @page
      lines from: "function B(x0, y0, z0, x1, y1, z1, c, extra) {", to: "\n  }"
      highlight [612..612, 613..618]
    end
  end

  slide "slabs" do
    heading "A hexagon is three slabs"

    notes """
    On screen, a box is a hexagon, and a hexagon is the intersection of three slabs in
    u, v and w. Two boxes overlap on screen exactly when their three intervals overlap.
    """

    columns do
      column do
        diagram "axes.svg" do
          alt "The three axes of the scene, seen from +x, +y and +z, 30 degrees above the horizontal. Each face of a box has its own shade."
        end
      end

      column do
        diagram "slabs.svg" do
          alt "A box seen as a hexagon, cut out by three slabs: u = x − y, v = x − z and w = y − z."
        end
      end
    end
  end

  slide "cycles" do
    heading "When no order is possible"

    notes """
    Three boxes can each be behind the next along a different axis. The sort finds the
    cycle and releases the member whose broken orders share the least screen area. It
    never releases a box that only waits behind a cycle.
    """

    diagram "cycle.svg" do
      alt "Three boxes A, B and C in a cycle: A behind B on x, B behind C on y, C behind A on z. Releasing C breaks only the smallest overlap."
      width "70%"
    end
  end

  slide "cache" do
    heading "Draw only what changed"

    notes """
    A box unchanged for 45 frames joins the cached layer. Each frame redraws only the
    32-pixel tiles that something live touches, on a scratch canvas, copied as
    rectangles: a clip anti-aliases differently and shows seams.
    """

    columns do
      column do
        width "60%"

        diagram "cache.svg" do
          alt "A grid of 32-pixel tiles over the scene. Most tiles come from the cached layer; the few that something live touches are redrawn."
        end
      end

      column do
        stat 45 do
          label "frames unchanged before a box is cached"
        end

        stat 32 do
          suffix " px"
          label "tiles, redrawn whole"
          at from: 2
        end
      end
    end
  end

  # ------------------------------------------------------------------ the arms
  slide "two arms" do
    section "Rocky and Bullwinkle"
    heading "Two arms, one belt"

    notes """
    Both depalletizers take a whole layer, fifteen widgets, by suction, and set it down
    on belt A1 a row in each lane. Their heads are a layer wide, so their paths to the
    belt and the rack cross.
    """

    columns do
      column do
        width "30%"

        icon "bot" do
          label "Rocky"
          size "5em"
          color :accent
        end

        icon "bot" do
          label "Bullwinkle"
          size "5em"
          color :warning
        end
      end

      column do
        list do
          reveal true
          item "Each takes a whole layer and sets it on belt A1, a row in each lane"
          item "Neither moves into the other: a 3D check of every part, 5 cm to spare"
          item "Only one works over the belt and the rack at a time"
          item "Each picks the most downstream pallet it can reach first"
        end
      end
    end
  end

  slide "shared floor" do
    heading "One arm over the shared floor"

    notes """
    SHARED is the floor both reach over: the belt and the rack. A move that takes the head
    over it waits until the other has gone. Waiting step by step for each other there
    left both stuck.
    """

    code "js" do
      src @page
      lines from: "  // The floor both depalletizers reach over", to: "const overShared"
      highlight [2161..2166, 2167..2169]
    end
  end

  slide "deadlock" do
    heading "When each waits for the other"
    class "dense"

    notes """
    One gives way: never one already on its way to its rest, then the one waiting for the
    shared floor, or else one chosen at random. It goes up and round to its rest, and on
    with its job from there. The status panel counts the deadlocks broken.
    """

    code "js" do
      src @page
      lines from: "const stuck = () =>", to: "return sim.armYield.arm === arm;\n    };"
      highlight [2222..2222, 2223..2226, 2227..2227]
    end

    callout :definition do
      title "A rule of the line"
      at from: 4

      text_area(
        text:
          "If each is waiting for the other, one moves out of the way, round to its rest, and carries on from there."
      )
    end
  end

  # ------------------------------------------------------------------ traffic
  slide "booking" do
    section "Traffic"
    heading "Book the floor before you move"

    notes """
    Two lifts share a lane one lift wide. People and robots cross it and walk along it.
    Everyone books floor in space and time before moving, so nobody moves through
    anybody else. Here A has booked its walk; B asks for a window to cross, finds A,
    and crosses after A has passed.
    """

    diagram "booking.svg" do
      alt "A chart of position along the floor against time. Walker A books its walk as a staircase of small boxes and ends in a hold with no end. Walker B first asks for a window that meets A's, and crosses later instead."
      width "75%"
    end
  end

  slide "the table" do
    heading "The reservation table"

    notes """
    One map from mover to bookings. Each booking is a box of floor, a level and a window
    of time, plus a box round them all for a quick reject. FOREVER ends a hold with no
    end in sight.
    """

    code "js" do
      src @page
      lines from: "  const RES = new Map();", to: "const levelsAt"
    end
  end

  slide "resHit" do
    heading "The reservation table"
    class "dense"

    notes "resHit is the one question the planners ask: does anyone else's booking meet this one?"

    code "js" do
      src @page
      lines from: "  function resHit(m, b, m2) {", to: "return hit;\n  }"
      highlight [3589..3590, 3591..3591, 3593..3593]
    end
  end

  slide "in the way" do
    heading "When a plan runs into someone"

    notes """
    The order matters, and each step came from a deadlock found in a long run. The table
    costs about 3% of the throughput: people now queue for each other where they used to
    walk through.
    """

    columns do
      column do
        width "62%"

        list do
          ordered true
          reveal true
          dim true
          item "Someone idle steps aside, waits a moment, and goes back"
          item "Someone busy: after 3 s, go round them, or another way"
          item "Failing both, go round firmly: the idle step aside on arrival"
          item "Failing all, walk as far as you can and try again"
          item "Lifts nose to nose: the one with less far to go backs off"
        end
      end

      column do
        stat 3 do
          prefix "~"
          suffix "%"
          label "of the throughput: the cost of the table"
          at from: 6
        end
      end
    end
  end

  # ------------------------------------------------------------------ trouble
  slide "a run" do
    section "Trouble"
    heading "Ten seconds of a run, at 4×"

    notes """
    A recording of the page, ten seconds at four times its speed, with captions. Press
    play: the video does not start by itself.
    """

    video "run.webm" do
      title "Ten seconds of Line 4 at four times its speed"
      poster "run.jpg"
      captions "run.vtt"
      controls true
      width "70%"
    end
  end

  slide "faults" do
    heading "Faults, and who mends them"

    notes """
    The tech mends by priority: the MCC and the switchboard, then the line machines, then
    waste. A lower-priority repair pauses for a higher one. A robot down where it holds
    someone up counts as a line machine.
    """

    table do
      header true
      reveal true
      row ["Level", "Share", "Who", "Repair"]
      row ["1", "50%", "the operator or the tech", "3–8 s"]
      row ["2", "35%", "the tech", "8–20 s"]
      row ["3", "15%", "the tech and a contractor", "a call-out, then 20–45 s"]
    end

    callout :warning do
      at from: 5
      title "Estimates"

      text_area(
        text:
          "After a look, each fault shows an estimate. The real repair comes in early a quarter of the time, and now and then blows out to more than twice as long."
      )
    end
  end

  slide "physics check" do
    heading "A monitor, not a constraint"

    notes """
    The physics check never stops a move. It logs it in sim.viol.list and counts it in the
    status panel. A change to layout or routing must leave the count at zero over a long
    run: sixteen seeds, eight hours each.
    """

    columns do
      column do
        callout :important do
          title "Flag, never prevent"

          text_area(
            text:
              "Impossible moves are logged and counted. A guard that silently stopped them would hide the bug."
          )
        end
      end

      column do
        list do
          reveal true
          item "Lifts against each other and against people on foot"
          item "People and robots against each other, on the same level"
          item "Feet against the treads of the stairs"
          item "A jam check too: nobody with work still for over a minute"
        end
      end
    end
  end

  # ------------------------------------------------------------------ the numbers
  slide "OEE" do
    section "The numbers"
    heading "OEE = Availability × Performance × Quality"

    notes """
    OEE is counted at the painter. A stop of 60 seconds or more costs availability,
    slow running and short stops cost performance, and anything not good first time
    costs quality. The rated cycle is 0.45 s, 8,000 an hour, ahead of the line at every
    setting.
    """

    diagram "oee.svg" do
      alt "The planned time as a bar, shortened in three steps: availability 98%, performance 88% and quality 98%, for an OEE of 85%."
      width "75%"
    end
  end

  slide "oeeFigures" do
    heading "Two samples, one window"
    class "dense"

    notes "The rolling figure takes a sample a second and differences two samples ten minutes apart."

    columns do
      column do
        width "76%"

        code "js" do
          src @page

          lines from: "  function oeeFigures(from, to) {",
                to: "return { A, P, Q, oee: A * P * Q };\n  }"

          highlight [6728..6730, 6732..6734, 6735..6735]
        end
      end

      column do
        stat 85 do
          suffix "%"
          label "OEE at the world-class settings"
          morph "oee"
        end
      end
    end
  end

  slide "settings" do
    heading "Settings that start at world class"
    class "dense"

    notes """
    Breakdowns multiply every mean time between faults; a change rescales the clocks
    already running. Quality multiplies the reject rates. Measured over three seeds of
    four and a half hours each.
    """

    code "js" do
      src @page
      lines from: "  let faultScale = 8;", to: "$('faultRate')"
    end

    columns do
      column do
        stat 85 do
          suffix "%"
          label "OEE at the world-class settings"
          morph "oee"
        end
      end

      column do
        stat 53 do
          suffix "%"
          label "at 1×, typical breakdowns, typical quality"
          at from: 2
        end
      end
    end
  end

  slide "throughput" do
    heading "Widgets painted an hour, commit by commit"

    notes """
    Means over sixteen seeds of eight hours at 4×. The last point is at the new default
    settings; at the old settings the same commit paints 4,426 an hour.
    """

    chart :line do
      title "Widgets painted an hour, as the last commits changed the line"
      src "throughput.csv"
      width "62%"
      effect :grow
    end

    footnote "Means over sixteen seeds × 8 hours at 4×, from the commit messages of rellen/iso-factories."
  end

  # ------------------------------------------------------------------ the screen
  slide "operator screen" do
    section "The operator screen"
    heading "What needs attention, first"

    notes """
    The status panel: performance with an hour of sparklines, what needs attention,
    supplies, and the crew. The rest is under More detail. On a phone the view fills the
    screen and the panel opens as a sheet.
    """

    image "screen.jpg" do
      alt "The operator screen: the top bar with the line's state and the shift clock, the factory view, the status panel with OEE 95%, 7,641 painted an hour, supplies and the crew, and the controls along the bottom."
      width "70%"
    end
  end

  slide "a canvas with words" do
    heading "A canvas with words"

    notes "Each part of the page has the markup that a screen reader needs. The canvas cannot take focus, so the table of machines is the keyboard route."

    table do
      header true
      reveal true
      row ["Part", "Markup"]
      row ["The view", "a canvas with role=\"img\" and a written description"]
      row ["The figures", "output elements"]
      row ["The controls", "real buttons and fieldsets, a visible focus ring, 44 px to hit"]
      row ["Machines & faults", "a table: the keyboard route to every action"]
      row ["Reduced motion", "the page starts paused"]
    end
  end

  # ------------------------------------------------------------------ next
  slide "the port" do
    section "Next: the port"
    heading "Where each part goes"

    notes """
    Planning only: nothing is ported. First separate the simulation from the drawing in
    the page itself, with the jam harness running throughout. Then one Rust crate with
    two hosts: WebAssembly in the browser, and a Rustler NIF on the server.
    """

    table do
      header true
      reveal true
      row ["Part", "Goes to", "Because"]
      row ["Simulation", "a Rust crate", "typed, fast, deterministic, builds for both hosts"]
      row ["Drawing", "TypeScript", "it is already JavaScript"]
      row ["Serving, viewers, history", "Elixir and Phoenix", "supervision, fan-out, persistence"]
    end

    callout :note do
      at from: 5
      title "Why not the simulation in Elixir"

      text_area(
        text:
          "Every sub-step needs one consistent view of the whole floor. One process per actor turns that into a coordination problem."
      )
    end
  end

  slide "bandwidth" do
    heading "Streaming the factory"

    notes """
    With the simulation on the server, the browser needs the state it draws from, not
    boxes. Measured headless over two seeds; treat the figures as estimates.
    """

    chart :bar do
      title "Kilobytes a second for each viewer, upper estimates"
      categories ["60 updates a second", "20 a second, smoothed"]
      width "70%"
      series "Raw JSON", [65, 38]
      series "Binary", [17, 8.6]
      series "Compressed WebSocket", [11, 5.6]
    end

    footnote "From docs/porting.md: 2.4–5.6 KB/s at 20 updates a second, compressed."
  end

  slide "decisions" do
    heading "Decisions to make"

    list do
      reveal true
      item "One shared factory, one per viewer, or each browser running its own?"
      item "Keep a static GitHub Pages build alongside, through WebAssembly?"
      item "Is the claude.ai artifact still a target?"
      item "Does the single-file page stay as the reference until the port matches it?"
    end
  end

  # ------------------------------------------------------------------ the end
  slide "the end" do
    heading "Open the page, and watch Line 4 run"
    transition :fade

    columns do
      column do
        qr_code "https://rellen.github.io/iso-factories/" do
          label "rellen.github.io/iso-factories"
          size "36%"
        end
      end

      column do
        text_area do
          text "This talk is in the same repository: talks/line-4, a Mix project with Expresso as a dev dependency."
        end
      end
    end
  end
end

Line4Talk.Deck
