# Crisis Engine

Crisis Engine is a SwiftUI strategy game prototype about connected systems that spread, mutate, and spiral out of control. The current build starts with **Collapse Engine**, a playable prototype where players apply pressure to global systems and watch stability, panic, resources, and awareness react over time.

## Current Status

- **Platform:** iOS / SwiftUI
- **Project file:** `Leaked Music V2.xcodeproj`
- **App entry point:** `Leaked Music V2/App/MovieBoxHostApp.swift`
- **Playable mode:** Collapse Engine
- **Future modes shown in the prototype:** Alien Parasite, Dream Invader, Invasive Species, and Shadow Market

## What Is Playable Now

The prototype currently includes:

1. A dark sci-fi main menu with a mode carousel.
2. A playable Collapse Engine scenario.
3. Four crisis metrics:
   - Global Stability
   - Public Panic
   - Resource Pressure
   - Crisis Awareness
4. Four pressure-point actions:
   - Climate Shock
   - Market Panic
   - Grid Failure
   - Trust Erosion
5. A chain-reaction log that records how each player choice changes the simulation.

## How We Move Forward

The next step is to turn the current prototype into a full game-ready vertical slice before expanding into the other modes. The priority is to make Collapse Engine feel complete, replayable, understandable, and stable.

### Phase 1 — Stabilize the Prototype

- Rename remaining legacy project/app references so the repo, product, and app identity consistently use **Crisis Engine**.
- Confirm the project builds cleanly in Xcode.
- Add a basic smoke-test checklist for launching the app, opening the playable scenario, and using every action.
- Fix any navigation, layout, or device-size issues found during testing.

### Phase 2 — Make Collapse Engine Game-Ready

- Add clear win, loss, and partial-success endings.
- Add turn goals, scenario objectives, and end-of-run scoring.
- Balance metric changes so player choices create meaningful tradeoffs.
- Add more pressure-point actions and event outcomes.
- Add tutorial prompts for first-time players.
- Add stronger feedback when a metric reaches a dangerous threshold.

### Phase 3 — Add Progression and Replayability

- Add upgrades, modifiers, or policy cards that change action effects.
- Add randomized events so each run feels different.
- Add difficulty levels.
- Add unlockable scenarios or starting conditions.
- Track best scores and completed endings locally.

### Phase 4 — Improve Presentation

- Add custom visual identity: logo, launch screen, icon pass, color system, and typography polish.
- Add sound effects and music direction.
- Add animations for metric changes, danger states, and major events.
- Improve accessibility with Dynamic Type, VoiceOver labels, and color-safe status indicators.

### Phase 5 — Prepare for Release

- Add app metadata, privacy notes, and release checklist.
- Test on real iPhone and iPad devices.
- Profile performance and memory usage.
- Create screenshots and store description copy.
- Decide whether the first public release includes only Collapse Engine or also one additional mode.

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

- Open `Leaked Music V2.xcodeproj` in Xcode.
- Build and run the `MovieBox Host` target until the project is renamed.
- The current SwiftUI app entry point is `CrisisEngineApp`.
- The current code is intentionally prototype-focused; expect future work to split game data, simulation logic, and UI into separate files.

## Immediate Next Checklist

- [ ] Rename legacy project and target names from MovieBox/Leaked Music to Crisis Engine.
- [ ] Add screenshots or a short gameplay GIF to this README.
- [ ] Create a simple issue list for Phase 1 work.
- [ ] Add end conditions and scoring to Collapse Engine.
- [ ] Add a manual QA checklist for iPhone sizes.
- [ ] Update this README after every meaningful code or design change.
