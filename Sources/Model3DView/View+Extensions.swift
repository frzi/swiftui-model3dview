/*
 * View+Extensions.swift
 * Created by Freek Zijlmans on 08-08-2021.
 */

import SwiftUI

// MARK: - Extensions
extension View {
	// MARK: -
	public func camera(_ camera: Camera) -> some View {
		environment(\.camera, camera)
	}
	
	// MARK: -
	public func ibl(file: URL?) -> some View {
		environment(\.ibl, file)
	}

	public func ibl(named: String) -> some View {
		environment(\.ibl, Bundle.main.url(forResource: named, withExtension: nil))
	}

	// MARK: -
	public func skybox(file: URL?) -> some View {
		environment(\.skybox, file)
	}

	public func skybox(named: String) -> some View {
		environment(\.skybox, Bundle.main.url(forResource: named, withExtension: nil))
	}
}
