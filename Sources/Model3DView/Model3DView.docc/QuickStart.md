#  Quick start

Setting up a `Model3DView` and exploring some of its features.

## Overview

With Model3DView displaying a 3D model is as easy as displaying an image. Additionally, Model3DView exposes methods to setup the scene like transforming the model or changing the camera.

## Displaying a 3D model

``Model3DView/Model3DView`` can display a 3D model from three different sources:
* ``Model3DView/Model3DView/init(file:)`` to reference a file using a file `URL`
* ``Model3DView/Model3DView/init(named:)`` to reference a file from the app's bundle
* ``Model3DView/Model3DView/init(scene:)`` to render a `SCNScene`.

```swift
Model3DView(named: "duck.gltf")
```

The model and camera will be centered by default.

- Note: When referencing a `SCNScene` instance, its contents will be copied to an internal SceneKit scene. Modifications made to the original `SCNScene` will have no effect to the scene rendered by Model3DView. 

## Setting up a camera

By default a perspective camera is setup by Model3DView. Use the ``Model3DView/Model3DView/camera(_:)`` view modifier to setup a custom camera.

Model3DView comes with two cameras available out of the box:
* ``PerspectiveCamera``: A perspective camera with a customizable FOV (field of view).
* ``OrthographicCamera``: An orthographic camera, used often for technical and isometric visuals.

```swift
Model3DView(named: "robot.gltf")
	.camera(PerspectiveCamera(fov: .degrees(70)))
```

The view modifier sets the camera as an environment value, meaning the camera will be applied to all underlying Model3DViews.

```swift
ForEach(models) { model in 
	Model3DView(file: model.file)
}
.camera(OrthographicCamera())
```

## Interactive cameras

For your convenience Model3DView comes with ``OrbitControls`` out of the box, applying orbit controls (also known as arcball) to the underlying Model3DViews. Use the ``Model3DView/Model3DView/cameraControls(_:)`` view modifier to apply interactive camera controls. This view modifier replaces the ``Model3DView/Model3DView/camera(_:)`` modifier.

```swift
struct MyView: View {
	@State private var camera = PerspectiveCamera()

	var body: some View {
		Model3DView(named: "shoe.gltf")
			.cameraControls(OrbitControls(
				camera: $camera,
				sensitivity: 0.5
			))
	}
}
```

## Transform the model

Use the ``Model3DView/Model3DView/transform(rotate:scale:translate:)`` view modifier to transform (rotate, scale and/or translate) the model in 3D space.

```swift
Model3DView(named: "car.gltf")
	.transform(
		rotate: Euler(y: .degrees(90)),
		scale: 1.5,
		translate: [0, 0, -2]
	)
```

These properties are animatable.

## Skybox and IBL (image based lighting)

Models using PBR materials (physically based rendering) can utilize IBL (image based lighting) to light up the scene using a texture. Optionally, the intensity of the IBL can also be set. 

```swift
Model3DView(named: "house.glb")
	.ibl(named: "outside-hdri.exr", intensity: 1.1)
	.skybox(named: "outside.png")
```

## Responding to model loading

Models are loaded asynchronously. With the ``Model3DView/Model3DView/onLoad(perform:)`` view modifier you can attach handlers to respond to models loading - either successfully or failing.

Because models are loaded asynchronously they may not be immediately visible. The more complex the model, the longer it takes to load. During this, it may be desirable to temporarily display a placeholder until the model is loaded.

```swift
struct MyView: View {
	@State private var state: ModelLoadState?

	var body: some View {
		Model3DView(named: "bird.gltf")
			.onLoad { state in
				self.state = state
			}
			.overlay(Group {
				if state == nil {
					ProgressView()
				}
				else if state == .failure {
					Image(systemName: "exclamationmark.square")
				}
			})
	}
}
