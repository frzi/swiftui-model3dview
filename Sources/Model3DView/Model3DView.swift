/*
 * Model3DView.swift
 * Created by Freek Zijlmans on 08-08-2021.
 */

import GLTFSceneKit
import SceneKit
import SwiftUI

// MARK: - Model3DView
/// View to render a 3D model or scene.
///
/// This view Utilizes SceneKit to render a 3D model or a SceneKit scene.
/// ```swift
/// Model3DView(named: "shoe.gltf")
/// ```
///
/// # Supported file types
/// The following 3D file formats are supported:
/// * `.gltf`, `.glb`: GL Transmission Format (both text and binary are supported)
/// * `.obj`: Waveform 3D Object format
///
/// - Note: Keep the number of `Model3DView`s simultenously on screen to a minimum.
public struct Model3DView: ViewRepresentable {

	private let sceneFile: SceneFileType

	@Environment(\.camera) var camera
	@Environment(\.ibl) var ibl: URL?
	@Environment(\.skybox) var skybox: URL?
	
	// Settable properties via view modifiers.
	fileprivate var rotation: Vector3 = [0, 0, 0]
	fileprivate var scale: Vector3 = [1, 1, 1]
	fileprivate var translate: Vector3 = [0, 0, 0]
	
	fileprivate var onLoadHandlers: [(ModelLoadState) -> Void] = []
	fileprivate var showsStatistics = false
	
	// MARK: -
	public init(named: String) {
		sceneFile = .url(Bundle.main.url(forResource: named, withExtension: nil))
	}
	
	public init(url: URL) {
		sceneFile = .url(url)
	}
	
	public init(scene: SCNScene) {
		sceneFile = .reference(scene)
	}

	// MARK: - Private implementations.
	private func makeView(context: Context) -> SCNView {
		let view = SCNView()
		view.antialiasingMode = .multisampling2X
		view.autoenablesDefaultLighting = true
		view.backgroundColor = .clear
		view.preferredFramesPerSecond = 60
		view.rendersContinuously = true // Not necessary?
		return view
	}
		
	private func updateView(_ view: SCNView, context: Context) {
		let coordinator = context.coordinator
		coordinator.view = view

		if coordinator.sceneFile != sceneFile {
			coordinator.sceneFile = sceneFile
			view.scene = coordinator.scene
			view.pointOfView = coordinator.cameraNode
		}

		coordinator.setCamera(camera)
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
	public class SceneCoordinator {
		fileprivate let cameraNode = SCNNode()
		fileprivate weak var view: SCNView?

		fileprivate private(set) var scene: SCNScene?
		fileprivate var sceneFile: SceneFileType? {
			didSet {
				scene = sceneFile?.scene
				prepareScene()
			}
		}
		
		private var contentNode: SCNNode? {
			scene?.rootNode.childNodes.first { $0 != cameraNode }
		}

		init() {
			cameraNode.camera = SCNCamera()
			cameraNode.camera?.name = "Camera"
		}
		
		private func prepareScene() {
			guard let scene = scene else {
				return
			}
			
			scene.rootNode.addChildNode(cameraNode)
			
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
		
		fileprivate func setCamera(_ camera: Camera) {
			if let view = view {
				let projection = camera.projectionMatrix(viewport: view.bounds.size)
				cameraNode.camera?.projectionTransform = SCNMatrix4(projection)
			}
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
	
	/// Transform the model in 3D space.
	public func transform(rotate: Vector3? = nil, scale: Vector3? = nil, translate: Vector3? = nil) -> Self {
		var view = self
		view.rotation = rotate ?? view.rotation
		view.scale = scale ?? view.scale
		view.translate = translate ?? view.translate
		return view
	}
	
	/// Show SceneKit statistics and inspector in the view.
	public func showStatistics() -> Self {
		var view = self
		view.showsStatistics = true
		return view
	}
}
