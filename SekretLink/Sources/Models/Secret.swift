import Foundation

struct Secret: Codable {
    let uuid: String
    var data: String?      // present in GET response only, absent from POST create response
    let created: Date
    var key: String?
    var expire: Date?
    var accessed: Date?
    var deleteKey: String?

    enum CodingKeys: String, CodingKey {
        case uuid = "UUID"
        case data = "Data"
        case created = "Created"
        case key = "Key"
        case expire = "Expire"
        case accessed = "Accessed"
        case deleteKey = "DeleteKey"
    }
}
