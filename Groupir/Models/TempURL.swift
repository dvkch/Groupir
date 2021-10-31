//
//  TempURL.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 29/10/2021.
//

import Foundation

/*
 @abstract This class is useful to create copies of items in the iOS gallery and exposing them to QLPreviewController and UIActivityViewController
 without having sandbox issues. On APFS copies are basically free (in time and storage space) so this is an ideal situation
 */
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
    init?(originalURL: URL, filename: String) {
        self.originalURL = originalURL
        
        do {
            var url = TempURL.baseFolder
                .appendingPathComponent(originalURL.deletingLastPathComponent().lastPathComponent, isDirectory: true)
                .appendingPathComponent(filename)

            var count = 0
            while FileManager.default.fileExists(atPath: url.path) {
                count += 1
                url = url.deletingLastPathComponent()
                    .appendingPathComponent((filename as NSString).deletingPathExtension + "-\(count)")
                    .appendingPathExtension((filename as NSString).pathExtension)
            }
            self.url = url
            
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: [:])
            try FileManager.default.copyItem(at: originalURL, to: url)
            
            let attributes = try FileManager.default.attributesOfItem(atPath: originalURL.path)
            try [FileAttributeKey.creationDate, .modificationDate].forEach { key in
                // useful when AirDrop-ing
                if let value = attributes[key] {
                    try FileManager.default.setAttributes([key: value], ofItemAtPath: url.path)
                }
            }
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
    func tempURL(filename: String? = nil) -> TempURL? {
        return TempURL(originalURL: self, filename: filename ?? self.lastPathComponent)
    }
}
