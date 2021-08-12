/*
 * CameraControls.swift
 * Created by Freek Zijlmans on 08-08-2021.
 */

import DisplayLink
import SwiftUI

public protocol CameraControls {}

public struct OrbitCamera: CameraControls, ViewModifier {

	public var camera: Binding<Camera>
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
	
	// MARK: -
	public init(
		camera: Binding<Camera>,
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
	
	private var dragGesture: some Gesture {
		DragGesture()
			.onChanged { state in
				if previousPosition == nil {
					previousPosition = state.location
				}

				position.x += (state.location.x - previousPosition!.x) * CGFloat(sensitivity)
				position.y += (state.location.y - previousPosition!.y) * CGFloat(sensitivity)
				previousPosition = state.location
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
	
	public func body(content: Content) -> some View {
		content
			.gesture(dragGesture)
			.gesture(pinchGesture)
			.environment(\.camera, camera.wrappedValue)
			.onFrame(isActive: false) { frame in
				// ...
			}
	}
}

// MARK: - View+CameraControls
extension View {
	/// Apply interactive camera controls to the underlying `Model3DView`s.
	public func cameraControls<T: CameraControls>(_ controls: T) -> ModifiedContent<Self, T> {
		modifier(controls)
	}
}
