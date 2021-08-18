/*
 * CameraControls.swift
 * Created by Freek Zijlmans on 08-08-2021.
 */

import DisplayLink
import SwiftUI

public protocol CameraControls {}

/// Camera with orbit controls (also known as "arcball").
///
/// The camera can be moved horizontally, vertically and zoomed in and out. The camera will always focus on the center
/// of the scene (0, 0, 0).
/// ```swift
/// @State var camera = PerspectiveCamera()
/// // etc ...
/// Model3DView("bunny.gltf")
/// 	.cameraControls(OrbitCamera(camera: $camera))
/// ```
///
/// ## Zooming
/// Zooming is done by moving the camera on its local Z axis, opposed to increasing and decreasing the FOV.
public struct OrbitCamera<C: Camera>: CameraControls, ViewModifier {

	public var camera: Binding<C>
	public var sensitivity: Float
	public var minPitch: Float
	public var maxPitch: Float
	public var minYaw: Float
	public var maxYaw: Float
	public var minZoom: Float
	public var maxZoom: Float

	// Keeping track of gestures.
	@State private var position = CGPoint()
	@State private var previousPosition: CGPoint?
	@State private var zoom: CGFloat = 0
	@State private var velocityPan: CGPoint = .zero
	@State private var velocityZoom: CGFloat = 0
	
	private var isAnimating: Bool {
		velocityPan.x > 0 || velocityPan.y > 0 || velocityZoom > 0
	}

	// MARK: -
	public init(
		camera: Binding<C>,
		sensitivity: Float = 1,
		minPitch: Float = -.infinity,
		maxPitch: Float = .infinity,
		minYaw: Float = -.infinity,
		maxYaw: Float = .infinity,
		minZoom: Float = 0,
		maxZoom: Float = .infinity
	) {
		self.camera = camera
		self.sensitivity = sensitivity
		self.minPitch = minPitch
		self.maxPitch = maxPitch
		self.minYaw = minYaw
		self.maxYaw = maxYaw
		self.minZoom = minZoom
		self.maxZoom = maxZoom
	}

	// MARK: -
	private var dragGesture: some Gesture {
		DragGesture()
			.onChanged { state in
				// ...
			}
			.onEnded { state in
				previousPosition = nil
			}
	}
	
	private var pinchGesture: some Gesture {
		MagnificationGesture()
			.onChanged { state in
				zoom += state
			}
	}

	// Updating the camera and other values at a per-tick rate.
	private func tick(frame: DisplayLink.Frame) {
		camera.wrappedValue.position.x = Float(position.x)
	}
	
	public func body(content: Content) -> some View {
		content
			.gesture(dragGesture)
			.gesture(pinchGesture)
			.environment(\.camera, camera.wrappedValue)
			.onFrame(isActive: isAnimating, tick)
	}
}

// MARK: - View+CameraControls
extension View {
	/// Apply interactive camera controls to the underlying `Model3DView`s.
	public func cameraControls<T: CameraControls>(_ controls: T) -> ModifiedContent<Self, T> {
		modifier(controls)
	}
}
