package entities;

import grid.HexCoord;

class SpawnPoint extends Entity {
    public var spawnTimer:Float;
    public var spawnCount:Int = 0;

    public function new(game:Game, coord:HexCoord) {
        super(game, coord);
        this.spawnTimer = Config.SPAWN_INTERVAL;
    }

    override public function update(dt:Float):Void {
        if (spawnCount >= Config.SPAWN_COUNT_LIMIT) {
            destroy();
            return;
        }

        spawnTimer -= dt;

        if (spawnTimer <= 0) {
            game.spawnEnemy(coord);
            spawnCount++;
            spawnTimer = Config.SPAWN_INTERVAL;
        }
    }

    override public function destroy():Void {
        game.grid.setObstacle(coord, false);
        super.destroy();
    }
}
