//
//  Epub.swift
//  mkepub
//
//  Created by Rumpel Stiltskin on 16.09.2024.
//

import Foundation

func createEpub(destPath: URL, epubInfo: EpubInfo, pages: [Page]) {
    let fileManager = FileManager.default
    
    // **Additional Code: Delete the destination folder if it exists**
    if fileManager.fileExists(atPath: destPath.path) {
        do {
            try fileManager.removeItem(at: destPath)
            logger.log("Deleted existing destination folder: \(destPath.path)")
        } catch {
            logger.log("Failed to delete existing destination folder: \(destPath.path) \(error)")
            return
        }
    }
    
    // Create the destination folder
    do {
        try fileManager.createDirectory(at: destPath, withIntermediateDirectories: true, attributes: nil)
    } catch {
        logger.log("Failed to create destination folder: \(destPath) \(error)")
        return
    }
    
    // Create the necessary subdirectories within the EPUB structure
    let epubFolders = ["META-INF", "OPS", "OPS/content"]
    
    for folder in epubFolders {
        let folderPath = destPath.appendingPathComponent(folder)
        
        do {
            try fileManager.createDirectory(at: folderPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            logger.log("Failed to create folder \(folder): \(error)")
            return
        }

        // Create the core skeleton files in the appropriate folders
        switch folder {
        case "META-INF":
            createFile(at: folderPath.appendingPathComponent("container.xml"), withContent: createContainerXmlContent())
            logger.log("Container.xml created")
            
            if let _ = epubInfo.fonts {
                createFile(at: folderPath.appendingPathComponent("com.apple.ibooks.display-options.xml"), withContent: createAppleXmlMeta())
                logger.log("com.apple.ibooks.display-options.xml created")
            }
        case "OPS":
            createFile(at: folderPath.appendingPathComponent("epb.opf"), withContent: createContentOpfContent(epubInfo: epubInfo, pages: pages))
            logger.log("epm.opf created")
            
            createFile(at: folderPath.appendingPathComponent("epb.ncx"), withContent: createTocNcxContent(epubInfo: epubInfo, pages: pages))
            logger.log("epb.ncx created")
        default:
            break
        }
    }
    
    logger.log("Uncompressed skeleton EPUB structure created at: \(destPath.path)")
}

func createTocXhtml(epubInfo: EpubInfo, pages: [Page], destPath: URL) {
    // Create the destination path for toc.xhtml
    let tocPath = destPath.appendingPathComponent("OPS").appendingPathComponent("toc.xhtml")
    
    // Generate the content of toc.xhtml
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
        <nav id="toc" role="doc-toc" epub:type="toc">
        <ol class="s2">
    """

    // Iterate over the pages and generate <li> tags for pages with non-empty titles
    for page in pages {
        let trimmedTitle = page.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty {
            let pageLink = "content/\(page.file).xhtml"
            let liTag = "        <li><a href=\"\(pageLink)\">\(page.title)</a></li>\n"
            tocContent.append(liTag)
        }
    }

    // Replace the content of the EPB-UUID meta tag
    let epubUuid = epubInfo.id ?? ""
    tocContent = tocContent.replacingOccurrences(of: "meta name=\"EPB-UUID\" content=\"\"", with: "meta name=\"EPB-UUID\" content=\"\(epubUuid)\"")

    // Add the closing tags to tocContent
    tocContent.append("""
        </ol>
        </nav>
    </body>
    </html>
    """)

    // Write the toc.xhtml content to the destination file
    do {
        try FileManager.default.createDirectory(at: tocPath.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        try tocContent.write(to: tocPath, atomically: true, encoding: .utf8)
    } catch {
        logger.log("Error writing toc.xhtml file: \(error)")
    }
}

func createContentOpfContent(epubInfo: EpubInfo, pages: [Page]) -> String {
    let bookId = epubInfo.id ?? ""

    // Create manifest items for the pages
    let manifestItems = pages.enumerated().map { (index, page) in
        return """
        <item id="item-\(index + 1)" href="content/\(page.file).xhtml" media-type="application/xhtml+xml" />
        """
    }.joined(separator: "\n")

    // Create spine items for the pages
    let spineItems = pages.enumerated().map { (index, _) in
        return """
        <itemref idref="item-\(index + 1)" />
        """
    }.joined(separator: "\n")

    // Get the current date and time in the required format
    let dateFormatter = ISO8601DateFormatter()
    dateFormatter.formatOptions = [.withInternetDateTime]
    let modified = dateFormatter.string(from: Date())

    // Create manifest items for fonts
    let fontItems = epubInfo.fonts?.enumerated().map { (index, font) in
        let fontFileName = URL(fileURLWithPath: font).lastPathComponent
        return """
        <item href="fonts/\(fontFileName)" id="font\(index + 1)" media-type="application/x-font-otf" />
        """
    }.joined(separator: "\n") ?? ""

    // Create manifest items for images
    let imageItems = epubInfo.images?.map { image in
        let imageFileName = URL(fileURLWithPath: image).lastPathComponent
        let imageId = imageFileName.split(separator: ".").first.map(String.init) ?? ""
        return """
        <item id="\(imageId)" href="images/\(imageFileName)" media-type="image/jpeg" />
        """
    }.joined(separator: "\n") ?? ""

    return """
    <?xml version="1.0" encoding="UTF-8"?>
    <package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="BookID">
      <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
        <dc:identifier id="BookID">\(bookId)</dc:identifier>
        <dc:title>\(epubInfo.title)</dc:title>
        <dc:creator>\(epubInfo.author)</dc:creator>
        <dc:language>en</dc:language>
        <meta property="dcterms:modified">\(modified)</meta>
        <meta name="cover" content="\(URL(fileURLWithPath: epubInfo.cover ?? "cover.jpg").deletingPathExtension().lastPathComponent)" />
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
    </package>
    """
}

func createXhtmlFiles(epubInfo: EpubInfo, pages: [Page], destPath: URL) {
    let fileManager = FileManager.default

    for page in pages {
        // Create the file name and destination path
        let fileName = "\(page.file).xhtml"
        let filePath = destPath
            .appendingPathComponent("OPS")
            .appendingPathComponent("content")
            .appendingPathComponent(fileName)
        
        // Use page.title if it is not empty, else use epubInfo.title
        let title = !page.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? page.title : epubInfo.title
        
        // Generate XHTML content
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

        // Ensure the directory exists
        do {
            try fileManager.createDirectory(at: filePath.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        } catch {
            logger.log("Error creating directory: \(error)")
        }

        // Write the XHTML content to the file
        do {
            try xhtmlContent.write(to: filePath, atomically: true, encoding: .utf8)
        } catch {
            logger.log("Error writing XHTML file: \(error)")
        }
    }
}

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

func createTocNcxContent(epubInfo: EpubInfo, pages: [Page]) -> String {
    var playOrderCounter = 1 // Start playOrder from 1

    let navMap = pages.compactMap { page -> String? in
        let trimmedTitle = page.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty {
            let navPoint = """
            <navPoint id="navpoint-\(playOrderCounter)" playOrder="\(playOrderCounter)">
                <navLabel>
                    <text>\(page.title)</text>
                </navLabel>
                <content src="content/\(page.file).xhtml"/>
            </navPoint>
            """
            playOrderCounter += 1 // Increment playOrder for the next navPoint
            return navPoint
        }
        return nil
    }.joined(separator: "\n")

    return """
    <?xml version="1.0" encoding="UTF-8"?>
    <ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
      <head>
        <meta name="dtb:uid" content="\(epubInfo.id ?? "")" />
        <meta name="dtb:depth" content="1" />
        <meta name="dtb:totalPageCount" content="0" />
        <meta name="dtb:maxPageNumber" content="0" />
      </head>
      <docTitle>
        <text>\(epubInfo.title)</text>
      </docTitle>
      <docAuthor>
        <text>\(epubInfo.author)</text>
      </docAuthor>
      <navMap>
        \(navMap)
      </navMap>
    </ncx>
    """
}
