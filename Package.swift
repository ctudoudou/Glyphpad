// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Glyphpad",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "GlyphpadCore", targets: ["GlyphpadCore"]),
        .library(name: "GlyphpadStorage", targets: ["GlyphpadStorage"]),
        .executable(name: "GlyphpadApp", targets: ["GlyphpadApp"])
    ],
    targets: [
        .systemLibrary(
            name: "CSQLite",
            pkgConfig: "sqlite3"
        ),
        .target(
            name: "GlyphpadCore"
        ),
        .target(
            name: "GlyphpadStorage",
            dependencies: [
                "CSQLite",
                "GlyphpadCore"
            ]
        ),
        .executableTarget(
            name: "GlyphpadApp",
            dependencies: [
                "GlyphpadCore",
                "GlyphpadStorage"
            ]
        ),
        .testTarget(
            name: "GlyphpadStorageTests",
            dependencies: [
                "GlyphpadStorage"
            ]
        )
    ]
)
