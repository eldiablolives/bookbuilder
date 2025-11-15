import Foundation
import Ink

// MARK: - makeBook --------------------------------------------------------------
// MARK: - makeBook --------------------------------------------------------------
func makeBook(folderURL: URL, epubInfo: inout EpubInfo, destFolder: URL?) {
    // Generate UUID for the book
    epubInfo.id = UUID().uuidString

    // Determine the EPUB name
    let epubName = epubInfo.name
    
    // Destination folder
    let destinationFolder = destFolder ?? folderURL
    let destPath = destinationFolder.appendingPathComponent(epubName)

    // -----------------------------------------------------------------------
    // 1. Process markdown files → raw pages
    // -----------------------------------------------------------------------
    let rawPages = processDocuments(from: epubInfo)
    
    // -----------------------------------------------------------------------
    // 2. Rearrange pages so the “start” page is first (if any)
    // -----------------------------------------------------------------------
    let pages = rearrangeStartPage(epubInfo: epubInfo, pages: rawPages)

    // -----------------------------------------------------------------------
    // 3. SET RELATIVE paths for OPF (css/book.css, fonts/xxx.otf, images/cover.jpg)
    // -----------------------------------------------------------------------
    if let styleURL = globalFileHelper.selectedStyleFile {
        epubInfo.style = "css/\(styleURL.lastPathComponent)"
    }
    epubInfo.fonts = globalFileHelper.addedFonts.map { "fonts/\($0.lastPathComponent)" }
    if let coverURL = globalFileHelper.coverImagePath {
        let coverName = coverURL.lastPathComponent
        let sanitizedCoverName = sanitizeImageName(coverName)
        epubInfo.cover = "images/\(sanitizedCoverName)"
    }

    // -----------------------------------------------------------------------
    // 4. CREATE the EPUB skeleton
    // -----------------------------------------------------------------------
    createEpub(destPath: destPath, epubInfo: epubInfo, pages: pages)

    // -----------------------------------------------------------------------
    // 5. Generate XHTML files for the pages
    // -----------------------------------------------------------------------
    createXhtmlFiles(epubInfo: epubInfo, pages: pages, destPath: destPath)

    // -----------------------------------------------------------------------
    // 6. COPY CSS, FONTS, COVER using the ORIGINAL absolute URLs from globalFileHelper
    // -----------------------------------------------------------------------
    copyExternalAssets(epubInfo: epubInfo, to: destPath)

    // -----------------------------------------------------------------------
    // 7. Table of Contents (XHTML)
    // -----------------------------------------------------------------------
    createTocXhtml(epubInfo: epubInfo, pages: pages, destPath: destPath)

    // -----------------------------------------------------------------------
    // 8. mimetype file
    // -----------------------------------------------------------------------
    createMimetypeFile(destPath: destPath)

    // -----------------------------------------------------------------------
    // 9. Compress into final .epub
    // -----------------------------------------------------------------------
    compressEPUB(folderURL: destPath)
}

// MARK: - Dedicated copy function that uses the REAL absolute paths
private func copyExternalAssets(epubInfo: EpubInfo, to destURL: URL) {
    let fm = FileManager.default
    let opsPath = destURL.appendingPathComponent("OPS")

    // Create dirs
    for sub in ["css", "fonts", "images"] {
        try? fm.createDirectory(at: opsPath.appendingPathComponent(sub), withIntermediateDirectories: true)
    }

    // CSS
    if let src = globalFileHelper.selectedStyleFile {
        let dest = opsPath.appendingPathComponent("css").appendingPathComponent(src.lastPathComponent)
        do {
            if fm.fileExists(atPath: dest.path) { try fm.removeItem(at: dest) }
            try fm.copyItem(at: src, to: dest)
            logger.log("✓ Copied CSS: \(src.lastPathComponent)")
        } catch {
            logger.log("⚠️ Failed to copy CSS: \(error)")
        }
    }

    // FONTS
    for src in globalFileHelper.addedFonts {
        let dest = opsPath.appendingPathComponent("fonts").appendingPathComponent(src.lastPathComponent)
        do {
            if fm.fileExists(atPath: dest.path) { try fm.removeItem(at: dest) }
            try fm.copyItem(at: src, to: dest)
            logger.log("✓ Copied font: \(src.lastPathComponent)")
        } catch {
            logger.log("⚠️ Failed to copy font \(src.lastPathComponent): \(error)")
        }
    }

    // COVER
    if let src = globalFileHelper.coverImagePath {
        let sanitizedCoverName = sanitizeImageName(src.lastPathComponent)
        let dest = opsPath.appendingPathComponent("images").appendingPathComponent(sanitizedCoverName)
        do {
            if fm.fileExists(atPath: dest.path) { try fm.removeItem(at: dest) }
            try fm.copyItem(at: src, to: dest)
            logger.log("✓ Copied cover: \(sanitizedCoverName)")
        } catch {
            logger.log("⚠️ Failed to copy cover: \(error)")
        }
    }
}

// MARK: - mimetype --------------------------------------------------------------
func createMimetypeFile(destPath: URL) {
    let filePath = destPath.appendingPathComponent("mimetype")
    do {
        try "application/epub+zip".write(to: filePath, atomically: true, encoding: .utf8)
    } catch {
        logger.log("Error writing mimetype file: \(error)")
    }
}

// MARK: - rearrange start page --------------------------------------------------
func rearrangeStartPage(epubInfo: EpubInfo, pages: [Page]) -> [Page] {
    var rearranged: [Page] = []

    for page in pages {
        if let startPage = epubInfo.start?.trimmingCharacters(in: .whitespacesAndNewlines),
           page.name == startPage {
            let startTitle = epubInfo.startTitle?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                ? epubInfo.startTitle!
                : "Title page"
            rearranged.append(Page(
                name: page.name,
                file: page.file,
                title: startTitle,
                body: page.body
            ))
        } else {
            rearranged.append(page)
        }
    }
    return rearranged
}

// MARK: - copyResources (CSS, FONTS, COVER) ------------------------------------
func copyResources(epubInfo: EpubInfo, destURL: URL) {
    let fm = FileManager.default
    let opsPath = destURL.appendingPathComponent("OPS")

    // Create directories
    let subdirs = ["css", "images", "fonts", "js"]
    for sub in subdirs {
        try? fm.createDirectory(at: opsPath.appendingPathComponent(sub), withIntermediateDirectories: true)
    }

    // COPY CSS (full path from epubInfo)
    if let stylePath = epubInfo.style {
        let srcURL = URL(fileURLWithPath: stylePath)
        let destURL = opsPath.appendingPathComponent("css").appendingPathComponent(srcURL.lastPathComponent)
        try? fm.copyItem(at: srcURL, to: destURL)
        logger.log("Copied CSS: \(srcURL.lastPathComponent)")
    }

    // COPY FONTS (full paths from epubInfo)
    if let fonts = epubInfo.fonts {
        for fontPath in fonts {
            let srcURL = URL(fileURLWithPath: fontPath)
            let destURL = opsPath.appendingPathComponent("fonts").appendingPathComponent(srcURL.lastPathComponent)
            try? fm.copyItem(at: srcURL, to: destURL)
            logger.log("Copied font: \(srcURL.lastPathComponent)")
        }
    }

    // COPY COVER (full path from epubInfo)
    if let coverPath = epubInfo.cover {
        let srcURL = URL(fileURLWithPath: coverPath)
        let destURL = opsPath.appendingPathComponent("images").appendingPathComponent(srcURL.lastPathComponent)
        try? fm.copyItem(at: srcURL, to: destURL)
        logger.log("Copied cover: \(srcURL.lastPathComponent)")
    }

    // COPY CONTENT IMAGES (your existing logic)
    if let images = epubInfo.images {
        for img in images {
            let srcURL = URL(fileURLWithPath: img)
            let sanitized = sanitizeImageName(srcURL.lastPathComponent)
            let destURL = opsPath.appendingPathComponent("images").appendingPathComponent(sanitized)
            try? fm.copyItem(at: srcURL, to: destURL)
            logger.log("Copied image: \(sanitized)")
        }
    }
}

// MARK: - renderMarkdownToPage --------------------------------------------------
func renderMarkdownToPage(source: URL) -> Page {
    func isImageFile(_ url: URL) -> Bool {
        let imageExtensions = ["jpg", "jpeg", "png"]
        return imageExtensions.contains(url.pathExtension.lowercased())
    }

    let fileNameWithExtension = source.lastPathComponent

    if isImageFile(source) {
        let imageTag = "<img src=\"../images/\(sanitizeImageName(fileNameWithExtension))\" class=\"cover\"/>"
        return Page(name: sanitizeImageName(fileNameWithExtension),
                    file: sanitizeImageName(fileNameWithExtension),
                    title: "",
                    body: imageTag)
    }

    let rawContent: String
    do {
        rawContent = try String(contentsOf: source, encoding: .utf8)
    } catch {
        fatalError("Failed to read markdown file: \(error)")
    }

    let markdownContent = preprocessMarkdown(text: rawContent)
    let parser = MarkdownParser()
    let htmlContent = parser.html(from: markdownContent)
    let title = titleCase(extractTitle(from: markdownContent))
    let file = sanitizeName(source.deletingPathExtension().lastPathComponent)

    return Page(name: file, file: file, title: title, body: htmlContent)
}

// MARK: - processDocuments ------------------------------------------------------
func processDocuments(from epubInfo: EpubInfo) -> [Page] {
    let fm = FileManager.default
    var markdownFiles: [URL] = []

    markdownFiles = epubInfo.documents.compactMap { documentPath in
        let url = URL(fileURLWithPath: documentPath)
        return fm.fileExists(atPath: url.path) ? url : nil
    }

    var results: [Page] = []
    for fileURL in markdownFiles {
        results.append(renderMarkdownToPage(source: fileURL))
    }
    return results
}
