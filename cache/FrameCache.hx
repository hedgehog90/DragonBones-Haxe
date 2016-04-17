package dragonbones.cache;

import flash.geom.Matrix;

import dragonBones.objects.DBTransform;

class FrameCache
{
private static inline var ORIGIN_TRAMSFORM:DBTransform = new DBTransform();
private static inline var ORIGIN_MATRIX:Matrix = new Matrix();

public var globalTransform:DBTransform = new DBTransform();
public var globalTransformMatrix:Matrix = new Matrix();
public function new()
{
}

//浅拷贝提高效率
public function copy(frameCache:FrameCache):Void
{
	globalTransform = frameCache.globalTransform;
	globalTransformMatrix = frameCache.globalTransformMatrix;
}

public function clear():Void
{
	globalTransform = ORIGIN_TRAMSFORM;
	globalTransformMatrix = ORIGIN_MATRIX;
}
}