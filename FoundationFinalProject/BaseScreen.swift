import SwiftUI
import UIKit

private let catalogBackground = Color(red: 246/255, green: 247/255, blue: 248/255)
private let catalogPanel = Color(red: 231/255, green: 231/255, blue: 231/255)
private let catalogInk = Color(red: 20/255, green: 22/255, blue: 23/255)

private enum CatalogRoute: Hashable {
    case category(String), product(DailyProduct), seller(String)
}

struct BaseScreen: View {
    @State private var products: [DailyProduct] = []
    @State private var loading = true
    @State private var error: String?
    @State private var search = ""
    @State private var selectedTab = 0
    @State private var path: [CatalogRoute] = []
    private let categories = ["Doces", "Salgados", "Bijuteria", "Eletrônicos", "Cultura Geek", "Outros"]
    private let representative = ["Doces": "Cookie", "Salgados": "Coxinha", "Bijuteria": "Pulseira", "Eletrônicos": "Mouse USB", "Cultura Geek": "Botton", "Outros": "Brownie"]

    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { geometry in
                Group {
                    if selectedTab == 0 { home(width: geometry.size.width) }
                    else { searchScreen }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(catalogBackground)
                .overlay(alignment: .top) {
                    if loading { ProgressView().padding(8).background(.regularMaterial, in: Capsule()) }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) { tabBar }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: CatalogRoute.self) { route in
                Group {
                    switch route {
                    case .category(let category):
                        overview(category)
                    case .product(let product):
                        CatalogProductDetail(product: product) { id in path.append(.seller(id)) }
                    case .seller(let id):
                        CatalogSellerDetail(id: id)
                    }
                }
                .background(catalogBackground)
                .toolbar(.hidden, for: .navigationBar)
                .safeAreaInset(edge: .bottom, spacing: 0) { tabBar }
            }
        }
        .preferredColorScheme(.light)
        .task { await load() }
    }

    private func load() async {
        loading = true
        error = nil
        defer { loading = false }
        do { products = try await NotionService().fetchDailyProducts() }
        catch { self.error = error.localizedDescription }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tab(0, title: "Produtos")
            tab(1, title: "Pesquisar")
        }
        .padding(3)
        .frame(width: 184, height: 61)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.black.opacity(0.14), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
    }

    private func tab(_ index: Int, title: String) -> some View {
        Button {
            path.removeAll()
            selectedTab = index
        } label: {
            VStack(spacing: 3) {
                if index == 0 { CatalogCookieIcon().frame(width: 25, height: 25) }
                else { Image(systemName: "magnifyingglass").font(.system(size: 25, weight: .medium)) }
                Text(title).font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(selectedTab == 1 && index == 1 ? Color.blue : catalogInk)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(selectedTab == index ? Color.black.opacity(0.08) : .clear, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selectedTab == index ? .isSelected : [])
    }

    private func home(width: CGFloat) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Bem-vindo!")
                    .font(.system(size: 22, weight: .bold))
                    .padding(.horizontal, 21)
                    .padding(.top, 20)
                    .padding(.bottom, 29)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 19) {
                        ForEach(bannerProducts) { product in
                            Button { path.append(.product(product)) } label: {
                                CatalogRemoteImage(url: product.imageURL)
                                    .frame(width: width * 0.86, height: width * 0.40)
                                    .clipShape(RoundedRectangle(cornerRadius: 28))
                            }.buttonStyle(.plain)
                        }
                        if bannerProducts.isEmpty {
                            CatalogRemoteImage(url: nil)
                                .frame(width: width * 0.86, height: width * 0.40)
                                .clipShape(RoundedRectangle(cornerRadius: 28))
                        }
                    }.padding(.horizontal, 21)
                }
                Text("Categorias")
                    .font(.system(size: 28, weight: .bold))
                    .padding(.horizontal, 21)
                    .padding(.top, 37)
                    .padding(.bottom, 20)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 13), GridItem(.flexible(), spacing: 13)], spacing: 17) {
                    ForEach(categories, id: \.self) { category in
                        Button { path.append(.category(category)) } label: {
                            CatalogTile(title: category, url: categoryImage(category), height: width * 0.22)
                        }.buttonStyle(.plain)
                    }
                }.padding(.horizontal, 18)
                if let error {
                    Text(error).font(.caption).padding()
                    Button("Tentar novamente") { Task { await load() } }.padding(.horizontal)
                }
            }
            .padding(.bottom, 8)
        }.refreshable { await load() }
        .foregroundStyle(catalogInk)
    }

    private var bannerProducts: [DailyProduct] {
        let preferred = ["Bolo de pote", "Brownie", "Cookie"]
        var result: [DailyProduct] = []
        for name in preferred {
            if let p = products.first(where: { $0.name == name && $0.imageURL != nil }) { result.append(p) }
        }
        return result.isEmpty ? Array(products.filter { $0.imageURL != nil }.prefix(3)) : result
    }

    private func categoryImage(_ category: String) -> URL? {
        let group = products.filter { $0.category == category && $0.imageURL != nil }
        return group.first { $0.name == representative[category] }?.imageURL ?? group.first?.imageURL
    }

    private func overview(_ category: String) -> some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(category)
                        .font(.system(size: 34, weight: .bold))
                        .padding(.horizontal, 16)
                        .padding(.top, 22)
                    ForEach(Array(sections(category).enumerated()), id: \.offset) { _, section in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.title)
                                .font(.system(size: 22, weight: .bold))
                                .padding(.horizontal, 16)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .top, spacing: 13) {
                                    ForEach(section.items) { p in
                                        Button { path.append(.product(p)) } label: {
                                            CatalogTile(title: p.name, url: p.imageURL, height: geometry.size.width * 0.22)
                                                .frame(width: geometry.size.width * 0.435)
                                        }.buttonStyle(.plain)
                                    }
                                }.padding(.horizontal, 16)
                            }
                        }
                    }
                }.padding(.bottom, 12)
            }
            .foregroundStyle(catalogInk)
            .overlay(alignment: .topTrailing) {
                Button { if !path.isEmpty { path.removeLast() } } label: {
                    Image(systemName: "chevron.left").font(.system(size: 17, weight: .medium))
                        .padding(10).background(.ultraThinMaterial, in: Circle())
                }.buttonStyle(.plain).padding(.trailing, 16).padding(.top, 24)
                    .accessibilityLabel("Voltar")
            }
        }
    }

    private struct SectionData {
        let title: String
        let items: [DailyProduct]
    }

    private func sections(_ category: String) -> [SectionData] {
        let all = products.filter { $0.category == category }
        if category == "Doces" {
            let groups = [
                ("Destaques", ["Cookie", "Brownie"]),
                ("Vai uma sobremesa?", ["Sorvete", "Barra de cereal", "Bolo de pote", "Brigadeiro", "Beijinho", "Trufa"]),
                ("Ou algo para matar a fome?", ["Pão doce", "Torta", "Palha italiana", "Sequilho"])
            ]
            var used = Set<String>()
            var result = groups.map { title, names in
                let items = names.flatMap { name in all.filter { $0.name == name } }
                used.formUnion(items.map(\.id))
                return SectionData(title: title, items: items)
            }.filter { !$0.items.isEmpty }
            let rest = all.filter { !used.contains($0.id) }
            if !rest.isEmpty { result.append(SectionData(title: "Outros produtos", items: rest)) }
            return result
        }
        let featured = Array(all.prefix(4))
        let remaining = Array(all.dropFirst(4))
        return [SectionData(title: "Destaques", items: featured), SectionData(title: "Mais produtos", items: remaining)].filter { !$0.items.isEmpty }
    }

    private var searchScreen: some View {
        GeometryReader { geometry in
            VStack(spacing: 12) {
                HStack(spacing: 7) {
                    HStack(spacing: 9) {
                        Image(systemName: "magnifyingglass").font(.system(size: 19))
                        TextField("Search", text: $search)
                            .font(.system(size: 17))
                            .textInputAutocapitalization(.never)
                        if !search.isEmpty {
                            Button { search = "" } label: { Image(systemName: "xmark.circle.fill") }.buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 15)
                    .frame(height: 47)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.black.opacity(0.14), lineWidth: 0.5))
                    Button {
                        search = ""
                        selectedTab = 0
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 23, weight: .light))
                            .frame(width: 47, height: 47)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().strokeBorder(Color.black.opacity(0.14), lineWidth: 0.5))
                    }.buttonStyle(.plain)
                }.padding(.horizontal, 8).padding(.top, 20)
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 13), GridItem(.flexible(), spacing: 13)], spacing: 21) {
                        ForEach(products.filter {
                            search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) ||
                            $0.category.localizedCaseInsensitiveContains(search) ||
                            $0.description.localizedCaseInsensitiveContains(search)
                        }) { p in
                            Button { path.append(.product(p)) } label: {
                                CatalogTile(title: p.category, url: p.imageURL, height: geometry.size.width * 0.22)
                            }.buttonStyle(.plain)
                            .accessibilityLabel(p.name + ", " + p.category)
                        }
                    }.padding(.horizontal, 18).padding(.bottom, 12)
                }.scrollDismissesKeyboard(.interactively)
            }
        }.foregroundStyle(catalogInk)
    }
}

private struct CatalogTile: View {
    let title: String
    let url: URL?
    let height: CGFloat
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CatalogRemoteImage(url: url)
                .frame(height: height)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .lineLimit(1)
                .padding(.horizontal, 15)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CatalogRemoteImage: View {
    let url: URL?
    var body: some View {
        GeometryReader { geo in
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height).clipped()
                } else {
                    catalogPanel.overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                }
            }.frame(width: geo.size.width, height: geo.size.height).clipped()
        }
    }
}

private struct CatalogCookieIcon: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            var outline = Path()
            outline.move(to: CGPoint(x: w*0.61, y: h*0.06))
            outline.addArc(center: CGPoint(x: w*0.48, y: h*0.51), radius: w*0.45,
                           startAngle: .degrees(-73), endAngle: .degrees(8), clockwise: true)
            outline.addQuadCurve(to: CGPoint(x: w*0.61,y: h*0.06), control: CGPoint(x: w*0.52,y: h*0.50))
            outline.closeSubpath()
            context.fill(outline, with: .color(.black))
            for (x,y,r) in [(0.30,0.33,0.06),(0.20,0.57,0.045),(0.43,0.57,0.06),(0.56,0.79,0.045),(0.39,0.85,0.04)] {
                context.fill(Path(ellipseIn: CGRect(x:w*(x-r), y:h*(y-r), width:w*r*2,height:h*r*2)), with:.color(catalogBackground))
            }
            for (x,y,r) in [(0.78,0.10,0.035),(0.88,0.22,0.045),(0.69,0.25,0.025)] {
                context.fill(Path(ellipseIn: CGRect(x:w*(x-r), y:h*(y-r), width:w*r*2,height:h*r*2)), with:.color(.black))
            }
        }
    }
}

private struct CatalogInfoPanel: View {
    let title: String
    let rows: [(String, String)]
    var onCopy: ((String, String) -> Void)? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(Color.gray.opacity(0.55))
                .padding(.horizontal, 8)
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                    if let onCopy, !row.1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button { onCopy(row.0, row.1) } label: {
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text(row.0).font(.system(size: 21, weight: .bold))
                                Spacer(minLength: 4)
                                Text(row.1)
                                    .font(.system(size: 21, weight: .bold))
                                    .foregroundStyle(Color.gray.opacity(0.65))
                                    .multilineTextAlignment(.trailing)
                                    .lineLimit(3)
                                    .minimumScaleFactor(0.7)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 13)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(row.0 + " " + row.1)
                        .accessibilityHint("Copia o contato")
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text(row.0).font(.system(size: 21, weight: .bold))
                            Spacer(minLength: 4)
                            Text(row.1)
                                .font(.system(size: 21, weight: .bold))
                                .foregroundStyle(Color.gray.opacity(0.65))
                                .multilineTextAlignment(.trailing)
                                .lineLimit(3)
                                .minimumScaleFactor(0.7)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 13)
                    }
                    if i < rows.count - 1 { Divider() }
                }
            }
            .background(catalogPanel, in: RoundedRectangle(cornerRadius: 17))
        }
        .foregroundStyle(.black)
    }
}

private struct CatalogHero: View {
    let url: URL?
    let height: CGFloat
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        CatalogRemoteImage(url: url)
            .frame(height: height)
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 43, bottomTrailingRadius: 43))
            .overlay(alignment: .topLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 23, weight: .medium))
                        .foregroundStyle(.black)
                        .frame(width: 43, height: 43)
                        .background(.regularMaterial, in: Circle())
                        .overlay(Circle().strokeBorder(.white.opacity(0.6), lineWidth: 0.5))
                }.buttonStyle(.plain).padding(.leading, 16).padding(.top, 12)
                    .accessibilityLabel("Voltar")
            }
    }
}

private struct CatalogProductDetail: View {
    let product: DailyProduct
    let openSeller: (String) -> Void
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    CatalogHero(url: product.imageURL, height: geo.size.width * 0.88)
                    CatalogInfoPanel(title: "Detalhes do Produto:", rows: [
                        ("Produto:", product.name),
                        ("Descrição:", product.description),
                        ("Valor:", product.price.map { $0.formatted(.currency(code: "BRL").locale(Locale(identifier: "pt_BR"))) } ?? "—")
                    ])
                    .padding(.horizontal, 16)
                    .padding(.top, 40)
                    Button {
                        if let id = product.sellerID { openSeller(id) }
                    } label: {
                        Text("Informações do vendedor")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 58)
                            .background(catalogPanel, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(product.sellerID == nil)
                    .padding(.horizontal, 16)
                    .padding(.top, 70)
                    .padding(.bottom, 12)
                }
            }
        }
    }
}

private struct CatalogSellerDetail: View {
    let id: String
    @State private var seller: CatalogSeller?
    @State private var error: String?
    @State private var copiedMessage: String?
    @State private var copyEvent = UUID()

    private func copyContact(_ label: String, _ value: String) {
        UIPasteboard.general.string = value
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        let name = label.trimmingCharacters(in: CharacterSet(charactersIn: ": "))
        withAnimation(.easeInOut(duration: 0.2)) { copiedMessage = "\(name) copiado!" }
        copyEvent = UUID()
    }
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    CatalogHero(url: seller?.imageURL, height: geo.size.width * 0.88)
                    if let seller {
                        CatalogInfoPanel(title: "Detalhes do Vendedor:", rows: [("Nome:", seller.name), ("Curso:", seller.course)])
                            .padding(.horizontal, 16).padding(.top, 40)
                        CatalogInfoPanel(title: "Contatos do Vendedor:", rows: seller.contacts.sorted {
                            let a = $0.type.lowercased().contains("whatsapp")
                            let b = $1.type.lowercased().contains("whatsapp")
                            return a == b ? $0.type < $1.type : a
                        }.map { ($0.type + ":", $0.value) }, onCopy: copyContact)
                            .padding(.horizontal, 16).padding(.top, 40).padding(.bottom, 12)
                    } else if let error { Text(error).padding() }
                    else { ProgressView().padding() }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let copiedMessage {
                Label(copiedMessage, systemImage: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(catalogInk)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(.regularMaterial, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.black.opacity(0.12), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .allowsHitTesting(false)
            }
        }
        .task(id: copyEvent) {
            guard copiedMessage != nil else { return }
            do { try await Task.sleep(nanoseconds: 1_800_000_000) }
            catch { return }
            withAnimation(.easeInOut(duration: 0.2)) { copiedMessage = nil }
        }
        .task {
            do {
                seller = try await NotionService().fetchSeller(id: id)
                if seller == nil { error = "Vendedor não encontrado." }
            } catch { self.error = error.localizedDescription }
        }
    }
}

#Preview { BaseScreen() }
