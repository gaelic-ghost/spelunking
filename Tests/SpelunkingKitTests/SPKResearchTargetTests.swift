import Foundation
import SpelunkingKit
import Testing

@Suite("Research targets")
struct SPKResearchTargetTests {
    @Test("MediaRemote target points at the seeded documentation and research directories")
    func mediaRemotePaths() {
        let target = SPKResearchTarget.mediaRemote

        #expect(target.name == "MediaRemote.framework")
        #expect(target.documentationPath == "docs/frameworks/MediaRemote")
        #expect(target.researchPath == "research/MediaRemote")
    }

    @Test("Notification Center probe explains an absent Accessibility grant")
    func notificationProbeUntrustedResult() throws {
        let encoded = try JSONEncoder().encode(.accessibilityNotTrusted as SPKNotificationCenterAccessibilityProbeResult)
        let payload = try JSONSerialization.jsonObject(with: encoded) as? [String: String]

        #expect(payload?["status"] == "accessibility-not-trusted")
        #expect(payload?["message"]?.contains("Accessibility permission is not granted") == true)
    }
}
