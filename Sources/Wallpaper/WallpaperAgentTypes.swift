import Foundation

public enum AgentXPCMessage: Codable, Equatable, Sendable {
    case diagnosticState
    case snapshotAllSpaces
    case getCaches
}
