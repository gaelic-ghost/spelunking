import Foundation
import SpelunkingKit
import Testing

@Suite("Research targets")
struct SPKResearchTargetTests {
    @Test("Messages target points at the persisted documentation and research directories")
    func messagesPaths() {
        let target = SPKResearchTarget.messages

        #expect(target.name == "Messages.app and IMCore")
        #expect(target.documentationPath == "docs/frameworks/Messages")
        #expect(target.researchPath == "research/Messages")
    }

    @Test("Phone target points at the persisted documentation and research directories")
    func phonePaths() {
        let target = SPKResearchTarget.phone

        #expect(target.name == "Phone.app and telephony services")
        #expect(target.documentationPath == "docs/frameworks/Phone")
        #expect(target.researchPath == "research/Phone")
    }

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
