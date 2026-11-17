import SwiftUI

// MARK: - ContentView
// Tela raiz do app. Agora só mostra a BaseScreen.
// (O token do Notion e a busca dos produtos ficam em NotionConfig / NotionService / BaseViewModel.)
struct ContentView: View {
    var body: some View {
        BaseScreen()
    }
}

#Preview {
    ContentView()
}
