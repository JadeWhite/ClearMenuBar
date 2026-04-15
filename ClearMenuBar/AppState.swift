//
//  AppState.swift
//  Clear Menu Bar
//
//  Created by zorth64 on 11/03/26.
//

import SwiftUI

class AppState: ObservableObject {
    @Published var allowReduceTransparencyToBeDisabled: Bool = false {
        didSet {
            storedAllowReduceTransparencyToBeDisabled = allowReduceTransparencyToBeDisabled
        }
    }
    @Published var currentWallpaperPath: URL? {
        didSet {
            storedCurrentWallpaperPath = currentWallpaperPath
        }
    }
    @Published var modifiedWallpaperPath: URL? {
        didSet {
            storedModifiedWallpaperPath = modifiedWallpaperPath
        }
    }
    
    @AppStorage("allowReduceTransparencyDisabled") private var storedAllowReduceTransparencyToBeDisabled: Bool = false
    @AppStorage("currentWallpaperPath") private var storedCurrentWallpaperPath: URL?
    @AppStorage("modifiedWallpaperPath") private var storedModifiedWallpaperPath: URL?
    
    lazy var appSupportDirectory: URL? = {
        return Wallpaper.applicationSupportDirectory()
    }()
    
    init() {
        allowReduceTransparencyToBeDisabled = storedAllowReduceTransparencyToBeDisabled
        currentWallpaperPath = storedCurrentWallpaperPath
        modifiedWallpaperPath = storedModifiedWallpaperPath
    }
}
