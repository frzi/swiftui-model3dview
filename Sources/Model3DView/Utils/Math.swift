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

extension Quaternion {
	// http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/index.htm
	/// Initialize a Quaternion from a Matrix3x3.
	public static func fromMatrix3x3(_ m: Matrix3x3) -> Quaternion {
		/**
		 inline void CalculateRotation( Quaternion& q ) const {
		   float trace = a[0][0] + a[1][1] + a[2][2]; // I removed + 1.0f; see discussion with Ethan
		   if( trace > 0 ) {// I changed M_EPSILON to 0
			 float s = 0.5f / sqrtf(trace+ 1.0f);
			 q.x = ( a[2][1] - a[1][2] ) * s;
			 q.y = ( a[0][2] - a[2][0] ) * s;
			 q.z = ( a[1][0] - a[0][1] ) * s;
		     q.w = 0.25f / s;
		   } else {
			 if ( a[0][0] > a[1][1] && a[0][0] > a[2][2] ) {
			   float s = 2.0f * sqrtf( 1.0f + a[0][0] - a[1][1] - a[2][2]);
			   q.x = 0.25f * s;
			   q.y = (a[0][1] + a[1][0] ) / s;
			   q.z = (a[0][2] + a[2][0] ) / s;
				q.w = (a[2][1] - a[1][2] ) / s;
			 } else if (a[1][1] > a[2][2]) {
			   float s = 2.0f * sqrtf( 1.0f + a[1][1] - a[0][0] - a[2][2]);
			   q.x = (a[0][1] + a[1][0] ) / s;
			   q.y = 0.25f * s;
			   q.z = (a[1][2] + a[2][1] ) / s;
				q.w = (a[0][2] - a[2][0] ) / s;
			 } else {
			   float s = 2.0f * sqrtf( 1.0f + a[2][2] - a[0][0] - a[1][1] );
			   q.x = (a[0][2] + a[2][0] ) / s;
			   q.y = (a[1][2] + a[2][1] ) / s;
			   q.z = 0.25f * s;
				q.w = (a[1][0] - a[0][1] ) / s;
			 }
		   }
		 }
		 */
		
		var q: Quaternion
		
		let m = m.columns
		let t = m.0.x + m.1.y + m.2.z
		
		if t > 0 {
			let s = 0.5 / sqrt(t + 1)
			q = [
				(m.2.y - m.1.z) * s,
				(m.0.z - m.2.x) * s,
				(m.1.x - m.0.y) * s,
				0.25 / s
			]
		}
		else if m.0.x > m.1.y && m.0.x > m.2.z {
			let s = 2 * sqrt(1 + m.0.x - m.1.y - m.2.z)
			q = [
				0.25 * s,
				(m.0.y + m.1.x) / s,
				(m.0.z + m.2.x) / s,
				(m.2.y - m.1.z) / s
			]
		}
		else if m.1.y > m.2.z {
			let s = 2 * sqrt(1 + m.1.y - m.0.x - m.2.z)
			q = [
				(m.0.y + m.1.x) / s,
				0.25 * s,
				(m.1.z + m.2.y) / s,
				(m.0.z - m.2.x) / s
			]
		}
		else {
			let s = 2 * sqrt(1 + m.2.z - m.0.x - m.1.y)
			q = [
				(m.0.z + m.2.x) / s,
				(m.1.z + m.2.y) / s,
				0.25 * s,
				(m.1.x - m.0.y) / s
			]
		}
		
		return q
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

	public init(translation vec: Vector3) {
		self.init(
			[1, 0, 0, 0],
			[0, 1, 0, 0],
			[0, 0, 1, 0],
			[vec.x, vec.y, vec.z, 1]
		)
	}
	
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
