import Foundation
import Testing

@testable import FuginautCore

// VersionCase is one version parsing expectation.
struct VersionCase: Sendable, CustomTestStringConvertible {
    // text is the version to parse.
    let text: String
    // wantVersion is the expected description, or nil when parsing should fail.
    let wantVersion: String?

    // testDescription labels the case in test output.
    var testDescription: String { text.isEmpty ? "empty" : text }
}

// versionCases covers plain, prefixed, and malformed versions.
let versionCases: [VersionCase] = [
    VersionCase(text: "1.2.3", wantVersion: "1.2.3"),  // Test 0: Plain.
    VersionCase(text: "v0.7.0", wantVersion: "0.7.0"),  // Test 1: Leading v.
    VersionCase(text: "1.2", wantVersion: nil),  // Test 2: Too few parts.
    VersionCase(text: "1.2.3.4", wantVersion: nil),  // Test 3: Too many parts.
    VersionCase(text: "1.2.3-beta", wantVersion: nil),  // Test 4: Prerelease.
    VersionCase(text: "1..3", wantVersion: nil),  // Test 5: Empty part.
    VersionCase(text: "", wantVersion: nil),  // Test 6: Empty.
    VersionCase(text: "1.٢.3", wantVersion: nil),  // Test 7: Non-ASCII digit.
]

@Test(arguments: versionCases)
func releaseVersionParses(_ test: VersionCase) {
    #expect(ReleaseVersion(test.text)?.description == test.wantVersion)
}

@Test func releaseVersionOrders() {
    let v = { (text: String) in ReleaseVersion(text)! }
    #expect(v("0.6.0") < v("0.7.0"))
    #expect(v("0.9.9") < v("1.0.0"))
    #expect(v("1.2.3") < v("1.2.10"))
    #expect(!(v("1.2.3") < v("1.2.3")))
}

// ReleaseCase is one latest release response expectation.
struct ReleaseCase: Sendable, CustomTestStringConvertible {
    // name labels the case.
    let name: String
    // json is the response body.
    let json: String
    // wantVersion is the release found, or nil when none is newer.
    let wantVersion: String?
    // want is the error expected, or nil.
    let want: UpdateError?

    // testDescription labels the case in test output.
    var testDescription: String { name }
}

// release builds a latest release response body.
func release(tag: String, page: String? = nil, draft: Bool = false, prerelease: Bool = false) -> String {
    let url = page ?? "https://github.com/dcadolph/fuginaut/releases/tag/\(tag)"
    return #"{"tag_name":"\#(tag)","html_url":"\#(url)","draft":\#(draft),"prerelease":\#(prerelease)}"#
}

// releaseCases covers newer, same, older, drafts, prereleases, bad pages, and bad bodies, against 0.6.0.
let releaseCases: [ReleaseCase] = [
    ReleaseCase(name: "newer", json: release(tag: "v0.7.0"), wantVersion: "0.7.0", want: nil),  // Test 0.
    ReleaseCase(name: "same", json: release(tag: "v0.6.0"), wantVersion: nil, want: nil),  // Test 1.
    ReleaseCase(name: "older", json: release(tag: "v0.5.0"), wantVersion: nil, want: nil),  // Test 2.
    ReleaseCase(name: "draft", json: release(tag: "v0.7.0", draft: true), wantVersion: nil, want: nil),  // Test 3.
    ReleaseCase(  // Test 4: Prerelease is never offered.
        name: "prerelease", json: release(tag: "v0.7.0", prerelease: true), wantVersion: nil, want: nil),
    ReleaseCase(  // Test 5: Page off GitHub is refused.
        name: "foreign page", json: release(tag: "v0.7.0", page: "https://example.com/x"), wantVersion: nil,
        want: nil),
    ReleaseCase(  // Test 6: Plain http page is refused.
        name: "http page", json: release(tag: "v0.7.0", page: "http://github.com/x"), wantVersion: nil, want: nil),
    ReleaseCase(name: "bad tag", json: release(tag: "nightly"), wantVersion: nil, want: nil),  // Test 7.
    ReleaseCase(name: "not json", json: "<html>", wantVersion: nil, want: .decode),  // Test 8.
    ReleaseCase(name: "missing tag", json: #"{"html_url":"x"}"#, wantVersion: nil, want: .decode),  // Test 9.
]

@Test(arguments: releaseCases)
func updateCheckerReadsRelease(_ test: ReleaseCase) {
    let current = ReleaseVersion("0.6.0")!
    do {
        let got = try UpdateChecker.newer(than: current, in: Data(test.json.utf8))
        #expect(test.want == nil)
        #expect(got?.version.description == test.wantVersion)
    } catch {
        #expect(error as? UpdateError == test.want)
    }
}

@Test func updateCheckerAsksGitHub() async throws {
    let fetcher = FetcherFunc { request in
        #expect(request.url == UpdateChecker.api)
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/vnd.github+json")
        return (Data(release(tag: "v1.0.0").utf8), 200)
    }
    let got = try await UpdateChecker(fetcher: fetcher, current: ReleaseVersion("0.6.0")!).check()
    #expect(got?.version.description == "1.0.0")
    #expect(got?.page.absoluteString == "https://github.com/dcadolph/fuginaut/releases/tag/v1.0.0")
}

@Test func updateCheckerRejectsServerError() async {
    let fetcher = FetcherFunc { _ in (Data(), 403) }
    await #expect(throws: UpdateError.server(status: 403)) {
        try await UpdateChecker(fetcher: fetcher, current: ReleaseVersion("0.6.0")!).check()
    }
}

@Test func updateCheckerPassesFetchError() async {
    let fetcher = FetcherFunc { _ in throw URLError(.notConnectedToInternet) }
    await #expect(throws: URLError.self) {
        try await UpdateChecker(fetcher: fetcher, current: ReleaseVersion("0.6.0")!).check()
    }
}

// ScheduleCase is one schedule expectation, in seconds after launch.
struct ScheduleCase: Sendable, CustomTestStringConvertible {
    // name labels the case.
    let name: String
    // lastChecked is when the last check ran, or nil for never.
    let lastChecked: TimeInterval?
    // now is the current time.
    let now: TimeInterval
    // wantDue is whether a check should run.
    let wantDue: Bool

    // testDescription labels the case in test output.
    var testDescription: String { name }
}

// scheduleCases covers the launch delay, the first check, a fresh check, a stale check, and a clock set back.
let scheduleCases: [ScheduleCase] = [
    ScheduleCase(name: "just launched", lastChecked: nil, now: 59, wantDue: false),  // Test 0.
    ScheduleCase(name: "first check", lastChecked: nil, now: 60, wantDue: true),  // Test 1.
    ScheduleCase(name: "fresh", lastChecked: 60, now: 60 + 6 * 3600 - 1, wantDue: false),  // Test 2.
    ScheduleCase(name: "stale", lastChecked: 60, now: 60 + 6 * 3600, wantDue: true),  // Test 3.
    ScheduleCase(name: "clock set back", lastChecked: 9000, now: 120, wantDue: true),  // Test 4.
]

@Test(arguments: scheduleCases)
func updateScheduleIsDue(_ test: ScheduleCase) {
    let launched = Date(timeIntervalSince1970: 1_000_000)
    let got = UpdateSchedule.isDue(
        lastChecked: test.lastChecked.map { launched.addingTimeInterval($0) }, launched: launched,
        now: launched.addingTimeInterval(test.now))
    #expect(got == test.wantDue)
}
