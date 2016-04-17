package dragonbones.cache;

import dragonBones.core.ICacheUser;

import flash.Vector;

class TimelineCache
{
public var name:String;
public var frameCacheList:Vector<FrameCache> = new Vector();
public var currentFrameCache:FrameCache;
public function new()
{
}

public function addFrame():Void
{
}
public function update(frameIndex:Int):Void
{
	currentFrameCache.copy(frameCacheList[frameIndex]);
}

public function bindCacheUser(cacheUser:ICacheUser):Void
{
	cacheUser.frameCache = currentFrameCache;
}
}