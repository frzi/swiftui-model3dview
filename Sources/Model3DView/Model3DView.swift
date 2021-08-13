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
/// Model3DView(named: "shoe.gltf")
/// 	.transform(scale: [0.5, 0.5, 0.5])
/// 	.camera(perspectiveCamera)
/// ```
///
/// ## Supported file types
/// The following 3D file formats are supported:
/// * `.gltf`, `.glb`: GL Transmission Format (both text and binary are supported)
/// * `.obj`: Waveform 3D Object format
/// * `.scn`: SceneKit scene file
///
/// - Note: Keep the number of `Model3DView`s simultaneously on screen to a minimum.
public struct Model3DView: ViewRepresentable {

	private let sceneFile: SceneFileType
	
	// Settable properties via view modifiers.
	private var rotation: Vector3 = [0, 0, 0]
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

	// MARK: - Private implementations.
	private func makeView(context: Context) -> SCNView {
		let view = SCNView()
		view.antialiasingMode = .multisampling2X
		view.autoenablesDefaultLighting = true
		view.backgroundColor = .clear
		#if os(iOS)
		view.preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond
		#endif
		//view.rendersContinuously = true // Not necessary?
		
		context.coordinator.setView(view)
		
		return view
	}
		
	private func updateView(_ view: SCNView, context: Context) {
		let coordinator = context.coordinator
		
		if coordinator.sceneFile != sceneFile {
			coordinator.setSceneFile(sceneFile)
		}
		
		coordinator.camera = context.environment.camera
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
/// Holds all the state values.
extension Model3DView {
	public class SceneCoordinator: NSObject {
		// References for future diffing.
		private weak var view: SCNView?
		private var scene: SCNScene?
		fileprivate private(set) var sceneFile: SceneFileType?
		
		// Viewport.
		private var viewportSize: CGSize = .zero
		private var viewportSizeCancellable: AnyCancellable?
		
		// Camera
		fileprivate var camera: Camera?
		private var cameraNode: SCNNode = {
			let node = SCNNode()
			node.name = "CameraNode"
			node.camera = SCNCamera()
			return node
		}()

		private var contentNode: SCNNode? {
			scene?.rootNode.childNodes.first { $0 != cameraNode }
		}
		
		// MARK: - Setting scene properties.
		fileprivate func setView(_ view: SCNView) {
			self.view = view
			view.pointOfView = cameraNode

			// Prepare subscribers and publishers.
			viewportSizeCancellable = view.publisher(for: \.frame)
				.map { $0.size }
				.assign(to: \.viewportSize, on: self)
		}
		
		fileprivate func setSceneFile(_ sceneFile: SceneFileType) {
			self.sceneFile = sceneFile
			scene = sceneFile.scene
			scene?.rootNode.addChildNode(cameraNode)
			view?.scene = scene
			
			guard let contentNode = contentNode else {
				return
			}

			// Set up the camera positioning. Attempt to center the model in the view.
			let centerY = contentNode.boundingSphere.center.y
			cameraNode.position.y = centerY
			cameraNode.position.z = 10
		}
		
		// MARK: - Apply new values.
		fileprivate func setTransform(rotation: Vector3, scale: Vector3, translate: Vector3) {
			guard let contentNode = contentNode else {
				return
			}
			
			//rootNode.rotation = SCNVector4(rotation.x, rotation.y, rotation.z, 1)
			contentNode.scale = SCNVector3(scale)
			contentNode.position = SCNVector3(translate)
		}
	}
}

// MARK: - SCNSceneRendererDelegate
// Note: Methods can - and most likely will be - called on a different thread. Thus it is important to not
// refer to `self.view` at any time.
extension Model3DView.SceneCoordinator: SCNSceneRendererDelegate {
	public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
		if let camera = camera {
			let projection = SCNMatrix4(camera.projectionMatrix(viewport: viewportSize))
			cameraNode.camera?.projectionTransform = projection
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
	/// Applying this modifier multiple times will result in previously set values being overridden.
	public func transform(rotate: Vector3? = nil, scale: Vector3? = nil, translate: Vector3? = nil) -> Self {
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
