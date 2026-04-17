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
            return URL(string: "https://merkurmagduru.com/api")!
        case .staging:
            return URL(string: "https://merkurmagduru.com/api")!
        }
    }

    /// Static data files live at merkurmagduru.com root (no /api prefix).
    /// Endpoints like /data/daily-horoscope.json use this base.
    var staticDataURL: URL {
        URL(string: "https://merkurmagduru.com")!
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

    var geminiAPIKey: String {
        Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String ?? ""
    }

    var supabaseURL: URL? {
        guard let raw = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
              !raw.contains("REPLACE_WITH") && !raw.contains("YOUR_PROJECT_REF"),
              let url = URL(string: raw) else {
            return nil
        }
        return url
    }

    var supabaseAnonKey: String? {
        guard let key = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String,
              !key.isEmpty,
              !key.contains("REPLACE_WITH") && !key.contains("YOUR_SUPABASE") else {
            return nil
        }
        return key
    }

    static var current: APIEnvironment {
        #if DEBUG
        return .staging
        #else
        return .production
        #endif
    }
}
