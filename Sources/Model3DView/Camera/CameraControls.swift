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
	public var sensitivity: CGFloat
	public var minPitch: Angle
	public var maxPitch: Angle
	public var minYaw: Angle
	public var maxYaw: Angle
	public var minZoom: CGFloat
	public var maxZoom: CGFloat
	
	// Values to apply to the camera.
	@State private var rotation = CGPoint()
	@State private var zoom: CGFloat = 4

	// Keeping track of gestures.
	@State private var dragPosition: CGPoint?
	@State private var zoomPosition: CGFloat = 0
	@State private var velocityPan = CGPoint()
	@State private var velocityZoom: CGFloat = 0
	@State private var isAnimating = false

	// MARK: -
	public init(
		camera: Binding<C>,
		sensitivity: CGFloat = 1,
		minPitch: Angle = .degrees(-89),
		maxPitch: Angle = .degrees(89),
		minYaw: Angle = .degrees(-.infinity),
		maxYaw: Angle = .degrees(.infinity),
		minZoom: CGFloat = 0,
		maxZoom: CGFloat = .infinity
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
				if let dragPosition = dragPosition {
					velocityPan = CGPoint(
						x: (dragPosition.x - state.location.x) * sensitivity,
						y: (dragPosition.y - state.location.y) * sensitivity
					)
				}
				else {
					velocityPan = CGPoint(
						x: (state.startLocation.x - state.location.x) * sensitivity,
						y: (state.startLocation.y - state.location.y) * sensitivity
					)
				}
				
				isAnimating = true
				dragPosition = state.location
			}
			.onEnded { state in
				dragPosition = nil
			}
	}

	private var pinchGesture: some Gesture {
		MagnificationGesture()
			.onChanged { state in
				print(state)
			}
	}

	// Updating the camera and other values at a per-tick rate.
	private func tick(frame: DisplayLink.Frame? = nil) {
		let deceleration: CGFloat = 0.8
		velocityPan.x *= deceleration
		velocityPan.y *= deceleration
		velocityZoom *= deceleration
		
		rotation.x += velocityPan.x
		rotation.y += velocityPan.y
		zoom = min(max(zoom + velocityZoom, minZoom), maxZoom)
		
		let theta = rotation.x * (.pi / 180)
		let phi = rotation.y * (.pi / 180)
		camera.wrappedValue.position.x = Float(zoom * -sin(theta) * cos(phi))
		camera.wrappedValue.position.y = Float(zoom * -sin(phi))
		camera.wrappedValue.position.z = Float(-zoom * cos(theta) * cos(phi))
		
		let epsilon: CGFloat = 0.0001
		isAnimating = abs(velocityPan.x) > epsilon || abs(velocityPan.y) > epsilon || abs(velocityZoom) > epsilon
	}

	public func body(content: Content) -> some View {
		content
			.gesture(dragGesture)
			.gesture(pinchGesture)
			.environment(\.camera, camera.wrappedValue)
			.onFrame(isActive: isAnimating, tick)
			.onAppear { tick() }
	}
}

// MARK: - View+CameraControls
extension View {
	/// Apply interactive camera controls to the underlying `Model3DView`s.
	public func cameraControls<T: CameraControls>(_ controls: T) -> ModifiedContent<Self, T> {
		modifier(controls)
	}
}
