import Foundation
import MediaPlayer

@main
struct SPKNowPlayingFixture {
    static func main() throws {
        let duration = TimeInterval(CommandLine.arguments.dropFirst().first.flatMap(Double.init) ?? 30)
        let title = "Spelunking Fixture"
        let artist = "MediaRemote Research"

        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist,
            MPMediaItemPropertyAlbumTitle: "Spelunking",
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: 0,
            MPNowPlayingInfoPropertyPlaybackRate: 1
        ]
        MPNowPlayingInfoCenter.default().playbackState = .playing

        print("now-playing-fixture: publishing metadata-only '\(title)' by \(artist) for \(Int(duration))s")
        Thread.sleep(forTimeInterval: duration)

        MPNowPlayingInfoCenter.default().playbackState = .stopped
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        print("now-playing-fixture: stopped")
    }
}
