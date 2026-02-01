package entities;

import grid.*;

// Enemy walks along path to base. Per-enemy path cache simplifies invalidation on obstacle changes.

class Enemy extends Entity {
    public var path:Array<HexCoord>;
    public var pathIndex:Int = 0;
    public var progress:Float = 0.0;
    public var hp:Float;

    public function new(game:Game, startCoord:HexCoord, path:Array<HexCoord>) {
        super(game, startCoord);
        this.path = path;
        this.hp = Config.ENEMY_HP;
    }

    override public function update(dt:Float):Void {
        if (path == null || path.length == 0) return;

        progress += Config.ENEMY_SPEED * dt;

        // while (not if): handles ENEMY_SPEED > 1.0 where enemy advances multiple hexes per frame
        while (progress >= 1.0 && pathIndex < path.length - 1) {
            progress -= 1.0;
            pathIndex++;
            coord = path[pathIndex];
        }

        if (pathIndex >= path.length - 1 && coord == new HexCoord(0, 0, 0)) {
            onReachBase();
        }
    }

    // BASE_HIT_PENALTY = 10 energy allows 5 hits before death at 50 starting energy (recovery tension without instant loss).
    function onReachBase():Void {
        game.energy -= Config.BASE_HIT_PENALTY;
        destroy();
    }

    public function takeDamage(amount:Float):Void {
        hp -= amount;
        if (hp <= 0) {
            game.effectsRenderer.addDeathPop(coord, Config.ENEMY_HP);
            destroy();
        }
    }
}
