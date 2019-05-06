/*
 * Copyright (c) 2019 Jeremy Meltingtallow
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
 * Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
 * AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH
 * THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

package aseprite;

@:allow(aseprite.Parser)
class Aseprite<Texture>
{
    public var width (default, null):Int;
    public var height (default, null):Int;
    public var colorDepth (default, null):ColorDepth;
    public var transparentColor (default, null):Int;
    public var numberOfColors (default, null):Int;
    public var pixelWidth (default, null):Int;
    public var pixelHeight (default, null):Int;
    public var colorProfile (default, null):ColorProfile;
    public var palette (default, null):Palette;
    public var frames :Array<Frame<Texture>>;
    public var frameTags (default, null):Array<FrameTag>;
    public var layers (default, null):Array<Layer>;
    public var hasValidOpacity (default, null):Bool;

    public function new(width :Int, height :Int, colorDepth :Int, transparentColor :Int, numberOfColors :Int, pixelWidth :Int, pixelHeight :Int, hasValidOpacity :Bool) : Void
    {
        this.width = width;
        this.height = height;
        this.colorDepth = colorDepth;
        this.transparentColor = transparentColor;
        this.numberOfColors = numberOfColors;
        this.pixelWidth = pixelWidth;
        this.pixelHeight = pixelHeight;
        this.frames = [];
        this.layers = [];
        this.hasValidOpacity = hasValidOpacity;
    }
}

class Frame<Texture>
{
    public var duration (default, null) :Float;
    public var cels (default, null):Array<Cel<Texture>>;

    public function new(duration :Float) : Void
    {
        this.duration = duration;
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
    var useFixedGamma (default, null):Bool;
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
    var type (default, null):LayerType;
    var childLevel (default, null):Int;
    var blendMode (default, null):AseBlendmode;
    var opacity (default, null):Float;
    var name (default, null):String;
    var visible (default, null):Bool;
}

typedef Cel<Texture> =
{
    var layerIndex (default, null):Int;
    var x (default, null):Int;
    var y (default, null):Int;
    var opacityLevel (default, null):Int;
    var data (default, null):CelData<Texture>;
    @:optional var texture :Texture;
}

enum CelData<Texture> {
    RAW_DATA(width :Int, height :Int, pixels :Int);
    LINKED_DATA(linkedFramePosition :Int);
    IMAGE_DATA(width :Int, height :Int, texture :Texture);
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
