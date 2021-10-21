# ``Model3DView``

Effortlessly display 3D models in your SwiftUI app.

## Overview

With *Model3DView* you can effortlessly display 3D models in your SwiftUI just like you would with images. Additionally you can manipulate the camera and transform the model, all while keeping things SwiftUI-friendly.

## Topics

### Guides

- <doc:QuickStart>

### Main view

- ``Model3DView/Model3DView``

### Cameras

- ``Model3DView/Model3DView/camera(_:)``
- ``Camera``
- ``OrthographicCamera``
- ``PerspectiveCamera``

### Camera controls

- ``Model3DView/Model3DView/cameraControls(_:)``
- ``CameraControls``
- ``OrbitControls``

### View modifiers

- ``Model3DView/Model3DView/onLoad(perform:)``
- ``Model3DView/Model3DView/showStatistics()``
- ``Model3DView/Model3DView/transform(rotate:scale:translate:)``

### Scenery

- ``Model3DView/Model3DView/ibl(file:intensity:)``
- ``Model3DView/Model3DView/ibl(named:intensity:)``
- ``Model3DView/Model3DView/skybox(file:)``
- ``Model3DView/Model3DView/skybox(named:)``

### Math

Value types used regularly with *Model3DView*.
- ``Euler``
- ``Vector3``
