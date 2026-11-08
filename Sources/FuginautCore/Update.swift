import Foundation

// UpdateError names why an update check failed.
public enum UpdateError: Error, Equatable, Sendable {
    // server is a response other than 200.
    case server(status: Int)
    // decode is a body that is not a release.
    case decode
}

// ReleaseVersion is a release number such as 1.2.3.
public struct ReleaseVersion: Sendable, Comparable, Equatable, CustomStringConvertible {
    // major is the first number.
    public let major: Int
    // minor is the second number.
    public let minor: Int
    // patch is the third number.
    public let patch: Int

    // init parses "1.2.3" or "v1.2.3", and returns nil for anything else, prereleases included.
    public init?(_ text: String) {
        let body = text.hasPrefix("v") ? String(text.dropFirst()) : text
        let parts = body.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else {
            return nil
        }
        let numbers = parts.compactMap { part in
            !part.isEmpty && part.allSatisfy { $0.isASCII && $0.isNumber } ? Int(part) : nil
        }
        guard numbers.count == 3 else {
            return nil
        }
        major = numbers[0]
        minor = numbers[1]
        patch = numbers[2]
    }

    // description is the version without a leading v, such as 1.2.3.
    public var description: String { "\(major).\(minor).\(patch)" }

    // < orders versions by major, then minor, then patch.
    public static func < (lhs: ReleaseVersion, rhs: ReleaseVersion) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }
}

// Release is a published release newer than the running app.
public struct Release: Sendable, Equatable {
    // version is the release's number.
    public let version: ReleaseVersion
    // page is the release page on GitHub.
    public let page: URL

    // init builds a release from its number and page.
    public init(version: ReleaseVersion, page: URL) {
        self.version = version
        self.page = page
    }
}

// Fetcher sends a request and returns the body and the HTTP status.
public protocol Fetcher: Sendable {
    // fetch sends request and returns the body and status.
    func fetch(_ request: URLRequest) async throws -> (Data, Int)
}

// FetcherFunc adapts a function to Fetcher.
public struct FetcherFunc: Fetcher {
    // body is the function that sends the request.
    let body: @Sendable (URLRequest) async throws -> (Data, Int)

    // init wraps body.
    public init(_ body: @escaping @Sendable (URLRequest) async throws -> (Data, Int)) {
        self.body = body
    }

    // fetch calls the wrapped function.
    public func fetch(_ request: URLRequest) async throws -> (Data, Int) {
        try await body(request)
    }
}

// URLSessionFetcher sends requests with URLSession.
public struct URLSessionFetcher: Fetcher {
    // init builds a fetcher on the shared session.
    public init() {}

    // fetch sends request on the shared session.
    public func fetch(_ request: URLRequest) async throws -> (Data, Int) {
        let (data, response) = try await URLSession.shared.data(for: request)
        return (data, (response as? HTTPURLResponse)?.statusCode ?? 0)
    }
}

// UpdateChecker asks GitHub whether a newer release exists.
public struct UpdateChecker: Sendable {
    // api is the endpoint that names the latest release.
    public static let api = URL(string: "https://api.github.com/repos/dcadolph/fuginaut/releases/latest")!

    // fetcher sends the request.
    let fetcher: any Fetcher
    // current is the running version.
    let current: ReleaseVersion

    // init builds a checker for the running version.
    public init(fetcher: any Fetcher = URLSessionFetcher(), current: ReleaseVersion) {
        self.fetcher = fetcher
        self.current = current
    }

    // check returns the latest release when it is newer than the running version, and nil otherwise.
    public func check() async throws -> Release? {
        var request = URLRequest(url: Self.api)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        let (data, status) = try await fetcher.fetch(request)
        guard status == 200 else {
            throw UpdateError.server(status: status)
        }
        return try Self.newer(than: current, in: data)
    }

    // newer decodes a latest release response and returns the release when it is newer than current.
    // Drafts, prereleases, tags that do not parse, and pages that are not https on github.com are never newer.
    static func newer(than current: ReleaseVersion, in data: Data) throws -> Release? {
        guard let release = try? JSONDecoder().decode(Payload.self, from: data) else {
            throw UpdateError.decode
        }
        guard !(release.draft ?? false), !(release.prerelease ?? false),
            let version = ReleaseVersion(release.tagName), version > current,
            let page = URL(string: release.htmlURL), page.scheme == "https", page.host == "github.com"
        else {
            return nil
        }
        return Release(version: version, page: page)
    }

    // Payload is the part of GitHub's release response the check reads.
    private struct Payload: Decodable {
        // tagName is the release tag.
        let tagName: String
        // htmlURL is the release page.
        let htmlURL: String
        // draft reports an unpublished release.
        let draft: Bool?
        // prerelease reports a release marked as a prerelease.
        let prerelease: Bool?

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlURL = "html_url"
            case draft
            case prerelease
        }
    }
}

// UpdateSchedule decides when the next automatic check is due.
public enum UpdateSchedule {
    // everySeconds is how long one check stays fresh.
    public static let everySeconds: TimeInterval = 6 * 60 * 60
    // firstSeconds is how long after launch the first check waits, so it never slows a login.
    public static let firstSeconds: TimeInterval = 60

    // isDue reports whether an automatic check should run now. A clock set behind the last check counts as
    // due.
    public static func isDue(lastChecked: Date?, launched: Date, now: Date) -> Bool {
        guard now.timeIntervalSince(launched) >= firstSeconds else {
            return false
        }
        guard let lastChecked else {
            return true
        }
        let age = now.timeIntervalSince(lastChecked)
        return age >= everySeconds || age < 0
    }
}
