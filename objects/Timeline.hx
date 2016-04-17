package dragonbones.objects;

import flash.Vector;

class Timeline
{
public var duration:Int;
public var scale:Float;

private var _frameList:Vector<Frame>;

public function new()
{
	_frameList = new Vector<Frame>(0, true);
	duration = 0;
	scale = 1;
}

public function dispose():Void
{
	var i:Int = _frameList.length;
	while(i --)
	{
	_frameList[i].dispose();
	}
	_frameList.fixed = false;
	_frameList.length = 0;
	_frameList = null;
}

public function addFrame(frame:Frame):Void
{
	if(!frame)
	{
	throw new ArgumentError();
	}
	
	if(_frameList.indexOf(frame) < 0)
	{
	_frameList.fixed = false;
	_frameList[_frameList.length] = frame;
	_frameList.fixed = true;
	}
	else
	{
	throw new ArgumentError();
	}
}

public var frameList(getFrameList, null):Vector;
 	private function getFrameList():Vector<Frame>
{
	return _frameList;
}
}