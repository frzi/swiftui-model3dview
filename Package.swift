// swift-tools-version:5.4

import PackageDescription

let package = Package(
	name: "Model3DView",
	platforms: [
		.macOS(.v11),
		.iOS(.v14),
		.tvOS(.v14),
		.watchOS(.v7)
	],
	products: [
		// Products define the executables and libraries a package produces, and make them visible to other packages.
		.library(
			name: "Model3DView",
			targets: ["Model3DView"]),
	],
	dependencies: [
		// Dependencies declare other packages that this package depends on.
		// .package(url: /* package url */, from: "1.0.0"),
		.package(url: "https://github.com/magicien/GLTFSceneKit", from: "0.3.0"),
		.package(url: "https://github.com/timdonnelly/DisplayLink", from: "0.2.0"),
	],
	targets: [
		// Targets are the basic building blocks of a package. A target can define a module or a test suite.
		// Targets can depend on other targets in this package, and on products in packages this package depends on.
		.target(
			name: "Model3DView",
			dependencies: ["GLTFSceneKit", "DisplayLink"]),
		.testTarget(
			name: "Model3DViewTests",
			dependencies: ["Model3DView"]),
	]
)
