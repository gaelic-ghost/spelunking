import SpelunkingKit

@main
struct SPKMain {
    static func main() {
        let target = SPKResearchTarget.mediaRemote

        print(target.name)
        print(target.summary)
        print("Docs: \(target.documentationPath)")
        print("Research: \(target.researchPath)")
    }
}
