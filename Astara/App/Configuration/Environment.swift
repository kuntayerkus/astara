import Foundation

enum APIEnvironment {
    case production
    case staging

    var baseURL: URL {
        switch self {
        case .production:
            if let urlString = Bundle.main.infoDictionary?["API_BASE_URL"] as? String,
               let url = URL(string: urlString) {
                return url
            }
            return URL(string: "https://astara.app/api")!
        case .staging:
            return URL(string: "http://localhost:3000/api")!
        }
    }

    var legacyBaseURL: URL {
        URL(string: "https://merkurmagduru.com/api")!
    }

    var vpsURL: URL {
        if let urlString = Bundle.main.infoDictionary?["VPS_URL"] as? String,
           let url = URL(string: urlString) {
            return url
        }
        return URL(string: "https://swiss.grio.works")!
    }

    var vpsAPIKey: String {
        Bundle.main.infoDictionary?["VPS_API_KEY"] as? String ?? ""
    }

    var geonamesUsername: String {
        Bundle.main.infoDictionary?["GEONAMES_USERNAME"] as? String ?? ""
    }

    static var current: APIEnvironment {
        #if DEBUG
        return .staging
        #else
        return .production
        #endif
    }
}
