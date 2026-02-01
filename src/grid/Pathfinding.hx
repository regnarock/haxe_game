package grid;

// A* pathfinding on hex grid with grid invariant validation.
// Algorithm: A* with hex distance heuristic (admissible, guarantees optimal paths).
// Priority queue: sorted array sufficient for ~200-node grid (O(n) insert acceptable at this scale).
// Grid invariant: all non-obstacle hexes must reach origin (prevents softlock placements).

class Pathfinding {
    // Finds shortest path from start to goal avoiding obstacles. Returns null if no path exists.
    public static function findPath(grid:HexGrid, start:HexCoord, goal:HexCoord):Null<Array<HexCoord>> {
        if (!grid.isValidCoord(start) || !grid.isValidCoord(goal)) return null;
        if (grid.isObstacle(goal)) return null;

        if (start == goal) return [goal];

        var openSet:Array<{coord:HexCoord, f:Int}> = [{coord: start, f: 0}];
        var cameFrom:Map<String, HexCoord> = new Map();
        var gScore:Map<String, Int> = new Map();
        gScore.set(HexMath.coordToKey(start), 0);

        while (openSet.length > 0) {
            var current = openSet.shift().coord;

            if (current == goal) {
                return reconstructPath(cameFrom, current);
            }

            for (neighbor in HexMath.getNeighbors(current)) {
                if (!grid.isValidCoord(neighbor) || grid.isObstacle(neighbor)) continue;

                var tentativeG = gScore.get(HexMath.coordToKey(current)) + 1;
                var neighborKey = HexMath.coordToKey(neighbor);

                if (!gScore.exists(neighborKey) || tentativeG < gScore.get(neighborKey)) {
                    cameFrom.set(neighborKey, current);
                    gScore.set(neighborKey, tentativeG);
                    var fScore = tentativeG + HexMath.distance(neighbor, goal);

                    var inserted = false;
                    for (i in 0...openSet.length) {
                        if (fScore < openSet[i].f) {
                            openSet.insert(i, {coord: neighbor, f: fScore});
                            inserted = true;
                            break;
                        }
                    }
                    if (!inserted) openSet.push({coord: neighbor, f: fScore});
                }
            }
        }

        return null;
    }

    // Rebuilds path from goal to start using cameFrom backpointers.
    static function reconstructPath(cameFrom:Map<String, HexCoord>, current:HexCoord):Array<HexCoord> {
        var path:Array<HexCoord> = [current];
        var key = HexMath.coordToKey(current);
        while (cameFrom.exists(key)) {
            current = cameFrom.get(key);
            path.insert(0, current);
            key = HexMath.coordToKey(current);
        }
        return path;
    }

    // Tests if placing obstacle at coord preserves grid invariant (all hexes reach origin).
    // Try-finally pattern ensures obstacle removed even if validation throws.
    public static function validatePlacement(grid:HexGrid, coord:HexCoord):Bool {
        if (!grid.isValidCoord(coord)) return false;
        if (grid.isObstacle(coord)) return false;

        grid.setObstacle(coord, true);
        var isValid = false;
        try {
            isValid = allHexesReachOrigin(grid);
        } catch (e:Dynamic) {
            grid.setObstacle(coord, false);
            throw e;
        }
        grid.setObstacle(coord, false);
        return isValid;
    }

    // DFS from origin marks all reachable hexes. O(V+E) single pass more efficient than BFS-from-edges O(E*V).
    static function allHexesReachOrigin(grid:HexGrid):Bool {
        var origin = new HexCoord(0, 0, 0);
        var visited:Map<String, Bool> = new Map();
        var stack:Array<HexCoord> = [origin];

        while (stack.length > 0) {
            var current = stack.pop();
            var key = HexMath.coordToKey(current);
            if (visited.exists(key)) continue;
            visited.set(key, true);

            for (neighbor in HexMath.getNeighbors(current)) {
                if (!grid.isValidCoord(neighbor) || grid.isObstacle(neighbor)) continue;
                if (!visited.exists(HexMath.coordToKey(neighbor))) {
                    stack.push(neighbor);
                }
            }
        }

        for (q in -Config.GRID_RADIUS...Config.GRID_RADIUS + 1) {
            for (r in -Config.GRID_RADIUS...Config.GRID_RADIUS + 1) {
                var s = -q - r;
                var coord = new HexCoord(q, r, s);
                if (grid.isValidCoord(coord) && !grid.isObstacle(coord)) {
                    if (!visited.exists(HexMath.coordToKey(coord))) return false;
                }
            }
        }

        return true;
    }
}
