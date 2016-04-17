package dragonbones.objects;

import flash.geom.Point;

/** @private */
class DisplayData
{
public static inline var ARMATURE:String = "armature";
public static inline var IMAGE:String = "image";
public static inline var MESH:String = "mesh";

public var name:String;
public var slotName:String;
public var type:String;
public var transform:DBTransform;
public var pivot:Point;

public function new()
{
	transform = new DBTransform();
	pivot = new Point();
}

public function dispose():Void
{
	transform = null;
	pivot = null;
}
}