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

        var targetX = 0.0;
        var targetY = 0.0;

        if (tower.target != null) {
            var targetPos = getEnemyPosition(tower.target);
            targetX = targetPos.x;
            targetY = targetPos.y;
            // Add PI/2 to align triangle (points up at angle=0) with atan2 (0 = right)
            tower.facingAngle = Math.atan2(targetY - pos.y, targetX - pos.x) + Math.PI / 2;
        }

        var angle = tower.facingAngle;

        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        var v1x = 0.0;
        var v1y = -10.0;
        var v2x = -8.0;
        var v2y = 8.0;
        var v3x = 8.0;
        var v3y = 8.0;

        var r1x = v1x * cos - v1y * sin;
        var r1y = v1x * sin + v1y * cos;
        var r2x = v2x * cos - v2y * sin;
        var r2y = v2x * sin + v2y * cos;
        var r3x = v3x * cos - v3y * sin;
        var r3y = v3x * sin + v3y * cos;

        graphics.beginFill(Palette.TOWER);
        graphics.moveTo(pos.x + r1x, pos.y + r1y);
        graphics.lineTo(pos.x + r2x, pos.y + r2y);
        graphics.lineTo(pos.x + r3x, pos.y + r3y);
        graphics.lineTo(pos.x + r1x, pos.y + r1y);
        graphics.endFill();

        if (tower.target != null && tower.target.alive && tower.attackProgress > 0) {
            var progress = tower.attackProgress / Config.TOWER_KILL_TIME;
            var projX = pos.x + (targetX - pos.x) * progress;
            var projY = pos.y + (targetY - pos.y) * progress;

            // Draw short laser beam (line segment pointing toward target)
            var beamLength = 12.0;
            var dx = targetX - pos.x;
            var dy = targetY - pos.y;
            var dist = Math.sqrt(dx * dx + dy * dy);
            var nx = dx / dist;
            var ny = dy / dist;

            graphics.lineStyle(3, Palette.TOWER);
            graphics.moveTo(projX - nx * beamLength * 0.5, projY - ny * beamLength * 0.5);
            graphics.lineTo(projX + nx * beamLength * 0.5, projY + ny * beamLength * 0.5);
            graphics.lineStyle();
        }
    }

    function getEnemyPosition(enemy:Enemy):{x:Float, y:Float} {
        var currentPos = HexMath.cubeToPixel(enemy.coord);
        var x = currentPos.x;
        var y = currentPos.y;

        if (enemy.path != null && enemy.pathIndex < enemy.path.length - 1) {
            var nextPos = HexMath.cubeToPixel(enemy.path[enemy.pathIndex + 1]);
            x = currentPos.x + (nextPos.x - currentPos.x) * enemy.progress;
            y = currentPos.y + (nextPos.y - currentPos.y) * enemy.progress;
        }

        return {x: x, y: y};
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
        graphics.lineStyle(); // Clear lineStyle to prevent bleeding to other entities
    }

    public function drawBase(base:Base):Void {
        var pos = HexMath.cubeToPixel(base.coord);
        graphics.beginFill(Palette.BASE, 0.5 + base.glowIntensity * 0.5);
        graphics.drawCircle(pos.x, pos.y, 12);
        graphics.endFill();
    }
}
