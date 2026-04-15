//
//  Wallpaper.swift
//  ClearMenuBar
//
//  Created by zorth64 on 24/06/25.
//

import AppKit
import OSLog

public enum Wallpaper {
    public enum Screen {
        case all
        case main
        case index(Int)
        case nsScreens([NSScreen])
        
        fileprivate var nsScreens: [NSScreen] {
            switch self {
            case .all:
                return NSScreen.screens
            case .main:
                guard let mainScreen = NSScreen.main else {
                    return []
                }
                
                return [mainScreen]
            case .index(let index):
                guard let screen = NSScreen.screens[safe: index] else {
                    return []
                }
                
                return [screen]
            case .nsScreens(let nsScreens):
                return nsScreens
            }
        }
    }
    
    public enum Scale: String, CaseIterable {
        case auto
        case fill
        case fit
        case stretch
        case center
    }
    
    public static func getLastWallpaperURL() -> URL? {
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "log show --last 2m --style syslog --predicate 'subsystem==\"com.apple.wallpaper\" and category==\"image-cache\" and composedMessage contains \"BEGIN - Image cache lookup - url\"' | tail -n 1 | grep -o 'file:///.*,' | sed -e 's/\\,.*$//'"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if let url = URL(string: String(output)) {
                return url
            }
        } else { return nil }
        
        return nil
    }
    
    public static func getLastWallpaperURLFromLogs() -> URL? {
        let store = try! OSLogStore.local()
        let interval = store.position(timeIntervalSinceEnd: -60.0)
        let predicate = NSPredicate(format: "subsystem == %@ AND category == %@ AND composedMessage CONTAINS %@", "com.apple.wallpaper", "image-cache", "BEGIN - Image cache lookup - url")
        let entries = try! store.getEntries(with: [], at: interval, matching: predicate)
        
        var response: [String] = [""]
        let regex = try! NSRegularExpression(pattern: "url: (file://[^,]+)", options: [])
        
        for e in entries {
            if e.composedMessage.contains("BEGIN - Image cache lookup - url: file") {
                response.append(e.composedMessage)
            }
        }
        
        if let lastEntry = response.last {
            let matches = regex.matches(in: lastEntry, options: [], range: NSRange(location: 0, length: lastEntry.utf16.count))
            
            for match in matches {
                if let range = Range(match.range(at: 1), in: lastEntry) {
                    let urlString = String(lastEntry[range])
                    
                    if let url = URL(string: urlString) {
                        return url
                    }
                }
            }
        }
        
        return nil
    }
    
    public static func getCurrentWallpaperURL() -> URL? {
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "log show --last 2s --style syslog --predicate 'subsystem==\"com.apple.wallpaper\" and category==\"image-cache\" and composedMessage contains \"BEGIN - Image cache lookup - url\"' | tail -n 1 | grep -o 'file:///.*,' | sed -e 's/\\,.*$//'"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if let url = URL(string: String(output)) {
                return url
            }
        } else { return nil }
        
        return nil
    }
    
    public static func getCurrentWallpaperURLFromLogs() -> URL? {
        let store = try! OSLogStore.local()
        let interval = store.position(timeIntervalSinceEnd: -1.55)
        let predicate = NSPredicate(format: "subsystem == %@ AND category == %@ AND composedMessage CONTAINS %@", "com.apple.wallpaper", "image-cache", "BEGIN - Image cache lookup - url")
        let entries = try! store.getEntries(with: [], at: interval, matching: predicate)
        
        var response: [String] = [""]
        let regex = try! NSRegularExpression(pattern: "url: (file://[^,]+)", options: [])
        
        for e in entries {
            if e.composedMessage.contains("BEGIN - Image cache lookup - url: file") {
                response.append(e.composedMessage)
            }
        }
        
        if let lastEntry = response.last {
            let matches = regex.matches(in: lastEntry, options: [], range: NSRange(location: 0, length: lastEntry.utf16.count))
            
            for match in matches {
                if let range = Range(match.range(at: 1), in: lastEntry) {
                    let urlString = String(lastEntry[range])
                    
                    if let url = URL(string: urlString) {
                        return url
                    }
                }
            }
        }
        
        return nil
    }
    
    public static func listenToWallpaperChanges() {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/log")
        process.arguments = ["stream", "--predicate", "subsystem=='com.apple.wallpaper' and category=='image-cache' and composedMessage contains 'BEGIN - Image cache lookup - url'"]
        
        process.standardOutput = pipe
        process.launch()
        
        let fileHandle = pipe.fileHandleForReading
        fileHandle.readInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: FileHandle.readCompletionNotification, object: fileHandle, queue: nil) { notification in
            if let data = notification.userInfo {
                Swift.print(data)
            }
        }
    }
    
    /**
     Get the current wallpapers.
     */
    public static func get(screen: Screen = .all) -> [URL?] {
        let wallpaperURLs = screen.nsScreens.compactMap { NSWorkspace.shared.desktopImageURL(for: $0) }
        return wallpaperURLs.map { url in
            if #available(macOS 26, *) {
                return url
            } else {
                if (url.isDirectory) {
                    return getLastWallpaperURL()
                } else {
                    return url
                }
            }
        }
    }
    
    public static func getCurrent(screen: Screen = .all) -> [URL?] {
        let wallpaperURLs = screen.nsScreens.compactMap { NSWorkspace.shared.desktopImageURL(for: $0) }
        return wallpaperURLs.map { url in
            if #available(macOS 26, *) {
                return url
            } else {
                if (url.isDirectory) {
                    return getCurrentWallpaperURL()
                } else {
                    return url
                }
            }
        }
    }
    
    public static func isWallpaperFromADirectory(screen: Screen = .all) -> [Bool?] {
        let wallpaperURLs = screen.nsScreens.compactMap{ NSWorkspace.shared.desktopImageURL(for: $0) }
        
        return wallpaperURLs.map { $0.isDirectory }
    }
    
    /**
    Set an image URL as wallpaper.
    */
    public static func set(
        _ image: URL,
        screen: Screen = .all,
        scale: Scale = .auto,
        fillColor: NSColor? = nil
    ) throws {
        try validateFile(image)

        var options = [NSWorkspace.DesktopImageOptionKey: Any]()

        switch scale {
        case .auto:
            break
        case .fill:
            options[.imageScaling] = NSImageScaling.scaleProportionallyUpOrDown.rawValue
            options[.allowClipping] = true
        case .fit:
            options[.imageScaling] = NSImageScaling.scaleProportionallyUpOrDown.rawValue
            options[.allowClipping] = false
        case .stretch:
            options[.imageScaling] = NSImageScaling.scaleAxesIndependently.rawValue
            options[.allowClipping] = true
        case .center:
            options[.imageScaling] = NSImageScaling.scaleNone.rawValue
            options[.allowClipping] = false
        }

        options[.fillColor] = fillColor

        for nsScreen in screen.nsScreens {
            try NSWorkspace.shared.setDesktopImageURL(image, for: nsScreen, options: options)
        }
    }
    
    private static func validateFile(_ url: URL) throws {
        var isDirectory: ObjCBool = false

        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            throw NSError(
                domain: "WallpaperError",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "The file doesn't exist."]
            )
        }

        if !isDirectory.boolValue {
            guard (try? url.checkResourceIsReachable()) == true else {
                throw NSError(
                    domain: "WallpaperError",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "The file exists but is not accessible."]
                )
            }
        }
    }
    
    public static func applicationSupportDirectory() -> URL? {
        let fileManager = FileManager.default
        
        guard let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
         
        let appFolder = baseURL.appendingPathComponent(Bundle.main.bundleIdentifier ?? "com.zorth64.ClearMenuBar")
            
        if !fileManager.fileExists(atPath: appFolder.path) {
            try? fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true)
        }
        
        return appFolder
    }
    
    public static func generateToken() -> String {
        String((0..<6).compactMap { _ in "abcdefghijklmnopqrstuvwxyz0123456789".randomElement() })
    }
    
    public static func saveWallpaper(_ image: NSImage) -> URL? {
        guard let directory = applicationSupportDirectory() else { return nil }
        guard let data = image.pngData() else { return nil }
       
        let token = generateToken()
        let filename = "Managed by Clear Menu Bar (\(token)).png"
        let fileURL = directory.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving image: ", error)
            return nil
        }
    }
}

extension NSImage {
    func pngData() -> Data? {
        guard let tiffData = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        
        return bitmap.representation(using: .png, properties: [:])
    }
}
