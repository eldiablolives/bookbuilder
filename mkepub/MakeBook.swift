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


func checkFontFiles(in folderURL: URL) throws -> [String]? {
    let fileManager = FileManager.default
    var fontFiles = [String]()
    
    // Get the list of files in the directory
    let entries = try fileManager.contentsOfDirectory(atPath: folderURL.path)
    
    // Iterate over each entry
    for entry in entries {
        let fullPathURL = folderURL.appendingPathComponent(entry)
        var isDir: ObjCBool = false
        
        // Check if the entry is a file (not a directory)
        if fileManager.fileExists(atPath: fullPathURL.path, isDirectory: &isDir), !isDir.boolValue {
            let fileExtension = fullPathURL.pathExtension.lowercased()
            
            // Check if the file extension is "ttf" or "otf"
            if fileExtension == "ttf" || fileExtension == "otf" {
                fontFiles.append(entry)
            }
        }
    }
    
    // If no font files are found, return nil, otherwise return the list
    return fontFiles.isEmpty ? nil : fontFiles
}

func checkImageFiles(in folderURL: URL) throws -> [String]? {
    let fileManager = FileManager.default
    var imageFiles = [String]()
    
    // Get the list of files in the directory
    let entries = try fileManager.contentsOfDirectory(atPath: folderURL.path)
    
    // Iterate over each entry
    for entry in entries {
        let fileURL = folderURL.appendingPathComponent(entry)
        var isDir: ObjCBool = false
        
        // Check if the entry is a file (not a directory)
        if fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDir), !isDir.boolValue {
            let fileExtension = fileURL.pathExtension.lowercased()
            
            // Check if the file extension is "jpg" or "png"
            if fileExtension == "jpg" || fileExtension == "png" {
                imageFiles.append(entry)
            }
        }
    }
    
    // If no image files are found, return nil, otherwise return the list
    return imageFiles.isEmpty ? nil : imageFiles
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

func copyFiles(sourceURL: URL, destURL: URL) {
    let fileManager = FileManager.default
    
    // Create necessary directories
    let opsSubdirs = ["css", "images", "fonts", "js"]
    for subdir in opsSubdirs {
        let dir = destURL.appendingPathComponent("OPS").appendingPathComponent(subdir)
        do {
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            logger.log("Error creating directory \(dir.path): \(error)")
        }
    }

    // Helper function to copy files with a certain extension to a directory
    func copyFilesToDir(dir: URL, ext: String, entries: [URL]) {
        for entry in entries {
            if entry.pathExtension == ext {
                let dest = dir.appendingPathComponent(entry.lastPathComponent)
                do {
                    try fileManager.copyItem(at: entry, to: dest)
                } catch {
                    logger.log("Error copying file \(entry.path) to \(dest.path): \(error)")
                }
            }
        }
    }

    // Get all entries in the source directory
    do {
        let entries = try fileManager.contentsOfDirectory(at: sourceURL, includingPropertiesForKeys: nil)
        
        // Copy files to the appropriate directories
        copyFilesToDir(dir: destURL.appendingPathComponent("OPS/css"), ext: "css", entries: entries)
        copyFilesToDir(dir: destURL.appendingPathComponent("OPS/images"), ext: "png", entries: entries)
        copyFilesToDir(dir: destURL.appendingPathComponent("OPS/images"), ext: "jpg", entries: entries)
        copyFilesToDir(dir: destURL.appendingPathComponent("OPS/fonts"), ext: "ttf", entries: entries)
        copyFilesToDir(dir: destURL.appendingPathComponent("OPS/fonts"), ext: "otf", entries: entries)
        copyFilesToDir(dir: destURL.appendingPathComponent("OPS/js"), ext: "js", entries: entries)
    } catch {
        logger.log("Error reading contents of directory \(sourceURL.path): \(error)")
    }
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

//    // Copy the cover image (if exists, using its absolute path)
//    if let coverImage = epubInfo.cover {
//        copyFileToDir(from: coverImage, to: destURL.appendingPathComponent("OPS/images"))
//    }

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
            copyFileToDir(from: image, to: destURL.appendingPathComponent("OPS/images"))
        }
    }

//    // Copy documents (using their absolute paths)
//    for document in epubInfo.documents {
//        copyFileToDir(from: document, to: destURL.appendingPathComponent("OPS/documents"))
//    }
}

func renderMarkdownToPage(source: URL) -> Page {
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
    let title = extractTitle(from: markdownContent)

    // Get the file name without full path and extension
    let name = getFileName(from: source)

    // Sanitize the file name
    let file = sanitizeName(name)

    // Create a new Page instance with the extracted title, XHTML content, and file name
    return Page(name: name, file: file, title: title, body: htmlContent)
}

func processDocuments(from epubInfo: EpubInfo) -> [Page] {
    let fileManager = FileManager.default
    var markdownFiles: [URL] = []

    // Filter the Markdown files from the EpubInfo documents
    markdownFiles = epubInfo.documents.compactMap { documentPath -> URL? in
        let fileURL = URL(fileURLWithPath: documentPath)
        let fileExtension = fileURL.pathExtension.lowercased()

        // Check if the file is a Markdown file (with .md extension) and doesn't start with '_'
        if fileExtension == "md" && fileManager.fileExists(atPath: fileURL.path) {
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
