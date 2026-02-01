package render;

import grid.*;
import h2d.Text;

typedef DeathPop = {
    coord:HexCoord,
    value:Float,
    lifetime:Float,
    timestamp:Float,
    text:Text
}

class EffectsRenderer {
    var pops:Array<DeathPop> = [];
    var font:h2d.Font;
    var parent:h2d.Object;

    public function new(parent:h2d.Object) {
        this.parent = parent;
        this.font = hxd.res.DefaultFont.get();
    }

    public function addDeathPop(coord:HexCoord, energyValue:Float):Void {
        var now = haxe.Timer.stamp();
        var aggregated = false;

        for (pop in pops) {
            if (pop.coord == coord && (now - pop.timestamp) < 0.3) {
                pop.value += energyValue;
                pop.timestamp = now;
                aggregated = true;
                break;
            }
        }

        if (!aggregated) {
            if (pops.length >= 3) {
                var oldest = pops.shift();
                oldest.text.remove();
            }
            var text = new Text(font, parent);
            text.smooth = false;
            text.setScale(2);
            text.textAlign = Center;
            text.visible = false;
            pops.push({
                coord: coord,
                value: energyValue,
                lifetime: 0.0,
                timestamp: now,
                text: text
            });
        }
    }

    public function update(dt:Float):Void {
        for (pop in pops.copy()) {
            pop.lifetime += dt;
            if (pop.lifetime > 2.0) {
                pop.text.remove();
                pops.remove(pop);
            }
        }
    }

    public function render():Void {
        for (pop in pops) {
            var pos = HexMath.cubeToPixel(pop.coord);
            pop.text.text = '+${Math.round(pop.value * 10) / 10}';
            pop.text.x = pos.x;
            pop.text.y = pos.y - 20 - (pop.lifetime * 30);
            pop.text.textColor = 0x00ff00;
            pop.text.visible = true;
        }
    }
}
