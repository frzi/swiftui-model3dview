/*
 * Model3DView.swift
 * Created by Freek (github.com/frzi) on 08-08-2021.
 */

import Combine
import DeveloperToolsSupport
import GLTFSceneKit
import SceneKit
import SwiftUI

// MARK: - Model3DView
/// View to render a 3D model or scene.
///
/// This view utilizes SceneKit to render a 3D model or a SceneKit scene.
/// ```swift
/// Model3DView(named: "duck.gltf")
/// 	.transform(scale: [0.5, 0.5, 0.5])
/// 	.camera(PerspectiveCamera())
/// ```
///
/// ## Supported file types
/// The following 3D file formats are supported:
/// * `.gltf`, `.glb`: GL Transmission Format (both text and binary are supported)
/// * `.obj`: Waveform 3D Object format
/// * `.scn`: SceneKit scene file
///
/// - Important: Keep the number of `Model3DView`s simultaneously on screen to a minimum.
public struct Model3DView: ViewRepresentable {

	private let sceneFile: SceneFileType

	// Settable properties via view modifiers.
	// private var rotation: Quaternion = [0, 0, 0, 1]
	private var rotation: Euler = Euler()
	private var scale: Vector3 = [1, 1, 1]
	private var translate: Vector3 = [0, 0, 0]

	private var onLoadHandlers: [(ModelLoadState) -> Void] = []
	private var showsStatistics = false

	// MARK: - Initializers
	/// Load a 3D asset from the app's bundle.
	public init(named: String) {
		sceneFile = .url(Bundle.main.url(forResource: named, withExtension: nil))
	}
	
	/// Load a 3D asset from a file URL.
	public init(file: URL) {
		#if DEBUG
		precondition(file.isFileURL, "Given URL is not a file URL.")
		#endif
		sceneFile = .url(file)
	}
	
	/// Load 3D assets from a SceneKit scene instance.
	///
	/// When passing a SceneKit scene instance to `Model3DView` all the contents will be copied to an internal scene.
	/// Although geometry data will be shared (an optimization provided by SceneKit), any changes to nodes in the
	/// original scene will not apply to the scene rendered by `Model3DView`.
	///
	/// - Important: It is important pass an already initialized instance of `SCNScene`.
	/// ```swift
	/// // ❌ Bad
	/// var body: some View {
	/// 	Model3DView(scene: SCNScene(named: "myscene")!)
	/// }
	///
	/// // ✅ Good
	/// static var scene = SCNScene(named: "myscene")!
	///
	/// var body: some View {
	/// 	Model3DView(scene: Self.scene)
	/// }
	/// ```
	public init(scene: SCNScene) {
		sceneFile = .reference(scene)
	}

	// MARK: - Private implementations
	private func makeView(context: Context) -> SCNView {
		let view = SCNView()
		view.autoenablesDefaultLighting = true
		view.backgroundColor = .clear
		
		// Framerate
		#if os(macOS)
		if #available(macOS 12, *) {
			//view.preferredFramesPerSecond = NSScreen.main?.maximumFramesPerSecond ?? view.preferredFramesPerSecond
		}
		#else
		view.preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond
		#endif
		
		// Anti-aliasing.
		// If the screen's pixel ratio is above 1 we disable anti-aliasing. Otherwise use MSAAx2.
		// This may become a view modifier at some point instead.
		#if os(macOS)
		let screenScale = NSScreen.main?.backingScaleFactor ?? 1
		#else
		let screenScale = UIScreen.main.scale
		#endif

		view.antialiasingMode = screenScale > 1 ? .none : .multisampling2X

		context.coordinator.camera = context.environment.camera
		context.coordinator.setView(view)

		return view
	}

	private func updateView(_ view: SCNView, context: Context) {
		view.showsStatistics = showsStatistics

		// Update the coordinator.
		let coordinator = context.coordinator
		coordinator.setSceneFile(sceneFile)

		// Properties.
		coordinator.camera = context.environment.camera
		coordinator.onLoadHandlers = onLoadHandlers

		// Methods.
		coordinator.setIBL(settings: context.environment.ibl)
		coordinator.setSkybox(asset: context.environment.skybox)
		coordinator.setTransform(rotation: rotation, scale: scale, translate: translate)
	}
}

// MARK: - ViewRepresentable implementations
extension Model3DView {
	public func makeCoordinator() -> SceneCoordinator {
		SceneCoordinator()
	}
	
	#if os(macOS)
	public func makeNSView(context: Context) -> SCNView {
		makeView(context: context)
	}
	
	public func updateNSView(_ view: SCNView, context: Context) {
		updateView(view, context: context)
	}
	#else
	public func makeUIView(context: Context) -> SCNView {
		makeView(context: context)
	}
	
	public func updateUIView(_ view: SCNView, context: Context) {
		updateView(view, context: context)
	}
	#endif
}

// MARK: - Animatable
extension Model3DView: Animatable {
	public var animatableData: AnimatablePair<Vector3, Euler> {
		get {
			.init(translate, rotation)
		}
		set {
			translate = newValue.first
			rotation = newValue.second
		}
	}
}

// MARK: - Coordinator
extension Model3DView {
	/// Holds all the state values.
	public class SceneCoordinator: NSObject {

		private enum LoadError: Error {
			case unableToLoad
		}

		// Keeping track of already loaded resources.
		private static let imageCache = ResourcesCache<URL, PlatformImage>()
		private static let sceneCache = AsyncResourcesCache<URL, SCNScene>()

		// MARK: -
		private let cameraNode = SCNNode()
		private let contentNode = SCNNode()
		private let scene = SCNScene()

		private weak var view: SCNView!

		private var loadSceneCancellable: AnyCancellable?
		private var loadedScene: SCNScene? // Keep a reference for `AsyncResourcesCache`.

		fileprivate var onLoadHandlers: [(ModelLoadState) -> Void] = []
		
		// Properties for diffing.
		private var sceneFile: SceneFileType?
		private var ibl: IBLValues?
		private var skybox: URL?

		// Instead of using the `.simdPosition` and `.simdOrientation` properties, use a transform matrix instead.
		// We want to depend on as little SceneKit features as possible.
		private var transform = Matrix4x4.identity

		private var contentScale: Float = 1
		fileprivate var camera: Camera! {
			didSet {
				cameraNode.camera?.name = String(describing: type(of: camera))
			}
		}

		// MARK: -
		fileprivate override init() {
			// Prepare the scene to house the loaded models/content.
			cameraNode.camera = SCNCamera()
			cameraNode.name = "Camera"
			scene.rootNode.addChildNode(cameraNode)

			contentNode.name = "Content"
			scene.rootNode.addChildNode(contentNode)

			super.init()
		}

		// MARK: - Setting scene properties.
		fileprivate func setView(_ sceneView: SCNView) {
			view = sceneView
			view.delegate = self
			view.pointOfView = cameraNode
			view.scene = scene
		}

		fileprivate func setSceneFile(_ sceneFile: SceneFileType) {
			guard self.sceneFile != sceneFile else {
				return
			}

			self.sceneFile = sceneFile

			// Load the scene file/reference.
			// If an url is given, the scene will be loaded asynchronously via `AsyncResourcesCache`, making sure
			// only one instance lives in memory and doesn't block the main thread.
			// TODO: Add (better?) error handling...
			if case .url(let sceneUrl) = sceneFile,
			   let url = sceneUrl
			{
				loadSceneCancellable = Self.sceneCache.resource(for: url) { url, promise in
					do {
						if ["gltf", "glb"].contains(url.pathExtension.lowercased()) {
							let source = GLTFSceneSource(url: url, options: nil)
							let scene = try source.scene()
							promise(.success(scene))
						}
						else {
							let scene = try SCNScene(url: url)
							promise(.success(scene))
						}
					}
					catch {
						promise(.failure(LoadError.unableToLoad))
					}
				}
				.sink { completion in
					if case .failure(_) = completion {
						DispatchQueue.main.async {
							for onLoad in self.onLoadHandlers {
								onLoad(.error)
							}
						}
					}
				} receiveValue: { [weak self] scene in
					self?.loadedScene = scene
					self?.prepareScene()
				}
			}
			else if case .reference(let scene) = sceneFile {
				loadSceneCancellable = Just(scene)
					.receive(on: DispatchQueue.global())
					.sink { [weak self] scene in
						self?.loadedScene = scene
						self?.prepareScene()
					}
			}
		}
		
		private func prepareScene() {
			contentNode.childNodes.forEach { $0.removeFromParentNode() }

			// Copy the root node(s) of the scene, copy their geometry, and place them in the coordinator's scene.
			guard let loadedScene = loadedScene else {
				return
			}

			let copiedRoot = loadedScene.rootNode.clone()

			// Copy the materials.
			copiedRoot
				.childNodes { node, _ in node.geometry?.firstMaterial != nil }
				.forEach { node in
					node.geometry = node.geometry?.copy() as? SCNGeometry
				}

			// Scale the scene/model to normalized (-1, 1) scale.
			let maxDimension = max(
				copiedRoot.boundingBox.max.x - copiedRoot.boundingBox.min.x,
				copiedRoot.boundingBox.max.y - copiedRoot.boundingBox.min.y,
				copiedRoot.boundingBox.max.z - copiedRoot.boundingBox.min.z)
			contentScale = Float(2 / maxDimension)
			
			contentNode.addChildNode(copiedRoot)
			
			DispatchQueue.main.async {
				for onLoad in self.onLoadHandlers {
					onLoad(.success)
				}
			}
		}

		// MARK: - Apply new values.
		/// Apply scene transforms.
		fileprivate func setTransform(rotation: Euler, scale: Vector3, translate: Vector3) {
			let quat = Quaternion(rotation)
			transform = Matrix4x4(scale: scale) * Matrix4x4(translation: translate) * Matrix4x4(quat)
		}

		/// Set the skybox texture from file.
		fileprivate func setSkybox(asset: URL?) {
			guard asset != skybox else {
				return
			}
			
			if let asset = asset {
				scene.background.contents = Self.imageCache.resource(for: asset) { url in
					PlatformImage(contentsOfFile: url.path)
				}
			}
			else {
				scene.background.contents = nil
			}
			
			skybox = asset
		}
		
		/// Set the image based lighting (IBL) texture and intensity.
		fileprivate func setIBL(settings: IBLValues?) {
			guard ibl?.url != settings?.url || ibl?.intensity != settings?.intensity else {
				return
			}
			
			if let settings = settings,
			   let image = Self.imageCache.resource(for: settings.url, action: { url in
				   PlatformImage(contentsOfFile: url.path)
			   })
			{
				scene.lightingEnvironment.contents = image
				scene.lightingEnvironment.intensity = settings.intensity
			}
			else {
				scene.lightingEnvironment.contents = nil
				scene.lightingEnvironment.intensity = 1
			}
			
			ibl = settings
		}
	}
}

// MARK: - SCNSceneRendererDelegate
/**
 * Note: Methods can - and most likely will be - called on a different thread.
 */
extension Model3DView.SceneCoordinator: SCNSceneRendererDelegate {
	public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
		// Update the content node.
		contentNode.simdTransform = Matrix4x4(scale: [contentScale, contentScale, contentScale]) * transform
		
		// Update the camera.
		let projection = camera.projectionMatrix(viewport: view.currentViewport.size)
		cameraNode.camera?.projectionTransform = SCNMatrix4(projection)

		let cameraTransform = Matrix4x4(translation: camera.position) * Matrix4x4(camera.rotation)
		cameraNode.simdTransform = cameraTransform
	}
}

// MARK: - Modifiers for Model3DView.
extension Model3DView {
	/// Adds an action to perform when the model is loaded.
	public func onLoad(perform: @escaping (ModelLoadState) -> Void) -> Self {
		var view = self
		view.onLoadHandlers.append(perform)
		return view
	}
	
	/// Transform the model in 3D space. Use this to either rotate, scale or move the 3D model from the center.
	/// Applying this modifier multiple times will result in overriding previously set values.
	public func transform(rotate: Euler? = nil, scale: Vector3? = nil, translate: Vector3? = nil) -> Self {
		var view = self
		view.rotation = rotate ?? view.rotation
		view.scale = scale ?? view.scale
		view.translate = translate ?? view.translate
		return view
	}
	
	/// Show SceneKit statistics and inspector in the view.
	///
	/// Only use this modifier during development (i.e. using `#if DEBUG`).
	/// ```swift
	/// Model3DView(named: "robot.gltf")
	/// 	#if DEBUG
	/// 	.showStatistics()
	/// 	#endif
	/// ```
	public func showStatistics() -> Self {
		var view = self
		view.showsStatistics = true
		return view
	}
}

// MARK: - Developer Tools
struct Model3DView_Library: LibraryContentProvider {
	@LibraryContentBuilder
	var views: [LibraryItem] {
		LibraryItem(Model3DView(named: "model.gltf"), visible: true, title: "Model3D View")
	}
}
