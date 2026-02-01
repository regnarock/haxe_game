package grid;

class HexMath {
    public static final DIRECTIONS:Array<HexCoord> = [
        new HexCoord(1, -1, 0),  new HexCoord(1, 0, -1),
        new HexCoord(0, 1, -1),  new HexCoord(-1, 1, 0),
        new HexCoord(-1, 0, 1),  new HexCoord(0, -1, 1)
    ];

    public static function distance(a:HexCoord, b:HexCoord):Int {
        return Std.int((Math.abs(a.q - b.q) + Math.abs(a.r - b.r) + Math.abs(a.s - b.s)) / 2);
    }

    public static function getNeighbors(coord:HexCoord):Array<HexCoord> {
        var result:Array<HexCoord> = [];
        for (dir in DIRECTIONS) {
            result.push(new HexCoord(coord.q + dir.q, coord.r + dir.r, coord.s + dir.s));
        }
        return result;
    }

    public static function cubeToPixel(coord:HexCoord):{ x:Float, y:Float } {
        var size = Config.HEX_SIZE;
        var x = size * (Math.sqrt(3) * coord.q + Math.sqrt(3) / 2 * coord.r) + Config.SCREEN_CENTER_X;
        var y = size * (3.0 / 2 * coord.r) + Config.SCREEN_CENTER_Y;
        return {x: x, y: y};
    }

    public static function pixelToCube(x:Float, y:Float):HexCoord {
        var size = Config.HEX_SIZE;
        var cx = x - Config.SCREEN_CENTER_X;
        var cy = y - Config.SCREEN_CENTER_Y;
        var q = (Math.sqrt(3) / 3 * cx - 1.0 / 3 * cy) / size;
        var r = (2.0 / 3 * cy) / size;
        return cubeRound(q, r, -q - r);
    }

    static function cubeRound(fq:Float, fr:Float, fs:Float):HexCoord {
        var q = Math.round(fq);
        var r = Math.round(fr);
        var s = Math.round(fs);
        var dq = Math.abs(q - fq);
        var dr = Math.abs(r - fr);
        var ds = Math.abs(s - fs);
        if (dq > dr && dq > ds) q = -r - s;
        else if (dr > ds) r = -q - s;
        else s = -q - r;
        return new HexCoord(Std.int(q), Std.int(r), Std.int(s));
    }

    public static inline function coordToKey(coord:HexCoord):String return '${coord.q},${coord.r},${coord.s}';
}
