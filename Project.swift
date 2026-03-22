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
            dependencies: [
                .target(name: "SekretLinkKeyboard"),
            ],
            settings: .settings(base: ["DEVELOPMENT_TEAM": "3RHDCDMV3P"])
        ),
        .target(
            name: "SekretLinkKeyboard",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "com.talkingchickenfriend.sekretlink.client.keyboard",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "SekretLink Keyboard",
                "NSExtension": [
                    "NSExtensionAttributes": [
                        "IsASCIICapable": false,
                        "PrefersRightToLeft": false,
                        "PrimaryLanguage": "en-US",
                        "RequestsOpenAccess": true,
                    ],
                    "NSExtensionPointIdentifier": "com.apple.keyboard-input-mode",
                    "NSExtensionPrincipalClass": "$(PRODUCT_MODULE_NAME).KeyboardViewController",
                ],
            ]),
            sources: [
                "SekretLinkKeyboard/Sources/**",
                // Shared with main app
                "SekretLink/Sources/Services/**",
                "SekretLink/Sources/Models/**",
                "SekretLink/Sources/Utilities/Theme.swift",
                "SekretLink/Sources/Features/Create/CreateSecretViewModel.swift",
            ],
            entitlements: .file(path: "SekretLinkKeyboard/Resources/SekretLinkKeyboard.entitlements"),
            settings: .settings(base: ["DEVELOPMENT_TEAM": "3RHDCDMV3P"])
        ),
    ]
)
