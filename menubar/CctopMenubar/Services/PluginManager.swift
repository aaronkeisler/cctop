import Foundation
import os.log

private let logger = Logger(subsystem: "com.st0012.CctopMenubar", category: "PluginManager")

@MainActor
class PluginManager: ObservableObject {
    @Published var ccInstalled: Bool = false
    @Published var cxInstalled: Bool = false
    @Published var ocInstalled: Bool = false
    @Published var ocConfigExists: Bool = false

    private static let home = FileManager.default.homeDirectoryForCurrentUser
    private static let codexWrapperPath = home.appendingPathComponent(".local/bin/cctop-codex")
    private static let ocPluginPath = home.appendingPathComponent(".config/opencode/plugins/cctop.js")

    init() {
        refresh()
    }

    func refresh() {
        let fm = FileManager.default
        let home = Self.home

        let ccDir = home.appendingPathComponent(".claude/plugins/cache/cctop")
        var isDir: ObjCBool = false
        ccInstalled = fm.fileExists(atPath: ccDir.path, isDirectory: &isDir) && isDir.boolValue

        cxInstalled = fm.isExecutableFile(atPath: Self.codexWrapperPath.path)

        let ocConfigDir = home.appendingPathComponent(".config/opencode")
        ocConfigExists = fm.fileExists(atPath: ocConfigDir.path)

        ocInstalled = fm.fileExists(atPath: Self.ocPluginPath.path)
    }

    func installCodexWrapper() -> Bool {
        defer { refresh() }

        guard let bundledWrapper = Bundle.main.url(forResource: "cctop-codex", withExtension: nil),
              let bundledData = try? Data(contentsOf: bundledWrapper) else {
            logger.error("Could not read bundled Codex wrapper")
            return false
        }

        let binDir = Self.codexWrapperPath.deletingLastPathComponent()

        do {
            try FileManager.default.createDirectory(at: binDir, withIntermediateDirectories: true)
            try bundledData.write(to: Self.codexWrapperPath, options: .atomic)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: Self.codexWrapperPath.path
            )
            logger.info("Installed Codex wrapper to \(Self.codexWrapperPath.path, privacy: .public)")
            return true
        } catch {
            logger.error("Failed to install Codex wrapper: \(error, privacy: .public)")
            return false
        }
    }

    func removeCodexWrapper() -> Bool {
        defer { refresh() }

        do {
            try FileManager.default.removeItem(at: Self.codexWrapperPath)
            logger.info("Removed Codex wrapper from \(Self.codexWrapperPath.path, privacy: .public)")
            return true
        } catch {
            logger.error("Failed to remove Codex wrapper: \(error, privacy: .public)")
            return false
        }
    }

    func installOpenCodePlugin() -> Bool {
        defer { refresh() }

        guard let bundledPlugin = Bundle.main.url(forResource: "opencode-plugin", withExtension: "js"),
              let bundledData = try? Data(contentsOf: bundledPlugin) else {
            logger.error("Could not read bundled opencode plugin")
            return false
        }

        let pluginsDir = Self.ocPluginPath.deletingLastPathComponent()

        do {
            try FileManager.default.createDirectory(at: pluginsDir, withIntermediateDirectories: true)
            try bundledData.write(to: Self.ocPluginPath, options: .atomic)
            logger.info("Installed opencode plugin to \(Self.ocPluginPath.path, privacy: .public)")
            return true
        } catch {
            logger.error("Failed to install opencode plugin: \(error, privacy: .public)")
            return false
        }
    }

    func removeOpenCodePlugin() -> Bool {
        defer { refresh() }

        do {
            try FileManager.default.removeItem(at: Self.ocPluginPath)
            logger.info("Removed opencode plugin from \(Self.ocPluginPath.path, privacy: .public)")
            return true
        } catch {
            logger.error("Failed to remove opencode plugin: \(error, privacy: .public)")
            return false
        }
    }
}
