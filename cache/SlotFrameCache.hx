package dragonbones.cache;

import flash.geom.ColorTransform;

class SlotFrameCache extends FrameCache
{
public var colorTransform:ColorTransform;
public var displayIndex:Int = -1;
public var gotoAndPlay:String;
//	public var zOrder:Int;
public function new()
{
	super();
}

//浅拷贝提高效率
override public function copy(frameCache:FrameCache):Void
{
	super.copy(frameCache);
	colorTransform = (frameCache as SlotFrameCache).colorTransform;
	displayIndex = (frameCache as SlotFrameCache).displayIndex;
	gotoAndPlay = (frameCache as SlotFrameCache).gotoAndPlay;
}

override public function clear():Void 
{
	super.clear();
	colorTransform = null;
	displayIndex = -1;
	gotoAndPlay = null;
}
}