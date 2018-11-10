package aseprite;

import aseprite.Reader;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.zip.InflateImpl;

class Parser
{
    public static function parse(bytes :Bytes) : Aseprite
    {
        var reader = new Reader(bytes);
        var header = readHeader(reader);
        var frames = [for(i in 0...header.frames) readFrame(reader)];
        return new Aseprite(header, frames);
    }

    static function readHeader(reader :Reader) : Header
    {
        var fileSize :Int = reader.getDWord();
        var magicNumber :Int = reader.getWord();
        if(magicNumber != 0xA5E0) {
            throw "FILE NOT ASE";
        }
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

        return {
            fileSize: fileSize,
            frames: frames,
            width: width,
            height: height,
            colorDepth: colorDepth,
            flags: flags,
            transparentColor: transparentColor,
            numberOfColors: numberOfColors,
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight
        };
    }

    static function readFrame(reader :Reader) : Frame
    {
        var bytesLength :Int = reader.getDWord();
        var magicNumber :Int = reader.getWord();
        if(magicNumber != 0xF1FA) {
            throw "INCORRECT MAGIC NUMBER";
        }
        var numberOfChunksOld :Int = reader.getWord();
        var frameDuration :Int = reader.getWord();
        reader.seek(2);
        var numberOfChunksNew :Int = reader.getDWord();
        var length = numberOfChunksNew == 0 ? numberOfChunksOld : numberOfChunksNew;

        var frame = new Frame(frameDuration);

        for(i in 0...length) {
            getChunk(frame, reader);
        }

        return frame;
    }

    static function getChunk(frame :Frame, reader :Reader) : Void
    {
        var chunkSize = reader.getDWord();
        var chunkType :ChunkType = reader.getWord();
        switch chunkType {
            case CEL_CHUNK: {
                frame.cels.push(readCel(reader));
            }

            case CEL_EXTRA_CHUNK: throw "CEL_EXTRA_CHUNK";

            case COLOR_PROFILE_CHUNK: {
                if(frame.colorProfile != null) {
                    throw "frame profile is already set";
                }
                frame.colorProfile = readColorProfile(reader);
            }

            case FRAME_TAGS_CHUNK: {
                if(frame.frameTags != null) {
                    throw "frame tags are already set";
                }
                frame.frameTags = readFrameTags(reader);
            }

            case LAYER_CHUNK: {
                frame.layers.push(readLayer(reader));
            }

            case OLD_PALETTE_CHUNK_A: readOldPaletteA(reader);

            case OLD_PALETTE_CHUNK_B: throw "OLD_PALETTE_CHUNK_B";

            case PALETTE_CHUNK:{
                if(frame.palette != null) {
                    throw "frame palette is already set";
                }
                frame.palette = readPalette(reader);
            }

            case PATH_CHUNK: throw "PATH_CHUNK";

            case SLICE_CHUNK: throw "SLICE_CHUNK";

            case USER_DATA_CHUNK: throw "USER_DATA_CHUNK";

            case _: throw ("CHUNK NOT FOUND: " + chunkType);
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

    static function readCel(reader :Reader) : Cel
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
}

@:allow(aseprite.Parser)
class Frame
{
    public var duration (default, null) :Int;
    public var colorProfile (default, null):ColorProfile;
    public var palette (default, null):Palette;
    public var layers (default, null):Array<Layer>;
    public var cels (default, null):Array<Cel>;
    public var frameTags (default, null):Array<FrameTag>;

    public function new(duration :Int) : Void
    {
        this.duration = duration;
        this.layers = [];
        this.cels = [];
    }
}

typedef Header =
{
    var fileSize :Int;
    var frames :Int;
    var width :Int;
    var height :Int;
    var colorDepth :ColorDepth;
    var flags :Int;
    var transparentColor :Int;
    var numberOfColors :Int;
    var pixelWidth :Int;
    var pixelHeight :Int;
}

typedef FrameTag =
{
    var fromFrame :Int;
    var toFrame :Int;
    var direction :Direction;
    var colors :Array<Int>;
    var name :String;
}

typedef ColorProfile =
{
    var type :ColorProfileType;
    var flags :Int;
    var gamma :Float;
    var iccData :Array<Int>;
}

typedef Palette =
{
    var firstColorIndex :Int;
    var lastColorIndex :Int;
    var colors :Array<PaletteColor>;
}

typedef Layer =
{
    var flags :Int;
    var type :LayerType;
    var childLevel :Int;
    var blendMode :AseBlendmode;
    var opacity :Int;
    var name :String;
}

typedef Cel =
{
    var layerIndex :Int;
    var x :Int;
    var y :Int;
    var opacityLevel :Int;
    var data :CelData;
}

enum CelData {
    RAW_DATA(width :Int, height :Int, pixels :Int);
    LINKED_DATA(linkedFramePosition :Int);
    IMAGE_DATA(width :Int, height :Int, data :haxe.io.Bytes);
}

enum PaletteColor
{
    NAMED_RGBA(name :String, r :Int, g :Int, b :Int, a :Int);
    RGBA(r :Int, g :Int, b :Int, a :Int);
    RGB(r :Int, g :Int, b :Int);
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

@:enum
abstract ColorProfileType(Int) from Int
{
    var NO_COLOR_PROFILE = 0;
    var SRGB = 1;
    var ICC = 2;
}

@:enum
abstract ColorDepth(Int) from Int
{
    var DEPTH_INDEXED = 8;
    var DEPTH_GRAYSCALE = 16;
    var DEPTH_RGBA = 32;
}

@:enum 
abstract CelType(Int) from Int
{
    var RAW = 0;
    var LINKED = 1;
    var COMPRESSED_IMAGE = 2;
}

@:enum 
abstract Direction(Int) from Int
{
    var FORWARD = 0;
    var REVERSE = 1;
    var PING_PONG = 2;
}

@:enum
abstract LayerType(Int) from Int
{
    var NORMAL = 0;
    var GROUP = 1;
}

@:enum
abstract AseBlendmode(Int) from Int
{
    var NORMAL = 0;
    var NULTIPLY = 1;
    var SCREEN = 2;
    var OVERLAY = 3;
    var DARKEN = 4;
    var LIGHTEN = 5;
    var COLOR_DODGE = 6;
    var COLOR_BURN = 7;
    var HARD_LIGHT = 8;
    var SOFT_LIGHT = 9;
    var DIFFERENCE = 10;
    var EXCLUSION = 11;
    var HUE = 12;
    var SATURATION = 13;
    var COLOR = 14;
    var LUMINOSITY = 15;
    var ADDITION = 16;
    var SUBTRACT = 17;
    var DIVIDE = 18;
}