#  Quick start

Setting up a ``Model3DView/Model3DView`` and exploring some of its features.

## Overview

With *Model3DView* displaying a 3D model is as easy as displaying an image. Additionally, *Model3DView* exposes methods to setup the scene like transforming the model or changing the camera.

### Displaying a 3D model

``Model3DView/Model3DView`` can display a 3D model from three different sources. Use ``Model3DView/Model3DView/init(file:)`` to reference a file using a file `URL`, ``Model3DView/Model3DView/init(named:)`` to reference a file from the app's bundle, and ``Model3DView/Model3DView/init(scene:)`` to render a `SCNScene`.

```swift
Model3DView(named: "duck.gltf")
```

The model and camera will be centered to show the model in its entire by default.

- Note: When referencing a `SCNScene` instance, its contents will be copied to an internal SceneKit scene. Modifications made to the original `SCNScene` will have no effect to the scene rendered by *Model3DView*. 

### Setting up a camera

By default a perspective camera is setup by *Model3DView*. Use the ``Model3DView/Model3DView/camera(_:)`` view modifier to setup a custom camera.

*Model3DView* comes with two cameras available out of the box:
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

### Interactive cameras

```swift
struct MyView: View {
	@State private var camera = PerspectiveCamera()

	var body: some View {
		Model3DView(named: "shoe.gltf")
			.cameraControls(OrbitCamera(camera: $camera))
	}
}
```

This view modifier replaces the ``Model3DView/Model3DView/camera(_:)`` modifier.

### Transform the model

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

### Skybox and IBL (image based lighting)

Models using PBR materials (physically based rendering) can utilize IBL (image based lighting) to light up the scene using a texture. Optionally, the intensity of the IBL can also be set.

```swift
Model3DView(named: "house.glb")
	.ibl(named: "suburbs-ibl.exr", intensity: 1.1)
	.skybox(named: "suburbs.jpg")
```
