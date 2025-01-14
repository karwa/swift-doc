import Foundation
import SwiftSemantics
import struct SwiftSemantics.Protocol

public final class Module {
    public let name: String
    public let sourceFiles: [SourceFile]
    public let interface: Interface

    public required init(name: String = "Anonymous", sourceFiles: [SourceFile], exclusions: [String] = []) {
        self.name = name
        self.sourceFiles = sourceFiles

        let imports = sourceFiles.flatMap { $0.imports }
        let symbols = sourceFiles.flatMap { $0.symbols }.filter({ !exclusions.contains($0.id.description) })
        self.interface = Interface(imports: imports, symbols: symbols)
    }

    public convenience init(name: String = "Anonymous", paths: [String], exclusionsFilePath: String? = nil) throws {
        var sources: [(file: URL, directory: URL)] = []

        let fileManager = FileManager.default
        for path in paths {
            let directory = URL(fileURLWithPath: path)
            guard let directoryEnumerator = fileManager.enumerator(at: directory,
                                                                   includingPropertiesForKeys: [.isDirectoryKey],
                                                                   options: [.skipsHiddenFiles, .skipsPackageDescendants])
            else { continue }

            let ignoredDirectories: Set<URL> = Set([
                "node_modules",
                "Packages",
                "Pods",
                "Resources",
                "Tests"
            ].map { directory.appendingPathComponent($0) })

            for case let url as URL in directoryEnumerator {
                guard url.pathExtension == "swift",
                      fileManager.isReadableFile(atPath: url.path)
                else {
                    if ignoredDirectories.contains(url) {
                        directoryEnumerator.skipDescendants()
                    }

                    continue
                }

                sources.append((url, directory))
            }
        }

        var excludedSymbols = [String]()
        if let exclusionsFilePath = exclusionsFilePath {
          excludedSymbols = try String(contentsOfFile: exclusionsFilePath).components(separatedBy: "\n").filter { !$0.isEmpty }
        }
        let sourceFiles = try sources.parallelMap {
          try SourceFile(file: $0.file, relativeTo: $0.directory, excludedSymbols: excludedSymbols)
        }

        self.init(name: name, sourceFiles: sourceFiles, exclusions: excludedSymbols)
    }
}
