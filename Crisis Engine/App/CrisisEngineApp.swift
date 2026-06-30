import SwiftUI

@main
struct CrisisEngineApp: App {
    var body: some Scene {
        WindowGroup {
            CrisisEngineView()
        }
    }
}

struct CrisisEngineView: View {
    @State private var selectedMode = GameMode.collapse
    @State private var navigationPath: [Scenario] = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        modeCarousel
                        featuredScenario
                        designNotes
                    }
                    .padding(20)
                }
            }
            .navigationDestination(for: Scenario.self) { scenario in
                ScenarioSimulationView(scenario: scenario)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CRISIS ENGINE")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .accessibilityAddTraits(.isHeader)

            Text("A strategy sandbox about systems that spread, mutate, and spiral out of control.")
                .font(.title3.weight(.medium))
                .foregroundStyle(.white.opacity(0.78))

            HStack(spacing: 10) {
                StatusPill(text: "Launch mode: Collapse Engine", color: .orange, icon: "play.fill")
                StatusPill(text: "Vertical slice", color: .cyan, icon: "checkmark.seal.fill")
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var modeCarousel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Modes")
                .font(.title2.bold())
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(GameMode.allCases) { mode in
                        ModeCard(mode: mode, isSelected: selectedMode == mode) {
                            selectedMode = mode
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var featuredScenario: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(selectedMode.isPlayable ? "Playable Scenario" : "Future Expansion")
                .font(.title2.bold())
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedMode.title)
                            .font(.title.bold())
                            .foregroundStyle(.white)

                        Text(selectedMode.pitch)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.78))
                    }

                    Spacer()

                    Text(selectedMode.isPlayable ? "PLAY" : "LOCKED")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(selectedMode.isPlayable ? .green.opacity(0.18) : .white.opacity(0.10), in: Capsule())
                        .foregroundStyle(selectedMode.isPlayable ? .green : .white.opacity(0.7))
                }

                Divider().overlay(.white.opacity(0.15))

                ForEach(selectedMode.hooks, id: \.self) { hook in
                    Label(hook, systemImage: "sparkle")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.white.opacity(0.82))
                }

                Button {
                    if selectedMode.isPlayable {
                        navigationPath.append(Scenario.collapseEngine)
                    }
                } label: {
                    Text(selectedMode.isPlayable ? "Start Collapse Engine" : "Coming After Launch")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedMode.isPlayable ? .orange : .gray.opacity(0.45), in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
                }
                .disabled(!selectedMode.isPlayable)
            }
            .padding(18)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
        }
    }

    private var designNotes: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Why start here?")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text("Collapse Engine is now the game-ready vertical slice: choose pressure points, manage detection risk, survive random events, unlock policy modifiers, and chase distinct endings with local best-score tracking. Future modes can reuse the same turn, event, score, and ending structure with new systems.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.76))
                .padding(16)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
        }
    }
}

struct ScenarioSimulationView: View {
    let scenario: Scenario
    @AppStorage("collapseEngineBestScore") private var bestScore = 0
    @AppStorage("collapseEngineCompletedEndings") private var completedEndings = ""
    @State private var state = CollapseRunState()
    @State private var selectedModifier: PolicyModifier = .none
    @State private var showTutorial = true
    @State private var latestEvent: RandomEvent?

    private var completedEndingList: [String] {
        completedEndings.split(separator: ",").map(String.init)
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    if showTutorial { tutorialCard }
                    objectiveCard
                    worldStatus
                    modifierPicker
                    if let latestEvent { eventCard(latestEvent) }
                    actionGrid
                    scoringCard
                    eventLog
                }
                .padding(20)
            }
        }
        .navigationTitle("Simulation")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: state.ending) { ending in
            guard let ending = ending else { return }
            bestScore = max(bestScore, state.score)
            var endings = Set(completedEndingList)
            endings.insert(ending.title)
            completedEndings = endings.sorted().joined(separator: ",")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(scenario.title)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .accessibilityAddTraits(.isHeader)

            Text("Day \(state.day) of \(CollapseRunState.maxDays) · \(state.phase.title)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.72))
        }
    }

    private var tutorialCard: some View {
        InfoPanel(title: "Commander Briefing", icon: "lightbulb.fill", color: .yellow) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Goal: push global stability below 18 by day 12 without letting awareness hit 92. Ending quality depends on panic, resource pressure, stability, and your final score.")
                Text("Tip: modifiers change every action. Each action also nudges the world forward and can trigger randomized events.")
                Button("Dismiss Tutorial") { showTutorial = false }
                    .font(.callout.bold())
                    .foregroundStyle(.yellow)
                    .padding(.top, 4)
            }
        }
    }

    private var objectiveCard: some View {
        InfoPanel(title: "Scenario Objectives", icon: "scope", color: state.ending == nil ? .cyan : (state.ending?.color ?? .cyan)) {
            VStack(alignment: .leading, spacing: 8) {
                if let ending = state.ending {
                    Text(ending.title)
                        .font(.title3.bold())
                        .foregroundStyle(ending.color)
                    Text(ending.summary)
                    Button("Start New Run") { resetRun() }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                } else {
                    ObjectiveRow(text: "Collapse stability below 18", isComplete: state.stability < 18)
                    ObjectiveRow(text: "Keep awareness below 92", isComplete: state.awareness < 92)
                    ObjectiveRow(text: "Reach day 12 or force an early ending", isComplete: state.day >= CollapseRunState.maxDays)
                }
            }
        }
    }

    private var worldStatus: some View {
        VStack(spacing: 14) {
            MetricRow(title: "Global Stability", value: state.stability, color: .green, icon: "shield.lefthalf.filled", danger: state.stability < 25)
            MetricRow(title: "Public Panic", value: state.panic, color: .red, icon: "exclamationmark.triangle.fill", danger: state.panic > 75)
            MetricRow(title: "Resource Pressure", value: state.resources, color: .orange, icon: "shippingbox.fill", danger: state.resources > 82)
            MetricRow(title: "Crisis Awareness", value: state.awareness, color: .blue, icon: "eye.fill", danger: state.awareness > 72)
        }
        .padding(16)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
    }

    private var modifierPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Policy Modifier")
                .font(.title2.bold())
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(PolicyModifier.allCases) { modifier in
                    Button { selectedModifier = modifier } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Label(modifier.title, systemImage: modifier.icon)
                                .font(.headline)
                            Text(modifier.description)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.68))
                        }
                        .frame(maxWidth: .infinity, minHeight: 90, alignment: .topLeading)
                        .padding(12)
                        .background(selectedModifier == modifier ? modifier.color.opacity(0.22) : .white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(selectedModifier == modifier ? modifier.color : .white.opacity(0.10)))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                }
            }
        }
    }

    private var actionGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Pressure Points")
                .font(.title2.bold())
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), spacing: 12)], spacing: 12) {
                ForEach(CrisisAction.allCases) { action in
                    Button { apply(action) } label: { ActionCard(action: action) }
                        .buttonStyle(.plain)
                        .disabled(state.ending != nil)
                        .opacity(state.ending == nil ? 1 : 0.45)
                }
            }
        }
    }

    private var scoringCard: some View {
        InfoPanel(title: "Run Score", icon: "trophy.fill", color: .green) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Current score: \(state.score)")
                    .font(.headline.monospacedDigit())
                Text("Best score: \(bestScore)")
                    .font(.subheadline.monospacedDigit())
                Text("Completed endings: \(completedEndingList.isEmpty ? "None yet" : completedEndingList.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.70))
            }
        }
    }

    private var eventLog: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chain Reaction Log")
                .font(.title2.bold())
                .foregroundStyle(.white)

            ForEach(state.log.indices.reversed(), id: \.self) { index in
                Text(state.log[index])
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.78))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func eventCard(_ event: RandomEvent) -> some View {
        InfoPanel(title: event.title, icon: event.icon, color: event.color) {
            Text(event.description)
        }
    }

    private func apply(_ action: CrisisAction) {
        guard state.ending == nil else { return }
        state.day += 1
        var effects = action.effects.applying(selectedModifier)
        let event = RandomEvent.event(for: state.day, action: action)
        effects = effects.combining(event.effects)
        latestEvent = event

        state.stability = clamp(state.stability + effects.stability)
        state.panic = clamp(state.panic + effects.panic)
        state.resources = clamp(state.resources + effects.resources)
        state.awareness = clamp(state.awareness + effects.awareness)
        state.score += action.scoreValue + selectedModifier.scoreBonus + event.scoreBonus
        state.phase = CollapsePhase.phase(for: state.day)

        state.log.append("Day \(state.day): \(action.logLine) \(event.logLine)")
        evaluateEnding()
    }

    private func evaluateEnding() {
        if state.awareness >= 92 {
            state.ending = .coordinatedRecovery(score: state.score)
        } else if state.stability <= 10 && state.panic >= 78 && state.resources >= 78 {
            state.score += 500
            state.ending = .totalCollapse(score: state.score)
        } else if state.day >= CollapseRunState.maxDays {
            if state.stability < 18 {
                state.score += 250
                state.ending = .unstableSurvival(score: state.score)
            } else {
                state.ending = .containedCrisis(score: state.score)
            }
        }
    }

    private func resetRun() {
        state = CollapseRunState()
        selectedModifier = .none
        showTutorial = true
        latestEvent = nil
    }

    private func clamp(_ value: Double) -> Double { min(100, max(0, value)) }
}

struct ActionCard: View {
    let action: CrisisAction

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: action.icon)
                .font(.title3)
                .foregroundStyle(action.color)
            Text(action.title)
                .font(.headline)
                .foregroundStyle(.white)
            Text(action.effect)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.67))
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .padding(14)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.10)))
    }
}

struct MetricRow: View {
    let title: String
    let value: Double
    let color: Color
    let icon: String
    let danger: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                HStack(spacing: 6) {
                    if danger { Image(systemName: "exclamationmark.octagon.fill") }
                    Text("\(Int(value))%")
                        .font(.headline.monospacedDigit())
                }
                .foregroundStyle(danger ? .red : color)
            }
            ProgressView(value: value, total: 100)
                .tint(danger ? .red : color)
                .accessibilityLabel(title)
                .accessibilityValue("\(Int(value)) percent")
        }
    }
}

struct InfoPanel<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.title3.bold())
                .foregroundStyle(color)
            content
                .font(.callout)
                .foregroundStyle(.white.opacity(0.78))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(color.opacity(0.25)))
    }
}

struct ObjectiveRow: View {
    let text: String
    let isComplete: Bool

    var body: some View {
        Label(text, systemImage: isComplete ? "checkmark.circle.fill" : "circle")
            .foregroundStyle(isComplete ? .green : .white.opacity(0.78))
    }
}

struct StatusPill: View {
    let text: String
    let color: Color
    let icon: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
    }
}

struct CollapseRunState {
    static let maxDays = 12
    var day = 1
    var stability = 82.0
    var panic = 12.0
    var resources = 58.0
    var awareness = 8.0
    var score = 0
    var phase = CollapsePhase.opening
    var ending: CollapseEnding?
    var log = ["Day 1: Small pressure points appear across the world. Choose a pressure point to begin the run."]
}

struct MetricEffects {
    var stability: Double = 0
    var panic: Double = 0
    var resources: Double = 0
    var awareness: Double = 0

    func applying(_ modifier: PolicyModifier) -> MetricEffects {
        MetricEffects(
            stability: stability * modifier.stabilityMultiplier,
            panic: panic * modifier.panicMultiplier,
            resources: resources * modifier.resourceMultiplier,
            awareness: awareness * modifier.awarenessMultiplier
        )
    }

    func combining(_ other: MetricEffects) -> MetricEffects {
        MetricEffects(stability: stability + other.stability, panic: panic + other.panic, resources: resources + other.resources, awareness: awareness + other.awareness)
    }
}

enum CollapsePhase {
    case opening, cascade, endgame

    var title: String {
        switch self {
        case .opening: "Opening pressure"
        case .cascade: "Cascading failures"
        case .endgame: "Endgame instability"
        }
    }

    static func phase(for day: Int) -> CollapsePhase {
        if day >= 9 { return .endgame }
        if day >= 5 { return .cascade }
        return .opening
    }
}

enum CollapseEnding: Equatable {
    case totalCollapse(score: Int)
    case unstableSurvival(score: Int)
    case coordinatedRecovery(score: Int)
    case containedCrisis(score: Int)

    var title: String {
        switch self {
        case .totalCollapse: "Ending: Total Collapse"
        case .unstableSurvival: "Ending: Unstable Survival"
        case .coordinatedRecovery: "Ending: Coordinated Recovery"
        case .containedCrisis: "Ending: Contained Crisis"
        }
    }

    var summary: String {
        switch self {
        case .totalCollapse(let score): "Systems failed faster than institutions could respond. Final score: \(score)."
        case .unstableSurvival(let score): "The world survives, but every system is brittle. Final score: \(score)."
        case .coordinatedRecovery(let score): "Awareness peaked too soon and the world organized a recovery. Final score: \(score)."
        case .containedCrisis(let score): "The crisis never reached critical mass before the scenario ended. Final score: \(score)."
        }
    }

    var color: Color {
        switch self {
        case .totalCollapse: .red
        case .unstableSurvival: .orange
        case .coordinatedRecovery: .blue
        case .containedCrisis: .green
        }
    }
}

enum PolicyModifier: String, CaseIterable, Identifiable {
    case none, misinformationFog, austerityPush, mutualAid
    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: "No Modifier"
        case .misinformationFog: "Info Fog"
        case .austerityPush: "Austerity Push"
        case .mutualAid: "Mutual Aid"
        }
    }

    var description: String {
        switch self {
        case .none: "Balanced action effects."
        case .misinformationFog: "Lower awareness, higher panic."
        case .austerityPush: "More resource strain, less stability."
        case .mutualAid: "Less panic, but more awareness."
        }
    }

    var icon: String {
        switch self {
        case .none: "circle.grid.cross"
        case .misinformationFog: "cloud.fog.fill"
        case .austerityPush: "scalemass.fill"
        case .mutualAid: "hands.sparkles.fill"
        }
    }

    var color: Color {
        switch self {
        case .none: .gray
        case .misinformationFog: .purple
        case .austerityPush: .orange
        case .mutualAid: .mint
        }
    }

    var stabilityMultiplier: Double { self == .austerityPush ? 1.18 : 1 }
    var panicMultiplier: Double { self == .misinformationFog ? 1.18 : (self == .mutualAid ? 0.78 : 1) }
    var resourceMultiplier: Double { self == .austerityPush ? 1.25 : 1 }
    var awarenessMultiplier: Double { self == .misinformationFog ? 0.72 : (self == .mutualAid ? 1.25 : 1) }
    var scoreBonus: Int { self == .none ? 8 : 18 }
}

struct RandomEvent: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let logLine: String
    let icon: String
    let color: Color
    let effects: MetricEffects
    let scoreBonus: Int

    static func event(for day: Int, action: CrisisAction) -> RandomEvent {
        let events = action.events
        return events[day % events.count]
    }
}

enum GameMode: String, CaseIterable, Identifiable {
    case collapse, alienParasite, dreamInvader, invasiveSpecies, shadowMarket
    var id: String { rawValue }

    var title: String {
        switch self {
        case .collapse: "Collapse Engine"
        case .alienParasite: "Alien Parasite"
        case .dreamInvader: "Dream Invader"
        case .invasiveSpecies: "Invasive Species"
        case .shadowMarket: "Shadow Market"
        }
    }

    var shortDescription: String {
        switch self {
        case .collapse: "Trigger cascading global failure."
        case .alienParasite: "Evolve, hide, and overtake Earth."
        case .dreamInvader: "Spread through dreams and break reality."
        case .invasiveSpecies: "Dominate ecosystems through mutation."
        case .shadowMarket: "Grow a fictional shadow economy."
        }
    }

    var pitch: String {
        switch self {
        case .collapse: "Push climate, markets, health, energy, and trust until one crack becomes a worldwide chain reaction."
        case .alienParasite: "Begin as a tiny alien organism and choose whether to hide in hosts, bloom across nature, or merge with technology."
        case .dreamInvader: "Start as one recurring nightmare, spread from mind to mind, and make waking life feel unsafe."
        case .invasiveSpecies: "Adapt an organism to predators, climates, and humans while deciding whether to balance or devour the ecosystem."
        case .shadowMarket: "Build a fictional underground network where risk, demand, rival factions, and enforcement pressure collide."
        }
    }

    var hooks: [String] {
        switch self {
        case .collapse: ["Cascading cause-and-effect across connected systems", "Multiple endings: recovery, collapse, or unstable survival", "Local best-score and completed-ending tracking"]
        case .alienParasite: ["Stealth vs monster outbreak evolution paths", "Military detection creates constant pressure", "Hosts, habitats, and technology become upgrade routes"]
        case .dreamInvader: ["Fear, obsession, and sleep science become resources", "Lucid dreamers and therapists fight back", "Reality-bleed upgrades change the map rules"]
        case .invasiveSpecies: ["Ecosystem balance creates strategic tradeoffs", "Predators and humans force adaptation", "Beautiful maps can become hostile living puzzles"]
        case .shadowMarket: ["A stylized fictional economy, not a real crime guide", "Supply, demand, heat, and rival pressure drive strategy", "Can become a tense city-control management mode"]
        }
    }

    var icon: String {
        switch self {
        case .collapse: "globe.americas.fill"
        case .alienParasite: "ant.fill"
        case .dreamInvader: "moon.stars.fill"
        case .invasiveSpecies: "leaf.fill"
        case .shadowMarket: "building.2.crop.circle.fill"
        }
    }

    var accent: Color {
        switch self {
        case .collapse: .orange
        case .alienParasite: .mint
        case .dreamInvader: .purple
        case .invasiveSpecies: .green
        case .shadowMarket: .gray
        }
    }

    var isPlayable: Bool { self == .collapse }
}

struct ModeCard: View {
    let mode: GameMode
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: mode.icon).font(.title2).foregroundStyle(mode.accent)
                Text(mode.title).font(.headline).foregroundStyle(.white).multilineTextAlignment(.leading)
                Text(mode.shortDescription).font(.caption).foregroundStyle(.white.opacity(0.68)).multilineTextAlignment(.leading).lineLimit(3)
                Spacer()
            }
            .frame(width: 172, height: 178, alignment: .topLeading)
            .padding(16)
            .background(isSelected ? mode.accent.opacity(0.20) : .white.opacity(0.07), in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(isSelected ? mode.accent : .white.opacity(0.12), lineWidth: isSelected ? 2 : 1))
        }
        .buttonStyle(.plain)
    }
}

struct Scenario: Identifiable, Hashable {
    let id = UUID()
    let title: String
    static let collapseEngine = Scenario(title: "Collapse Engine")
}

enum CrisisAction: String, CaseIterable, Identifiable {
    case climateShock, marketPanic, gridFailure, trustErosion, healthSurge, logisticsSnarl
    var id: String { rawValue }

    var title: String {
        switch self {
        case .climateShock: "Climate Shock"
        case .marketPanic: "Market Panic"
        case .gridFailure: "Grid Failure"
        case .trustErosion: "Trust Erosion"
        case .healthSurge: "Health Surge"
        case .logisticsSnarl: "Logistics Snarl"
        }
    }

    var effect: String {
        switch self {
        case .climateShock: "+resources, +panic, -stability"
        case .marketPanic: "big -stability, +panic"
        case .gridFailure: "+resources, -stability"
        case .trustErosion: "-stability, +awareness"
        case .healthSurge: "+panic, +resources"
        case .logisticsSnarl: "big +resources, +awareness"
        }
    }

    var icon: String {
        switch self {
        case .climateShock: "cloud.sun.bolt.fill"
        case .marketPanic: "chart.line.downtrend.xyaxis"
        case .gridFailure: "bolt.slash.fill"
        case .trustErosion: "person.2.slash.fill"
        case .healthSurge: "cross.case.fill"
        case .logisticsSnarl: "truck.box.fill"
        }
    }

    var color: Color {
        switch self {
        case .climateShock: .yellow
        case .marketPanic: .red
        case .gridFailure: .orange
        case .trustErosion: .blue
        case .healthSurge: .pink
        case .logisticsSnarl: .brown
        }
    }

    var effects: MetricEffects {
        switch self {
        case .climateShock: MetricEffects(stability: -8, panic: 11, resources: 14, awareness: 7)
        case .marketPanic: MetricEffects(stability: -13, panic: 16, resources: 5, awareness: 9)
        case .gridFailure: MetricEffects(stability: -12, panic: 9, resources: 17, awareness: 8)
        case .trustErosion: MetricEffects(stability: -10, panic: 7, resources: 4, awareness: 15)
        case .healthSurge: MetricEffects(stability: -7, panic: 15, resources: 13, awareness: 12)
        case .logisticsSnarl: MetricEffects(stability: -9, panic: 8, resources: 19, awareness: 10)
        }
    }

    var scoreValue: Int { 80 + Int(abs(effects.stability) + effects.panic + effects.resources) }

    var logLine: String {
        switch self {
        case .climateShock: "Extreme weather damages crops and ports, raising food prices across connected regions."
        case .marketPanic: "A selloff spreads from finance feeds into jobs, housing, and public confidence."
        case .gridFailure: "Power interruptions ripple into hospitals, data centers, fuel pumps, and emergency response."
        case .trustErosion: "Conflicting narratives make communities slower to coordinate and faster to blame each other."
        case .healthSurge: "Clinics and emergency rooms fill, forcing leaders to divert staff from other fragile systems."
        case .logisticsSnarl: "Container delays and fuel shortages turn small shortages into visible empty shelves."
        }
    }

    var events: [RandomEvent] {
        [
            RandomEvent(title: "Countermeasure Delay", description: "Agencies disagree on priorities, slowing relief.", logLine: "Countermeasures lag behind the new failure point.", icon: "hourglass", color: .orange, effects: MetricEffects(stability: -3, panic: 3, resources: 3, awareness: 1), scoreBonus: 35),
            RandomEvent(title: "Community Response", description: "Local networks cushion the shock but make the pattern easier to see.", logLine: "Community responders reduce harm while increasing visibility.", icon: "person.3.fill", color: .mint, effects: MetricEffects(stability: 4, panic: -4, resources: -2, awareness: 7), scoreBonus: 15),
            RandomEvent(title: "Media Spiral", description: "The crisis dominates feeds, amplifying fear and scrutiny.", logLine: "Media attention amplifies fear and detection risk.", icon: "dot.radiowaves.left.and.right", color: .purple, effects: MetricEffects(stability: -2, panic: 7, resources: 2, awareness: 6), scoreBonus: 25)
        ]
    }
}

enum AppTheme {
    static var backgroundGradient: LinearGradient {
        LinearGradient(colors: [.black, Color(red: 0.08, green: 0.09, blue: 0.14), Color(red: 0.24, green: 0.08, blue: 0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
