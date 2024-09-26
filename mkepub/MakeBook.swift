import Foundation
import Ink

// The makeBook function that uses the logic from the Rust code
func makeBook(folderURL: URL, epubInfo: inout EpubInfo, destFolder: URL?) {
    // Generate UUID for the book
    epubInfo.id = UUID().uuidString

    // Determine the EPUB name
    let epubName = epubInfo.name
    
    // Determine the destination folder
    let destinationFolder: URL
    if let destFolder = destFolder {
        destinationFolder = destFolder
    } else {
        destinationFolder = folderURL // Default to the provided folderURL if destFolder is not passed
    }

    // Create the destination path
    let destPath = destinationFolder.appendingPathComponent(epubName)
    
    // Process markdown files
    let rawPages = processDocuments(from: epubInfo)
    
    // Rearrange the pages based on the start page
    let pages = rearrangeStartPage(epubInfo: epubInfo, pages: rawPages)
    
    // Create the EPUB
    createEpub(destPath: destPath, epubInfo: epubInfo, pages: pages)
    
    // Create XHTML files
    createXhtmlFiles(epubInfo: epubInfo, pages: pages, destPath: destPath)
    
    // Copy necessary files
//    copyFiles(sourceURL: folderURL, destURL: destPath)
    copyResources(epubInfo: epubInfo, destURL: destPath)
    
    // Create Table of Contents (TOC)
    createTocXhtml(epubInfo: epubInfo, pages: pages, destPath: destPath)
    
    // Create mimetype file
    createMimetypeFile(destPath: destPath)
    
    // Compress the EPUB
    compressEPUB(folderURL: destPath)
}

func createMimetypeFile(destPath: URL) {
//    let fileManager = FileManager.default
    let filePath = destPath.appendingPathComponent("mimetype")

    do {
        try "application/epub+zip".write(to: filePath, atomically: true, encoding: .utf8)
    } catch {
        logger.log("Error writing mimetype file: \(error)")
    }
}

func rearrangeStartPage(epubInfo: EpubInfo, pages: [Page]) -> [Page] {
    var rearrangedPages: [Page] = []

    for page in pages {
        if let startPage = epubInfo.start?.trimmingCharacters(in: .whitespacesAndNewlines), page.name == startPage {
            let startPageTitle = epubInfo.startTitle?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                ? epubInfo.startTitle!
                : "Title page"
            
            rearrangedPages.append(Page(
                name: page.name,
                file: page.file,
                title: startPageTitle,
                body: page.body
            ))
        } else {
            rearrangedPages.append(page)
        }
    }

    return rearrangedPages
}

func copyResources(epubInfo: EpubInfo, destURL: URL) {
    let fileManager = FileManager.default
    
    // Create necessary directories at the destination
    let opsSubdirs = ["css", "images", "fonts", "js"]
    for subdir in opsSubdirs {
        let dir = destURL.appendingPathComponent("OPS").appendingPathComponent(subdir)
        do {
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            logger.log("Error creating directory \(dir.path): \(error)")
        }
    }
    
    // Helper function to copy files to a directory
    func copyFileToDir(from sourcePath: String?, to destDir: URL) {
        guard let sourcePath = sourcePath else { return }
        let sourceURL = URL(fileURLWithPath: sourcePath)
        let destPath = destDir.appendingPathComponent(sourceURL.lastPathComponent)
        
        if fileManager.fileExists(atPath: sourceURL.path) {
            do {
                try fileManager.copyItem(at: sourceURL, to: destPath)
                logger.log("Copied file \(sourceURL.lastPathComponent) to \(destPath.path)")
            } catch {
                logger.log("Error copying file \(sourceURL.path) to \(destPath.path): \(error)")
            }
        } else {
            logger.log("File \(sourceURL.path) does not exist.")
        }
    }

    // Copy the style file (if exists, using its absolute path)
    if let styleFile = epubInfo.style {
        copyFileToDir(from: styleFile, to: destURL.appendingPathComponent("OPS/css"))
    }

    // Copy fonts (using their absolute paths)
    if let fonts = epubInfo.fonts {
        for font in fonts {
            copyFileToDir(from: font, to: destURL.appendingPathComponent("OPS/fonts"))
        }
    }

    // Copy images (using their absolute paths)
    if let images = epubInfo.images {
        for image in images {
            let imageURL = URL(fileURLWithPath: image) // Convert the string to URL
            let sanitizedFileName = sanitizeImageName(imageURL.lastPathComponent) // Sanitize just the file name
            
            // Construct the destination file URL by appending the sanitized file name to the target directory
            let destinationURL = destURL
                .appendingPathComponent("OPS/images") // Target directory
                .appendingPathComponent(sanitizedFileName) // Sanitized file name (no need to append further)
            
            // Copy the original file to the sanitized destination
            do {
                if FileManager.default.fileExists(atPath: imageURL.path) {
                    try FileManager.default.copyItem(at: imageURL, to: destinationURL)
                    logger.log("Copied file \(imageURL.lastPathComponent) to \(destinationURL.path)")
                } else {
                    logger.log("File \(imageURL.path) does not exist.")
                }
            } catch {
                logger.log("Error copying file \(imageURL.path) to \(destinationURL.path): \(error)")
            }
        }
    }
}

func renderMarkdownToPage(source: URL) -> Page {
    // Helper function to check if a file is an image
    func isImageFile(_ url: URL) -> Bool {
        let imageExtensions = ["jpg", "jpeg", "png"]
        return imageExtensions.contains(url.pathExtension.lowercased())
    }

    // Get the full file name including extension
    let fileNameWithExtension = source.lastPathComponent

    // Check if the source URL is an image
    if isImageFile(source) {
        // Return the <img> tag with the full file name including the extension
        let imageTag = "<img src=\"../images/\(sanitizeImageName(fileNameWithExtension))\" class=\"cover\"/>"
        
        // Create a new Page instance with the image tag as the body
        return Page(name: sanitizeImageName(fileNameWithExtension), file: sanitizeImageName(fileNameWithExtension), title: "", body: imageTag)
    }

    // If it's not an image, proceed to read the file and process the markdown

    // Read the Markdown file content
    let rawContent: String
    do {
        rawContent = try String(contentsOf: source, encoding: .utf8)
    } catch {
        fatalError("Failed to read the Markdown file: \(error)")
    }

    // Preprocess the Markdown content (Assuming a similar preprocessing function exists)
    let markdownContent = preprocessMarkdown(text: rawContent)

    // Parse the Markdown content using the Ink parser
    let parser = MarkdownParser()
    let htmlContent = parser.html(from: markdownContent)

    // Extract the title from the Markdown content
    let title = titleCase(extractTitle(from: markdownContent))

    // Sanitize the file name (without extension, if necessary)
    let file = sanitizeName(source.deletingPathExtension().lastPathComponent)

    // Create a new Page instance with the extracted title, XHTML content, and file name
    return Page(name: file, file: file, title: title, body: htmlContent)
}

func processDocuments(from epubInfo: EpubInfo) -> [Page] {
    let fileManager = FileManager.default
    var markdownFiles: [URL] = []

    // Filter the Markdown files from the EpubInfo documents
    markdownFiles = epubInfo.documents.compactMap { documentPath -> URL? in
        let fileURL = URL(fileURLWithPath: documentPath)
        _ = fileURL.pathExtension.lowercased()

        // Check if the file is a Markdown file (with .md extension) and doesn't start with '_'
        if fileManager.fileExists(atPath: fileURL.path) {
            return fileURL
        }
        return nil
    }

    // Process each Markdown file and generate a list of `Page` instances
    var results: [Page] = []
    for fileURL in markdownFiles {
        let page = renderMarkdownToPage(source: fileURL)
        results.append(page)
    }

    return results
}
