/*
 * Cameras.swift
 * Created by Freek Zijlmans on 08-08-2021.
 */

import SwiftUI

/// Protocol for `Model3DView` cameras.
public protocol Camera {
	var position: Vector3 { get set }
	var rotation: Vector3 { get set }
	func projectionMatrix(viewport: CGSize) -> Matrix4x4
}

/// Camera with orthographic projection.
public struct OrthographicCamera: Camera {
	public var position: Vector3
	public var rotation: Vector3
	public var near: Float
	public var far: Float
	
	public init(
		position: Vector3 = [0, 0, 0],
		rotation: Vector3 = [0, 0, 0],
		near: Float = 0.0001,
		far: Float = 100
	) {
		self.position = position
		self.rotation = rotation
		self.near = near
		self.far = far
	}
	
	public func projectionMatrix(viewport size: CGSize) -> Matrix4x4 {
		let ratio = Float(size.width / size.height)
		return .orthographic(left: -ratio, right: ratio, bottom: -1, top: 1, near: near, far: far)
	}
}

/// Camera with perspective projection.
public struct PerspectiveCamera: Camera {
	public var position: Vector3
	public var rotation: Vector3
	public var fov: Angle
	public var near: Float
	public var far: Float
	
	public init(
		position: Vector3 = [0, 0, 0],
		rotation: Vector3 = [0, 0, 0],
		fov: Angle = .degrees(60),
		near: Float = 0.0001,
		far: Float = 100
	) {
		self.position = position
		self.rotation = rotation
		self.fov = fov
		self.near = near
		self.far = far
	}
	
	public func projectionMatrix(viewport size: CGSize) -> Matrix4x4 {
		.perspective(fov: Float(fov.radians), aspect: Float(size.width / size.height), near: near, far: far)
	}
}
