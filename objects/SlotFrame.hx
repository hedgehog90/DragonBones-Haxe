package dragonbones.objects;

import flash.geom.ColorTransform;
import flash.geom.Point;

/** @private */
final class SlotFrame extends Frame
{
//NaN:no tween, 10:auto tween, [-1, 0):ease in, 0:line easing, (0, 1]:ease out, (1, 2]:ease in out
public var tweenEasing:Float;
public var displayIndex:Int;
public var visible:Bool;
public var zOrder:Float;
public var color:ColorTransform;
public var gotoAndPlay:String;

public function new()
{
	super();
	
	tweenEasing = 10;
	displayIndex = 0;
	visible = true;
	zOrder = NaN;
}

override public function dispose():Void
{
	super.dispose();
	color = null;
}

public var colorChanged(getColorChanged, null):Bool;
 	private function getColorChanged():Bool
{
	if(color && (color.alphaMultiplier != 1 || color.alphaOffset != 0 || 
		color.blueMultiplier != 1 || color.blueOffset != 0 ||
		color.greenMultiplier != 1 || color.greenOffset != 0 ||
		color.redMultiplier != 1 || color.redOffset != 0))
	{
	return true;
	}
	return false;
}
}