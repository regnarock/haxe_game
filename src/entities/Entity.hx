package entities;

import grid.HexCoord;

class Entity {
    public var coord:HexCoord;
    public var alive:Bool = true;
    var game:Game;

    public function new(game:Game, coord:HexCoord) {
        this.game = game;
        this.coord = coord;
    }

    public function update(dt:Float):Void {}

    public function destroy():Void {
        alive = false;
        game.removeEntity(this);
    }
}
