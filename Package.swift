// swift-tools-version:5.5

import PackageDescription

let package = Package(
	name: "Model3DView",
	platforms: [
		.macOS(.v11),
		.iOS(.v14),
		.tvOS(.v14)
	],
	products: [
		.library(
			name: "Model3DView",
			targets: ["Model3DView"]),
	],
	dependencies: [
		.package(url: "https://github.com/frzi/GLTFSceneKit", from: "0.3.1"),
		.package(url: "https://github.com/timdonnelly/DisplayLink", from: "0.2.0"),
	],
	targets: [
		.target(
			name: "Model3DView",
			dependencies: ["GLTFSceneKit", "DisplayLink"]),
		.testTarget(
			name: "Model3DViewTests",
			dependencies: ["Model3DView"]),
	]
)
