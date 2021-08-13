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
	
	// MARK: -
	/// Sets the default Image Based Lighting (IBL) image from a file URL.
	public func ibl(file: URL?) -> some View {
		environment(\.ibl, file)
	}

	/// Sets the default Image Based Lighting (IBL) image from a bundle resource.
	public func ibl(named: String) -> some View {
		environment(\.ibl, Bundle.main.url(forResource: named, withExtension: nil))
	}

	// MARK: -
	/// Sets the default skybox image from a file URL.
	public func skybox(file: URL?) -> some View {
		environment(\.skybox, file)
	}

	/// Sets the default skybox image from a bundle resource.
	public func skybox(named: String) -> some View {
		environment(\.skybox, Bundle.main.url(forResource: named, withExtension: nil))
	}
}
