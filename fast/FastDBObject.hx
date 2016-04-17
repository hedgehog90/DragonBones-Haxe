package dragonbones.fast;

import dragonBones.objects.ParentTransformObject;
import flash.geom.Matrix;

import dragonBones.cache.FrameCache;
import dragonBones.core.DBObject;
import dragonBones.core.dragonBones_internal;
import dragonBones.objects.DBTransform;
import dragonBones.utils.TransformUtil;

use namespace dragonBones_internal;


class FastDBObject
{
private var _name:String;

/**
 * An object that can contain any user extra data.
 */
public var userData:Object;

/**
 * 
 */
public var inheritRotation:Bool;

/**
 * 
 */
public var inheritScale:Bool;

/**
 * 
 */
public var inheritTranslation:Bool;



/** @private */
dragonBones_private var _global:DBTransform;
/** @private */
dragonBones_private var _globalTransformMatrix:Matrix;

/** @private */
dragonBones_private var _globalBackup:DBTransform;
/** @private */
dragonBones_private var _globalTransformMatrixBackup:Matrix;

dragonBones_internal static var _tempParentGlobalTransform:DBTransform = new DBTransform();

dragonBones_private var _frameCache:FrameCache;

/** @private */
dragonBones_private function updateByCache():Void
{
	_global = _frameCache.globalTransform;
	_globalTransformMatrix = _frameCache.globalTransformMatrix;
}

/** @private */
dragonBones_private function switchTransformToBackup():Void
{
	if(!_globalBackup)
	{
	_globalBackup = new DBTransform();
	_globalTransformMatrixBackup = new Matrix();
	}
	_global = _globalBackup;
	_globalTransformMatrix = _globalTransformMatrixBackup;
}

/**
 * The armature this DBObject instance belongs to.
 */
public var armature:FastArmature;

/** @private */
private var _origin:DBTransform;

/** @private */
private var _visible:Bool;

/** @private */
dragonBones_private var _parent:FastBone;

/** @private */
dragonBones_private function setParent(value:FastBone):Void
{
	_parent = value;
}

public function new()
{
	_globalTransformMatrix = new Matrix();
	
	_global = new DBTransform();
	_origin = new DBTransform();
	
	_visible = true;
	
	armature = null;
	_parent = null;
	
	userData = null;
	
	this.inheritRotation = true;
	this.inheritScale = true;
	this.inheritTranslation = true;
}

/**
 * Cleans up any resources used by this DBObject instance.
 */
public function dispose():Void
{
	userData = null;
	
	_globalTransformMatrix = null;
	_global = null;
	_origin = null;
	
	armature = null;
	_parent = null;
}

private function calculateParentTransform():ParentTransformObject
{
	if(this.parent && (this.inheritTranslation || this.inheritRotation || this.inheritScale))
	{
	var parentGlobalTransform:DBTransform = this._parent._global;
	var parentGlobalTransformMatrix:Matrix = this._parent._globalTransformMatrix;
	/*
	if(	!this.inheritTranslation && (parentGlobalTransform.x != 0 || parentGlobalTransform.y != 0) ||
		!this.inheritRotation && (parentGlobalTransform.skewX != 0 || parentGlobalTransform.skewY != 0) ||
		!this.inheritScale && (parentGlobalTransform.scaleX != 1 || parentGlobalTransform.scaleY != 1))
	{
		parentGlobalTransform = FastDBObject._tempParentGlobalTransform;
		parentGlobalTransform.copy(this._parent._global);
		if(!this.inheritTranslation)
		{
		parentGlobalTransform.x = 0;
		parentGlobalTransform.y = 0;
		}
		if(!this.inheritScale)
		{
		parentGlobalTransform.scaleX = 1;
		parentGlobalTransform.scaleY = 1;
		}
		if(!this.inheritRotation)
		{
		parentGlobalTransform.skewX = 0;
		parentGlobalTransform.skewY = 0;
		}
		
		parentGlobalTransformMatrix = DBObject._tempParentGlobalTransformMatrix;
		TransformUtil.transformToMatrix(parentGlobalTransform, parentGlobalTransformMatrix);
	}
	*/
	return ParentTransformObject.create().setTo(parentGlobalTransform,parentGlobalTransformMatrix);
	}
	TransformUtil.transformToMatrix(_global, _globalTransformMatrix);
	return null;
}

private function updateGlobal():ParentTransformObject
{
	calculateRelativeParentTransform();
	var output:ParentTransformObject = calculateParentTransform();
	if(output != null)
	{
	//计算父骨头绝对坐标
	var parentMatrix:Matrix = output.parentGlobalTransformMatrix;
	var parentGlobalTransform:DBTransform = output.parentGlobalTransform;
	//计算绝对坐标
	var x:Float = _global.x;
	var y:Float = _global.y;
	
	_global.x = parentMatrix.a * x + parentMatrix.c * y + parentMatrix.tx;
	_global.y = parentMatrix.d * y + parentMatrix.b * x + parentMatrix.ty;
	
	if(this.inheritRotation)
	{
		_global.skewX += parentGlobalTransform.skewX;
		_global.skewY += parentGlobalTransform.skewY;
	}
	
	if(this.inheritScale)
	{
		_global.scaleX *= parentGlobalTransform.scaleX;
		_global.scaleY *= parentGlobalTransform.scaleY;
	}
	}
	TransformUtil.transformToMatrix(_global, _globalTransformMatrix);
	return output;
}

private function calculateRelativeParentTransform():Void
{
}

public var name(getName, setName):String;
 	private function getName():String
{
	return _name;
}
private function setName(value:String):Void
{
	_name = value;
}

/**
 * This DBObject instance global transform instance.
 * @see dragonBones.objects.DBTransform
 */
public var global(getGlobal, setGlobal):DBTransform;
 	private function getGlobal():DBTransform
{
	return _global;
}


public var global(getGlobal, setGlobal):DBTransform;
 	private function getGlobalTransformMatrix():Matrix
{
	return _globalTransformMatrix;
}

/**
 * This DBObject instance related to parent transform instance.
 * @see dragonBones.objects.DBTransform
 */
public var origin(getOrigin, setOrigin):DBTransform;
 	private function getOrigin():DBTransform
{
	return _origin;
}

/**
 * Indicates the Bone instance that directly contains this DBObject instance if any.
 */
public var parent(getParent, setParent):FastBone;
 	private function getParent():FastBone
{
	return _parent;
}

/** @private */

public var visible(getVisible, setVisible):Bool;
 	private function getVisible():Bool
{
	return _visible;
}
private function setVisible(value:Bool):Void
{
	_visible = value;
}

public var frameCache(null, setFrameCache):FrameCache;
 	private function setFrameCache(cache:FrameCache):Void
{
	_frameCache = cache;
}
}