
/*
 * Euler.swift
 * Created by Freek (github.com/frzi) on 14-10-2021.
 */

import SwiftUI

/// Rotation vector where all elements are of type `Angle`.
///
/// The vector represents Euler angles.
/// - Note: Any arithmetic calculations are based on radians.
public struct Euler: Equatable {
	public var x: Angle
	public var y: Angle
	public var z: Angle
	
	public init(x: Angle = .radians(0), y: Angle = .radians(0), z: Angle = .radians(0)) {
		self.x = x
		self.y = y
		self.z = z
	}
	
	// https://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles#Source_code_2
	/// Initialize with a rotation quaternion.
	public init(_ quat: Quaternion) {
		let sinr_cosp = 2 * (quat.real * quat.imag.x + quat.imag.y * quat.imag.z)
		let cosr_cosp = 1 - 2 * (quat.imag.x * quat.imag.x + quat.imag.y * quat.imag.y)
		let x = atan2(sinr_cosp, cosr_cosp)
		
		let sinp = 2 * (quat.real * quat.imag.y - quat.imag.z * quat.imag.x)
		let y = abs(sinp) >= 1 ? copysign(.pi / 2, sinp) : asin(sinp)
		
		let siny_cosp = 2 * (quat.real * quat.imag.z + quat.imag.x * quat.imag.y)
		let cosy_cosp = 1 - 2 * (quat.imag.y * quat.imag.y + quat.imag.z * quat.imag.z)
		let z = atan2(siny_cosp, cosy_cosp)
		
		self.init(x: .radians(Double(x)), y: .radians(Double(y)), z: .radians(Double(z)))
	}
}

extension Euler: CustomStringConvertible {
	public var description: String {
		"Euler(\(x), \(y), \(z))"
	}
}

// MARK: - Vector arithemtic conformance.
extension Euler: VectorArithmetic {
	public static func - (lhs: Euler, rhs: Euler) -> Euler {
		Euler(
			x: .radians(lhs.x.radians - rhs.x.radians),
			y: .radians(lhs.y.radians - rhs.y.radians),
			z: .radians(lhs.z.radians - rhs.z.radians)
		)
	}

	public static func + (lhs: Euler, rhs: Euler) -> Euler {
		Euler(
			x: .radians(lhs.x.radians + rhs.x.radians),
			y: .radians(lhs.y.radians + rhs.y.radians),
			z: .radians(lhs.z.radians + rhs.z.radians)
		)
	}

	public mutating func scale(by rhs: Double) {
		x = .radians(x.radians * rhs)
		y = .radians(y.radians * rhs)
		z = .radians(z.radians * rhs)
	}

	public var magnitudeSquared: Double {
		x.radians * x.radians + y.radians * y.radians + z.radians * z.radians
	}

	public static var zero: Euler {
		Euler(x: .radians(0), y: .radians(0), z: .radians(0))
	}
}
