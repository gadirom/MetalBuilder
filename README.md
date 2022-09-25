# MetalBuilder
<p align="center">
    <img src="https://img.shields.io/badge/platforms-iPadOS_15_-blue.svg" alt="iPadOS" />
    <a href="https://swift.org/about/#swiftorg-and-open-source"><img src="https://img.shields.io/badge/Swift-5.5-orange.svg" alt="Swift 5.5" /></a>
    <a href="https://developer.apple.com/metal/"><img src="https://img.shields.io/badge/Metal-2.4-green.svg" alt="Metal 2.4" /></a>
    <a href="https://apps.apple.com/ru/app/swift-playgrounds/id908519492?l=en"><img src="https://img.shields.io/badge/SwiftPlaygrounds-4.0-orange.svg" alt="Swift Playgrounds 4" /></a>
   <a href="https://en.wikipedia.org/wiki/MIT_License"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT" /></a>
    
</p>

## Overview

MetalBuilder is an open source Swift Package for declarative dispatching of Metal shaders.

It can extremely simplify your Swift and Metal code, especially if you use Metal in SwiftUI apps.

Also, if you're new to Metal or to GPU programming in general, MetalBuilder will make it easy for you to start.
 
Since MetalBuilder is purely Swift Package, you can import it in Swift Playgrounds on an iPad.

## How to use

MetalBuilder is a wrapper that alllows you to manage Metal objects in a functional manner mimicking SwiftUI. E.g., buffers and textures are created using property wrappers like this: 
```
@MetalBuffer<Particle>(count: particlesCount, metalName: "particles") var particlesBuffer
@MetalTexture(textureDescriptor
        .pixelFormat(.rgba16Float)) var texture
```
To show what you're are rendering you use MetalBuilderView struct just like any other SwiftUI view.
It takes the following main parameters: `librarySource` - a string that contains shaders code, and `metalContent` - a resultBuilder closure that describes shader dispatch like this:
```
Compute("integration")
                    .buffer(particlesBuffer, space: "device",
                            fitThreads: true)
Render(vertex: "vertexShader", fragment: "fragmentShader", 
       type: .point, count: particlesCount)
                    .vertexBuf(particlesBuffer)
                    .vertexBytes(context.$viewportSize)
                    .fragBytes($flameType, name: "type")
                    .toTexture(renderTexture)
```
You can use Binding as a shader parameter. Along with it you can pass a name of the metal property that the binded Swift property would represent in shader code.
This allows MetalBuilder to generate automatically most of the declarations of the shader functions at the time the view loads. 
This considerably reduces the amount of Metal code and makes Metal much more simple to use with SwiftUI, making it approachable even for beginners.

See the Example app to get the idea of how MetalBuilder works.

This is a work in progress! I will add a lot more documentation and examples in the nearest future!

