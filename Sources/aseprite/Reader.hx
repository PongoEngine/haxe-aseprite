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

import haxe.io.BytesInput;
import haxe.io.Encoding;
import haxe.io.Bytes;

class Reader
{
    public var input :BytesInput;

    public function new(bytes :Bytes) : Void
    {
        this.input = new BytesInput(bytes);
        this.input.bigEndian = false;
    }

    public inline function getByte() : Int
    {
        return input.readByte();   
    }

    public inline function getWord() : Int
    {
        return input.readUInt16();   
    }

    public inline function getShort() : Int
    {
        return input.readInt16();   
    }

    public inline function getDWord() : Int
    {
        return input.readInt32();
    }

    public inline function getLong() : Int
    {
        return input.readInt32(); 
    }

    public inline function getFixed() : Float
    {
        return input.readFloat(); 
    }

    public function getBytes(n :Int) : Array<Int>
    {
        var bytes :Array<Int> = [];
        for(i in 0...n) {
            bytes.push(this.getByte());
        }
        return bytes;
    }

    public function seek(n :Int) : Void
    {
        for(i in 0...n) this.getByte();
    }

    public inline function getString() : String
    {
        return input.readString(getWord(), Encoding.UTF8);
    }

    public function getPixel() : Int
    {
        return throw "getPixel";
    }
}
