import Foundation

// Apenas para testes locais no simulador. Em produção use um backend
// que mantenha o token do Notion fora do aplicativo.
enum NotionConfig {
    static let token = ProcessInfo.processInfo.environment["BEARER_TOKEN"] ?? ""
    static let databaseID = ProcessInfo.processInfo.environment["NOTION_DATABASE_ID"] ?? "497acf78-8e58-835c-8835-07130871a5c9"
    static let imagesID = "fe2acf78-8e58-8357-8705-8788353af227"
    static let sellersID = "414acf78-8e58-80af-b468-000b4e2f3a77"
    static let sellersImagesID = "414acf78-8e58-809e-aafa-000babbeb47a"
    static let contactsID = "414acf78-8e58-808e-9906-000bc47557f9"
    static let apiVersion = "2025-09-03"
}
