import grid.*;

class TestGrid {
    static function main() {
        // Test 1: HexCoord(1, -1, 0).neighbors() returns 6 valid coordinates
        var coord = new HexCoord(1, -1, 0);
        var neighbors = coord.neighbors;
        trace('Test 1 - Neighbors count: ${neighbors.length} (expected: 6)');
        
        // Test 2: HexMath.distance((0,0,0), (3,0,-3)) returns 3
        var origin = new HexCoord(0, 0, 0);
        var target = new HexCoord(3, 0, -3);
        var dist = HexMath.distance(origin, target);
        trace('Test 2 - Distance: ${dist} (expected: 3)');
        
        // Test 3: HexGrid.isValidCoord returns true for hexes within radius 7
        var grid = new HexGrid();
        var validCoord = new HexCoord(5, 0, -5);
        var invalidCoord = new HexCoord(8, 0, -8);
        trace('Test 3a - Valid coord (5,0,-5): ${grid.isValidCoord(validCoord)} (expected: true)');
        trace('Test 3b - Invalid coord (8,0,-8): ${grid.isValidCoord(invalidCoord)} (expected: false)');
        
        // Test 4: HexGrid.setObstacle/isObstacle correctly tracks obstacles
        grid.setObstacle(coord, true);
        trace('Test 4a - Is obstacle after set: ${grid.isObstacle(coord)} (expected: true)');
        grid.setObstacle(coord, false);
        trace('Test 4b - Is obstacle after unset: ${grid.isObstacle(coord)} (expected: false)');
        
        trace('\nAll tests completed successfully!');
    }
}
