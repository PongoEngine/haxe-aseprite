package aseprite;

class Aseprite<Texture>
{
    public var header :Header;
    public var frames :Array<Frame<Texture>>;

    public function new(header :Header, frames :Array<Frame<Texture>>) : Void
    {
        this.header = header;
        this.frames = frames;
    }
}

class Header
{
    public var frames (default, null):Int;
    public var width (default, null):Int;
    public var height (default, null):Int;
    public var colorDepth (default, null):ColorDepth;
    public var flags (default, null):Int;
    public var transparentColor (default, null):Int;
    public var numberOfColors (default, null):Int;
    public var pixelWidth (default, null):Int;
    public var pixelHeight (default, null):Int;

    public function new(frames :Int, width :Int, height :Int, colorDepth :Int, flags :Int, transparentColor :Int, numberOfColors :Int, pixelWidth :Int, pixelHeight :Int) : Void
    {
        this.frames = frames;
        this.width = width;
        this.height = height;
        this.colorDepth = colorDepth;
        this.flags = flags;
        this.transparentColor = transparentColor;
        this.numberOfColors = numberOfColors;
        this.pixelWidth = pixelWidth;
        this.pixelHeight = pixelHeight;
    }
}

@:allow(aseprite.Parser)
class Frame<Texture>
{
    public var duration (default, null) :Float;
    public var colorProfile (default, null):ColorProfile;
    public var palette (default, null):Palette;
    public var layers (default, null):Array<Layer>;
    public var cels (default, null):Array<Cel<Texture>>;
    public var frameTags (default, null):Array<FrameTag>;

    public function new(duration :Float) : Void
    {
        this.duration = duration;
        this.layers = [];
        this.cels = [];
    }
}

typedef FrameTag =
{
    var fromFrame (default, null):Int;
    var toFrame (default, null):Int;
    var direction (default, null):Direction;
    var colors (default, null):Array<Int>;
    var name (default, null):String;
}

typedef ColorProfile =
{
    var type (default, null):ColorProfileType;
    var flags (default, null):Int;
    var gamma (default, null):Float;
    var iccData (default, null):Array<Int>;
}

typedef Palette =
{
    var firstColorIndex (default, null):Int;
    var lastColorIndex (default, null):Int;
    var colors (default, null):Array<PaletteColor>;
}

typedef Layer =
{
    var flags (default, null):Int;
    var type (default, null):LayerType;
    var childLevel (default, null):Int;
    var blendMode (default, null):AseBlendmode;
    var opacity (default, null):Int;
    var name (default, null):String;
}

typedef Cel<Texture> =
{
    var layerIndex (default, null):Int;
    var x (default, null):Int;
    var y (default, null):Int;
    var opacityLevel (default, null):Int;
    var data (default, null):CelData;
    @:optional var texture :Texture;
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