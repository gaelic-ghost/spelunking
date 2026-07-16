#if canImport(AppKit)
import AppKit
import Foundation

public struct SPKDesktopImageRedrawEntry: Equatable, Sendable {
    public var screenName: String
    public var imageURL: String?
    public var optionKeys: [String]
    public var reapplied: Bool
}

public struct SPKDesktopImageRedrawResult: Equatable, Sendable {
    public var execute: Bool
    public var entries: [SPKDesktopImageRedrawEntry]
}

@MainActor
public struct SPKWallpaperStaticRedraw: Sendable {
    public init() {}

    public func reapplyCurrentDesktopImages(execute: Bool) throws -> SPKDesktopImageRedrawResult {
        let workspace = NSWorkspace.shared
        let entries = try NSScreen.screens.map { screen in
            let imageURL = workspace.desktopImageURL(for: screen)
            let options = workspace.desktopImageOptions(for: screen) ?? [:]

            if execute, let imageURL {
                try workspace.setDesktopImageURL(imageURL, for: screen, options: options)
            }

            return SPKDesktopImageRedrawEntry(
                screenName: screen.localizedName,
                imageURL: imageURL?.absoluteString,
                optionKeys: options.keys.map(\.rawValue).sorted(),
                reapplied: execute && imageURL != nil
            )
        }

        return SPKDesktopImageRedrawResult(execute: execute, entries: entries)
    }
}
#endif
