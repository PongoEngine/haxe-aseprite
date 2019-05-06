# haxe-aseprite
Haxe parser for .ase and .aseprite files.

haxe-aseprite was created for the GitHub GameOff. I've tested it for my needs however I would love for this to be feature complete. If you have access to aseprite files that break the parser send them my way!

The goal of this parser is to be concice, framework agnostic, and easy to use.

## Example Usage
```haxe
function createTexture(bytes :Bytes, width :Int, height :Int, colorDepth :ColorDepth) {
    return Texture.fromBytes(bytes, width, height, colorDepth);
}

/**
 * The Parser.parse has two parameters. The first is expecting a 
 * bytes representation of an Aseprite file. The second expects a callback
 * function that will create a texture for your specific framework.
 */
var file = Parser.parse(assets.getFile("animation.aseprite").toBytes(), createTexture);
```

Chunk types tested -

- [x] OLD_PALETTE_CHUNK_A
- [ ] OLD_PALETTE_CHUNK_B
- [x] LAYER_CHUNK
- [x] CEL_CHUNK
- [ ] CEL_EXTRA_CHUNK
- [x] COLOR_PROFILE_CHUNK
- [ ] MASK_CHUNK
- [ ] PATH_CHUNK
- [x] FRAME_TAGS_CHUNK
- [x] PALETTE_CHUNK
- [ ] USER_DATA_CHUNK
- [ ] SLICE_CHUNK
