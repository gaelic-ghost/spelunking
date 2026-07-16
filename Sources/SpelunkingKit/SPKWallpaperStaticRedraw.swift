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

public struct SPKDesktopImageRedrawProbeEntry: Equatable, Sendable {
    public var screenName: String
    public var beforeImageURL: String?
    public var afterImageURL: String?
    public var beforeOptionKeys: [String]
    public var afterOptionKeys: [String]?
    public var reapplied: Bool
    public var preservedImageURL: Bool?
}

public struct SPKDesktopImageRedrawProbeResult: Equatable, Sendable {
    public var execute: Bool
    public var entries: [SPKDesktopImageRedrawProbeEntry]
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

    public func redrawProbe(execute: Bool) throws -> SPKDesktopImageRedrawProbeResult {
        let workspace = NSWorkspace.shared
        let entries = try NSScreen.screens.map { screen in
            let beforeImageURL = workspace.desktopImageURL(for: screen)
            let beforeOptions = workspace.desktopImageOptions(for: screen) ?? [:]

            if execute, let beforeImageURL {
                try workspace.setDesktopImageURL(beforeImageURL, for: screen, options: beforeOptions)
            }

            let afterImageURL = execute ? workspace.desktopImageURL(for: screen) : nil
            let afterOptions = execute ? workspace.desktopImageOptions(for: screen) ?? [:] : nil

            return SPKDesktopImageRedrawProbeEntry(
                screenName: screen.localizedName,
                beforeImageURL: beforeImageURL?.absoluteString,
                afterImageURL: afterImageURL?.absoluteString,
                beforeOptionKeys: beforeOptions.keys.map(\.rawValue).sorted(),
                afterOptionKeys: afterOptions?.keys.map(\.rawValue).sorted(),
                reapplied: execute && beforeImageURL != nil,
                preservedImageURL: execute ? beforeImageURL == afterImageURL : nil
            )
        }

        return SPKDesktopImageRedrawProbeResult(execute: execute, entries: entries)
    }
}
#endif
