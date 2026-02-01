import entities.*;
import grid.*;
import render.EffectsRenderer;

class Game {
    public var entities:Array<Entity> = [];
    public var enemies:Array<Enemy> = [];
    public var towers:Array<Tower> = [];
    public var spawns:Array<SpawnPoint> = [];
    public var grid:HexGrid;
    public var energy:Float;
    public var entropy:Float;
    public var elapsedTime:Float = 0.0;
    public var gameOver:Bool = false;
    public var firstPlay:Bool = true;
    public var showTowerTip:Bool = false;
    public var effectsRenderer:EffectsRenderer;
    var addQueue:Array<Entity> = [];
    var removeQueue:Array<Entity> = [];

    public function new(grid:HexGrid) {
        this.grid = grid;
        this.energy = Config.ENERGY_START;
        this.entropy = Config.ENTROPY_BASE;
    }

    // Typed arrays updated immediately (targeting needs current state); entities array deferred (prevents concurrent modification during iteration)
    public function addEntity(entity:Entity):Void {
        addQueue.push(entity);
        if (Std.isOfType(entity, Enemy)) {
            enemies.push(cast entity);
        }
        if (Std.isOfType(entity, Tower)) {
            towers.push(cast entity);
        }
        if (Std.isOfType(entity, SpawnPoint)) {
            spawns.push(cast entity);
        }
    }

    public function removeEntity(entity:Entity):Void {
        removeQueue.push(entity);
        if (Std.isOfType(entity, Enemy)) {
            enemies.remove(cast entity);
        }
        if (Std.isOfType(entity, Tower)) {
            towers.remove(cast entity);
        }
        if (Std.isOfType(entity, SpawnPoint)) {
            spawns.remove(cast entity);
        }
    }

    public function spawnEnemy(coord:HexCoord):Void {
        var goal = new HexCoord(0, 0, 0);
        var path = Pathfinding.findPath(grid, coord, goal);
        if (path != null) {
            var enemy = new Enemy(this, coord, path);
            addEntity(enemy);
        }
    }

    public function placeTower(coord:HexCoord):Bool {
        for (spawn in spawns) {
            if (spawn.coord == coord && spawn.alive) return false;
        }
        var placed = tryPlaceObstacle(coord, Config.TOWER_COST, () -> new Tower(this, coord));
        if (placed) showTowerTip = false;
        return placed;
    }

    public function placeSpawn(coord:HexCoord):Bool {
        for (tower in towers) {
            if (tower.coord == coord && tower.alive) return false;
        }
        var isFirst = spawns.length == 0;
        var placed = tryPlaceObstacle(coord, Config.SPAWN_COST, () -> new SpawnPoint(this, coord));
        if (placed && isFirst) showTowerTip = true;
        return placed;
    }

    function tryPlaceObstacle(coord:HexCoord, cost:Int, entityFactory:Void->Entity):Bool {
        if (energy < cost) return false;
        if (coord.q == 0 && coord.r == 0 && coord.s == 0) return false; // Can't place on base
        if (!Pathfinding.validatePlacement(grid, coord)) return false;

        energy -= cost;
        grid.setObstacle(coord, true);
        var entity = entityFactory();
        addEntity(entity);

        recalculateEnemyPaths();
        return true;
    }

    function recalculateEnemyPaths():Void {
        var goal = new HexCoord(0, 0, 0);
        for (enemy in enemies) {
            if (!enemy.alive) continue;
            enemy.path = Pathfinding.findPath(grid, enemy.coord, goal);
            enemy.pathIndex = 0;
            // Don't reset progress - preserves visual interpolation position
        }
    }

    public function update(dt:Float):Void {
        if (gameOver) return;

        elapsedTime += dt;
        entropy = Config.ENTROPY_BASE + (elapsedTime / 10.0) * Config.ENTROPY_GROWTH;

        for (entity in entities) {
            if (entity.alive) {
                entity.update(dt);
            }
        }
        processQueues();

        updateEnergy(dt);
    }

    function processQueues():Void {
        for (entity in addQueue) {
            entities.push(entity);
        }
        for (entity in removeQueue) {
            entities.remove(entity);
        }
        addQueue = [];
        removeQueue = [];
    }

    public function countAliveEnemies():Int {
        var count = 0;
        for (enemy in enemies) {
            if (enemy.alive) count++;
        }
        return count;
    }

    function updateEnergy(dt:Float):Void {
        var aliveEnemies = countAliveEnemies();
        var delta = (aliveEnemies * Config.ENEMY_ENERGY_VALUE) - entropy;
        energy += delta * dt;

        if (energy <= 0) {
            energy = 0;
            gameOver = true;
        }
        // Hard cap (not just display cap) forces spending rather than hoarding energy. Players risk waste if cap reached, maintaining tension.
        if (energy > Config.ENERGY_MAX) {
            energy = Config.ENERGY_MAX;
        }
    }
}
