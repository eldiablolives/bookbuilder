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

func sanitizeImageName(_ input: String) -> String {
    // Separate file name and extension
    let fileExtension = (input as NSString).pathExtension.lowercased()
    var fileName = (input as NSString).deletingPathExtension.lowercased()
    
    // Replace non-alphanumeric characters in the file name with '-'
    fileName = fileName.map { $0.isLetter || $0.isNumber ? String($0) : "-" }.joined()
    
    // Replace multiple hyphens with a single hyphen using regex
    fileName = fileName.replacingOccurrences(of: "-+", with: "-", options: .regularExpression)
    
    // Remove leading and trailing hyphens
    fileName = fileName.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    
    // Append the extension back to the sanitized file name
    return fileExtension.isEmpty ? fileName : "\(fileName).\(fileExtension)"
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

func titleCase(_ input: String) -> String {
    // Define the list of words that should remain lowercase unless they are the first or last word
    let lowercaseWords: Set = ["a", "an", "and", "as", "at", "but", "by", "for", "if", "in", "nor", "of", "on", "or", "so", "the", "to", "up", "yet"]
    
    // Split the string into words
    let words = input.lowercased().split(separator: " ")
    
    // Map over each word to apply title case rules
    let titleCasedWords = words.enumerated().map { index, word -> String in
        // Capitalize the first and last words or words not in the lowercase list
        if index == 0 || index == words.count - 1 || !lowercaseWords.contains(String(word)) {
            return word.prefix(1).uppercased() + word.dropFirst()
        } else {
            return String(word)  // Leave it lowercase
        }
    }
    
    // Join the words back into a single string with spaces in between
    return titleCasedWords.joined(separator: " ")
}
