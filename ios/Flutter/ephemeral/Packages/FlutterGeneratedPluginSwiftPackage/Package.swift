// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "integration_test", path: "../.packages/integration_test"),
        .package(name: "webview_flutter_wkwebview", path: "../.packages/webview_flutter_wkwebview-3.23.0"),
        .package(name: "url_launcher_ios", path: "../.packages/url_launcher_ios-6.3.4"),
        .package(name: "speech_to_text", path: "../.packages/speech_to_text-7.4.0"),
        .package(name: "shared_preferences_foundation", path: "../.packages/shared_preferences_foundation-2.5.4"),
        .package(name: "google_sign_in_ios", path: "../.packages/google_sign_in_ios-6.2.1"),
        .package(name: "path_provider_foundation", path: "../.packages/path_provider_foundation-2.4.2"),
        .package(name: "flutter_secure_storage_darwin", path: "../.packages/flutter_secure_storage_darwin-0.3.2"),
        .package(name: "flutter_native_splash", path: "../.packages/flutter_native_splash-2.4.4"),
        .package(name: "flutter_appauth", path: "../.packages/flutter_appauth-11.0.0"),
        .package(name: "firebase_storage", path: "../.packages/firebase_storage-13.4.2"),
        .package(name: "firebase_core", path: "../.packages/firebase_core-4.10.0"),
        .package(name: "firebase_auth", path: "../.packages/firebase_auth-6.5.2"),
        .package(name: "file_picker", path: "../.packages/file_picker-11.0.2"),
        .package(name: "cloud_firestore", path: "../.packages/cloud_firestore-6.5.0"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "integration-test", package: "integration_test"),
                .product(name: "webview-flutter-wkwebview", package: "webview_flutter_wkwebview"),
                .product(name: "url-launcher-ios", package: "url_launcher_ios"),
                .product(name: "speech-to-text", package: "speech_to_text"),
                .product(name: "shared-preferences-foundation", package: "shared_preferences_foundation"),
                .product(name: "google-sign-in-ios", package: "google_sign_in_ios"),
                .product(name: "path-provider-foundation", package: "path_provider_foundation"),
                .product(name: "flutter-secure-storage-darwin", package: "flutter_secure_storage_darwin"),
                .product(name: "flutter-native-splash", package: "flutter_native_splash"),
                .product(name: "flutter-appauth", package: "flutter_appauth"),
                .product(name: "firebase-storage", package: "firebase_storage"),
                .product(name: "firebase-core", package: "firebase_core"),
                .product(name: "firebase-auth", package: "firebase_auth"),
                .product(name: "file-picker", package: "file_picker"),
                .product(name: "cloud-firestore", package: "cloud_firestore"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
