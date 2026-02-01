package render;

import grid.*;
import h2d.Graphics;

class HexRenderer {
    var graphics:Graphics;

    public function new(parent:h2d.Object) {
        graphics = new Graphics(parent);
    }

    public function drawGrid(grid:HexGrid):Void {
        graphics.clear();
        graphics.lineStyle(1, Palette.GRID_LINE);

        for (q in -Config.GRID_RADIUS...Config.GRID_RADIUS + 1) {
            for (r in -Config.GRID_RADIUS...Config.GRID_RADIUS + 1) {
                var s = -q - r;
                var coord = new HexCoord(q, r, s);
                if (grid.isValidCoord(coord)) {
                    drawHexOutline(coord);
                }
            }
        }
    }

    function drawHexOutline(coord:HexCoord):Void {
        var pos = HexMath.cubeToPixel(coord);
        var size = Config.HEX_SIZE;
        var angle = Math.PI / 3;

        for (i in 0...6) {
            var a = angle * i + Math.PI / 6;
            var x = pos.x + size * Math.cos(a);
            var y = pos.y + size * Math.sin(a);
            if (i == 0) graphics.moveTo(x, y) else graphics.lineTo(x, y);
        }
        var closeX = pos.x + size * Math.cos(Math.PI / 6);
        var closeY = pos.y + size * Math.sin(Math.PI / 6);
        graphics.lineTo(closeX, closeY);
    }
}
