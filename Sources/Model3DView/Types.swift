/*
 * Types.swift
 * Created by Freek Zijlmans on 08-08-2021.
 */

import Foundation
import GLTFSceneKit
import SceneKit
import SwiftUI

#if os(macOS)
typealias PlatformImage = NSImage
typealias ViewRepresentable = NSViewRepresentable
#else
typealias PlatformImage = UIImage
typealias ViewRepresentable = UIViewRepresentable
#endif

public enum ModelLoadState {
	case success
	case error
}

public enum LoadResult {
	case success
	case failure(Error)
}

enum SceneFileType: Equatable {
	case reference(SCNScene)
	case url(URL?)
	
	var scene: SCNScene? {
		if case .url(let url) = self,
		   let url = url
		{
			if url.pathExtension == "gltf" || url.pathExtension == "glb" {
				let source = GLTFSceneSource(url: url, options: nil)
				let scene = try! source.scene()
				return scene
			}
			else {
				return try? SCNScene(url: url)
			}
		}
		else if case .reference(let scene) = self {
			return scene
		}
		return nil
	}
	
	static func == (lhs: Self, rhs: Self) -> Bool {
		if case .url(let l) = lhs, case .url(let r) = rhs {
			return l == r
		}
		else if case .reference(let l) = lhs, case .reference(let r) = rhs {
			return l == r
		}
		return false
	}
}
