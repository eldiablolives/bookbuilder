//
//  Compress.swift
//  mkepub
//
//  Created by Rumpel Stiltskin on 16.09.2024.
//

import Foundation
import ZIPFoundation

func addDirToZip(dirPath: URL, prefix: String, archive: Archive) throws {
    let fileManager = FileManager.default
    let dir = dirPath.appendingPathComponent(prefix)
    
    let contents = try fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
    
    for entry in contents {
        let name = entry.lastPathComponent
        let prefixedName = "\(prefix)/\(name)"  // This now includes folder structure
                
        if entry.hasDirectoryPath {
            // Recursively add subdirectory contents
            try addDirToZip(dirPath: dirPath, prefix: prefixedName, archive: archive)  // Pass the correct `prefix`
        } else {
            // Add the file entry to the zip archive using the full relative path
            logger.log("Adding \(prefixedName) to \(dir)")
            try archive.addEntry(with: prefixedName, relativeTo: dirPath, compressionMethod: .deflate, bufferSize: 16384)
        }
    }
}

func compressEPUB(folderURL: URL) {
    let fileManager = FileManager.default
    let epubFileURL = folderURL.appendingPathExtension("epub")
    
    // **Delete the existing .epub archive if it exists**
    if fileManager.fileExists(atPath: epubFileURL.path) {
        do {
            try fileManager.removeItem(at: epubFileURL)
            logger.log("Existing EPUB archive removed: \(epubFileURL.path)")
        } catch {
            logger.log("Failed to remove existing EPUB archive: \(epubFileURL.path) \(error)")
            return
        }
    }
    
    // **Create the .epub archive using the throwing initializer**
    do {
        let archive = try Archive(url: epubFileURL, accessMode: .create)
        
        // Start by adding the "mimetype" file without compression
        let mimetypeFileURL = folderURL.appendingPathComponent("mimetype")
        let mimetypeData = try Data(contentsOf: mimetypeFileURL)
        
        try archive.addEntry(
            with: "mimetype",
            type: .file,
            uncompressedSize: Int64(mimetypeData.count),
            compressionMethod: .none,
            bufferSize: 16384
        ) { position, size in
            let start = Int(position)
            let end = start + Int(size)
            return mimetypeData.subdata(in: start..<end)
        }
        
        // Add META-INF and OPS directories to the zip archive
        let directories = ["META-INF", "OPS"]
        for dir in directories {
//            let dirURL = folderURL.appendingPathComponent(dir)
            try addDirToZip(dirPath: folderURL, prefix: dir, archive: archive)
        }
        
        logger.log("EPUB compression completed.")
        
    } catch {
        logger.log("Failed to create the .epub archive or process files: \(error)")
    }
}
