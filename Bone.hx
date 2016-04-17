package dragonbones;

import flash.geom.Matrix;
import flash.geom.Point;

import dragonBones.animation.AnimationState;
import dragonBones.animation.TimelineState;
import dragonBones.core.DBObject;
import dragonBones.core.dragonBones_internal;
import dragonBones.events.FrameEvent;
import dragonBones.events.SoundEvent;
import dragonBones.events.SoundEventManager;
import dragonBones.objects.BoneData;
import dragonBones.objects.DBTransform;
import dragonBones.objects.Frame;
import dragonBones.objects.ParentTransformObject;
import dragonBones.utils.TransformUtil;

use namespace dragonBones_internal;

import flash.Vector;

class Bone extends DBObject
{
/**
 * The instance dispatch sound event.
 */
private static inline var _soundManager:SoundEventManager = SoundEventManager.getInstance();

public static function initWithBoneData(boneData:BoneData):Bone
{
	var outputBone:Bone = new Bone();
	
	outputBone.name = boneData.name;
	outputBone.length = boneData.length;
	outputBone.inheritRotation = boneData.inheritRotation;
	outputBone.inheritScale = boneData.inheritScale;
	outputBone.origin.copy(boneData.transform);
	
	return outputBone;
}

public var applyOffsetTranslationToChild:Bool = true;

public var applyOffsetRotationToChild:Bool = true;

public var applyOffsetScaleToChild:Bool = false;

/**
 * AnimationState that slots belong to the bone will be controlled by.
 * Sometimes, we want slots controlled by a spedific animation state when animation is doing mix or addition.
 */
public var displayController:String;

public var rotationIK:Float;
public var length:Float;
public var isIKConstraint:Bool = false;
public var childrenBones:Vector<Bone> = new Vector();

/** @private */
private var _boneList:Vector<Bone>;

/** @private */
private var _slotList:Vector<Slot>;

/** @private */
private var _timelineStateList:Vector<TimelineState>;

/** @private */
dragonBones_private var _tween:DBTransform;

/** @private */
dragonBones_private var _tweenPivot:Point;

/** @private */
dragonBones_private var _needUpdate:Int;

/** @private */
//dragonBones_private var _isColorChanged:Bool;

/** @private */
dragonBones_private var _globalTransformForChild:DBTransform;
/** @private */
dragonBones_private var _globalTransformMatrixForChild:Matrix;
/** @private */
dragonBones_private var _localTransform:DBTransform;

private var _tempGlobalTransformForChild:DBTransform;
private var _tempGlobalTransformMatrixForChild:Matrix;

public function new()
{
	super();
	
	_tween = new DBTransform();
	_tweenPivot = new Point();
	_tween.scaleX = _tween.scaleY = 1;
	
	_boneList = new Vector<Bone>;
	_boneList.fixed = true;
	_slotList = new Vector<Slot>;
	_slotList.fixed = true;
	_timelineStateList = new Vector<TimelineState>;
	
	_needUpdate = 2;
	//_isColorChanged = false;
}

/**
 * @inheritDoc
 */
override public function dispose():Void
{
	if(!_boneList)
	{
	return;
	}
	
	super.dispose();
	var i:Int = _boneList.length;
	while(i --)
	{
	_boneList[i].dispose();
	}
	
	i = _slotList.length;
	while(i --)
	{
	_slotList[i].dispose();
	}
	
	_boneList.fixed = false;
	_boneList.length = 0;
	_slotList.fixed = false;
	_slotList.length = 0;
	_timelineStateList.length = 0;
	
	_tween = null;
	_tweenPivot = null;
	_boneList = null;
	_slotList = null;
	_timelineStateList = null;
}

//骨架装配
/**
 * If contains some bone or slot
 * @param Slot or Bone instance
 * @return Boolean
 * @see dragonBones.core.DBObject
 */
public function contains(child:DBObject):Bool
{
	if(!child)
	{
	throw new ArgumentError();
	}
	if(child == this)
	{
	return false;
	}
	var ancestor:DBObject = child;
	while(!(ancestor == this || ancestor == null))
	{
	ancestor = ancestor.parent;
	}
	return ancestor == this;
}

/**
 * Add a bone as child
 * @param a Bone instance
 * @see dragonBones.core.DBObject
 */
public function addChildBone(childBone:Bone, updateLater:Bool = false):Void
{
	if(!childBone)
	{
	throw new ArgumentError();
	}
	
	if(childBone == this || childBone.contains(this))
	{
	throw new ArgumentError("An Bone cannot be added as a child to itself or one of its children (or children's children, etc.)");
	}
	
	if(childBone.parent == this)
	{
	return;
	}
	
	if(childBone.parent)
	{
	childBone.parent.removeChildBone(childBone);
	}
	
	_boneList.fixed = false;
	_boneList[_boneList.length] = childBone;
	_boneList.fixed = true;
	childBone.setParent(this);
	childBone.setArmature(_armature);
	var index:Int = childrenBones.indexOf(childBone);
	if (index < 0)
	{
	childrenBones.push(childBone);
	}
	
	if(_armature && !updateLater)
	{
	_armature.updateAnimationAfterBoneListChanged();
	}
}

/**
 * remove a child bone 
 * @param a Bone instance
 * @see dragonBones.core.DBObject
 */
public function removeChildBone(childBone:Bone, updateLater:Bool = false):Void
{
	if(!childBone)
	{
	throw new ArgumentError();
	}
	
	var index:Int = _boneList.indexOf(childBone);
	if(index < 0)
	{
	throw new ArgumentError();
	}
	
	_boneList.fixed = false;
	_boneList.splice(index, 1);
	_boneList.fixed = true;
	var indexs:Int = childrenBones.indexOf(childBone);
	if (indexs >= 0)
	{
	childrenBones.splice(indexs, 1);
	}
	childBone.setParent(null);
	childBone.setArmature(null);
	
	if(_armature && !updateLater)
	{
	_armature.updateAnimationAfterBoneListChanged(false);
	}
}

/**
 * Add a slot as child
 * @param a Slot instance
 * @see dragonBones.core.DBObject
 */
public function addSlot(childSlot:Slot):Void
{
	if(!childSlot)
	{
	throw new ArgumentError();
	}
	
	if(childSlot.parent)
	{
	childSlot.parent.removeSlot(childSlot);
	}
	
	_slotList.fixed = false;
	_slotList[_slotList.length] = childSlot;
	_slotList.fixed = true;
	childSlot.setParent(this);
	childSlot.setArmature(this._armature);
}

/**
 * remove a child slot
 * @param a Slot instance
 * @see dragonBones.core.DBObject
 */
public function removeSlot(childSlot:Slot):Void
{
	if(!childSlot)
	{
	throw new ArgumentError();
	}
	
	var index:Int = _slotList.indexOf(childSlot);
	if(index < 0)
	{
	throw new ArgumentError();
	}
	
	_slotList.fixed = false;
	_slotList.splice(index, 1);
	_slotList.fixed = true;
	childSlot.setParent(null);
	childSlot.setArmature(null);
}

/** @private */
override dragonBones_private function setArmature(value:Armature):Void
{
	if(_armature == value)
	{
	return;
	}
	if(_armature)
	{
	_armature.removeBoneFromBoneList(this);
	_armature.updateAnimationAfterBoneListChanged(false);
	}
	_armature = value;
	if(_armature)
	{
	_armature.addBoneToBoneList(this);
	}
	
	var i:Int = _boneList.length;
	while(i --)
	{
	_boneList[i].setArmature(this._armature);
	}
	
	i = _slotList.length;
	while(i --)
	{
	_slotList[i].setArmature(this._armature);
	}
}

/**
 * Get all Bone instance associated with this bone.
 * @return A Vector.&lt;Slot&gt; instance.
 * @see dragonBones.Slot
 */
public function getBones(returnCopy:Bool = true):Vector<Bone>
{
	return returnCopy?_boneList.concat():_boneList;
}

/**
 * Get all Slot instance associated with this bone.
 * @return A Vector.&lt;Slot&gt; instance.
 * @see dragonBones.Slot
 */
public function getSlots(returnCopy:Bool = true):Vector<Slot>
{
	return returnCopy?_slotList.concat():_slotList;
}

//动画
/**
 * Force update the bone in next frame even if the bone is not moving.
 */
public function invalidUpdate():Void
{
	_needUpdate = 2;
	operationInvalidUpdate(this);
	for each (var i:Bone in childrenBones) 
	{
	if(i._needUpdate != 2){
		operationInvalidUpdate(i)	
		i.invalidUpdate()
	}
	}
}
private function operationInvalidUpdate(bone:Bone):Void
{
	var arr:Array = this.armature.getIKTargetData(bone);
	var i:Int;
	var len:Int;
	var j:Int;
	var jLen:Int;
	var ik:IKConstraint;
	var bo:Bone;
	for (i = 0, len = arr.length; i < len; i++)
	{
	ik = arr[i];
	for (j = 0, jLen = ik.bones.length; j < jLen; j++)
	{
		bo = ik.bones[j];
		if(bo._needUpdate != 2){
		bo.invalidUpdate();
		}
	}
	}
}

override private function calculateRelativeParentTransform():Void
{
	_global.scaleX = this._origin.scaleX * _tween.scaleX * this._offset.scaleX;
	_global.scaleY = this._origin.scaleY * _tween.scaleY * this._offset.scaleY;
	_global.skewX = this._origin.skewX + _tween.skewX + this._offset.skewX;
	_global.skewY = this._origin.skewY + _tween.skewY + this._offset.skewY;
	_global.x = this._origin.x + _tween.x + this._offset.x;
	_global.y = this._origin.y + _tween.y + this._offset.y;
	
}

/** @private */
dragonBones_private function update(needUpdate:Bool = false):Void
{
	_needUpdate --;
	if(needUpdate || _needUpdate > 0 || (this._parent && this._parent._needUpdate > 0))
	{
	_needUpdate = 1;
	}
	else
	{
	return;
	}
	blendingTimeline();
	//计算global
	var result:ParentTransformObject = updateGlobal();
	var parentGlobalTransform:DBTransform; 
	var parentGlobalTransformMatrix:Matrix;
	
	if (result)
	{
	parentGlobalTransform = result.parentGlobalTransform;
	parentGlobalTransformMatrix = result.parentGlobalTransformMatrix;
	result.release();
	}
//计算globalForChild
	var ifExistOffsetTranslation:Bool = _offset.x != 0 || _offset.y != 0;
	var ifExistOffsetScale:Bool = _offset.scaleX != 1 || _offset.scaleY != 1;
	var ifExistOffsetRotation:Bool = _offset.skewX != 0 || _offset.skewY != 0;
	
	if(	(!ifExistOffsetTranslation || applyOffsetTranslationToChild) &&
	(!ifExistOffsetScale || applyOffsetScaleToChild) &&
	(!ifExistOffsetRotation || applyOffsetRotationToChild))
	{
	_globalTransformForChild = _global;
	_globalTransformMatrixForChild = _globalTransformMatrix;
	}
	else
	{
	if(!_tempGlobalTransformForChild)
	{
		_tempGlobalTransformForChild = new DBTransform();
	}
	_globalTransformForChild = _tempGlobalTransformForChild;
	
	if(!_tempGlobalTransformMatrixForChild)
	{
		_tempGlobalTransformMatrixForChild = new Matrix();
	}
	_globalTransformMatrixForChild = _tempGlobalTransformMatrixForChild;
	
	_globalTransformForChild.x = this._origin.x + _tween.x;
	_globalTransformForChild.y = this._origin.y + _tween.y;
	_globalTransformForChild.scaleX = this._origin.scaleX * _tween.scaleX;
	_globalTransformForChild.scaleY = this._origin.scaleY * _tween.scaleY;
	_globalTransformForChild.skewX = this._origin.skewX + _tween.skewX;
	_globalTransformForChild.skewY = this._origin.skewY + _tween.skewY;
	
	if(applyOffsetTranslationToChild)
	{
		_globalTransformForChild.x += this._offset.x;
		_globalTransformForChild.y += this._offset.y;
	}
	if(applyOffsetScaleToChild)
	{
		_globalTransformForChild.scaleX *= this._offset.scaleX;
		_globalTransformForChild.scaleY *= this._offset.scaleY;
	}
	if(applyOffsetRotationToChild)
	{
		_globalTransformForChild.skewX += this._offset.skewX;
		_globalTransformForChild.skewY += this._offset.skewY;
	}
	
	TransformUtil.transformToMatrix(_globalTransformForChild, _globalTransformMatrixForChild);
	if(parentGlobalTransformMatrix)
	{
		_globalTransformMatrixForChild.concat(parentGlobalTransformMatrix);
		TransformUtil.matrixToTransform(_globalTransformMatrixForChild, _globalTransformForChild, _globalTransformForChild.scaleX * parentGlobalTransform.scaleX >= 0, _globalTransformForChild.scaleY * parentGlobalTransform.scaleY >= 0 );
	}
	}
}
public function adjustGlobalTransformMatrixByIK():Void
{
	if(!parent)
	{
	return;
	}
	
	global.rotation = rotationIK;
	TransformUtil.transformToMatrix(global, _globalTransformMatrix);
	_globalTransformForChild.rotation= rotationIK;
	TransformUtil.transformToMatrix(_globalTransformForChild, _globalTransformMatrixForChild);
}

/** @private */
dragonBones_private function hideSlots():Void
{
	for each(var childSlot:Slot in _slotList)
	{
	childSlot.changeDisplay(-1);
	}
}

/** @private When bone timeline enter a key frame, call this func*/
dragonBones_private function arriveAtFrame(frame:Frame, timelineState:TimelineState, animationState:AnimationState, isCross:Bool):Void
{
	var displayControl:Bool = 
	animationState.displayControl &&
	(!displayController || displayController == animationState.name) &&
	animationState.containsBoneMask(name)
	
	if(displayControl)
	{
	var childSlot:Slot;
	if(frame.event && this._armature.hasEventListener(FrameEvent.BONE_FRAME_EVENT))
	{
		var frameEvent:FrameEvent = new FrameEvent(FrameEvent.BONE_FRAME_EVENT);
		frameEvent.bone = this;
		frameEvent.animationState = animationState;
		frameEvent.frameLabel = frame.event;
		this._armature._eventList.push(frameEvent);
	}
	if(frame.sound && _soundManager.hasEventListener(SoundEvent.SOUND))
	{
		var soundEvent:SoundEvent = new SoundEvent(SoundEvent.SOUND);
		soundEvent.armature = this._armature;
		soundEvent.animationState = animationState;
		soundEvent.sound = frame.sound;
		_soundManager.dispatchEvent(soundEvent);
	}
	
	//[TODO]currently there is only gotoAndPlay belongs to frame action. In future, there will be more.  
	//后续会扩展更多的action，目前只有gotoAndPlay的含义
	if(frame.action) 
	{
		for each(childSlot in _slotList)
		{
		var childArmature:Armature = childSlot.childArmature;
		if(childArmature)
		{
			childArmature.animation.gotoAndPlay(frame.action);
		}
		}
	}
	}
}

override private function updateGlobal():ParentTransformObject 
{
	if (!_armature._skewEnable)
	{
	return super.updateGlobal();
	}
	
	calculateRelativeParentTransform();
	var output:ParentTransformObject = calculateParentTransform();
	if(output != null && output.parentGlobalTransformMatrix && output.parentGlobalTransform)
	{
	//计算父骨头绝对坐标
	var parentMatrix:Matrix = output.parentGlobalTransformMatrix;
	var parentGlobalTransform:DBTransform = output.parentGlobalTransform;
	
	var scaleXF:Bool = _global.scaleX * parentGlobalTransform.scaleX > 0;
	var scaleYF:Bool = _global.scaleY * parentGlobalTransform.scaleY > 0;
	var relativeRotation:Float = _global.rotation;
	var relativeScaleX:Float = _global.scaleX;
	var relativeScaleY:Float = _global.scaleY;
	var parentRotation:Float = parentBoneRotation;
	
	_localTransform = _global;
	if (this.inheritScale && !inheritRotation)
	{
		if (parentRotation != 0)
		{
		_localTransform = _localTransform.clone();
		_localTransform.rotation -= parentRotation;
		}
	}
	TransformUtil.transformToMatrix(_localTransform, _globalTransformMatrix);
	_globalTransformMatrix.concat(parentMatrix);
	
	if (inheritScale)
	{
		TransformUtil.matrixToTransform(_globalTransformMatrix, _global, scaleXF, scaleYF);
	}
	else 
	{
		TransformUtil.matrixToTransformPosition(_globalTransformMatrix, _global);

		_global.scaleX = _localTransform.scaleX;
		_global.scaleY = _localTransform.scaleY;
		_global.rotation = _localTransform.rotation + (inheritRotation ? parentRotation : 0);
		
		TransformUtil.transformToMatrix(_global, _globalTransformMatrix);
	}
	}
	return output;
}

/** @private */
dragonBones_private function addState(timelineState:TimelineState):Void
{
	if(_timelineStateList.indexOf(timelineState) < 0)
	{
	_timelineStateList.push(timelineState);
	_timelineStateList.sort(sortState);
	}
}

/** @private */
dragonBones_private function removeState(timelineState:TimelineState):Void
{
	var index:Int = _timelineStateList.indexOf(timelineState);
	if(index >= 0)
	{
	_timelineStateList.splice(index, 1);
	}
}

/** @private */
dragonBones_private function removeAllStates():Void
{
	_timelineStateList.length = 0;
}

private function blendingTimeline():Void
{
	var timelineState:TimelineState;
	var transform:DBTransform;
	var pivot:Point;
	var weight:Float;
	
	var i:Int = _timelineStateList.length;
	if(i == 1)
	{
	timelineState = _timelineStateList[0];
	weight = timelineState._animationState.weight * timelineState._animationState.fadeWeight;
	timelineState._weight = weight;
	transform = timelineState._transform;
	pivot = timelineState._pivot;
	
	_tween.x = transform.x * weight;
	_tween.y = transform.y * weight;
	_tween.skewX = transform.skewX * weight;
	_tween.skewY = transform.skewY * weight;
	_tween.scaleX = 1 + (transform.scaleX - 1) * weight;
	_tween.scaleY = 1 + (transform.scaleY - 1) * weight;
	
	_tweenPivot.x = pivot.x * weight;
	_tweenPivot.y = pivot.y * weight;
	}
	else if(i > 1)
	{
	var x:Float = 0;
	var y:Float = 0;
	var skewX:Float = 0;
	var skewY:Float = 0;
	var scaleX:Float = 1;
	var scaleY:Float = 1;
	var pivotX:Float = 0;
	var pivotY:Float = 0;
	
	var weigthLeft:Float = 1;
	var layerTotalWeight:Float = 0;
	var prevLayer:Int = _timelineStateList[i - 1]._animationState.layer;
	var currentLayer:Int;
	
	//Traversal the layer from up to down
	//layer由高到低依次遍历
	
	while(i --)
	{
		timelineState = _timelineStateList[i];
		
		currentLayer = timelineState._animationState.layer;
		if(prevLayer != currentLayer)
		{
		if(layerTotalWeight >= weigthLeft)
		{
			timelineState._weight = 0;
			break;
		}
		else
		{
			weigthLeft -= layerTotalWeight;
		}
		}
		prevLayer = currentLayer;
		
		weight = timelineState._animationState.weight * timelineState._animationState.fadeWeight * weigthLeft;
		timelineState._weight = weight;
		if(weight)
		{
		transform = timelineState._transform;
		pivot = timelineState._pivot;
		
		x += transform.x * weight;
		y += transform.y * weight;
		skewX += transform.skewX * weight;
		skewY += transform.skewY * weight;
		scaleX += (transform.scaleX - 1) * weight;
		scaleY += (transform.scaleY - 1) * weight;
		pivotX += pivot.x * weight;
		pivotY += pivot.y * weight;
		
		layerTotalWeight += weight;
		}
	}
	
	_tween.x = x;
	_tween.y = y;
	_tween.skewX = skewX;
	_tween.skewY = skewY;
	_tween.scaleX = scaleX;
	_tween.scaleY = scaleY;
	_tweenPivot.x = pivotX;
	_tweenPivot.y = pivotY;
	}
}

private function sortState(state1:TimelineState, state2:TimelineState):Int
{
	return state1._animationState.layer < state2._animationState.layer?-1:1;
}

/**
 * Unrecommended API. Recommend use slot.childArmature.
 */
public var childArmature(getChildArmature, setChildArmature):Armature;
 	private function getChildArmature():Armature
{
	if(slot)
	{
	return slot.childArmature;
	}
	return null;
}

/**
 * Unrecommended API. Recommend use slot.display.
 */
public var display(getDisplay, setDisplay):Object;
 	private function getDisplay():Object
{
	if(slot)
	{
	return slot.display;
	}
	return null;
}
private function setDisplay(value:Object):Void
{
	if(slot)
	{
	slot.display = value;
	}
}

/**
 * Unrecommended API. Recommend use offset.
 */
public var node(getNode, setNode):DBTransform;
 	private function getNode():DBTransform
{
	return _offset;
}




/** @private */
override public var visible(null, setVisible):Bool;
 	private function setVisible(value:Bool):Void
{
	if(this._visible != value)
	{
	this._visible = value;
	for each(var childSlot:Slot in _slotList)
	{
		childSlot.updateDisplayVisible(this._visible);
	}
	}
}

public var slot(getSlot, setSlot):Slot;
 	private function getSlot():Slot
{
	return _slotList.length > 0?_slotList[0]:null;
}
public var parentBoneRotation(getParentBoneRotation, setParentBoneRotation):Float;
 	private function getParentBoneRotation():Float
{
	return this.parent ? this.parent.rotationIK : 0;
}
}