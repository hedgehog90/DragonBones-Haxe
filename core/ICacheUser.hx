package dragonbones.core;

import dragonBones.cache.FrameCache;

public interface ICacheUser
{
function get name():String;
function set frameCache(cache:FrameCache):Void;

}