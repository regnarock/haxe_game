package entities;

import grid.*;

class Tower extends Entity {
    public var range:Int;
    public var target:Enemy = null;
    public var attackProgress:Float = 0.0;
    public var facingAngle:Float = 0;

    public function new(game:Game, coord:HexCoord) {
        super(game, coord);
        this.range = Config.TOWER_RANGE;
    }

    override public function update(dt:Float):Void {
        if (target == null || !target.alive || HexMath.distance(coord, target.coord) > range) {
            target = acquireTarget();
            attackProgress = 0.0;
        }

        if (target != null && target.alive) {
            attackProgress += dt;
            if (attackProgress >= Config.TOWER_KILL_TIME) {
                target.takeDamage(Config.ENEMY_HP);
                target = null;
                attackProgress = 0.0;
            }
        }
    }

    function acquireTarget():Null<Enemy> {
        for (enemy in game.enemies) {
            if (!enemy.alive) continue;
            if (HexMath.distance(coord, enemy.coord) <= range) {
                return enemy;
            }
        }
        return null;
    }
}
