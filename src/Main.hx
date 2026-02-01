import grid.*;
import render.*;
import entities.*;
import input.*;

class Main extends hxd.App {
    var grid:HexGrid;
    var hexRenderer:HexRenderer;
    var entityRenderer:EntityRenderer;
    var uiRenderer:UIRenderer;
    var effectsRenderer:EffectsRenderer;
    var game:Game;
    var placementController:PlacementController;

    override function init() {
        s2d.scaleMode = Stretch(1920, 1080);
        engine.backgroundColor = Palette.BG_DARK;

        grid = new HexGrid();
        hexRenderer = new HexRenderer(s2d);
        hexRenderer.drawGrid(grid);

        entityRenderer = new EntityRenderer(s2d);
        uiRenderer = new UIRenderer(s2d);
        effectsRenderer = new EffectsRenderer(s2d);

        game = new Game(grid);
        game.effectsRenderer = effectsRenderer;
        var base = new Base(game);
        game.addEntity(base);

        placementController = new PlacementController(game, grid);

        s2d.addEventListener(onEvent);
    }

    function onEvent(event:hxd.Event):Void {
        if (game.firstPlay && event.kind == EPush) {
            game.firstPlay = false;
        }
        placementController.onMouseMove(event.relX, event.relY);
        if (event.kind == EPush && event.button == 0) placementController.onLeftClick();
        if (event.kind == EPush && event.button == 1) placementController.onRightClick();

        // R key to restart when game over
        if (event.kind == EKeyDown && event.keyCode == 82 && game.gameOver) {
            restart();
        }
    }

    function restart():Void {
        grid = new HexGrid();
        hexRenderer.drawGrid(grid);

        game = new Game(grid);
        game.effectsRenderer = effectsRenderer;
        var base = new Base(game);
        game.addEntity(base);

        placementController = new PlacementController(game, grid);
    }

    override function update(dt:Float) {
        game.update(dt);

        entityRenderer.clear();
        for (entity in game.entities) {
            if (!entity.alive) continue;
            if (Std.isOfType(entity, Enemy)) {
                entityRenderer.drawEnemy(cast entity);
            } else if (Std.isOfType(entity, Tower)) {
                entityRenderer.drawTower(cast entity);
            } else if (Std.isOfType(entity, SpawnPoint)) {
                entityRenderer.drawSpawn(cast entity);
            } else if (Std.isOfType(entity, Base)) {
                entityRenderer.drawBase(cast entity);
            }
        }

        effectsRenderer.update(dt);
        effectsRenderer.render();

        if (game.gameOver) {
            uiRenderer.drawGameOver(game.elapsedTime);
        } else {
            uiRenderer.drawEnergyBar(game.energy, Config.ENERGY_MAX);
            uiRenderer.drawFlowIndicator(
                game.countAliveEnemies() * Config.ENEMY_ENERGY_VALUE,
                game.entropy
            );
            uiRenderer.drawWarnings(game.energy);
            if (game.firstPlay) {
                uiRenderer.drawFirstPlayMessage();
            } else {
                uiRenderer.hideFirstPlayMessage();
            }

            if (placementController.mode != NONE && placementController.hoveredCoord != null) {
                var isValid = false;
                var cost = 0;
                if (placementController.mode == TOWER) {
                    cost = Config.TOWER_COST;
                    isValid = game.energy >= cost && Pathfinding.validatePlacement(grid, placementController.hoveredCoord);
                    for (spawn in game.spawns) {
                        if (spawn.coord == placementController.hoveredCoord && spawn.alive) {
                            isValid = false;
                            break;
                        }
                    }
                } else if (placementController.mode == SPAWN) {
                    cost = Config.SPAWN_COST;
                    isValid = game.energy >= cost && Pathfinding.validatePlacement(grid, placementController.hoveredCoord);
                    for (tower in game.towers) {
                        if (tower.coord == placementController.hoveredCoord && tower.alive) {
                            isValid = false;
                            break;
                        }
                    }
                }
                var hexPos = HexMath.cubeToPixel(placementController.hoveredCoord);
                uiRenderer.drawPlacementPreview(placementController.hoveredCoord, placementController.mode, isValid);
                uiRenderer.drawPlacementCost(cost, game.energy >= cost, hexPos);
            }
        }
    }

    static function main() {
        new Main();
    }
}
