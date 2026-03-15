import ProjectDescription

let project = Project(
    name: "SekretLink",
    targets: [
        .target(
            name: "SekretLink",
            destinations: .iOS,
            product: .app,
            bundleId: "link.sekret.client",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .file(path: "SekretLink/Resources/Info.plist"),
            sources: ["SekretLink/Sources/**"],
            resources: ["SekretLink/Resources/**"],
            entitlements: .file(path: "SekretLink/Resources/SekretLink.entitlements")
        )
    ]
)
