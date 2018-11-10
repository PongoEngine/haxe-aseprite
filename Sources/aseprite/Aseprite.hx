package aseprite;

import aseprite.Parser;

class Aseprite
{
    public var header :Header;
    public var frames :Array<Frame>;

    public function new(header :Header, frames :Array<Frame>) : Void
    {
        this.header = header;
        this.frames = frames;
    }
}