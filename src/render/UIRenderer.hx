package render;

import h2d.Text;
import h2d.Graphics;
import grid.*;
import input.PlacementController.PlacementMode;

class UIRenderer {
    var graphics:Graphics;
    var energyText:Text;
    var flowText:Text;
    var messageText:Text;
    var costText:Text;
    var restartText:Text;

    public function new(parent:h2d.Object) {
        graphics = new Graphics(parent);

        var font = hxd.res.DefaultFont.get();

        energyText = new Text(font, parent);
        energyText.textColor = Palette.UI_TEXT;
        energyText.smooth = false;
        energyText.setScale(2);

        flowText = new Text(font, parent);
        flowText.textColor = Palette.UI_TEXT;
        flowText.smooth = false;
        flowText.setScale(2);

        messageText = new Text(font, parent);
        messageText.textColor = Palette.UI_TEXT;
        messageText.smooth = false;
        messageText.setScale(2);

        costText = new Text(font, parent);
        costText.textColor = Palette.UI_TEXT;
        costText.smooth = false;
        costText.setScale(2);
        costText.visible = false;

        restartText = new Text(font, parent);
        restartText.textColor = Palette.UI_TEXT;
        restartText.smooth = false;
        restartText.setScale(2);
        restartText.visible = false;
    }

    public function drawEnergyBar(energy:Float, max:Float):Void {
        graphics.clear();
        costText.visible = false;

        var barWidth = 1920 - 20;
        graphics.lineStyle(2, Palette.UI_TEXT);
        graphics.drawRect(10, 10, barWidth, 20);

        var fillWidth = (energy / max) * barWidth;
        graphics.beginFill(0x00ff00);
        graphics.drawRect(10, 10, fillWidth, 20);
        graphics.endFill();

        energyText.text = 'Energy: ${Math.floor(energy)}/${Math.floor(max)}';
        energyText.x = 10;
        energyText.y = 35;
    }

    public function drawGameOver(survivalTime:Float):Void {
        messageText.text = 'GAME OVER\nSurvival: ${Math.floor(survivalTime)}s';
        messageText.x = 800;
        messageText.y = 500;
        messageText.textAlign = Center;

        restartText.text = 'Press R to restart';
        restartText.textAlign = Right;
        restartText.x = 1920 - 20;
        restartText.y = 1080 - 50;
        restartText.visible = true;
    }

    public function drawFlowIndicator(enemyRate:Float, entropyRate:Float):Void {
        var net = enemyRate - entropyRate;
        flowText.text = 'ENEMIES: +${Math.round(enemyRate * 10) / 10}/s\nENTROPY: -${Math.round(entropyRate * 10) / 10}/s\nNET: ${Math.round(net * 10) / 10}/s';
        flowText.x = 10;
        flowText.y = 60;
    }

    public function drawWarnings(energy:Float):Void {
        if (energy / Config.ENERGY_MAX <= 0.25) {
            graphics.beginFill(0xff0000, 0.2);
            graphics.drawRect(0, 0, 1920, 1080);
            graphics.endFill();
        }
    }

    public function drawFirstPlayMessage():Void {
        messageText.text = 'Danger is fuel! Place spawn points to generate energy.\nClick to dismiss.';
        messageText.x = 600;
        messageText.y = 300;
        messageText.textColor = Palette.UI_TEXT;
        messageText.visible = true;
    }

    public function hideFirstPlayMessage():Void {
        messageText.visible = false;
    }

    public function drawPlacementPreview(coord:HexCoord, mode:PlacementMode, valid:Bool):Void {
        var pos = HexMath.cubeToPixel(coord);
        graphics.lineStyle(2, valid ? 0x00ff00 : 0xff0000);

        switch (mode) {
            case TOWER:
                graphics.drawCircle(pos.x, pos.y, 10);
            case SPAWN:
                graphics.drawRect(pos.x - 10, pos.y - 10, 20, 20);
            case NONE:
        }

        if (!valid) {
            graphics.lineStyle(3, Palette.WARNING);
            graphics.moveTo(pos.x - 10, pos.y - 10);
            graphics.lineTo(pos.x + 10, pos.y + 10);
            graphics.moveTo(pos.x + 10, pos.y - 10);
            graphics.lineTo(pos.x - 10, pos.y + 10);
        }
    }

    public function drawPlacementCost(cost:Int, canAfford:Bool, hexPos:{x:Float, y:Float}):Void {
        costText.visible = true;
        costText.textColor = canAfford ? Palette.UI_TEXT : Palette.WARNING;
        costText.text = 'Cost: $cost';
        costText.x = hexPos.x + 25;
        costText.y = hexPos.y - 30;
    }
}
