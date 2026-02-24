import Foundation

enum UpdateChecker {
    struct Release: Decodable {
        let tag_name: String
        let html_url: String
    }

    private static let lastCheckKey = "lastUpdateCheck"
    private static let cachedVersionKey = "cachedUpdateVersion"
    private static let cachedURLKey = "cachedUpdateURL"
    private static let checkInterval: TimeInterval = 24 * 60 * 60 // 24 hours

    /// Check GitHub for a newer release. Returns (latestVersion, url) if an update is available.
    /// Uses a 24-hour cache unless force is true.
    static func check(force: Bool = false) async -> (String, String)? {
        let defaults = UserDefaults.standard

        // Return cached result if within 24 hours
        if !force,
           let lastCheck = defaults.object(forKey: lastCheckKey) as? Date,
           Date().timeIntervalSince(lastCheck) < checkInterval
        {
            if let version = defaults.string(forKey: cachedVersionKey),
               let url = defaults.string(forKey: cachedURLKey)
            {
                return (version, url)
            }
            return nil
        }

        let urlString = "https://api.github.com/repos/\(Constants.githubRepo)/releases/latest"
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              http.statusCode == 200,
              let release = try? JSONDecoder().decode(Release.self, from: data) else {
            return nil
        }

        let latest = release.tag_name.hasPrefix("v")
            ? String(release.tag_name.dropFirst())
            : release.tag_name

        // Cache the result
        defaults.set(Date(), forKey: lastCheckKey)

        if isNewer(latest, than: Constants.version) {
            defaults.set(latest, forKey: cachedVersionKey)
            defaults.set(release.html_url, forKey: cachedURLKey)
            return (latest, release.html_url)
        }

        defaults.removeObject(forKey: cachedVersionKey)
        defaults.removeObject(forKey: cachedURLKey)
        return nil
    }

    private static func isNewer(_ a: String, than b: String) -> Bool {
        let aParts = a.split(separator: ".").compactMap { Int($0) }
        let bParts = b.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(aParts.count, bParts.count) {
            let av = i < aParts.count ? aParts[i] : 0
            let bv = i < bParts.count ? bParts[i] : 0
            if av > bv { return true }
            if av < bv { return false }
        }
        return false
    }
}
