package grid;

class HexGrid {
    var obstacles:Map<String, Bool> = new Map();

    public function new() {}

    public function isValidCoord(coord:HexCoord):Bool {
        return HexMath.distance(coord, new HexCoord(0, 0, 0)) <= Config.GRID_RADIUS;
    }

    public function setObstacle(coord:HexCoord, isObstacle:Bool):Void {
        var key = HexMath.coordToKey(coord);
        if (isObstacle) {
            obstacles.set(key, true);
        } else {
            obstacles.remove(key);
        }
    }

    public function isObstacle(coord:HexCoord):Bool {
        return obstacles.exists(HexMath.coordToKey(coord));
    }
}
