# BMI — Design System

A calm, instrument-like health tool. Paper canvas, one moss accent, numerals set in mono.
It should feel like a clinic's paper intake form that learned to compute — not like a
fitness app trying to motivate you.

---

## 1. Atmosphere

| Dimension | Value | Meaning |
|---|---|---|
| Density | 4 | Roomy. One thought per screen. Generous 24px gutters, single column. |
| Variance | 6 | Structured but not rigid — cards, segmented controls, a tier bar. |
| Motion | 5 | Present but restrained. Spring settle, no bounce loops, no parallax. |

The app opens on a person, not a number. Identity first (who is measuring), then
measurement (what was entered), then readout (what it means and what came before).

---

## 2. Color

One accent. Everything else is ink, steel, and paper.

| Role | Hex | Usage |
|---|---|---|
| Canvas | `#F9FAFB` | App background, every screen. |
| Surface | `#FFFFFF` | Cards, inputs, sheets. |
| Ink | `#18181B` | Primary text. Never `#000000`. |
| Steel | `#71717A` | Secondary text, labels, hints. |
| Whisper | `#E2E8F0` @ 50% | 1px borders and dividers. |
| Accent — Deep Moss | `#3D5A3D` | Focus rings, active segment, primary button, selected states. |
| Accent tint | `#3D5A3D` @ 8% | Focus ring halo, selected segment fill. |
| Amber 700 | `#B45309` | Overweight / Obesity tier signal only. |
| Moss 600 | `#2F6F4E` | Normal tier signal only. |
| Steel 400 | `#A1A1AA` | Underweight tier signal only. |

Rules:

- Saturation of the accent stays under 80%. Deep Moss is a green you'd find in a
  forest, not on a notification badge.
- Exactly one accent drives interaction state. Amber/steel/moss-600 are *semantic
  signals for BMI tiers*, not UI accents — they never appear on a button.
- No purple. No neon. No pure black. No gradient fills.
- No glow, no bloom, no `boxShadow` with colored spread.

---

## 3. Typography

Two families, both variable, both bundled as `.ttf` assets (no runtime font fetch).

- **Outfit** — display and body. Geometric humanist sans, warm but neutral.
  Never `Inter`. Never a system serif.
- **JetBrains Mono** — every number the user reads as data: BMI value, weight,
  height, age, history rows. Tabular by nature, so digits don't jitter as they change.

Scale (Outfit unless noted):

| Token | Size / Line | Weight (`wght`) | Notes |
|---|---|---|---|
| Display | 44 / 48 | 600 | The BMI readout, but in **JetBrains Mono**. |
| Title | 28 / 34 | 600 | Screen titles. |
| Heading | 20 / 26 | 600 | Card headings. |
| Body | 16 / 24 | 400 | Default copy. |
| Body strong | 16 / 24 | 600 | Emphasis inside body. |
| Label | 13 / 18 | 600 | Field labels, uppercase with 0.06em tracking. |
| Caption | 12 / 16 | 400 | Hints, tier explanations. |
| Numeric input | 32 / 40 | 500 | JetBrains Mono, weight/height entry. |
| Numeric data | 15 / 20 | 500 | JetBrains Mono, history rows. |

Variable fonts are set with `fontWeight` **and** `fontVariations: [FontVariation('wght', N)]`
together — Flutter ignores one or the other depending on platform, so both are always present.

---

## 4. Components

### Cards
Radius `20px`, `surface` fill, 1px whisper border at 50% opacity, and a single
diffused shadow: `blur 24, offset (0, 4), color #18181B @ 0.04`. Never stacked
cards-inside-cards.

### Inputs
Label sits **above** the field, never floating inside it. Field is `surface`,
radius `14px`, 1px whisper border, 56px tall. On focus the border turns accent and
a 3px accent ring at 12% opacity appears — no size change, no layout shift.
Numeric fields are JetBrains Mono.

### Segmented control (cm / m)
Two segments in a whisper-bordered pill. The selected segment fills with accent
tint and its label goes accent + 600. 44px tall — meets the minimum touch target.

### Primary button
56px tall, full width, accent fill, `surface` label at 16/600, radius `14px`.
Pressed state: 4% darker, scale settles to 0.985 via spring. Disabled: whisper
fill, steel label.

### Tier bar
A single horizontal track split into four proportional segments
(underweight → normal → overweight → obesity). The current tier's segment fills
with its semantic color; the rest stay whisper. A small mono marker sits above
the value. This replaces the "three/four equal cards in a row" pattern — one
continuous measure, not a grid of tiles.

### History rows
Dense, unboxed, separated by 1px whisper rules. Left: date in mono. Right: BMI
value in mono, tier label in caption. Rows cascade in with a stagger.

### Icons
Material outlined only. 22–24px. Always inside a 44×44 touch target.

---

## 5. Layout

- Mobile-first, single column, **no horizontal scrolling** anywhere.
- Screen gutter: 24px. Vertical rhythm: 8 / 12 / 16 / 24 / 32.
- Every screen: 24px safe top, an optional 56px app bar, a content block, and an
  action anchored to the bottom of the viewport (thumb-reachable).
- Max content width 560px, centered, so tablets don't stretch lines to unreadable.
- Form fields stack with 20px gaps. Never two inputs side by side on mobile.

### Three screens

1. **Onboarding / Profile** — name, gender (segmented), age. Reachable again to
   edit a profile or add a new user.
2. **Calculator** — who's measuring (name + a wrapped row of profile chips, each
   44px tall, ending in an *Add user* chip), weight, height with the cm/m
   segmented control, and the Calculate action.
3. **Result** — the number, the classification, the tier bar, and a history
   icon in the app bar that opens past records (same screen, revealed section
   or pushed route).

The profile chips wrap onto the next line rather than scrolling sideways, so
adding a user never requires a horizontal gesture. The row is always present —
even for a single profile — because *Add user* is the only way to reach the
second profile from there.

---

## 6. Motion

Spring physics, `stiffness: 100`, `damping: 20`. Nothing eases linearly.

| Moment | Behavior |
|---|---|
| Calculate press | Button scales to 0.985 and settles back; result then springs in. |
| Result value | Enters at scale 0.92, opacity 0, settles to 1/1 with spring. |
| Tier bar fill | Segment width animates over 500ms, `easeOutCubic`. |
| Screen transitions | Shared-axis style: 300ms, `easeOutCubic`, opacity + 12px translate. |
| History rows | Staggered cascade, 40ms apart, 6px rise + fade, spring. |
| Segmented control | Thumb and label color cross-fade, 180ms. |

Constraints:

- Animate **`transform` and `opacity` only** — never `width`, `height`, `top`, `left`.
- No looping animation. Nothing pulses, spins, or breathes while idle.
- `44px` minimum hit area on anything tappable; motion never shrinks it.
- Respect `MediaQuery.disableAnimations` — when reduced motion is on, use
  1ms durations instead of springs.

---

## 7. Anti-patterns

This project rejects all of the following:

- AI purple or neon palettes; `#6366F1`, `#8B5CF6`, `#06B6D4` as accents.
- Pure black `#000000` text or backgrounds.
- `Inter`, `Roboto` as the display face, or generic system serifs.
- Emojis anywhere in the UI — icons are Material outlined glyphs.
- Neon glows, colored shadows, gradient buttons, glassmorphism.
- Rows of three or four equal-height cards used to present one continuous scale.
- Generic placeholder names (`John Doe`, `Test User`) in code or copy.
- AI copywriting clichés: "Unlock your potential", "Your journey starts here",
  "Take control of your health today".
- Filler UI text: "Scroll to explore", "Lorem ipsum", "Coming soon".
- Horizontal scroll on mobile, or any carousel of health tips.
- Dialogs for validation errors — errors are inline, under the field.
- Gender influencing the BMI number or classification. It is display data only.
- Color as the sole carrier of meaning — tier is always spelled out in words.
