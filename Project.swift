import ProjectDescription

let appName = "Plakaki"
let bundleIdPrefix = "xyz.etotot"
let signingXcconfig: Path = .relativeToRoot("Config/Signing.xcconfig")

let swiftLintScript = TargetScript.pre(
    script: """
    if command -v swiftlint >/dev/null 2>&1; then
        swiftlint lint --strict --config "${SRCROOT}/.swiftlint.yml"
    elif [ -x "$HOME/.local/bin/mise" ]; then
        "$HOME/.local/bin/mise" x -- swiftlint lint --strict --config "${SRCROOT}/.swiftlint.yml"
    else
        echo "warning: SwiftLint not found. Run 'mise install' to enable linting."
    fi
    """,
    name: "SwiftLint",
    inputPaths: [
        "\(appName)/Sources/**",
        "\(appName)/Tests/**",
        "Project.swift",
        "Tuist.swift",
        "Tuist/**",
        ".swiftlint.yml"
    ],
    basedOnDependencyAnalysis: false
)

let appSettings: Settings = .settings(
    base: [:]
        .swiftVersion("6.0"),
    configurations: [
        .debug(
            name: .debug,
            xcconfig: signingXcconfig
        ),
        .release(
            name: .release,
            xcconfig: signingXcconfig
        )
    ]
)

let testSettings: Settings = .settings(
    base: [:]
        .swiftVersion("6.0")
        .merging([
            "CODE_SIGNING_ALLOWED": "NO",
            "CODE_SIGNING_REQUIRED": "NO",
            "CODE_SIGN_IDENTITY": "-"
        ])
)

let project = Project(
    name: appName,
    targets: [
        .target(
            name: appName,
            destinations: .macOS,
            product: .app,
            bundleId: "\(bundleIdPrefix).\(appName)",
            infoPlist: .default,
            buildableFolders: [
                .folder("\(appName)/Sources"),
                .folder("\(appName)/Resources")
            ],
            scripts: [swiftLintScript],
            dependencies: [],
            settings: appSettings
        ),
        .target(
            name: "\(appName)Tests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "\(bundleIdPrefix).\(appName)Tests",
            infoPlist: .default,
            buildableFolders: [
                .folder("\(appName)/Tests")
            ],
            dependencies: [.target(name: appName)],
            settings: testSettings
        )
    ]
)
