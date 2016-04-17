package dragonbones.objects;

import flash.geom.Point;

public final class SlotTimeline extends Timeline
{
public var name:String;
public var transformed:Bool;

public var offset:Float;

public function SlotTimeline()
{
	super();
	offset = 0;
}

override public function dispose():Void
{
	super.dispose();
}
}