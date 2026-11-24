
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
    @State private var products: [DailyProduct] = []
    @State private var loading = true
    @State private var error: String?
    @State private var search = ""
    private func load() async {
        loading = true
        error = nil
        defer { loading = false }
        do { products = try await NotionService().fetchDailyProducts() }
        catch { self.error = error.localizedDescription }
    }

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
                        if loading { ProgressView() }
                        if let error { Text(error).font(.caption); Button("Tentar novamente") { Task { await load() } } }

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
                List(products.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) || $0.category.localizedCaseInsensitiveContains(search) }) { product in
                    NavigationLink { CatalogProductDetail(product: product) } label: { CatalogProductRow(product: product) }
                }
                .searchable(text: $search)
                .navigationTitle("Pesquisar")
            }
            .tabItem { Label("Pesquisar", systemImage: "magnifyingglass") }
        }
        .task { await load() }
    }

    // MARK: - Carrossel de banners
    private var bannerCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(products.prefix(3))) { product in
                    NavigationLink { CatalogProductDetail(product: product) } label: {
                        CatalogRemoteImage(url: product.imageURL)
                            .frame(width: 300, height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
            }
        }
    }

    // MARK: - Grade de categorias
    private var categoryGrid: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(categories) { category in
                // NavigationLink(value: category) { ... }  ← use quando houver a próxima tela
                NavigationLink {
                    List(products.filter { $0.category == category.name }) { product in
                        NavigationLink { CatalogProductDetail(product: product) } label: { CatalogProductRow(product: product) }
                    }.navigationTitle(category.name)
                } label: {
                VStack(alignment: .leading, spacing: 4) {
                    CatalogRemoteImage(url: products.first { $0.category == category.name }?.imageURL)         // espaço da imagem da categoria
                        .frame(height: 80)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    Text(category.name)
                        .font(.caption.weight(.semibold))
                }
                }.buttonStyle(.plain)
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

private struct CatalogRemoteImage: View {
    let url: URL?
    var body: some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image { image.resizable().scaledToFill() }
            else { Color.gray.opacity(0.18).overlay(Image(systemName: "photo").foregroundStyle(.secondary)) }
        }.clipped()
    }
}
private struct CatalogProductRow: View {
    let product: DailyProduct
    var body: some View {
        HStack {
            CatalogRemoteImage(url: product.imageURL).frame(width: 72, height: 72).clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading) {
                Text(product.name).font(.headline)
                Text(product.description).font(.caption)
                if let price = product.price { Text(price, format: .currency(code: "BRL")) }
            }
        }
    }
}
private struct CatalogProductDetail: View {
    let product: DailyProduct
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CatalogRemoteImage(url: product.imageURL).frame(height: 260).clipShape(RoundedRectangle(cornerRadius: 14))
                Text(product.name).font(.title.bold())
                if let price = product.price { Text(price, format: .currency(code: "BRL")).font(.title2) }
                Text(product.description)
                if let id = product.sellerID {
                    NavigationLink("Ver vendedor") { CatalogSellerDetail(id: id) }
                }
            }.padding()
        }.navigationTitle(product.name)
    }
}
private struct CatalogSellerDetail: View {
    let id: String
    @State private var seller: CatalogSeller?
    @State private var error: String?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let seller {
                    CatalogRemoteImage(url: seller.imageURL).frame(width: 120, height: 120).clipShape(Circle())
                    Text(seller.name).font(.title.bold())
                    Text(seller.course)
                    ForEach(seller.contacts) { contact in
                        Text(contact.type).font(.headline)
                        Text(contact.value)
                    }
                } else if let error { Text(error) }
                else { ProgressView() }
            }.padding()
        }.navigationTitle("Vendedor").task {
            do {
                seller = try await NotionService().fetchSeller(id: id)
                if seller == nil { error = "Vendedor não encontrado." }
            } catch { self.error = error.localizedDescription }
        }
    }
}
