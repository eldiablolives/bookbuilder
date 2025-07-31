import Foundation

// Helper function to read the next paragraph from the input file
func nextParagraph(from fileHandle: FileHandle) -> String? {
    var paragraphData = Data()
    
    while let charData = try? fileHandle.read(upToCount: 1), !charData.isEmpty {
        paragraphData.append(charData) // Safely unwrap charData
        
        // Check for paragraph breaks (newlines or double newlines)
        if let str = String(data: paragraphData, encoding: .utf8), str.hasSuffix("\n\n") {
            let cleanedStr = str.trimmingCharacters(in: .whitespacesAndNewlines)
            return cleanedStr.replacingOccurrences(of: "&", with: "\\&")
        }
    }
    
    // Return any remaining text if EOF reached
    if !paragraphData.isEmpty {
        if let remainingStr = String(data: paragraphData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
            return remainingStr.replacingOccurrences(of: "&", with: "\\&")
        }
    }
    
    return nil
}

// Preprocess function to handle specific commands or reconstruct the original if not recognized
func preprocess(_ command: String, _ params: String? = nil) -> String {
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
                \\chapter*{
                  \\vspace*{-20pt} % Adjusts the vertical spacing before the smaller heading
                  \\begin{flushleft}
                    \\small\\textsc{\(chapterHeading)} % "Chapter X" in small caps
                  \\end{flushleft}
                  \\vspace{10pt} % Adjusts the space between the small text and the chapter title
                  \(chapterTitle) % Actual chapter title in regular chapter font size
                }
                \\addcontentsline{toc}{chapter}{\(chapterTitle)}
                """
            } else {
                // If no title is provided, just use the chapter heading and add it to the TOC
                result = """
                \\chapter*{\(chapterHeading)}
                \\addcontentsline{toc}{chapter}{\(chapterHeading)}
                """
            }
        } else {
            result = "{{chapter}}" // In case no params are provided
        }
    }
    
    // Handle the "break" command
    else if command == "break" {
        result = "\\par\\vspace{1em}"
    }
    
    // Handle the "pagebreak" command (ensure it happens on the right-hand page)
    else if command == "pagebreak" {
        result = "\\cleardoublepage"
    }
    
    // Handle the "copyright" command
    else if command == "copyright" {
        if let params = params {
            result = """
            \\begin{center}
            {\\small \(params)}
            \\end{center}
            """
        } else {
            result = """
            \\begin{center}
            {\\small Copyright}
            \\end{center}
            """
        }
    }
    
    // Handle the "email" command
    else if command == "email" {
        if let params = params {
            result = """
            \\begin{center}
            {\\small \(params)}
            \\end{center}
            """
        } else {
            result = """
            \\begin{center}
            {\\small Email Address}
            \\end{center}
            """
        }
    }
    
    // Handle the "quote" command
    else if command == "quote" {
        if let params = params {
            result = """
            \\begin{center}
            {\\small\\textit{\(params)}}
            \\end{center}
            """
        } else {
            result = """
            \\begin{center}
            {\\small\\textit{Quote}}
            \\end{center}
            """
        }
    }
    
    // Handle the "hero" command
    else if command == "hero" {
        if let params = params {
            result = """
            \\cleardoublepage
            \\vspace*{\\fill}
            \\begin{center}
            {\\Huge \\textbf{\(params)}}
            \\end{center}
            \\vspace*{\\fill}
            \\clearpage
            """
        } else {
            result = """
            \\cleardoublepage
            \\vspace*{\\fill}
            \\begin{center}
            {\\Huge \\textbf{Hero Text}}
            \\end{center}
            \\vspace*{\\fill}
            \\clearpage
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
    
    // Handle the "title" command
    else if command == "title" {
        result = "\\maketitle"
    }
    
    // If the command is not recognized, reconstruct the original {{command params}}
    else {
        if let params = params {
            result = "{{\(command) \(params)}}"
        } else {
            result = "{{\(command)}}"
        }
    }

    // Apply em dash processing to the result
    if result.hasPrefix("—") {
        result = result.replacingOccurrences(of: "^—", with: "\\leavevmode\\textemdash\\allowbreak{}", options: .regularExpression)
    } else {
        result = result.replacingOccurrences(of: "—", with: "\\textemdash\\allowbreak{}")
    }

    return result
}

// Process function: checks for chapter, headers, preprocessor commands, and markdown-style formatting
func process(_ paragraph: String) -> String {
    var result = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Handle 4 or more dashes at the start of the line with no other characters
    if result.range(of: #"^-{4,}$"#, options: .regularExpression) != nil {
        result = """
        \\bigskip
        \\centerline{* * *}
        \\bigskip
        """
        return result
    }
    
    // Check if the paragraph starts with "# " (Chapter title)
    if result.hasPrefix("# ") {
        let chapterTitle = result.dropFirst(2).trimmingCharacters(in: .whitespacesAndNewlines)
        result = "\\chapter*{\(chapterTitle)}"
    }
    
    // Check if the paragraph starts with "## " (Header level 2)
    if result.hasPrefix("## ") {
        let sectionTitle = result.dropFirst(3).trimmingCharacters(in: .whitespacesAndNewlines)
        result = "\\section*{\(sectionTitle)}"
    }
    
    // Check if the paragraph starts with "### " (Header level 3)
    if result.hasPrefix("### ") {
        let subsectionTitle = result.dropFirst(4).trimmingCharacters(in: .whitespacesAndNewlines)
        result = "\\subsection*{\(subsectionTitle)}"
    }
    
    // Check if the paragraph starts with "#### " (Header level 4)
    if result.hasPrefix("#### ") {
        let subsubsectionTitle = result.dropFirst(5).trimmingCharacters(in: .whitespacesAndNewlines)
        result = "\\subsubsection*{\(subsubsectionTitle)}"
    }

    // Handle preprocessing for any {{command}}
    let pattern = #"\{\{(.*?)\}\}"# // Regex pattern to match {{command params}}
    
    if let regex = try? NSRegularExpression(pattern: pattern) {
        let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))
        
        for match in matches.reversed() {
            if let range = Range(match.range, in: result) {
                let commandString = String(result[range])
                let innerContent = commandString.dropFirst(2).dropLast(2).trimmingCharacters(in: .whitespaces)
                let components = innerContent.split(separator: " ", maxSplits: 1).map { String($0) }
                let command = components.first ?? ""
                let params = components.count > 1 ? components.last : nil
                
                let processed = preprocess(command, params)
                result.replaceSubrange(range, with: processed)
            }
        }
    }
    
    // Handle markdown-style bold (**), italic (*), bold italic (***), and underline (_)
    
    // 1. Handle bold italic (***text*** -> \textbf{\textit{text}})
    let boldItalicPattern = #"\*\*\*(.*?)\*\*\*"# // Triple asterisks
    result = result.replacingOccurrences(of: boldItalicPattern, with: "\\\\textbf{\\\\textit{$1}}", options: .regularExpression)
    
    // 2. Handle bold (**text** -> \textbf{text})
    let boldPattern = #"\*\*(.*?)\*\*"# // Double asterisks
    result = result.replacingOccurrences(of: boldPattern, with: "\\\\textbf{$1}", options: .regularExpression)
    
    // 3. Handle italic (*text* -> \textit{text})
    let italicPattern = #"\*(.*?)\*"# // Single asterisk
    result = result.replacingOccurrences(of: italicPattern, with: "\\\\textit{$1}", options: .regularExpression)
    
    // 4. Handle underline (_text_ -> \textit{text}), only when no adjacent text
    let underlinePattern = #"\b_(.*?)_\b"# // Word boundaries for standalone underscore text
    result = result.replacingOccurrences(of: underlinePattern, with: "\\\\textit{$1}", options: .regularExpression)
    
    // Second pass to replace all instances of — with \textemdash{}, with a special case for when — is the first character
    if result.hasPrefix("—") {
        result = result.replacingOccurrences(of: "^—", with: "\\\\leavevmode\\\\textemdash\\\\allowbreak{}", options: .regularExpression)
    } else {
        result = result.replacingOccurrences(of: "—", with: "\\textemdash\\allowbreak{}")
    }
    
    return result
}

// Function to create a .tex file from an input file
func createTeXFile(inputFileURL: URL, outputFolderURL: URL) -> String? {
    let originalFileName = inputFileURL.deletingPathExtension().lastPathComponent
    let newFileName = "\(originalFileName).tex"
    let outputFileURL = outputFolderURL.appendingPathComponent(newFileName)
    
    // Open the input file for reading
    guard let fileHandle = try? FileHandle(forReadingFrom: inputFileURL) else {
        print("Failed to open the input file.")
        return nil
    }
    
    // Placeholder content to start the TeX document for each file
    var texContent = """
    """

    // Read and process paragraphs from the input file
    while let paragraph = nextParagraph(from: fileHandle) {
        let processedParagraph = process(paragraph)
        texContent += "\n\n" + processedParagraph
    }

//    // End the document
//    texContent += "\n\n\\end{document}"

    // Write the content to the new .tex file
    do {
        try texContent.write(to: outputFileURL, atomically: true, encoding: .utf8)
        print("TeX file successfully created at \(outputFileURL.path)")
    } catch {
        print("Failed to create TeX file: \(error)")
        return nil
    }
    
    // Close the file handle
    fileHandle.closeFile()
    
    // Return the file name for the \input command
    return newFileName
}

// Function to create a main TeX book from multiple input files
func makeTeXBook(folderURL: URL, epubInfo: inout EpubInfo, destFolder: URL) {
    logger.log("Making TeX book")
    
    // Construct the file name using epubInfo.title and .tex extension
    let fileName = "\(epubInfo.title).tex"
    
    // Create the full URL for the main TeX file
    let fileURL = destFolder.appendingPathComponent(fileName)
    
    // Define the content of the main TeX file with dynamic variables from epubInfo
    var texContent = """
    \\documentclass[12pt, twoside]{book}
    \\usepackage{graphicx}
    \\usepackage{microtype}
    \\usepackage[
      paperwidth=6in, paperheight=9in,
      inner=1in, outer=0.5in,
      top=0.75in, bottom=0.6in,
      includehead, includefoot,
      heightrounded,
      bindingoffset=0.125in
    ]{geometry}
    \\usepackage{fontspec}
    \\setmainfont[Scale=1.09]{EB Garamond}
    \\linespread{1.13}

    % Enable better hyphenation and tolerance to help prevent overflow
    \\hyphenpenalty=1000
    \\tolerance=500

    \\title{\\Huge\\textbf{\(epubInfo.title)}}
    \\author{\\LARGE \(epubInfo.author)}
    \\date{} % Ensure no date is printed

    \\begin{document}
    """

    // Iterate over the list of document URLs from epubInfo.documents and create a TeX file for each
    for documentPath in epubInfo.documents {
        let documentURL = URL(fileURLWithPath: documentPath)
        
        if let newFileName = createTeXFile(inputFileURL: documentURL, outputFolderURL: destFolder) {
            // Add the \input{} command for each created TeX file
            texContent += "\n\\input{\(newFileName)}"
        } else {
            logger.log("Failed to process document at \(documentURL.path)")
        }
    }

    // End the main document
    texContent += "\n\n\\end{document}"
    
    // Attempt to write the content to the main TeX file
    do {
        try texContent.write(to: fileURL, atomically: true, encoding: .utf8)
        logger.log("TeX book successfully created at \(fileURL.path)")
    } catch {
        logger.log("Failed to create TeX book: \(error)")
    }
}
