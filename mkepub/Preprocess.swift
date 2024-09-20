//
//  Util.swift
//  mkepub
//
//  Created by Rumpel Stiltskin on 16.09.2024.
//

import Foundation

func preprocessMarkdown(text: String) -> String {
    // Remove spaces between quotes and punctuation
    var content = removeSpacesBetweenQuotesAndPunctuation(in: text)

    // Replace quotes and apostrophes with curly ones and fix punctuation placement
    content = replaceQuotes(in: content)
    content = fixPunctuation(in: content)

    // Fix anomalies
    content = fixEmAnomaly(in: content)
    content = fixTshirtAnomaly(in: content)

    // Remove extra spaces
//    content = removeExtraSpaces(from: content)

    // Replace breaks
    return replaceBreaks(in: content)
}

func isPunctuation(_ ch: Character) -> Bool {
    switch ch {
    case ",", ".", "?", "!", ";", ":", "…":
        return true
    default:
        return false
    }
}

func removeExtraSpaces(from text: String) -> String {
    return text
        .split(separator: "\n")  // Split the string by lines
        .map { line in
            line.split(separator: " ")  // Split the line by whitespace
                .filter { !$0.isEmpty }  // Remove extra spaces
                .joined(separator: " ")  // Join words back with a single space
        }
        .joined(separator: "\n")  // Join the lines back together with newlines
}

func fixTshirtAnomaly(in text: String) -> String {
    let patterns = ["tshirt", "t-shirt", "Tshirt", "T-shirt"]
    var output = text

    for pattern in patterns {
        output = output.replacingOccurrences(of: pattern, with: "T-shirt")
    }

    return output
}

func fixEmAnomaly(in text: String) -> String {
    var output = ""
    let chars = Array(text)
    let length = chars.count
    var i = 0

    while i < length {
        let ch = chars[i]

        if ch == "—" {
            // Remove space before em dash if it exists
            if !output.isEmpty && output.last == " " {
                output.removeLast()
            }

            output.append(ch)

            // Skip space after em dash if it exists
            if i + 1 < length && chars[i + 1] == " " {
                i += 1
            }
        } else {
            output.append(ch)
        }

        i += 1
    }

    return output
}

func removeSpacesBetweenQuotesAndPunctuation(in text: String) -> String {
    let pattern = "\"\\s+([.,!?…])"
    let regex = try! NSRegularExpression(pattern: pattern, options: [])

    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    let modifiedText = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "\"$1")
    
    return modifiedText
}

func replaceBreaks(in text: String) -> String {
    return text.replacingOccurrences(of: "\n----\n", with: "\n\n&nbsp;\n\n<div class=\"center\">***</div>\n\n&nbsp;\n\n")
}

func replaceQuotes(in text: String) -> String {
    var output = ""
    var insideQuote = false
    var insideHtmlTag = false

    for ch in text {
        if ch == "<" {
            insideHtmlTag = true
        } else if ch == ">" {
            insideHtmlTag = false
        }

        if insideHtmlTag {
            output.append(ch)
            continue
        }

        switch ch {
        // Handle single quotes, simplified to always replace with a curly quote
        case "'":
            output.append("’")
        // Handle double quotes, toggle between opening and closing quotes
        case "\"", "“", "”":
            insideQuote.toggle()
            output.append(insideQuote ? "“" : "”")
        default:
            output.append(ch)
        }
    }

    return output
}


func fixPunctuation(in text: String) -> String {
    var output = ""
    let chars = Array(text)
    var insideQuote = false
    let length = chars.count

    var i = 0
    while i < length {
        let ch = chars[i]

        if ch == "<" || ch == ">" {
            output.append(ch)
        } else if ch == "\"" || ch == "“" || ch == "”" {
            insideQuote.toggle()
            output.append(ch)

            // Check if the next character is punctuation and we are closing a quote
            if !insideQuote && i + 1 < length && isPunctuation(chars[i + 1]) {
                i += 1 // Move past the quote
                output.append(chars[i]) // Add the punctuation inside the quote
            }
        } else {
            output.append(ch)
        }

        i += 1
    }

    return output
}


