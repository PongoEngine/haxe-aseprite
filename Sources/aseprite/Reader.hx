package aseprite;

import kha.Blob;
import haxe.io.BytesInput;
import haxe.io.Encoding;

class Reader
{
    public var input :BytesInput;

    public function new(blob :Blob) : Void
    {
        this.input = new BytesInput(blob.bytes);
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

    public function getString() : String
    {
        return input.readString(getWord(), Encoding.UTF8);
    }

    public function getPixel() : Int
    {
        return throw "getPixel";
    }
}