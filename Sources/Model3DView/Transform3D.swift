/*
 * Transform3D.swift
 * Created by Freek (github.com/frzi) on 15-10-2021.
 */

import SwiftUI

/**
 * As of writing this, the following code is the only way I managed to get the transform properties to be animatable.
 * Originally the properties lived inside `Model3DView`, but the `Animatable` protocol refused to actually
 * animate these properties. To circumvent this, the properties have been moved to Environment values and are set via
 * an `AnimatableModifier`. It works, but suggestions/improvements are welcome!
 */

/// Container for 3D transform properties.
/// Grouping them all together for the Environment values, opposed to making 3 individual environment key/values.
struct Transform3DProperties {
	var rotation = Euler()
	var scale: Vector3 = [1, 1, 1]
	var translation: Vector3 = [0, 0, 0]
}

// MARK: - Animatable transform 3D
private struct Transform3DModifier: AnimatableModifier {
	var properties: Transform3DProperties
	
	var animatableData: AnimatablePair<Euler, AnimatablePair<Vector3, Vector3>> {
		get {
			.init(properties.rotation, .init(properties.scale, properties.translation))
		}
		set {
			properties.rotation = newValue.first
			properties.scale = newValue.second.first
			properties.translation = newValue.second.second
		}
	}
	
	func body(content: Content) -> some View {
		content.environment(\.transform3D, properties)
	}
}

// MARK: - View modifier
extension Model3DView {
	/// Transform the model in 3D space. Use this to either rotate, scale or move the 3D model from the center.
	/// Applying this modifier multiple times will result in overriding/resetting previously set values.
	public func transform(rotate: Euler = Euler(), scale: Vector3 = 1, translate: Vector3 = 0) -> some View {
		let props = Transform3DProperties(rotation: rotate, scale: scale, translation: translate)
		return modifier(Transform3DModifier(properties: props))
	}
}
