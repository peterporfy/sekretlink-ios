import ProjectDescription

let project = Project(
    name: "SekretLink",
    targets: [
        .target(
            name: "SekretLink",
            destinations: .iOS,
            product: .app,
            bundleId: "com.talkingchickenfriend.sekretlink.client",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "SekretLink",
                "CFBundleURLTypes": [
                    [
                        "CFBundleTypeRole": "Viewer",
                        "CFBundleURLName": "link.sekret.client",
                        "CFBundleURLSchemes": ["sekretlink"],
                    ]
                ],
                "UILaunchScreen": [:],
                "UISupportedInterfaceOrientations": [
                    "UIInterfaceOrientationPortrait",
                    "UIInterfaceOrientationLandscapeLeft",
                    "UIInterfaceOrientationLandscapeRight",
                ],
                "UISupportedInterfaceOrientations~ipad": [
                    "UIInterfaceOrientationPortrait",
                    "UIInterfaceOrientationPortraitUpsideDown",
                    "UIInterfaceOrientationLandscapeLeft",
                    "UIInterfaceOrientationLandscapeRight",
                ],
            ]),
            sources: ["SekretLink/Sources/**"],
            resources: [.glob(pattern: "SekretLink/Resources/**", excluding: [
                "SekretLink/Resources/Info.plist",
                "SekretLink/Resources/SekretLink.entitlements",
            ])],
            entitlements: .file(path: "SekretLink/Resources/SekretLink.entitlements"),
            settings: .settings(base: ["DEVELOPMENT_TEAM": "3RHDCDMV3P"])
        )
    ]
)
