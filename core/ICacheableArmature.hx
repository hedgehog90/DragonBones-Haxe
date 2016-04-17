package dragonbones.core;

public interface ICacheableArmature extends IArmature
{
function get enableCache():Bool;
function set enableCache(value:Bool):Void;

function get enableEventDispatch():Bool;
function set enableEventDispatch(value:Bool):Void;

function getSlotDic():Object;
}