package dragonbones.cache;

import dragonBones.core.ISlotCacheGenerator;
import dragonBones.utils.ColorTransformUtil;

class SlotTimelineCache extends TimelineCache
{
public var cacheGenerator:ISlotCacheGenerator;
public function new()
{
	super();
}

override public function addFrame():Void
{
	var cache:SlotFrameCache = new SlotFrameCache();
	cache.globalTransform.copy(cacheGenerator.global);
	cache.globalTransformMatrix.copyFrom(cacheGenerator.globalTransformMatrix);
	if(cacheGenerator.colorChanged)
	{
	cache.colorTransform =  ColorTransformUtil.cloneColor(cacheGenerator.colorTransform);
	}
	cache.displayIndex = cacheGenerator.displayIndex;
	cache.gotoAndPlay = cacheGenerator.gotoAndPlay;
	frameCacheList.push(cache);
}
}