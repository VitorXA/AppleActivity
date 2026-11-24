import Foundation

struct DailyProduct: Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let imageURL: URL?
    var price: Double? = nil
    var description: String = ""
    var sellerID: String? = nil
}

struct CatalogSeller: Identifiable {
    let id: String
    let name: String
    let course: String
    let imageURL: URL?
    let contacts: [CatalogContact]
}

struct CatalogContact: Identifiable {
    let id: String
    let type: String
    let value: String
}

protocol DailyProductsProviding {
    func fetchDailyProducts() async throws -> [DailyProduct]
}

struct MockDailyProductsService: DailyProductsProviding {
    func fetchDailyProducts() async throws -> [DailyProduct] {
        [DailyProduct(id: "demo", name: "Brownie", category: "Doces", imageURL: nil, price: 7, description: "Sabor Ninho")]
    }
}

struct NotionService: DailyProductsProviding {
    enum NotionError: LocalizedError {
        case missingConfig, badStatus(Int), invalidPagination
        var errorDescription: String? {
            switch self {
            case .missingConfig: return "Configure BEARER_TOKEN no Scheme local do Xcode."
            case .badStatus(let code): return "Falha na consulta ao Notion (HTTP \(code))."
            case .invalidPagination: return "Resposta de paginação inválida."
            }
        }
    }

    private func query(_ source: String, filter: [String: Any]? = nil) async throws -> [NotionPage] {
        guard !NotionConfig.token.isEmpty else { throw NotionError.missingConfig }
        let url = URL(string: "https://api.notion.com/v1/data_sources/\(source)/query")!
        var pages: [NotionPage] = []
        var cursor: String?
        repeat {
            var body: [String: Any] = ["page_size": 100]
            if let cursor { body["start_cursor"] = cursor }
            if let filter { body["filter"] = filter }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(NotionConfig.token)", forHTTPHeaderField: "Authorization")
            request.setValue(NotionConfig.apiVersion, forHTTPHeaderField: "Notion-Version")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard status == 200 else { throw NotionError.badStatus(status) }
            let decoded = try JSONDecoder().decode(NotionResponse.self, from: data)
            pages += decoded.results
            if decoded.has_more && (decoded.next_cursor == nil || decoded.next_cursor == cursor) {
                throw NotionError.invalidPagination
            }
            cursor = decoded.has_more ? decoded.next_cursor : nil
        } while cursor != nil
        return pages
    }

    func fetchDailyProducts() async throws -> [DailyProduct] {
        let products = try await query(NotionConfig.databaseID)
        let images = try await query(NotionConfig.imagesID)
        var urls: [String: URL] = [:]
        for image in images {
            if let url = image.properties["image"]?.imageURL {
                for relation in image.properties["product_id"]?.relation ?? [] {
                    if urls[relation.id] == nil { urls[relation.id] = url }
                }
            }
        }
        return products.compactMap { page in
            let p = page.properties
            let name = (p["product"]?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            return DailyProduct(id: page.id, name: name, category: p["category"]?.text ?? "",
                                imageURL: urls[page.id], price: p["price"]?.number,
                                description: p["description"]?.text ?? "",
                                sellerID: p["seller_id"]?.relation?.first?.id)
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func fetchSeller(id: String) async throws -> CatalogSeller? {
        let sellers = try await query(NotionConfig.sellersID)
        guard let seller = sellers.first(where: { $0.id == id }) else { return nil }
        let filter: [String: Any] = ["property": "seller_id", "relation": ["contains": id]]
        let images = try await query(NotionConfig.sellersImagesID, filter: filter)
        let contacts = try await query(NotionConfig.contactsID, filter: filter)
        return CatalogSeller(id: id, name: seller.properties["Nome"]?.text ?? "",
            course: seller.properties["course"]?.text ?? "",
            imageURL: images.compactMap { $0.properties["image"]?.imageURL }.first,
            contacts: contacts.map { CatalogContact(id: $0.id,
                type: $0.properties["type"]?.text ?? "",
                value: $0.properties["contact"]?.text ?? "") })
    }
}

private struct NotionResponse: Decodable {
    let results: [NotionPage]
    let has_more: Bool
    let next_cursor: String?
}
private struct NotionPage: Decodable {
    let id: String
    let properties: [String: NotionProperty]
}
private struct NotionProperty: Decodable {
    let title: [RichText]?
    let rich_text: [RichText]?
    let number: Double?
    let relation: [Relation]?
    let files: [NotionFile]?
    var text: String { (title ?? rich_text ?? []).map(\.plain_text).joined() }
    var imageURL: URL? {
        (files?.first?.file?.url ?? files?.first?.external?.url).flatMap { URL(string: $0) }
    }
    struct RichText: Decodable { let plain_text: String }
    struct Relation: Decodable { let id: String }
    struct NotionFile: Decodable {
        let file: Link?
        let external: Link?
        struct Link: Decodable { let url: String }
    }
}
