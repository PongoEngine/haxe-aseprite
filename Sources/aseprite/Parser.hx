package aseprite;

import aseprite.Reader;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.zip.InflateImpl;

class Parser
{
    public static function parse(bytes :Bytes) : Aesprite
    {
        var reader = new Reader(bytes);
        var header = readHeader(reader);
        var frames = [for(i in 0...header.frames) readFrame(reader)];
        var spr = new Aesprite(header, frames);
        trace(spr);
        return spr;
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
            speed: speed,
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
        trace("Chunk length: " + length);

        return {
            bytesLength: bytesLength,
            numberOfChunksOld: numberOfChunksOld,
            frameDuration: frameDuration,
            numberOfChunksNew: numberOfChunksNew,
            chunks: [for(i in 0...length) getChunk(i, reader)]
        };
    }

    static function getChunk(index :Int, reader :Reader) : Chunk
    {
        var chunkSize = reader.getDWord();
        var chunkType :ChunkType = reader.getWord();
        trace("Chunk: " + (index+1));
        return switch chunkType {
            case CEL_CHUNK: readCel(reader);
            case CEL_EXTRA_CHUNK: throw "CEL_EXTRA_CHUNK";
            case COLOR_PROFILE_CHUNK: readColorProfile(reader);
            case FRAME_TAGS_CHUNK: throw "FRAME_TAGS_CHUNK";
            case LAYER_CHUNK: readLayer(reader);
            case OLD_PALETTE_CHUNK_A: readOldPaletteA(reader);
            case OLD_PALETTE_CHUNK_B: throw "OLD_PALETTE_CHUNK_B";
            case PALETTE_CHUNK: readPalette(reader);
            case PATH_CHUNK: throw "PATH_CHUNK";
            case SLICE_CHUNK: throw "SLICE_CHUNK";
            case USER_DATA_CHUNK: throw "USER_DATA_CHUNK";
            case _: throw ("CHUNK NOT FOUND: " + chunkType);
        }
    }

    static function readColorProfile(reader :Reader) : Chunk
    {
        var type :ColorProfileType = reader.getWord();
        var flags :Int = reader.getWord();
        var gamma :Float = reader.getFixed();
        reader.seek(8);

        trace("COMPLETED readColorProfile");
        return switch type {
            case ICC: throw "NOT READY";
            case _: COLOR_PROFILE(type, flags, gamma, null, null);
        }
    }

    static function readPalette(reader :Reader) : Chunk
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

        trace("COMPLETED readPalette");
        return PALETTE(paletteSize, firstColorIndex, lastColorIndex, colors);
    }

    static function readOldPaletteA(reader :Reader) : Chunk
    {
        var numberOfPackets = reader.getWord();
        var packets :Array<Packet> = [];
        
        for(i in 0...numberOfPackets) {
            var entriesToSkip = reader.getByte();
            var numberOfColors = reader.getByte();
            var colors = [for(i in 0...numberOfColors) RGB(reader.getByte(), reader.getByte(), reader.getByte())];
            packets.push({entriesToSkip:entriesToSkip, colors: colors});
        }

        trace("COMPLETED readOldPaletteA");
        return OLD_PALETTE_A(numberOfPackets, packets);
    }

    static function readLayer(reader :Reader) : Chunk
    {
        var flags :Int = reader.getWord();
        var type :Int = reader.getWord();
        var childLevel :Int = reader.getWord();
        var defaultWidth :Int = reader.getWord();
        var defaultHeight :Int = reader.getWord();
        var blendMode :Int = reader.getWord();
        var opacity :Int = reader.getByte();
        reader.seek(3);
        var name :String = reader.getString();
        return LAYER(flags, type, childLevel, defaultWidth, defaultHeight, blendMode, opacity, name);
    }

    static function readCel(reader :Reader) : Chunk
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
                var inflatedData = InflateImpl.run(reader.input, width*height);
                COMPRESSED_DATA(width, height, inflatedData);
            }
        }
        trace("COMPLETED readCel");
        return CEL(layerIndex, x, y, opacityLevel, celData);
    }
}

class Aesprite
{
    public var header :Header;
    public var frames :Array<Frame>;

    public function new(header :Header, frames :Array<Frame>) : Void
    {
        this.header = header;
        this.frames = frames;
    }
}

enum Chunk
{
    COLOR_PROFILE(type :ColorProfileType, flags :Int, gamma :Float, iccLength :Null<Int>, iccData :Null<Array<Int>>);
    PALETTE(paletteSize :Int, firstColorIndex :Int, lastColorIndex :Int, colors :Array<PaletteColor>);
    OLD_PALETTE_A(numberOfPackets :Int, packets :Array<Packet>);
    LAYER(flags :Int, type :Int, childLevel :Int, defaultWidth :Int, defaultHeight :Int, blendMode :Int, opacity :Int, name :String);
    CEL(layerIndex :Int, x :Int, y :Int, opacityLevel :Int, data :CelData);
}

enum CelData {
    RAW_DATA(width :Int, height :Int, pixels :Int);
    LINKED_DATA(linkedFramePosition :Int);
    COMPRESSED_DATA(width :Int, height :Int, inflatedData :haxe.io.Bytes);
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

typedef ChunkData =
{
    var size :Int;
    var type :ChunkType;
    var data :Array<Chunk>;
}

typedef Frame =
{
    var bytesLength :Int;
    var numberOfChunksOld :Int;
    var frameDuration :Int;
    var numberOfChunksNew :Int;
    var chunks :Array<Chunk>;
}

typedef Header =
{
    var fileSize :Int;
    var frames :Int;
    var width :Int;
    var height :Int;
    var colorDepth :ColorDepth;
    var flags :Int;
    var speed :Int;
    var transparentColor :Int;
    var numberOfColors :Int;
    var pixelWidth :Int;
    var pixelHeight :Int;
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