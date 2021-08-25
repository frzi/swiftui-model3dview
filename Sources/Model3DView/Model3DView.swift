/*
 * Model3DView.swift
 * Created by Freek Zijlmans on 08-08-2021.
 */

import Combine
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
	private var rotation: Quaternion = [0, 0, 0, 1]
	private var scale: Vector3 = [1, 1, 1]
	private var translate: Vector3 = [0, 0, 0]

	private var onLoadHandlers: [(ModelLoadState) -> Void] = []
	private var showsStatistics = false

	// MARK: -
	/// Load a 3D asset from the app's bundle.
	public init(named: String) {
		sceneFile = .url(Bundle.main.url(forResource: named, withExtension: nil))
	}
	
	/// Load a 3D asset from a file URL.
	public init(file: URL) {
		sceneFile = .url(file)
	}
	
	/// Load a SceneKit scene instance.
	public init(scene: SCNScene) {
		sceneFile = .reference(scene)
	}

	// MARK: - Private implementations
	private func makeView(context: Context) -> SCNView {
		let view = SCNView()
		view.antialiasingMode = .multisampling2X
		view.autoenablesDefaultLighting = true
		view.backgroundColor = .clear
		#if os(iOS)
		view.preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond
		#elseif os(macOS)
		if #available(macOS 12, *) {
			view.preferredFramesPerSecond = view.window?.screen?.maximumFramesPerSecond ?? view.preferredFramesPerSecond
		}
		#endif

		context.coordinator.setView(view)
	
		return view
	}

	private func updateView(_ view: SCNView, context: Context) {
		let coordinator = context.coordinator
		
		if coordinator.sceneFile != sceneFile {
			coordinator.setSceneFile(sceneFile)
		}

		coordinator.camera = context.environment.camera
		coordinator.onLoadHandlers = onLoadHandlers
		coordinator.setTransform(rotation: rotation, scale: scale, translate: translate)

		view.showsStatistics = showsStatistics
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

// MARK: - Coordinator
extension Model3DView {
	/// Holds all the state values.
	public class SceneCoordinator: NSObject {
		/// Keep track of already loaded scenes.
		private static let resources = ResourcesCache<URL, SCNScene>()

		private var loadCancellable: AnyCancellable?
		private weak var scene: SCNScene?
		private weak var view: SCNView!
		fileprivate private(set) var sceneFile: SceneFileType?
		
		fileprivate var onLoadHandlers: [(ModelLoadState) -> Void] = []

		// Camera
		fileprivate var camera: Camera?
		private var cameraNode: SCNNode = {
			let node = SCNNode()
			node.name = "Camera Node"
			node.camera = SCNCamera()
			return node
		}()

		private var contentScale: Float = 1
		private var contentCenter = Vector3()
		private var contentNode: SCNNode? {
			scene?.rootNode.childNodes.first { $0 != cameraNode }
		}

		// MARK: - Setting scene properties.
		fileprivate func setView(_ view: SCNView) {
			view.delegate = self
			self.view = view
		}

		fileprivate func setSceneFile(_ sceneFile: SceneFileType) {
			guard self.sceneFile != sceneFile else {
				return
			}

			self.sceneFile = sceneFile

			// Load the scene file/reference.
			// If an url is given, the scene will be loaded asynchronously via `ResourcesCache`, making sure only
			// only one instance lives in memory.
			// TODO: Clean this all up neatly. More loading resources to a different function.
			if case .url(let sceneUrl) = sceneFile,
			   let url = sceneUrl
			{
				loadCancellable = SceneCoordinator.resources.resource(for: url) { url in
					if ["gltf", "glb"].contains(url.pathExtension.lowercased()) {
						let source = GLTFSceneSource(url: url, options: nil)
						let scene = try! source.scene()
						return scene
					}
					else if let scene = try? SCNScene(url: url) {
						return scene
					}
					else {
						return SCNScene()
					}
				}
				.receive(on: DispatchQueue.main)
				.sink { _ in } receiveValue: { [weak self] scene in
					self?.scene = scene
					self?.prepareScene()
				}
			}
			else if case .reference(let scene) = sceneFile {
				self.scene = scene
				prepareScene()
			}
		}
		
		private func prepareScene() {
			scene?.rootNode.addChildNode(cameraNode)
			view.scene = scene
			view.pointOfView = cameraNode
			
			guard let contentNode = contentNode else {
				return
			}

			// Scale the scene/model to normalized (-1, 1) scale.
			let maxDimension = max(
				contentNode.boundingBox.max.x - contentNode.boundingBox.min.x,
				contentNode.boundingBox.max.y - contentNode.boundingBox.min.y,
				contentNode.boundingBox.max.z - contentNode.boundingBox.min.z
			)
			contentScale = Float(2 / maxDimension) * 0.8
			contentCenter = [0, Float(contentNode.boundingSphere.center.y) * contentScale, 0]
			
			DispatchQueue.main.async { // Redundant?
				for onLoad in self.onLoadHandlers {
					onLoad(.success)
				}
			}
		}

		// MARK: - Apply new values.
		fileprivate func setTransform(rotation: Quaternion, scale: Vector3, translate: Vector3) {
			guard let contentNode = contentNode else {
				return
			}
			
			contentNode.simdOrientation = rotation
			contentNode.simdScale = scale * contentScale
			contentNode.simdPosition = translate
		}
		
		// MARK: - Clean up
		deinit {
			cameraNode.removeFromParentNode()
		}
	}
}

// MARK: - SCNSceneRendererDelegate
// Note: Methods can - and most likely will be - called on a different thread. Thus it is important to not refer to
// `view.bounds` or `view.frame` etc.
extension Model3DView.SceneCoordinator: SCNSceneRendererDelegate {
	public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
		if let camera = camera {
			let projection = camera.projectionMatrix(viewport: view.currentViewport.size)
			cameraNode.camera?.projectionTransform = SCNMatrix4(projection)

			cameraNode.simdPosition = camera.position + contentCenter + [0, 0.0001, 0]
			cameraNode.simdOrientation = camera.rotation
			cameraNode.simdLook(at: contentCenter) // Replace with above.
		}
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
	public func transform(rotate: Quaternion? = nil, scale: Vector3? = nil, translate: Vector3? = nil) -> Self {
		var view = self
		view.rotation = rotate ?? view.rotation
		view.scale = scale ?? view.scale
		view.translate = translate ?? view.translate
		return view
	}
	
	/// Show SceneKit statistics and inspector in the view.
	///
	/// Only use this modifier during development (i.e. using `#if DEBUG`).
	public func showStatistics() -> Self {
		var view = self
		view.showsStatistics = true
		return view
	}
}
