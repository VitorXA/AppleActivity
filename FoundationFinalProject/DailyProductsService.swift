import Foundation

// MARK: - Modelo
// Produto do dia, já "limpo" (sem a bagunça do JSON do Notion). É o que a tela usa.
struct DailyProduct: Identifiable, Hashable {
    let id: String          // id da página no Notion
    let name: String
    let category: String
    let imageURL: URL?      // nil = mostra espaço cinza
}

// MARK: - Interface
// A tela só conhece este protocolo. Trocar Mock por Notion = trocar 1 linha em BaseScreen.
protocol DailyProductsProviding {
    func fetchDailyProducts() async throws -> [DailyProduct]
}

// MARK: - Versão de teste (sem internet / sem Notion)
struct MockDailyProductsService: DailyProductsProviding {
    func fetchDailyProducts() async throws -> [DailyProduct] {
        try await Task.sleep(nanoseconds: 600_000_000)   // simula carregamento
        return (1...3).map {
            DailyProduct(id: "mock\($0)", name: "Produto do dia \($0)", category: "Doces", imageURL: nil)
        }
    }
}

// MARK: - Versão real: Notion
struct NotionService: DailyProductsProviding {

    enum NotionError: LocalizedError {
        case badStatus(Int)
        case missingConfig
        var errorDescription: String? {
            switch self {
            case .missingConfig: return "Faltam BEARER_TOKEN ou NOTION_DATABASE_ID no Scheme do Xcode."
            case .badStatus(let c): return "Não foi possível carregar (erro \(c)). Verifique token e ID do banco."
            }
        }
    }

    func fetchDailyProducts() async throws -> [DailyProduct] {
        guard !NotionConfig.token.isEmpty, !NotionConfig.databaseID.isEmpty else { throw NotionError.missingConfig }

        // 1) Monta a requisição: POST /databases/{id}/query
        let url = URL(string: "https://api.notion.com/v1/databases/\(NotionConfig.databaseID)/query")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(NotionConfig.token)", forHTTPHeaderField: "Authorization")
        request.setValue(NotionConfig.apiVersion, forHTTPHeaderField: "Notion-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 2) Filtro "do dia": só linhas cuja coluna Data == hoje.
        //    (Alternativa: usar uma coluna checkbox "Produto do dia" -> {"checkbox": {"equals": true}})
        let body: [String: Any] = [
            "page_size": 10,
            "filter": ["property": NotionConfig.dateProp, "date": ["equals": Self.todayString]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // 3) Chama a API e confere o status
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else { throw NotionError.badStatus(status) }

        // 4) Converte o JSON do Notion em [DailyProduct]
        let decoded = try JSONDecoder().decode(NotionResponse.self, from: data)
        return decoded.results.map { page in
            let p = page.properties
            let image = p[NotionConfig.imageProp]
            // Imagem pode vir de "Arquivos e mídia" (upload ou link) ou de uma coluna URL.
            let urlString = image?.files?.first?.file?.url
                         ?? image?.files?.first?.external?.url
                         ?? image?.url
            return DailyProduct(
                id: page.id,
                name: p[NotionConfig.nameProp]?.title?.first?.plainText ?? "Sem nome",
                category: p[NotionConfig.categoryProp]?.select?.name ?? "",
                imageURL: urlString.flatMap(URL.init(string:))
            )
        }
    }

    /// Data de hoje no formato do Notion (yyyy-MM-dd), no fuso do aparelho.
    private static var todayString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f.string(from: Date())
    }
}

// MARK: - Formato do JSON do Notion (só o que precisamos)
// Cada propriedade do Notion tem um tipo diferente; deixamos tudo opcional e lemos o que existir.
private struct NotionResponse: Decodable { let results: [NotionPage] }

private struct NotionPage: Decodable {
    let id: String
    let properties: [String: NotionProperty]
}

private struct NotionProperty: Decodable {
    let title: [RichText]?
    let select: Select?
    let files: [NotionFile]?
    let url: String?

    struct RichText: Decodable {
        let plainText: String
        enum CodingKeys: String, CodingKey { case plainText = "plain_text" }
    }
    struct Select: Decodable { let name: String }
    struct NotionFile: Decodable {
        let file: Link?        // arquivo enviado ao Notion (link EXPIRA em ~1h)
        let external: Link?    // link externo (estável)
        struct Link: Decodable { let url: String }
    }
}
