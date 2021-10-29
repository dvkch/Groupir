//
//  TempURL.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 29/10/2021.
//

import Foundation

class TempURL {
    // MARK: Static
    private static let baseFolder = FileManager.default
        .urls(for: .cachesDirectory, in: .userDomainMask).first!
        .appendingPathComponent("previews", isDirectory: true)
    
    static func cleanup() {
        do {
            Logger.i(.tempURL, "Clearing up \(baseFolder)")
            try FileManager.default.removeItems(in: baseFolder)
        }
        catch {
            Logger.e(.tempURL, "Couldn't clear up: \(error)")
        }
    }
    
    // MARK: Init
    init?(originalURL: URL) {
        self.originalURL = originalURL
        
        do {
            url = TempURL.baseFolder
                .appendingPathComponent(originalURL.deletingLastPathComponent().lastPathComponent, isDirectory: true)
                .appendingPathComponent(originalURL.lastPathComponent)

            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: [:])
            try FileManager.default.copyItem(at: originalURL, to: url)
        }
        catch {
            Logger.e(.tempURL, "Couldn't create temp copy of \(originalURL): \(error)")
            return nil
        }
    }
    
    deinit {
        do {
            try FileManager.default.removeItem(at: url, removeParentIfEmpty: true)
        }
        catch {
            Logger.e(.tempURL, "Couldn't clean up temp copy of \(originalURL): \(error)")
        }
    }
    
    // MARK: Properties
    private let originalURL: URL
    let url: URL
}

extension URL {
    var tempURL: TempURL? {
        return TempURL(originalURL: self)
    }
}
