import Foundation

// MARK: - Configuração do Notion
// Tudo que depende da SUA base no Notion fica aqui. Quando o banco estiver pronto,
// só preencha estes valores. Os nomes das colunas precisam ser IGUAIS aos do Notion.
//
// ⚠️ SEGURANÇA: NÃO suba o token real para o GitHub. Um token dentro do app pode ser
// extraído por qualquer pessoa. Para desenvolver: coloque este arquivo no .gitignore
// depois de preencher. Para produção: use um servidor intermediário (ex.: Cloudflare
// Worker, Vercel) que guarda o token e devolve os produtos para o app.
enum NotionConfig {
    // Lidos das variáveis de ambiente do Xcode (Product > Scheme > Edit Scheme > Run > Arguments):
    //   BEARER_TOKEN       = token da integração do Notion
    //   NOTION_DATABASE_ID = ID do banco (parte da URL antes do "?v=")
    // Vazio = o app usa dados de exemplo (Mock) em vez do Notion.
    static let token      = ProcessInfo.processInfo.environment["BEARER_TOKEN"] ?? ""
    static let databaseID = ProcessInfo.processInfo.environment["NOTION_DATABASE_ID"] ?? ""
    static let apiVersion = "2022-06-28"

    // Nomes das colunas (propriedades) do banco no Notion:
    static let nameProp     = "Nome"        // tipo: Título
    static let imageProp    = "Imagem"      // tipo: Arquivos e mídia  (ou URL)
    static let categoryProp = "Categoria"   // tipo: Seleção
    static let dateProp     = "Data"        // tipo: Data  -> define "produto do dia"
}
