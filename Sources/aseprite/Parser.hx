package aseprite;

import aseprite.Reader;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.zip.InflateImpl;
import aseprite.Aseprite;

class Parser
{
    public static function parse<Texture>(bytes :Bytes) : Aseprite<Texture>
    {
        var reader = new Reader(bytes);

        var fileSize :Int = reader.getDWord();
        var magicNumber :Int = reader.getWord();
        assert(magicNumber == 0xA5E0, "FILE NOT ASE");
        var frames :Int = reader.getWord();
        var width :Int = reader.getWord();
        var height :Int = reader.getWord();
        var colorDepth :Int = reader.getWord();
        var flags :Int = reader.getDWord();
        var speed :Int = reader.getWord();
        var zero1 :Int = reader.getDWord();
        var zero2 :Int = reader.getDWord();
        var transparentColor :Int = reader.getByte();
        reader.seek(3);
        var numberOfColors :Int = reader.getWord();
        var pixelWidth :Int = reader.getByte();
        var pixelHeight :Int = reader.getByte();
        reader.seek(92);

        var sprite = new Aseprite(width, height, colorDepth, transparentColor, numberOfColors, pixelWidth, pixelHeight, flags);
        for(i in 0...frames) {
            sprite.frames.push(readFrame(sprite, reader));
        }
        return sprite;
    }

    static function readFrame<Texture>(sprite :Aseprite<Texture>, reader :Reader) : Frame<Texture>
    {
        var bytesLength :Int = reader.getDWord();
        var magicNumber :Int = reader.getWord();
        assert(magicNumber == 0xF1FA, "INCORRECT MAGIC NUMBER");
        var numberOfChunksOld :Int = reader.getWord();
        var frameDuration :Int = reader.getWord();
        reader.seek(2);
        var numberOfChunksNew :Int = reader.getDWord();
        var length = numberOfChunksNew == 0 ? numberOfChunksOld : numberOfChunksNew;

        var frame = new Frame(frameDuration/1000);

        for(i in 0...length) {
            getChunk(sprite, frame, reader);
        }

        return frame;
    }

    static function getChunk<Texture>(sprite :Aseprite<Texture>, frame :Frame<Texture>, reader :Reader) : Void
    {
        var chunkSize = reader.getDWord();
        var chunkType :ChunkType = reader.getWord();
        switch chunkType {
            case CEL_CHUNK:
                frame.cels.push(readCel(reader));

            case CEL_EXTRA_CHUNK: 
                assert(false, "CEL_EXTRA_CHUNK");

            case COLOR_PROFILE_CHUNK:
                assert(sprite.colorProfile == null, "color profile is already set");
                sprite.colorProfile = readColorProfile(reader);

            case FRAME_TAGS_CHUNK:
                assert(sprite.frameTags == null, "frame tags are already set");
                sprite.frameTags = readFrameTags(reader);

            case LAYER_CHUNK:
                sprite.layers.push(readLayer(reader));

            case OLD_PALETTE_CHUNK_A: 
                readOldPaletteA(reader);

            case OLD_PALETTE_CHUNK_B: 
                assert(false, "OLD_PALETTE_CHUNK_B");

            case PALETTE_CHUNK:
                assert(sprite.palette == null, "palette is already set");
                sprite.palette = readPalette(reader);

            case PATH_CHUNK: 
                assert(false, "PATH_CHUNK");

            case SLICE_CHUNK: 
                assert(false, "SLICE_CHUNK");

            case USER_DATA_CHUNK: 
                assert(false, "USER_DATA_CHUNK");

            case _: 
                assert(false, "CHUNK NOT FOUND: " + chunkType);
        }
    }

    static function readColorProfile(reader :Reader) : ColorProfile
    {
        var type :ColorProfileType = reader.getWord();
        var flags :Int = reader.getWord();
        var gamma :Float = reader.getFixed();
        reader.seek(8);

        return switch type {
            case ICC: {
                var length = reader.getWord();
                {type:type, flags:flags, gamma:gamma, iccData: reader.getBytes(length)};
            }
            case _: {type:type, flags:flags, gamma:gamma, iccData: null};
        }
    }

    static function readPalette(reader :Reader) : Palette
    {
        var paletteSize = reader.getDWord();
        var firstColorIndex = reader.getDWord();
        var lastColorIndex = reader.getDWord();
        reader.seek(8);
        var colors :Array<PaletteColor> = [];
        for(i in 0...paletteSize) {
            var hasName = reader.getWord() == 1;
            var r :Int = reader.getByte();
            var g :Int = reader.getByte();
            var b :Int = reader.getByte();
            var a :Int = reader.getByte();
            var color = hasName
                ? NAMED_RGBA(reader.getString(), r, g, b, a)
                : RGBA(r, g, b, a);
            colors.push(color);
        }

        return {firstColorIndex:firstColorIndex, lastColorIndex:lastColorIndex, colors:colors};
    }

    static function readOldPaletteA(reader :Reader) : Void
    {
        var numberOfPackets = reader.getWord();
        var packets :Array<Packet> = [];
        
        for(i in 0...numberOfPackets) {
            var entriesToSkip = reader.getByte();
            var numberOfColors = reader.getByte();
            var colors = [for(i in 0...numberOfColors) RGB(reader.getByte(), reader.getByte(), reader.getByte())];
            packets.push({entriesToSkip:entriesToSkip, colors: colors});
        }
    }

    static function readLayer(reader :Reader) : Layer
    {
        var flags :Int = reader.getWord();
        var type :LayerType = reader.getWord();
        var childLevel :Int = reader.getWord();
        var defaultWidth :Int = reader.getWord();
        var defaultHeight :Int = reader.getWord();
        var blendMode :AseBlendmode = reader.getWord();
        var opacity :Int = reader.getByte();
        reader.seek(3);
        var name :String = reader.getString();

        return {flags:flags, type:type, childLevel:childLevel, blendMode:blendMode, opacity:opacity, name:name};
    }

    static function readCel<Texture>(reader :Reader) : Cel<Texture>
    {
        var layerIndex :Int = reader.getWord();
        var x :Int = reader.getShort();
        var y :Int = reader.getShort();
        var opacityLevel = reader.getByte();
        var celType :CelType = reader.getWord();
        reader.seek(7);
        var celData = switch celType {
            case RAW: {
                var width = reader.getWord();
                var height = reader.getWord();
                var pixels = throw "RAW pixels are not ready yet!";
                RAW_DATA(width, height, pixels);
            }
            case LINKED: {
                var linkedFramePosition = reader.getWord();
                LINKED_DATA(linkedFramePosition);
            }
            case COMPRESSED_IMAGE: {
                var width = reader.getWord();
                var height = reader.getWord();
                var data = InflateImpl.run(reader.input, width*height);
                IMAGE_DATA(width, height, data);
            }
        }
        return {layerIndex:layerIndex, x:x, y:y, opacityLevel:opacityLevel, data:celData};
    }

    static function readFrameTags(reader :Reader) : Array<FrameTag>
    {
        var numberOfTags :Int = reader.getWord();
        reader.seek(8);
        var frameTags :Array<FrameTag> = [];
        for(i in 0...numberOfTags) {
            var fromFrame = reader.getWord();
            var toFrame = reader.getWord();
            var direction :Direction = reader.getByte();
            reader.seek(8);
            var colors = reader.getBytes(3);
            reader.seek(1);
            var name = reader.getString();

            frameTags.push({
                fromFrame: fromFrame,
                toFrame: toFrame,
                direction: direction,
                colors: colors,
                name: name
            });
        }

        return frameTags;
    }

    static function assert(that :Bool, msg :String) : Void
    {
        if(!that) throw msg;
    }
}

typedef Packet =
{
    var entriesToSkip :Int;
    var colors :Array<PaletteColor>;
}

@:enum
abstract ChunkType(Int) from Int
{
    var OLD_PALETTE_CHUNK_A = 0x0004;
    var OLD_PALETTE_CHUNK_B = 0x0011;
    var LAYER_CHUNK = 0x2004;
    var CEL_CHUNK = 0x2005;
    var CEL_EXTRA_CHUNK = 0x2006;
    var COLOR_PROFILE_CHUNK = 0x2007;
    var MASK_CHUNK = 0x2016;
    var PATH_CHUNK = 0x2017;
    var FRAME_TAGS_CHUNK = 0x2018;
    var PALETTE_CHUNK = 0x2019;
    var USER_DATA_CHUNK = 0x2020;
    var SLICE_CHUNK = 0x2022;
}