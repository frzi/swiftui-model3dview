/*
 * Math.swift
 * Created by Freek Zijlmans on 11-08-2021.
 */

import Foundation
import simd

public typealias Vector2 = SIMD2<Float>
public typealias Vector3 = SIMD3<Float>
public typealias Vector4 = SIMD4<Float>
public typealias Matrix4x4 = float4x4

extension Matrix4x4 {
	static func orthographic(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float) -> Matrix4x4 {
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
	
	static func perspective(fov: Float, aspect: Float, near: Float, far: Float) -> Matrix4x4 {
		let f = 1 / tan(fov * 0.5)
		let nf = 1 / (near - far)
		return Matrix4x4(
			[f / aspect, 0, 0, 0],
			[0, f, 0, 0],
			[0, 0, far * nf, -1],
			[0, 0, far * near * nf, 0]
		)
	}
}
