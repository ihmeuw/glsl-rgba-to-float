# glsl-rgba-to-float

## Installation

```bash
npm install --save glsl-rgba-to-float
```

## Signature

```glsl
float rgbaToFloat(vec4 texelRGBA, bool littleEndian);
```

## Usage

This package exports a GLSL function, `rgbaToFloat`, that decodes 32-bit floating point values from the RGBA channels of a WebGL texture. This is a workaround for the lack of support in baseline WebGL 1.0 for floating-point textures. WebGL 2.0 allows floating-point textures, and WebGL 1.0 allows them when the extension `OES_texture_float` is available, but some users may be using a browser or hardware that don't have these capabilities. This package seeks to fill that gap.

In baseline WebGL 1.0, a maximum of 32 bits are allotted for each texel (pixel in a texture). It's therefore possible to create textures in which each texel represents a single 32-bit float. A straightforward way to do that is to create a `Float32Array` with the desired texel values, then reinterpret the underlying binary data of the typed array's `ArrayBuffer` as a `Uint8Array`. This latter array can then be passed to the WebGL system as an RGBA texture of type `UNSIGNED_BYTE`. This "tricks" WebGL into treating a single 32-bit float as a vector of four bytes.

```javascript
// JavaScript control code

// construct the pixel data
const floatArray = new Float32Array([ /* pixels */ ]);
const uintArray = new Uint8Array(floatArray.buffer);

// bind the pixel data to a WebGL texture
gl.texImage2D(
  gl.TEXTURE_2D,    // target
  0,                // mipmap level
  gl.RGBA,          // internal format: 4 color channels
  width,            // width of texture in pixels
  height,           // height of texture in pixels
  0,                // border: must be 0
  gl.RGBA,          // format: must be the same as internal format
  gl.UNSIGNED_BYTE, // type: 8 bits per channel
  uintArray,        // pixels
);
```

`rgbaToFloat` is designed to be consumed as a [GLSLify](https://github.com/glslify/glslify) module (though other methods may be used to copy the source code into your shader). To decode a texel in your shader code, pass the `vec4` representing the texel to the function `rgbaToFloat`. Note that because the function has to decode the float from its constituent bits, it needs to know whether the machine on which it's running uses [big-endian or little-endian representation](https://en.wikipedia.org/wiki/Endianness).

```glsl
// fragment shader

#pragma glslify: rgbaToFloat = require('glsl-rgba-to-float')

// does the machine use little-endian representation?
uniform bool littleEndian;

// the texture
uniform sampler2D texture;

// texture coordinates, passed from the vertex shader
varying vec2 textureCoords;

void main() {
  vec4 texelRGBA = texture2D(texture, textureCoords);
  float texelFloat = rgbaToFloat(texelRGBA, littleEndian);
  // use the decoded float for something wonderful...
}
```

Here's a simple way to compute endianness in JavaScript. Pass the result as a `uniform` variable to your shader.

```javascript
const littleEndian = (function machineIsLittleEndian() {
  const uint8Array = new Uint8Array([0xAA, 0xBB]);
  const uint16array = new Uint16Array(uint8Array.buffer);
  return uint16array[0] === 0xBBAA;
})();
```
