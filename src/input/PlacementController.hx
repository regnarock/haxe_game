package input;

import grid.*;

enum PlacementMode {
    NONE;
    TOWER;
    SPAWN;
}

class PlacementController {
    public var mode:PlacementMode = NONE;
    public var hoveredCoord:Null<HexCoord> = null;
    var game:Game;
    var grid:HexGrid;

    public function new(game:Game, grid:HexGrid) {
        this.game = game;
        this.grid = grid;
    }

    public function onMouseMove(x:Float, y:Float):Void {
        hoveredCoord = HexMath.pixelToCube(x, y);
        if (!grid.isValidCoord(hoveredCoord)) {
            hoveredCoord = null;
        }
    }

    public function onLeftClick():Void {
        handlePlacementClick(TOWER, SPAWN);
    }

    public function onRightClick():Void {
        handlePlacementClick(SPAWN, TOWER);
    }

    function handlePlacementClick(attemptMode:PlacementMode, toggleMode:PlacementMode):Void {
        if (mode == attemptMode && hoveredCoord != null) {
            // Place and keep mode active for multiple placements
            if (attemptMode == TOWER) game.placeTower(hoveredCoord) else game.placeSpawn(hoveredCoord);
        } else if (mode == toggleMode) {
            mode = NONE;
        } else if (mode == NONE) {
            mode = attemptMode;
        }
    }
}
