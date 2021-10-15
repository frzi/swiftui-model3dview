/*
 * EnvironmentValues.swift
 * Created by Freek (github.com/frzi) on 08-08-2021.
 */

import SwiftUI

// TODO: Move me?
/// Container for 3D transform properties. Grouping them all together for the Environment values.
struct Transform3DProperties {
	var rotation = Euler()
	var scale: Vector3 = [1, 1, 1]
	var translation: Vector3 = [0, 0, 0]
}

extension Transform3DProperties: Equatable {
	static func == (lhs: Transform3DProperties, rhs: Transform3DProperties) -> Bool {
		lhs.rotation == rhs.rotation && lhs.scale == rhs.scale && lhs.translation == rhs.translation
	}
}

// MARK: - Environment keys.
struct CameraEnvironmentKey: EnvironmentKey {
	static var defaultValue: Camera = PerspectiveCamera()
}

struct IBLEnvironmentKey: EnvironmentKey {
	static var defaultValue: IBLValues?
}

struct SkyboxEnvironmentKey: EnvironmentKey {
	static var defaultValue: URL?
}

struct Transform3DEnvironmentKey: EnvironmentKey {
	static var defaultValue = Transform3DProperties()
}

// MARK: - Environment values.
extension EnvironmentValues {
	var camera: Camera {
		get { self[CameraEnvironmentKey.self] }
		set { self[CameraEnvironmentKey.self] = newValue }
	}
	
	var ibl: IBLValues? {
		get { self[IBLEnvironmentKey.self] }
		set { self[IBLEnvironmentKey.self] = newValue }
	}
	
	var skybox: URL? {
		get { self[SkyboxEnvironmentKey.self] }
		set { self[SkyboxEnvironmentKey.self] = newValue }
	}
	
	var transform3D: Transform3DProperties {
		get { self[Transform3DEnvironmentKey.self] }
		set { self[Transform3DEnvironmentKey.self] = newValue }
	}
}
