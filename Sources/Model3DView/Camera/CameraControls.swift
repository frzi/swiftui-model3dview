/*
 * CameraControls.swift
 * Created by Freek Zijlmans on 08-08-2021.
 */

import DisplayLink
import SwiftUI
import simd

public protocol CameraControls {}

/// Camera with orbit controls (also known as "arcball").
///
/// The camera can be moved horizontally, vertically and zoomed in and out. The camera will always focus on the center
/// of the model.
/// ```swift
/// @State var camera = PerspectiveCamera()
/// // etc ...
/// Model3DView(named: "bunny.gltf")
/// 	.cameraControls(OrbitCamera(camera: $camera))
/// ```
///
/// ## Zooming
/// Zooming is done by moving the camera on its local Z axis, opposed to increasing and decreasing the FOV.
public struct OrbitCamera<C: Camera>: CameraControls, ViewModifier {

	public var camera: Binding<C>
	public private(set) var sensitivity: CGFloat
	public var minPitch: Angle
	public var maxPitch: Angle
	public var minYaw: Angle
	public var maxYaw: Angle
	public var minZoom: CGFloat
	public var maxZoom: CGFloat
	public private(set) var friction: CGFloat
	
	// Values to apply to the camera.
	@State private var rotation = CGPoint()
	@State private var distance: CGFloat = 50

	// Keeping track of gestures.
	@State private var dragPosition: CGPoint?
	@State private var zoomPosition: CGFloat = 1
	@State private var velocityPan: CGPoint = .zero
	@State private var velocityZoom: CGFloat = 0

	@State private var isAnimating = false

	// MARK: -
	public init(
		camera: Binding<C>,
		sensitivity: CGFloat = 0.5,
		minPitch: Angle = .degrees(-89.9),
		maxPitch: Angle = .degrees(89.9),
		minYaw: Angle = .degrees(-.infinity),
		maxYaw: Angle = .degrees(.infinity),
		minZoom: CGFloat = 1,
		maxZoom: CGFloat = 10,
		friction: CGFloat = 0.1
	) {
		self.camera = camera
		self.sensitivity = max(sensitivity, 0.01)
		self.minPitch = minPitch
		self.maxPitch = maxPitch
		self.minYaw = minYaw
		self.maxYaw = maxYaw
		self.minZoom = minZoom
		self.maxZoom = maxZoom
		self.friction = clamp(friction, 0.01, 0.99)
		
		// TODO: Set initial `rotation` and `zoom` based on the Camera's values.
		_distance = State(initialValue: CGFloat(length(camera.wrappedValue.position)))
	}

	// MARK: -
	private var dragGesture: some Gesture {
		DragGesture(minimumDistance: 0, coordinateSpace: .local)
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
			.onEnded { _ in
				dragPosition = nil
			}
	}

	private var pinchGesture: some Gesture {
		MagnificationGesture()
			.onChanged { state in
				isAnimating = true
				velocityZoom = zoomPosition - state
				zoomPosition = state
			}
			.onEnded { _ in
				zoomPosition = 1
			}
	}

	// Updating the camera and other values at a per-tick rate.
	private func tick(frame: DisplayLink.Frame? = nil) {		
		rotation.x = clamp(rotation.x + velocityPan.x, minYaw.degrees, maxYaw.degrees)
		rotation.y = clamp(rotation.y + velocityPan.y, minPitch.degrees, maxPitch.degrees)
		distance = clamp(distance + velocityZoom, minZoom, maxZoom)
		
		let theta = rotation.x * (.pi / 180)
		let phi = rotation.y * (.pi / 180)
		camera.wrappedValue.position.x = Float(distance * -sin(theta) * cos(phi))
		camera.wrappedValue.position.y = Float(distance * -sin(phi))
		camera.wrappedValue.position.z = Float(-distance * cos(theta) * cos(phi))
		camera.wrappedValue.lookAt(center: [0, 0.0001, 0])
		
		let epsilon: CGFloat = 0.0001
		isAnimating = abs(velocityPan.x) > epsilon || abs(velocityPan.y) > epsilon || abs(velocityZoom) > epsilon
		
		// Apply deceleration to the velocity.
		let deceleration = 1 - friction
		velocityPan.x *= deceleration
		velocityPan.y *= deceleration
		velocityZoom *= deceleration
	}

	public func body(content: Content) -> some View {
		content
			.gesture(dragGesture)
			.gesture(pinchGesture)
			.environment(\.camera, camera.wrappedValue)
			.onAppear { tick() }
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
