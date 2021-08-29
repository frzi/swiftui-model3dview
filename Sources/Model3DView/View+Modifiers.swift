/*
 * View+Modifiers.swift
 * Created by Freek Zijlmans on 08-08-2021.
 */

import SwiftUI

// MARK: - Modifiers.
extension View {
	/// Sets the default camera.
	public func camera(_ camera: Camera) -> some View {
		environment(\.camera, camera)
	}
	
	// MARK: - Scene IBL
	/// Sets the default Image Based Lighting (IBL) image from a file URL.
	///
	/// - Note: This requires the 3D assets to use a PBR material.
	public func ibl(file: URL?, intensity: Double = 1) -> some View {
		if let url = file {
			return environment(\.ibl, (url, intensity))
		}
		return environment(\.ibl, nil)
	}

	/// Sets the default Image Based Lighting (IBL) image from a bundle resource.
	///
	/// - Note: This requires the 3D assets to use a PBR material.
	public func ibl(named: String, intensity: Double = 1) -> some View {
		if let url = Bundle.main.url(forResource: named, withExtension: nil) {
			return environment(\.ibl, (url, intensity))
		}
		return environment(\.ibl, nil)
	}

	// MARK: - Scene skybox
	/// Sets the default skybox image from a file URL.
	public func skybox(file: URL?) -> some View {
		environment(\.skybox, file)
	}

	/// Sets the default skybox image from a bundle resource.
	public func skybox(named: String) -> some View {
		environment(\.skybox, Bundle.main.url(forResource: named, withExtension: nil))
	}
	
	// MARK: - Model animation
	/// Sets the animation to play for underlying `Model3DView`s.
	///
	/// Animation names are case sensitive and should match the names as they're defined in the *glTF* file or
	/// SceneKit asset.
	///
	/// Use `nil` to play the default animation.
	///
	/// TODO: Consider using an enum with associated value(s) being the animation name?
	/// I.e.: `.modelAnimation(.play("rotate")` or `.modelAnimation(.position("rotate", 0.5))`.
	/// Or use extra modifiers to set playstate and/or frame:
	/// ```swift
	/// .modelAnimation("rotate")
	/// .playState(.paused)
	/// .animationPosition(0.5)
	/// ```
	//public func modelAnimation(_ name: String?) -> some View {
	//	environment(\.modelAnimation, name)
	//}
}
