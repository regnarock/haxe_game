package grid;

// Cube coordinate system for hexagonal grid (q + r + s = 0).
// Abstract type provides compile-time type safety without class overhead for immutable value semantics.

typedef HexCoordData = {q:Int, r:Int, s:Int};

abstract HexCoord(HexCoordData) from HexCoordData to HexCoordData {
    public var q(get, never):Int;
    public var r(get, never):Int;
    public var s(get, never):Int;

    inline function get_q():Int return this.q;
    inline function get_r():Int return this.r;
    inline function get_s():Int return this.s;

    public inline function new(q:Int, r:Int, s:Int) {
        if (q + r + s != 0) {
            throw 'Invalid cube coordinates: q+r+s must equal 0';
        }
        this = {q: q, r: r, s: s};
    }

    @:op(A == B)
    public inline function equals(other:HexCoord):Bool {
        return this.q == other.q && this.r == other.r && this.s == other.s;
    }

    public var neighbors(get, never):Array<HexCoord>;
    function get_neighbors():Array<HexCoord> {
        return HexMath.getNeighbors(this);
    }

    public inline function toString():String return 'HexCoord(${this.q},${this.r},${this.s})';
}
