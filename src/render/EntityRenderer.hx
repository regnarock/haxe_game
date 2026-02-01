package render;

import entities.*;
import grid.HexMath;
import h2d.Graphics;

class EntityRenderer {
    var graphics:Graphics;

    public function new(parent:h2d.Object) {
        graphics = new Graphics(parent);
    }

    public function clear():Void {
        graphics.clear();
    }

    public function drawEnemy(enemy:Enemy):Void {
        var currentPos = HexMath.cubeToPixel(enemy.coord);
        var x = currentPos.x;
        var y = currentPos.y;

        // Interpolate position between current and next hex
        if (enemy.path != null && enemy.pathIndex < enemy.path.length - 1) {
            var nextPos = HexMath.cubeToPixel(enemy.path[enemy.pathIndex + 1]);
            x = currentPos.x + (nextPos.x - currentPos.x) * enemy.progress;
            y = currentPos.y + (nextPos.y - currentPos.y) * enemy.progress;
        }

        graphics.beginFill(Palette.ENEMY);
        graphics.drawCircle(x, y, 8);
        graphics.endFill();
    }

    public function drawTower(tower:Tower):Void {
        var pos = HexMath.cubeToPixel(tower.coord);
        graphics.beginFill(Palette.TOWER);
        graphics.moveTo(pos.x, pos.y - 10);
        graphics.lineTo(pos.x - 8, pos.y + 8);
        graphics.lineTo(pos.x + 8, pos.y + 8);
        graphics.lineTo(pos.x, pos.y - 10);
        graphics.endFill();
    }

    public function drawSpawn(spawn:SpawnPoint):Void {
        var pos = HexMath.cubeToPixel(spawn.coord);
        graphics.lineStyle(2, Palette.SPAWN);
        var size = Config.HEX_SIZE * 0.8;
        for (i in 0...6) {
            var angle = Math.PI / 3 * i + Math.PI / 6;
            var x = pos.x + size * Math.cos(angle);
            var y = pos.y + size * Math.sin(angle);
            if (i == 0) graphics.moveTo(x, y) else graphics.lineTo(x, y);
        }
        var closeX = pos.x + size * Math.cos(Math.PI / 6);
        var closeY = pos.y + size * Math.sin(Math.PI / 6);
        graphics.lineTo(closeX, closeY);
    }

    public function drawBase(base:Base):Void {
        var pos = HexMath.cubeToPixel(base.coord);
        graphics.beginFill(Palette.BASE, 0.5 + base.glowIntensity * 0.5);
        graphics.drawCircle(pos.x, pos.y, 12);
        graphics.endFill();
    }
}
