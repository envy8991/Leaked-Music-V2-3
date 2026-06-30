# Crisis Engine

Crisis Engine is a SwiftUI strategy game about connected systems that spread, mutate, and spiral out of control. The current build starts with **Collapse Engine**, a playable vertical slice where players apply pressure to global systems, manage detection risk, react to events, and chase multiple endings.

## Current Status

- **Platform:** iOS / SwiftUI
- **Project file:** `Crisis Engine.xcodeproj`
- **App entry point:** `Crisis Engine/App/CrisisEngineApp.swift`
- **Playable mode:** Collapse Engine
- **Target/product name:** Crisis Engine
- **Future modes shown in the menu:** Alien Parasite, Dream Invader, Invasive Species, and Shadow Market

## What Is Playable Now

The current vertical slice includes:

1. A dark sci-fi main menu with a mode carousel.
2. A playable Collapse Engine scenario.
3. Four crisis metrics:
   - Global Stability
   - Public Panic
   - Resource Pressure
   - Crisis Awareness
4. Six pressure-point actions:
   - Climate Shock
   - Market Panic
   - Grid Failure
   - Trust Erosion
   - Health Surge
   - Logistics Snarl
5. Policy modifiers that alter action tradeoffs:
   - No Modifier
   - Info Fog
   - Austerity Push
   - Mutual Aid
6. Randomized event outcomes after each action.
7. Tutorial prompts and scenario objectives.
8. Clear endings:
   - Total Collapse
   - Unstable Survival
   - Coordinated Recovery
   - Contained Crisis
9. End-of-run scoring, local best-score tracking, and completed-ending tracking.
10. Three difficulty levels that adjust thresholds, effect intensity, and score multipliers.
11. Unlockable starting conditions tied to completed endings.
12. A chain-reaction log that records how each player choice and event changes the simulation.
13. Stronger danger feedback when metrics cross risky thresholds.
14. Animated metric changes, event-card transitions, numeric score/metric transitions, and press feedback on action cards.
15. A privacy manifest declaring no data collection or tracking for the current offline vertical slice.

## How to Test

Use this smoke-test checklist after meaningful changes:

1. Open `Crisis Engine.xcodeproj` in Xcode.
2. Build and run the `Crisis Engine` target on an iPhone simulator.
3. Confirm the main menu opens and the mode carousel scrolls horizontally.
4. Select every mode card and confirm only Collapse Engine is playable.
5. Start Collapse Engine.
6. Dismiss the tutorial.
7. Select every difficulty level before taking the first action.
8. Confirm locked starting conditions explain their unlock requirements.
9. Select every policy modifier.
10. Use every pressure-point action at least once.
11. Confirm the chain-reaction log records actions and random events.
12. Continue a run until an ending appears.
13. Start a new run from the ending card.
14. Confirm best score and completed endings persist after relaunching the app.
15. Confirm newly unlocked starting conditions become selectable after completing their required endings.
16. Repeat on a small iPhone and iPad simulator to check layout wrapping and scrolling.

## Roadmap

The next step is to polish Collapse Engine, then expand the shared simulation foundation into other modes.

### Phase 1 — Stabilize the Vertical Slice

- [x] Rename remaining legacy project/app references so the repo, product, and app identity consistently use **Crisis Engine**.
- [ ] Confirm the project builds cleanly in Xcode on local macOS.
- [x] Add a basic smoke-test checklist for launching the app, opening the playable scenario, and using every action.
- [ ] Fix any navigation, layout, or device-size issues found during simulator and device testing.

### Phase 2 — Make Collapse Engine Game-Ready

- [x] Add clear win, loss, and partial-success endings.
- [x] Add turn goals, scenario objectives, and end-of-run scoring.
- [x] Balance metric changes so player choices create meaningful tradeoffs.
- [x] Add more pressure-point actions and event outcomes.
- [x] Add tutorial prompts for first-time players.
- [x] Add stronger feedback when a metric reaches a dangerous threshold.

### Phase 3 — Add Progression and Replayability

- [x] Add modifiers that change action effects.
- [x] Add randomized events so each run feels different.
- [x] Add difficulty levels.
- [x] Add unlockable scenarios or starting conditions.
- [x] Track best scores and completed endings locally.

### Phase 4 — Improve Presentation

- [ ] Add custom visual identity: logo, launch screen, icon pass, color system, and typography polish.
- [ ] Add sound effects and music direction.
- [ ] Add animations for metric changes, danger states, and major events.
- [x] Improve accessibility basics with labels, values, and color-safe danger icons.
- [x] Add first-pass animations for metric changes, danger states, event reveals, and action-card press states.

### Phase 5 — Prepare for Release

- [x] Add baseline app metadata, privacy notes, and release checklist.
- [ ] Test on real iPhone and iPad devices.
- [ ] Profile performance and memory usage.
- [ ] Create screenshots and store description copy.
- [x] Decide whether the first public release includes only Collapse Engine or also one additional mode.

### Phase 6 — Future Modes

After Collapse Engine is strong, reuse the same simulation foundation for:

- **Alien Parasite:** stealth, hosts, mutation paths, military detection, and outbreak escalation.
- **Dream Invader:** dream spread, fear, lucid resistance, therapy counters, and reality-bleed effects.
- **Invasive Species:** ecosystem pressure, mutation, predators, climate adaptation, and human response.
- **Shadow Market:** a stylized fictional economy using risk, demand, rivals, and enforcement pressure without becoming a real-world crime guide.

## README Update Rule

This README should be updated whenever meaningful changes are made to the project. Every future change should include, when relevant:

- What changed.
- Why it changed.
- How to test it.
- Any known limitations or follow-up tasks.
- Whether the roadmap or current status changed.

Keeping the README current will make it easier to track progress, onboard collaborators, and decide what to build next.

## Development Notes

- Open `Crisis Engine.xcodeproj` in Xcode.
- Build and run the `Crisis Engine` target.
- The current SwiftUI app entry point is `CrisisEngineApp`.
- Collapse Engine now lives in a single SwiftUI file for speed of iteration; a future cleanup should split game data, simulation logic, persistence, setup/progression rules, and UI into separate files.
- First public release scope is **Collapse Engine only**. The other modes should remain visible as future expansions until the vertical slice is validated on simulator and real devices.
- Current privacy posture: the app is offline-only, uses local `@AppStorage` for best score and completed endings, and declares no tracking or collected data in `Crisis Engine/Resources/PrivacyInfo.xcprivacy`.

## Release Checklist

- [x] Confirm app display name is `Crisis Engine`.
- [x] Confirm bundle identifier is set for the app target.
- [x] Add an Apple privacy manifest for the current no-data-collection build.
- [x] Document first-release scope as Collapse Engine only.
- [ ] Build and archive on local macOS with Xcode.
- [ ] Run the smoke-test checklist on at least one small iPhone simulator, one large iPhone simulator, and one iPad simulator.
- [ ] Run the smoke-test checklist on real iPhone and iPad hardware.
- [ ] Capture App Store screenshots after final visual polish.
- [ ] Draft App Store subtitle, description, keywords, support URL, and age-rating notes.
- [ ] Profile launch time, scrolling smoothness, and memory usage on the oldest supported device.

## Completed in This Update

- Added animated metric/progress changes, numeric transitions, event-card reveals, danger pulsing, and action-card press feedback for the Collapse Engine play loop.
- Added an Apple privacy manifest for the current offline/no-tracking build.
- Added a release checklist and documented that the first public release should ship with Collapse Engine only while future modes remain expansions.
- Kept prior completed work: Guided, Standard, and Hardline difficulty levels; the Run Setup panel; unlockable starting conditions; setup-aware objectives, tutorial text, scoring, and ending checks.

## Known Limitations and Follow-Up Tasks

- This repository does not include automated XCTest coverage yet.
- Difficulty levels and unlockable starting conditions are implemented for Collapse Engine, but still need simulator balancing passes.
- Sound direction, custom icon/logo work, launch-screen polish, screenshots, and store copy are still needed.
- Real-device QA is still required before release.
- The project still needs to be built and archived on a local macOS/Xcode environment before any release submission.
