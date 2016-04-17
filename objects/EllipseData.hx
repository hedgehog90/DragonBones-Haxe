package dragonbones.objects;

import flash.geom.Point;

public final class EllipseData implements IAreaData
{
public var name:String;

public var width:Float;
public var height:Float;
public var transform:DBTransform;
public var pivot:Point;

public function EllipseData()
{
	width = 0;
	height = 0;
	transform = new DBTransform();
	pivot = new Point();
}

public function dispose():Void
{
	transform = null;
	pivot = null;
}
}