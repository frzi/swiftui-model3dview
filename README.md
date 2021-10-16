# Model3DView

> Effortlessly render 3D models in your SwiftUI app

![SwiftUI](https://img.shields.io/github/v/release/frzi/Model3DView?style=for-the-badge)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-blue.svg?style=for-the-badge&logo=swift&logoColor=black)](https://developer.apple.com/xcode/swiftui)
[![Swift](https://img.shields.io/badge/Swift-5.4-orange.svg?style=for-the-badge&logo=swift)](https://swift.org)
[![Xcode](https://img.shields.io/badge/Xcode-13-blue.svg?style=for-the-badge&logo=Xcode&logoColor=white)](https://developer.apple.com/xcode)
[![MIT](https://img.shields.io/badge/license-MIT-black.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

With *Model3DView* you can effortlessly display 3D models in your SwiftUI just like you would with images. Additionally you can manipulate the camera and transform the model, all while keeping things SwiftUI-friendly.

⚠️ ***IMPORTANT***: *Model3DView* is still in very early stages of development. The API is not final and ~~may~~ will change over the course of upcoming version releases.

## Index
* [Installation](#installation-)
* [Examples](https://github.com/frzi/Model3DView-Examples) ↗️
* [Features](#features-)
* [Quickstart](#quickstart-)
* [FAQ](#faq-)

<br>

## Installation 🛠
In Xcode add the dependency to your project via *File > Add Packages > Search or Enter Package URL* and use the following url:
```
https://github.com/frzi/Model3DView.git
```

Once added, import the package in your code:
```swift
import Model3DView
```

<br>

## Features ✨

<br>

## Quickstart 🚀
The code is provided with ample documentation. For detailed information about views, methods, etc, please see inquire Xcode's documentation features. Below a quick rundown of *Model3DView*'s features.

Using *Model3DView* couldn't possibly be more easy. Use `Model3DView` like any other view:
```swift
struct MyView: View {
	var body: some View {
		Model3DView(named: "duck.gltf")
	}
}
```
This renders a 3D model with the filename "*duck.gltf*" that's located in the app's bundle.

### `Model3DView`

#### Transform
#### `onLoad` handler

### Cameras

### Interactive cameras

### Skyboxes and IBL (image based lighting)

<br>

## FAQ ℹ️
### Can I use this to make 3D games?
***No***. It is very important to understand *Model3DView* is made to only render 3D models in your SwiftUI app, with very limited interaction. It acts as an ImageView, but for 3D models.

### Why use *Model3DView* instead of *SceneView*?**  
*SceneView* (included with SwiftUI) is very limited in its nature. It simply wraps a `SKSceneView` for SwiftUI. But due to it being closed source gives no control on this view. For instance: giving the view a transparent background is practically impossible. 

*Model3DView* also provides a workflow more inline with SwiftUI's; using view modifiers to manipulate the model and camera.

<br>

## License 📄
[MIT License](LICENSE).
