//
//  FileManager+SY.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 29/10/2021.
//

import Foundation

extension FileManager {
    func removeItems(in folder: URL) throws {
        Logger.i(.fileManager, "Clearing up \(folder)")
        let resourceKeys = Set<URLResourceKey>([.isDirectoryKey])
        let options: DirectoryEnumerationOptions = [.skipsPackageDescendants]
        
        guard isDirectoryAndExists(at: folder) else { return }
        
        let files = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: Array(resourceKeys), options: options)
        try files.forEach { fileURL in
            guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys), let isDirectory = resourceValues.isDirectory else { return }
            if isDirectory {
                try removeDirectory(at: fileURL)
            }
            else {
                Logger.i(.fileManager, "Deleting \(fileURL)")
                try FileManager.default.removeItem(at: fileURL)
            }
        }
    }
    
    func removeDirectory(at url: URL) throws {
        Logger.i(.fileManager, "Deleting \(url)")
        try removeItems(in: url)
        try FileManager.default.removeItem(at: url)
    }
    
    func removeItem(at url: URL, removeParentIfEmpty: Bool) throws {
        try FileManager.default.removeItem(at: url)
        if removeParentIfEmpty, try FileManager.default.contentsOfDirectory(atPath: url.deletingLastPathComponent().path).isEmpty {
            try FileManager.default.removeItem(at: url.deletingLastPathComponent())
        }
    }
    
    private func isDirectoryAndExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = .init(false)
        guard fileExists(atPath: url.path, isDirectory: &isDirectory) else { return false }
        return isDirectory.boolValue
    }
}
