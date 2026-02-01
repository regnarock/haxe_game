package entities;

import grid.HexCoord;

class Base extends Entity {
    public var glowIntensity:Float = 0.0;

    public function new(game:Game) {
        super(game, new HexCoord(0, 0, 0));
    }

    override public function update(dt:Float):Void {
        glowIntensity = 0.5 + 0.5 * Math.sin(haxe.Timer.stamp() * 2);
    }
}
