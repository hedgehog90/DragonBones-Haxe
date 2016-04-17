package dragonbones.objects;

/** @private */
class Frame
{
public var position:Int;
public var duration:Int;

public var action:String;
public var event:String;
public var sound:String;
public var curve:CurveData;

public function new()
{
	position = 0;
	duration = 0;
}

public function dispose():Void
{
}
}