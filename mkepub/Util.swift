//
//  Util.swift
//  mkepub
//
//  Created by Rumpel Stiltskin on 16.09.2024.
//

import Foundation

func createFile(at filePath: URL, withContent fileContent: String) {
    do {
        try fileContent.write(to: filePath, atomically: true, encoding: .utf8)
    } catch {
        logger.log("Failed to create or write to file: \(error)")
    }
}

func sanitizeName(_ input: String) -> String {
    var output = input.lowercased()
    
    // Replace non-alphanumeric characters with '-'
    output = output.map { $0.isLetter || $0.isNumber ? String($0) : "-" }.joined()
    
    // Remove multiple dashes
    while output.contains("--") {
        output = output.replacingOccurrences(of: "--", with: "-")
    }
    
    // Remove trailing dashes
    while output.hasSuffix("-") {
        output.removeLast()
    }
    
    return output
}

func extractTitle(from markdownContent: String) -> String {
    for line in markdownContent.split(separator: "\n") {
        if line.hasPrefix("#") {
            // Extract the title, trimming the `##` and any spaces
            let title = line.drop(while: { $0 == "#" || $0 == " " })
            return String(title)
        }
    }
    return ""
}

func getFileName(from source: URL) -> String {
    return source.deletingPathExtension().lastPathComponent
}
