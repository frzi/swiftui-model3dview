/*
 * Math.swift
 * Created by Freek Zijlmans on 11-08-2021.
 */

import Foundation
import simd
import SwiftUI

public typealias Vector2 = SIMD2<Float>
public typealias Vector3 = SIMD3<Float>
public typealias Vector4 = SIMD4<Float>
public typealias Quaternion = simd_quatf
public typealias Matrix3x3 = float3x3
public typealias Matrix4x4 = float4x4

// MARK: - Functions
@inlinable func clamp<T: Comparable>(_ val: T, _ minimum: T, _ maximum: T) -> T {
	min(max(val, minimum), maximum)
}

// MARK: - Quaternion utilities
extension Quaternion: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: Float...) {
		precondition(elements.count == 4)
		self.init(ix: elements[0], iy: elements[1], iz: elements[2], r: elements[3])
	}
}

// MARK: - Matrix 4x4 utilities
extension Matrix4x4 {
	// MARK: Initializers
	public static let identity = Matrix4x4(
		[1, 0, 0, 0],
		[0, 1, 0, 1],
		[0, 0, 1, 0],
		[0, 0, 0, 1]
	)
	
	public init(scale: Vector3) {
		self.init(
			[scale.x, 0, 0, 0],
			[0, scale.y, 0, 0],
			[0, 0, scale.z, 0],
			[0, 0, 0, 1]
		)
	}

	public init(translation vec: Vector3) {
		self.init(
			[1, 0, 0, 0],
			[0, 1, 0, 0],
			[0, 0, 1, 0],
			[vec.x, vec.y, vec.z, 1]
		)
	}
	
	// MARK: Extras
	/// Orthographic projection matrix.
	@inlinable
	public static func orthographic(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float) -> Matrix4x4 {
		let lr = 1 / (left - right)
		let bt = 1 / (bottom - top)
		let nf = 1 / (near - far)
		return Matrix4x4(
			[-2 * lr, 0, 0, 0],
			[0, -2 * bt, 0, 0],
			[0, 0, nf, 0],
			[(left + right) * lr, (top + bottom) * bt, near * nf, 1]
		)
	}

	/// Perspective projection matrix.
	///
	/// - Parameter fov: Field of fiew in radians.
	/// - Parameter aspect: Aspect ratio of the view.
	/// - Parameter near: Lowest Z value.
	/// - Parameter far: Highest Z value.
	@inlinable
	public static func perspective(fov: Float, aspect: Float, near: Float, far: Float) -> Matrix4x4 {
		let f = 1 / tan(fov * 0.5)
		let nf = 1 / (near - far)
		return Matrix4x4(
			[f / aspect, 0, 0, 0],
			[0, f, 0, 0],
			[0, 0, far * nf, -1],
			[0, 0, far * near * nf, 0]
		)
	}

	/// Right-handed look at.
	@inlinable
	public static func lookAt(eye: Vector3, target: Vector3, up: Vector3) -> Matrix4x4 {
		let z = normalize(target - eye)
		let x = normalize(cross(z, up))
		let y = cross(x, z)
		return Matrix4x4(
			[x.x, x.y, x.z, 0],
			[y.x, y.y, y.z, 0],
			[-z.x, -z.y, -z.z, 0],
			[eye.x, eye.y, eye.z, 1]
		)
	}
}
