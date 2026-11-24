
import SwiftUI

// =====================================================================
// BaseScreen — tela principal (Categorias) do app
// Arquivo AUTOSSUFICIENTE: pode colar inteiro no seu arquivo do Xcode.
// Se o nome da sua struct for outro (ex.: baseScreen), renomeie abaixo.
// =====================================================================

// MARK: - 1. Modelo de categoria
// `imageName` = nome da imagem dentro de Assets.xcassets (nil = espaço cinza).
private struct BaseCategory: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let imageName: String?
}

// MARK: - 2. Tela principal
struct BaseScreen: View {

    // ----- DADOS (edite aqui) -----------------------------------------

    /// Banners do carrossel cinza. Troque `nil` pelo nome da imagem, ex.: "banner_1".
    private let banners: [String?] = [nil, nil, nil]

    /// Categorias da grade. Troque `nil` pelo nome da imagem, ex.: "cat_doces".
    private let categories: [BaseCategory] = [
        BaseCategory(name: "Doces",        imageName: nil),   // TODO: "cat_doces"
        BaseCategory(name: "Salgados",     imageName: nil),   // TODO: "cat_salgados"
        BaseCategory(name: "Bijuteria",    imageName: nil),   // TODO: "cat_bijuteria"
        BaseCategory(name: "Eletrônicos",  imageName: nil),   // TODO: "cat_eletronicos"
        BaseCategory(name: "Cultura Geek", imageName: nil),   // TODO: "cat_geek"
        BaseCategory(name: "Outros",       imageName: nil),   // TODO: "cat_outros"
    ]

    /// Grade com 2 colunas, igual ao Figma.
    private let columns = [GridItem(.flexible(), spacing: 12),
                           GridItem(.flexible(), spacing: 12)]

    // ----- LAYOUT -----------------------------------------------------

    var body: some View {
        TabView {

            // ABA 1: Produtos (esta tela)
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // Saudação
                        Text("Bem-vindo!")
                            .font(.headline)

                        // Carrossel de banners (rola para o lado)
                        bannerCarousel

                        // Título da seção
                        Text("Categorias")
                            .font(.title3.bold())

                        // Grade de categorias
                        categoryGrid
                    }
                    .padding(16)
                }
                .background(Color(red: 0.97, green: 0.97, blue: 0.98)) // fundo do Figma
                .navigationBarTitleDisplayMode(.inline)

                // Quando a tela de Overview de Produtos existir, ligue aqui:
                // .navigationDestination(for: BaseCategory.self) { ProductsOverviewView(...) }
            }
            .tabItem { Label("Produtos", systemImage: "birthday.cake") } // TODO: ícone do cookie

            // ABA 2: Pesquisar (troque pela tela de busca do seu colega)
            NavigationStack {
                Text("Tela de Pesquisar")
            }
            .tabItem { Label("Pesquisar", systemImage: "magnifyingglass") }
        }
    }

    // MARK: - Carrossel de banners
    private var bannerCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(banners.enumerated()), id: \.offset) { _, name in
                    BaseImage(name: name)                       // espaço da imagem do banner
                        .frame(width: 300, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }
        }
    }

    // MARK: - Grade de categorias
    private var categoryGrid: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(categories) { category in
                // NavigationLink(value: category) { ... }  ← use quando houver a próxima tela
                VStack(alignment: .leading, spacing: 4) {
                    BaseImage(name: category.imageName)         // espaço da imagem da categoria
                        .frame(height: 80)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    Text(category.name)
                        .font(.caption.weight(.semibold))
                }
            }
        }
    }
}

// MARK: - 3. Espaço para imagem
// Mostra a imagem do Assets pelo nome; se não existir, mostra um quadrado cinza.
private struct BaseImage: View {
    let name: String?

    var body: some View {
        if let name, UIImage(named: name) != nil {
            Image(name).resizable().scaledToFill()
        } else {
            ZStack {
                Color.gray.opacity(0.18)
                Image(systemName: "photo").foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Pré-visualização no Xcode (Canvas)
#Preview {
    BaseScreen()
}
