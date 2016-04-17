package dragonbones.core;

import flash.geom.ColorTransform;
import flash.geom.Matrix;

import dragonBones.objects.DBTransform;

public interface ISlotCacheGenerator extends ICacheUser
{
function get global():DBTransform;
function get globalTransformMatrix():Matrix;
function get colorChanged():Bool;
function get colorTransform():ColorTransform;
function get displayIndex():Int;
function get gotoAndPlay():String;
}