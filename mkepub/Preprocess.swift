//
//  Util.swift
//  mkepub
//
//  Created by Rumpel Stiltskin on 16.09.2024.
//

import Foundation

// Preprocess function to handle specific commands or reconstruct the original if not recognized
func preprocessePubCommand(_ command: String, _ params: String? = nil) -> String {
    var result: String
    
    // Handle the "chapter" command
    if command == "chapter" {
        if let params = params {
            // Split the input at the "|" character (optional part)
            let parts = params.split(separator: "|", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespaces) }
            let chapterHeading = parts[0] // Always present (e.g., "Chapter 1")

            // Check if the optional title (after "|") is provided
            if parts.count > 1 {
                let chapterTitle = parts[1] // Optional title (e.g., "Perfect day")
                result = """
                <div class="chapter-heading">
                \(chapterHeading)
                </div>
                # \(chapterTitle)
                """
            } else {
                // If no title is provided, just use the chapter heading and add it to the TOC
                result = """
                # \(chapterHeading)
                """
            }
        } else {
            result = "{{chapter}}" // In case no params are provided
        }
    }
    
    // Handle the "break" command
    else if command == "break" {
        result = "<br/>"
    }
    
    // Handle the "pagebreak" command (ensure it happens on the right-hand page)
    else if command == "pagebreak" {
        result = ""
    }
    
    // Handle the "copyright" command
    else if command == "copyright" {
        if let params = params {
            result = """
            <div class="copyright">
            \(params)
            </div>
            """
        } else {
            result = """
            <div class="copyright">
            Copyright
            </div>
            """
        }
    }
    
    // Handle the "email" command
    else if command == "email" {
        if let params = params {
            result = """
            <a class="email" href="\(params)">\(params)</a>
            """
        } else {
            result = """
            <div class="email">Email Address
            </div>
            """
        }
    }
    
    // Handle the "quote" command
    else if command == "quote" {
        if let params = params {
            result = """
            <div class="quote">
            \(params)
            </div>
            """
        } else {
            result = """
            <div class="quote">
            Quote
            </div>
            """
        }
    }
    
    // Handle the "hero" command
    else if command == "hero" {
        if let params = params {
            result = """
            <div class="hero">
            \(params)
            </div>
            """
        } else {
            result = """
            <div class="hero">
            Hero Text
            </div>
            """
        }
    }
    
    // Handle the "cover" command
    else if command == "cover" {
        if let params = params {
            result = """
            \\cleardoublepage % Ensure the image starts on a new right-hand page
            
            % Turn off page numbers and headers/footers for this page
            \\thispagestyle{empty}
            
            % Temporarily reset margins to zero for the image page
            \\newgeometry{margin=0pt}
            
            % Stretch the image to cover the entire page, including the bleed
            \\noindent
            \\includegraphics[width=\\paperwidth, height=\\paperheight]{\(params)}
            
            % Restore original geometry for the rest of the document
            \\restoregeometry
            
            \\clearpage % Move to the next page
            """
        } else {
            result = """
            \\cleardoublepage % Ensure the image starts on a new right-hand page
            
            % Turn off page numbers and headers/footers for this page
            \\thispagestyle{empty}
            
            % Temporarily reset margins to zero for the image page
            \\newgeometry{margin=0pt}
            
            % Stretch the image to cover the entire page, including the bleed
            \\noindent
            \\includegraphics[width=\\paperwidth, height=\\paperheight]{path/to/your-cover.jpg}
            
            % Restore original geometry for the rest of the document
            \\restoregeometry
            
            \\clearpage % Move to the next page
            """
        }
    }
    
    // Handle the "link" command
    else if command == "link" {
        if let params = params {
            // Split the URL and optional description at the '|' character
            let parts = params.split(separator: "|", maxSplits: 1).map { String($0) }
            let url = parts[0] // URL part
            
            // Remove the protocol from the URL (http:// or https://)
            if let urlWithoutProtocol = url.components(separatedBy: "://").last {
                result = urlWithoutProtocol
            } else {
                result = url // In case there's no protocol (e.g., the URL was just 'example.com')
            }
        } else {
            result = "{{link}}"
        }
    }
    
    else if command == "title" {
        if let params = params {
            result = """
            <div class="title">
            \(params)
            </div>
            """
        } else {
            result = """
            <div class="title">
            Title
            </div>
            """
        }
    }

    else if command == "subtitle" {
        if let params = params {
            result = """
            <div class="subtitle">
            \(params)
            </div>
            """
        } else {
            result = """
            <div class="subtitle">
            Subtitle
            </div>
            """
        }
    }

    else if command == "author" {
        if let params = params {
            result = """
            <div class="author">
            \(params)
            </div>
            """
        } else {
            result = """
            <div class="author">
            Author
            </div>
            """
        }
    }
    
    // If the command is not recognized, reconstruct the original {{command params}}
    else {
        if let params = params {
            result = "{{\(command) \(params)}}"
        } else {
            result = "{{\(command)}}"
        }
    }

    return result
}

func preprocessMarkdown(text: String) -> String {
    // Remove spaces between quotes and punctuation
    var content = removeSpacesBetweenQuotesAndPunctuation(in: text)

    // Replace quotes and apostrophes with curly ones and fix punctuation placement
    content = replaceQuotes(in: content)
    content = fixPunctuation(in: content)

    // Handle preprocessing for any {{command}}
    let pattern = #"\{\{(.*?)\}\}"# // Regex pattern to match {{command params}}
    
    if let regex = try? NSRegularExpression(pattern: pattern) {
        let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))
        
        // Process matches in reverse order to avoid messing with ranges
        for match in matches.reversed() {
            if let range = Range(match.range, in: content) {
                let commandString = String(content[range])
                
                // Extract the inner content (command + params) from {{ }}
                let innerContent = commandString.dropFirst(2).dropLast(2).trimmingCharacters(in: .whitespaces)
                
                // Split inner content into command and optional params
                let components = innerContent.split(separator: " ", maxSplits: 1).map { String($0) }
                let command = components.first ?? ""
                let params = components.count > 1 ? components.last : nil
                
                // Process the command using the preprocess function
                let processed = preprocessePubCommand(command, params)
                
                // Replace the original {{command}} with the processed result
                content.replaceSubrange(range, with: processed)
            }
        }
    }
    
    // Remove extra spaces (commented out, but can be re-enabled if needed)
     content = removeExtraSpaces(from: content)

    // Replace breaks
    content = replaceBreaks(in: content)

    // Fix anomalies
    content = fixEmAnomaly(in: content)
    content = fixTshirtAnomaly(in: content)

    
    return content
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
        .joined(separator: "\n\n")  // Join the lines back together with newlines
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
    // Regular expression pattern to match lines with only dashes (and possibly spaces)
    let pattern = #"^\s*----+\s*$"#
    
    // Use regular expression to replace matching lines
    let regex = try! NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
    
    // Perform the replacement
    let modifiedText = regex.stringByReplacingMatches(
        in: text,
        options: [],
        range: NSRange(text.startIndex..., in: text),
        withTemplate: "\n\n<p class=\"center scene-break\">* * *</p>\n\n"
    )
    
    return modifiedText
}

func resetQuotes(in text: String) -> String {
    // Define a dictionary mapping various types of quotes/apostrophes to ASCII equivalents
    let quoteMap: [String: String] = [
        // Single quotes and apostrophes
        "‘": "'", "’": "'", "‚": "'", "‛": "'",
        "‹": "'", "›": "'", "`": "'",
        "´": "'", "ʹ": "'", "ʺ": "'",

        // Double quotes
        "“": "\"", "”": "\"", "„": "\"", "‟": "\"",
        "«": "\"", "»": "\"", "〝": "\"", "〞": "\"",
        "〟": "\"", "＂": "\"", "❝": "\"", "❞": "\"",
        "❮": "\"", "❯": "\"", "❠": "\"", "❡": "\""
    ]
    
    var result = text
    
    // Replace each type of quote or apostrophe with its ASCII equivalent
    for (quote, ascii) in quoteMap {
        result = result.replacingOccurrences(of: quote, with: ascii)
    }
    
    return result
}

func replaceQuotes(in text: String) -> String {
    let text = resetQuotes(in: text)
    
    var output = ""
    var insideDoubleQuote = false
    var insideSingleQuote = false
    var insideHtmlTag = false
    var previousChar: Character? = nil

    for ch in text {
        if ch == "<" {
            insideHtmlTag = true
        } else if ch == ">" {
            insideHtmlTag = false
        }

        if insideHtmlTag {
            output.append(ch)
            previousChar = ch
            continue
        }

        switch ch {
        // Handle single quotes or apostrophes
        case "'":
            // Check if it's part of a contraction or possessive
            if let prev = previousChar, prev.isLetter {
                output.append("’")  // Closing curly quote for contractions/names like D'Artagnan
            } else {
                insideSingleQuote.toggle()
                output.append(insideSingleQuote ? "‘" : "’")  // Toggle for standalone single quotes
            }
        // Handle double quotes, toggle between opening and closing quotes
        case "\"":
            insideDoubleQuote.toggle()
            output.append(insideDoubleQuote ? "“" : "”")
        // Handle paragraph terminators (new lines)
        case "\n":
            output.append(ch)
            // Reset flags at the end of a paragraph
            insideSingleQuote = false
            insideDoubleQuote = false
        default:
            output.append(ch)
        }

        previousChar = ch  // Track the previous character
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


