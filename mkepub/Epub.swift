//
//  Epub.swift
//  mkepub
//
//  Created by Rumpel Stiltskin on 16.09.2024.
//

import Foundation

// MARK: - Filename Sanitizer
private func sanitizeFilename(_ name: String) -> String {
    return name
        .replacingOccurrences(of: " ", with: "-")
        .replacingOccurrences(of: "[^\\w\\-]", with: "-", options: .regularExpression)
        .replacingOccurrences(of: "-+", with: "-", options: .regularExpression)
        .trimmingCharacters(in: .init(charactersIn: "-"))
        .lowercased()
}

// MARK: - Create EPUB
func createEpub(destPath: URL, epubInfo: EpubInfo, pages: [Page]) {
    let fileManager = FileManager.default
    
    // Delete existing
    if fileManager.fileExists(atPath: destPath.path) {
        do {
            try fileManager.removeItem(at: destPath)
            logger.log("Deleted existing destination folder: \(destPath.path)")
        } catch {
            logger.log("Failed to delete existing destination folder: \(destPath.path) \(error)")
            return
        }
    }
    
    // Create destination
    do {
        try fileManager.createDirectory(at: destPath, withIntermediateDirectories: true, attributes: nil)
    } catch {
        logger.log("Failed to create destination folder: \(destPath) \(error)")
        return
    }
    
    // Create subdirectories
    let epubFolders = ["META-INF", "OPS", "OPS/content"]
    
    for folder in epubFolders {
        let folderPath = destPath.appendingPathComponent(folder)
        
        do {
            try fileManager.createDirectory(at: folderPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            logger.log("Failed to create folder \(folder): \(error)")
            return
        }
        
        switch folder {
        case "META-INF":
            createFile(at: folderPath.appendingPathComponent("container.xml"), withContent: createContainerXmlContent())
            logger.log("Container.xml created")
            
            if epubInfo.fonts?.isEmpty == false {
                createFile(at: folderPath.appendingPathComponent("com.apple.ibooks.display-options.xml"), withContent: createAppleXmlMeta())
                logger.log("com.apple.ibooks.display-options.xml created")
            }
        case "OPS":
            createFile(at: folderPath.appendingPathComponent("epb.opf"), withContent: createContentOpfContent(epubInfo: epubInfo, pages: pages))
            logger.log("epb.opf created")
            
            createFile(at: folderPath.appendingPathComponent("epb.ncx"), withContent: createTocNcxContent(epubInfo: epubInfo, pages: pages))
            logger.log("epb.ncx created")
        default:
            break
        }
    }
    
    logger.log("Uncompressed skeleton EPUB structure created at: \(destPath.path)")
}

// MARK: - TOC XHTML (EPUB3 Nav)
func createTocXhtml(epubInfo: EpubInfo, pages: [Page], destPath: URL) {
    let tocPath = destPath.appendingPathComponent("OPS").appendingPathComponent("toc.xhtml")
    
    var tocContent = """
    <?xml version="1.0" encoding="UTF-8"?>
    <html xml:lang="en" xmlns:epub="http://www.idpf.org/2007/ops" xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <meta charset="UTF-8" />
        <title>Table of Contents</title>
        <link rel="stylesheet" href="css/\(URL(fileURLWithPath: epubInfo.style ?? "book.css").lastPathComponent)" type="text/css" />
        <meta name="EPB-UUID" content="" />
    </head>
    <body>
    
    """
    
    // MARK: 1. TOC FIRST — Apple Books requires this
    tocContent.append("""
        <!-- TABLE OF CONTENTS -->
        <nav id="toc" role="doc-toc" epub:type="toc">
        <ol class="s2">
    """)
    
    for page in pages {
        let trimmedTitle = page.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty {
            let pageLink = "content/\(page.file).xhtml"
            tocContent.append("        <li><a href=\"\(pageLink)\">\(page.title)</a></li>\n")
        }
    }
    
    tocContent.append("""
        </ol>
        </nav>
        
    """)
    
    // MARK: 2. LANDMARKS SECOND — with valid <h2>
    if let start = epubInfo.start {
        let startPage = pages.first { "content/\($0.file).xhtml" == start }
        let title = startPage?.title.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Start Reading"
        
        tocContent.append("""
            <!-- LANDMARKS -->
            <nav epub:type="landmarks" id="landmarks">
                <h2>Guide</h2>
                <ol>
                    <li><a epub:type="bodymatter" href="\(start)">\(title)</a></li>
                </ol>
            </nav>
            
        """)
    }
    
    tocContent.append("""
    </body>
    </html>
    """)
    
    // Replace UUID
    let epubUuid = epubInfo.id ?? ""
    tocContent = tocContent.replacingOccurrences(of: "meta name=\"EPB-UUID\" content=\"\"", with: "meta name=\"EPB-UUID\" content=\"\(epubUuid)\"")
    
    do {
        try FileManager.default.createDirectory(at: tocPath.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        try tocContent.write(to: tocPath, atomically: true, encoding: .utf8)
    } catch {
        logger.log("Error writing toc.xhtml file: \(error)")
    }
}
// MARK: - OPF Content
func createContentOpfContent(epubInfo: EpubInfo, pages: [Page]) -> String {
    let bookId = epubInfo.id ?? ""
    let dateFormatter = ISO8601DateFormatter()
    dateFormatter.formatOptions = [.withInternetDateTime]
    let modified = dateFormatter.string(from: Date())
    
    let manifestItems = pages.enumerated().map { (index, page) in
        "<item id=\"item-\(index + 1)\" href=\"content/\(page.file).xhtml\" media-type=\"application/xhtml+xml\" />"
    }.joined(separator: "\n")
    
    let spineItems = pages.enumerated().map { (index, _) in
        "<itemref idref=\"item-\(index + 1)\" />"
    }.joined(separator: "\n")
    
    let fontItems = epubInfo.fonts?.enumerated().map { (index, font) in
        let fontFileName = URL(fileURLWithPath: font).lastPathComponent
        return "<item href=\"fonts/\(fontFileName)\" id=\"font\(index + 1)\" media-type=\"application/x-font-otf\" />"
    }.joined(separator: "\n") ?? ""
    
    let imageItems = epubInfo.images?.map { image in
        let imageFileName = sanitizeImageName(URL(fileURLWithPath: image).lastPathComponent)
        let imageId = imageFileName.split(separator: ".").first.map(String.init) ?? ""
        return "<item id=\"img-\(imageId)\" href=\"images/\(imageFileName)\" media-type=\"image/jpeg\" />"
    }.joined(separator: "\n") ?? ""
    
    // FINAL FIX: Use type="start" in <guide>
    var guideSection = ""
    if let start = epubInfo.start {
        guideSection = """
          <guide>
            <reference type="start" title="Start Reading" href="\(start)" />
          </guide>
        """
    }
    
    return """
    <?xml version="1.0" encoding="UTF-8"?>
    <package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="BookID">
      <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
        <dc:identifier id="BookID">\(bookId)</dc:identifier>
        <dc:title>\(epubInfo.title)</dc:title>
        <dc:creator>\(epubInfo.author)</dc:creator>
        <dc:language>en</dc:language>
        <meta property="dcterms:modified">\(modified)</meta>
        <meta name="cover" content="img-\(sanitizeImageName(URL(fileURLWithPath: epubInfo.cover ?? "cover.jpg").deletingPathExtension().lastPathComponent))" />
      </metadata>
      <manifest>
        <item id="toc" href="toc.xhtml" media-type="application/xhtml+xml" properties="nav"/>
        \(manifestItems)
        <item id="ncx" href="epb.ncx" media-type="application/x-dtbncx+xml"/>
        <item id="stylesheet" href="css/\(URL(fileURLWithPath: epubInfo.style ?? "book.css").lastPathComponent)" media-type="text/css"/>
        \(fontItems)
        \(imageItems)
      </manifest>
      <spine toc="ncx">
        \(spineItems)
      </spine>
      \(guideSection)
    </package>
    """
}

// MARK: - XHTML Files
func createXhtmlFiles(epubInfo: EpubInfo, pages: [Page], destPath: URL) {
    let fileManager = FileManager.default
    
    for page in pages {
        let fileName = "\(page.file).xhtml"
        let filePath = destPath
            .appendingPathComponent("OPS")
            .appendingPathComponent("content")
            .appendingPathComponent(fileName)
        
        let title = !page.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? page.title : epubInfo.title
        
        let xhtmlContent = """
        <!DOCTYPE html>
        <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
            <title>\(title)</title>
            <meta name="EPB-UUID" content="\(epubInfo.id ?? "")" />
            <meta charset="UTF-8" />
            <link rel="stylesheet" href="../css/\(URL(fileURLWithPath: epubInfo.style ?? "book.css").lastPathComponent)" type="text/css" />
        </head>
        <body>
            \(page.body)
        </body>
        </html>
        """
        
        do {
            try fileManager.createDirectory(at: filePath.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            try xhtmlContent.write(to: filePath, atomically: true, encoding: .utf8)
        } catch {
            logger.log("Error writing XHTML file: \(error)")
        }
    }
}

// MARK: - Container & Apple Meta
func createContainerXmlContent() -> String {
    return """
    <?xml version="1.0" encoding="UTF-8"?>
    <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
      <rootfiles>
        <rootfile full-path="OPS/epb.opf" media-type="application/oebps-package+xml" />
      </rootfiles>
    </container>
    """
}

func createAppleXmlMeta() -> String {
    return """
    <?xml version="1.0" encoding="UTF-8"?>
    <display_options>
        <platform name="*">
            <option name="specified-fonts">true</option>
        </platform>
    </display_options>
    """
}

// MARK: - NCX with bodymatter
func createTocNcxContent(epubInfo: EpubInfo, pages: [Page]) -> String {
    var playOrderCounter = 1
    var navMap = ""
    
    for page in pages {
        let trimmedTitle = page.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty {
            let src = "content/\(page.file).xhtml"
            let isStart = epubInfo.start == src
            
            let navPoint = """
            <navPoint id="navpoint-\(playOrderCounter)" playOrder="\(playOrderCounter)"\(isStart ? " class=\"bodymatter\"" : "")>
                <navLabel>
                    <text>\(page.title)</text>
                </navLabel>
                <content src="\(src)"/>
            </navPoint>
            """
            navMap += navPoint
            playOrderCounter += 1
        }
    }
    
    return """
    <?xml version="1.0" encoding="UTF-8"?>
    <ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
      <head>
        <meta name="dtb:uid" content="\(epubInfo.id ?? "")" />
        <meta name="dtb:depth" content="1" />
        <meta name="dtb:totalPageCount" content="0" />
        <meta name="dtb:maxPageNumber" content="0" />
      </head>
      <docTitle><text>\(epubInfo.title)</text></docTitle>
      <docAuthor><text>\(epubInfo.author)</text></docAuthor>
      <navMap>
        \(navMap)
      </navMap>
    </ncx>
    """
}
