package dragonbones;

import dragonBones.animation.AnimationState;
import dragonBones.animation.SlotTimelineState;
import dragonBones.core.DBObject;
import dragonBones.core.dragonBones_internal;
import dragonBones.objects.DisplayData;
import dragonBones.objects.Frame;
import dragonBones.objects.MeshData;
import dragonBones.objects.ParentTransformObject;
import dragonBones.objects.SlotData;
import dragonBones.objects.SlotFrame;
import dragonBones.utils.TransformUtil;
import flash.errors.IllegalOperationError;
import flash.geom.ColorTransform;
import flash.geom.Matrix;


//import dragonBones.objects.FrameCached;
//import dragonBones.objects.TimelineCached;

import flash.Vector;

class Slot extends DBObject
{
/** @private Need to keep the reference of DisplayData. When slot switch displayObject, it need to restore the display obect's origional pivot. */
private var _displayDataList:Vector<DisplayData>;
/** @private */
private var _originZOrder:Float;
/** @private */
private var _tweenZOrder:Float;
/** @private */
private var _originDisplayIndex:Float;
/** @private */
private var _gotoAndPlay:String;
private var _defaultGotoAndPlay:String;

private var _offsetZOrder:Float;

private var _displayList:Array;
private var _currentDisplayIndex:Int;
private var _colorTransform:ColorTransform;

//TO DO: 以后把这两个属性变成getter
//另外还要处理 isShowDisplay 和 visible的矛盾
private var _currentDisplay:Object;
private var _isShowDisplay:Bool;

//private var _childArmature:Armature;
private var _blendMode:String;

/** @private */
private var _isColorChanged:Bool;
private var _needUpdate:Bool;
/** @private */
//	private var _timelineStateList:Vector<SlotTimelineState>;

public function new(self:Slot)
{
	super();
	
	if(self != this)
	{
	throw new IllegalOperationError("Abstract class can not be instantiated!");
	}
	
	_displayList = [];
	_currentDisplayIndex = -1;
	
	_originZOrder = 0;
	_tweenZOrder = 0;
	_offsetZOrder = 0;
	_isShowDisplay = false;
	_isColorChanged = false;
	_colorTransform = new ColorTransform();
	_displayDataList = null;
	//_childArmature = null;
	_currentDisplay = null;
//		_timelineStateList = new Vector<SlotTimelineState>;
	
	this.inheritRotation = true;
	this.inheritScale = true;
}

public function initWithSlotData(slotData:SlotData):Void
{
	name = slotData.name;
	blendMode = slotData.blendMode;
	_defaultGotoAndPlay = slotData.gotoAndPlay;
	_originZOrder = slotData.zOrder;
	_displayDataList = slotData.displayDataList;
	_originDisplayIndex = slotData.displayIndex;
}

/**
 * @inheritDoc
 */
override public function dispose():Void
{
	if(!_displayList)
	{
	return;
	}
	
	super.dispose();
	
	_displayList.length = 0;
//		_timelineStateList.length = 0;
	
	_displayDataList = null;
	_displayList = null;
	_currentDisplay = null;
//		_timelineStateList = null;
	
}

//	private function sortState(state1:SlotTimelineState, state2:SlotTimelineState):Int
//	{
//		return state1._animationState.layer < state2._animationState.layer?-1:1;
//	}

/** @private */
//	private function addState(timelineState:SlotTimelineState):Void
//	{
//		if(_timelineStateList.indexOf(timelineState) < 0)
//		{
//		_timelineStateList.push(timelineState);
//		_timelineStateList.sort(sortState);
//		}
//	}

/** @private */
//	private function removeState(timelineState:SlotTimelineState):Void
//	{
//		var index:Int = _timelineStateList.indexOf(timelineState);
//		if(index >= 0)
//		{
//		_timelineStateList.splice(index, 1);
//		}
//	}

//骨架装配
/** @private */
override private function setArmature(value:Armature):Void
{
	if(_armature == value)
	{
	return;
	}
	if(_armature)
	{
	_armature.removeSlotFromSlotList(this);
	}
	_armature = value;
	if(_armature)
	{
	_armature.addSlotToSlotList(this);
	_armature._slotsZOrderChanged = true;
	addDisplayToContainer(this._armature.display);
	}
	else
	{
	removeDisplayFromContainer();
	}
}

//动画
/** @private */
private function update():Void
{
	if(this._parent._needUpdate <= 0 && !_needUpdate)
	{
	return;
	}
	
	var result:ParentTransformObject = updateGlobal();
	if (result)
	{
	result.release();
	}
	
	updateTransform();
	_needUpdate = false;
}

override private function calculateRelativeParentTransform():Void
{
	_global.scaleX = this._origin.scaleX * this._offset.scaleX;
	_global.scaleY = this._origin.scaleY * this._offset.scaleY;
	_global.skewX = this._origin.skewX + this._offset.skewX;
	_global.skewY = this._origin.skewY + this._offset.skewY;
	_global.x = this._origin.x + this._offset.x + this._parent._tweenPivot.x;
	_global.y = this._origin.y + this._offset.y + this._parent._tweenPivot.y;
}

private function updateChildArmatureAnimation():Void
{
	if(childArmature)
	{
	if(_isShowDisplay)
	{
		var curAnimation:String = _gotoAndPlay;
		if (curAnimation == null)
		{
		curAnimation = _defaultGotoAndPlay;
		if (curAnimation == null)
		{
			curAnimation = childArmature.armatureData.defaultAnimation;
		}
		}
		if (curAnimation == null)
		{
		if (this._armature && this._armature.animation.lastAnimationState)
		{
			curAnimation = this._armature.animation.lastAnimationState.name;
		}
		}
		if (curAnimation && childArmature.animation.hasAnimation(curAnimation))
		{
		childArmature.animation.gotoAndPlay(curAnimation);
		}
		else
		{
		childArmature.animation.play();
		}
	}
	else
	{
		childArmature.animation.stop();
		childArmature.animation._lastAnimationState = null;
	}
	}
}

/** @private */
private function changeDisplay(displayIndex:Int):Void
{
	if (displayIndex < 0)
	{
	if(_isShowDisplay)
	{
		_isShowDisplay = false;
		removeDisplayFromContainer();
		updateChildArmatureAnimation();
	}
	}
	else if (_displayList.length > 0)
	{
	var length:UInt = _displayList.length;
	if(displayIndex >= length)
	{
		displayIndex = length - 1;
	}
	
	if(_currentDisplayIndex != displayIndex)
	{
		_isShowDisplay = true;
		_currentDisplayIndex = displayIndex;
		updateSlotDisplay();
		//updateTransform();//解决当时间和bone不统一时会换皮肤时会跳的bug
		updateChildArmatureAnimation();
		if(
		_displayDataList && 
		_displayDataList.length > 0 && 
		_currentDisplayIndex < _displayDataList.length
		)
		{
		this._origin.copy(_displayDataList[_currentDisplayIndex].transform);
		}
		_needUpdate = true;
	}
	else if(!_isShowDisplay)
	{
		_isShowDisplay = true;
		if(this._armature)
		{
		this._armature._slotsZOrderChanged = true;
		addDisplayToContainer(this._armature.display);
		}
		updateChildArmatureAnimation();
	}
	
	}
}

/** @private 
 * Updates the display of the slot.
 */
private function updateSlotDisplay():Void
{
	var currentDisplayIndex:Int = -1;
	if(_currentDisplay)
	{
	currentDisplayIndex = getDisplayIndex();
	removeDisplayFromContainer();
	}
	var displayObj:Object = _displayList[_currentDisplayIndex];
	if (displayObj)
	{
	if(displayObj is Armature)
	{
		//_childArmature = display as Armature;
		_currentDisplay = (displayObj as Armature).display;
	}
	else
	{
		//_childArmature = null;
		_currentDisplay = displayObj;
	}
	}
	else
	{
	_currentDisplay = null;
	//_childArmature = null;
	}
	updateDisplay(_currentDisplay);
	if(_currentDisplay)
	{
	if(this._armature && _isShowDisplay)
	{
		if(currentDisplayIndex < 0)
		{
		this._armature._slotsZOrderChanged = true;
		addDisplayToContainer(this._armature.display);
		}
		else
		{
		addDisplayToContainer(this._armature.display, currentDisplayIndex);
		}
	}
	updateDisplayBlendMode(_blendMode);
	updateDisplayColor(	_colorTransform.alphaOffset, _colorTransform.redOffset, _colorTransform.greenOffset, _colorTransform.blueOffset,
				_colorTransform.alphaMultiplier, _colorTransform.redMultiplier, _colorTransform.greenMultiplier, _colorTransform.blueMultiplier,true);
	updateDisplayVisible(_visible);
	updateTransform();
	}
}

/** @private */
override public var visible(null, setVisible):Bool;
 	private function setVisible(value:Bool):Void
{
	if(this._visible != value)
	{
	this._visible = value;
	updateDisplayVisible(this._visible);
	}
}

/**
 * The DisplayObject list belonging to this Slot instance (display or armature). Replace it to implement switch texture.
 */
public var displayList(getDisplayList, setDisplayList):Array;
 	public var display(getDisplay, setDisplay):Object;
 	private function getDisplayList():Array
{
	return _displayList;
}
private function setDisplayList(value:Array):Void
{
	if(!value)
	{
	throw new ArgumentError();
	}
	
	//为什么要修改_currentDisplayIndex?
	if (_currentDisplayIndex < 0)
	{
	_currentDisplayIndex = 0;
	}
	var i:Int = _displayList.length = value.length;
	while(i --)
	{
	_displayList[i] = value[i];
	}
	
	//在index不改变的情况下强制刷新 TO DO需要修改
	var displayIndexBackup:Int = _currentDisplayIndex;
	_currentDisplayIndex = -1;
	changeDisplay(displayIndexBackup);
	updateTransform();
}

/**
 * The DisplayObject belonging to this Slot instance. Instance type of this object varies from flash.display.DisplayObject to startling.display.DisplayObject and subclasses.
 */
public var display(getDisplay, setDisplay):Object;
 	private function getDisplay():Object
{
	return _currentDisplay;
}
private function setDisplay(value:Object):Void
{
	if (_currentDisplayIndex < 0)
	{
	_currentDisplayIndex = 0;
	}
	if(_displayList[_currentDisplayIndex] == value)
	{
	return;
	}
	_displayList[_currentDisplayIndex] = value;
	updateSlotDisplay();
	updateChildArmatureAnimation();
	updateTransform();//是否可以延迟更新？
}

/**
 * The sub-armature of this Slot instance.
 */
public var childArmature(getChildArmature, setChildArmature):Armature;
 	private function getChildArmature():Armature
{
	return _displayList[_currentDisplayIndex] is Armature ? _displayList[_currentDisplayIndex] : null;
}
private function setChildArmature(value:Armature):Void
{
	//设计的不好，要修改
	display = value;
}

/**
 * zOrder. Support decimal for ensure dynamically added slot work toghther with animation controled slot.  
 * @return zOrder.
 */
public var zOrder(getZOrder, setZOrder):Float;
 	private function getZOrder():Float
{
	return _originZOrder + _tweenZOrder + _offsetZOrder;
}
private function setZOrder(value:Float):Void
{
	if(zOrder != value)
	{
	_offsetZOrder = value - _originZOrder - _tweenZOrder;
	if(this._armature)
	{
		this._armature._slotsZOrderChanged = true;
	}
	}
}

/**
 * blendMode
 * @return blendMode.
 */
public var blendMode(getBlendMode, setBlendMode):String;
 	private function getBlendMode():String
{
	return _blendMode;
}
private function setBlendMode(value:String):Void
{
	if(_blendMode != value)
	{
	_blendMode = value;
	updateDisplayBlendMode(_blendMode);
	}
}

public var gotoAndPlay(null, setGotoAndPlay):String;
 	private function setGotoAndPlay(value:String):Void 
{
	if (_gotoAndPlay != value)
	{
	_gotoAndPlay = value;
	updateChildArmatureAnimation();
	}
	
}

//Abstract method

/**
 * @private
 */
private function updateDisplay(value:Object):Void
{
	throw new IllegalOperationError("Abstract method needs to be implemented in subclass!");
}

/**
 * @private
 */
dragonBones_public var display(getDisplay, setDisplay):Object;
 	private function getDisplayIndex():Int
{
	throw new IllegalOperationError("Abstract method needs to be implemented in subclass!");
}

/**
 * @private
 * Adds the original display object to another display object.
 * @param container
 * @param index
 */
private function addDisplayToContainer(container:Object, index:Int = -1):Void
{
	throw new IllegalOperationError("Abstract method needs to be implemented in subclass!");
}

/**
 * @private
 * remove the original display object from its parent.
 */
private function removeDisplayFromContainer():Void
{
	throw new IllegalOperationError("Abstract method needs to be implemented in subclass!");
}

/**
 * @private
 * Updates the transform of the slot.
 */
private function updateTransform():Void
{
	throw new IllegalOperationError("Abstract method needs to be implemented in subclass!");
}

/**
 * @private
 */
private function updateDisplayVisible(value:Bool):Void
{
	/**
	 * bone.visible && slot.visible && updateVisible
	 * this._parent.visible && this._visible && value;
	 */
	throw new IllegalOperationError("Abstract method needs to be implemented in subclass!");
}

/**
 * @private
 * Updates the color of the display object.
 * @param a
 * @param r
 * @param g
 * @param b
 * @param aM
 * @param rM
 * @param gM
 * @param bM
 */
private function updateDisplayColor(
	aOffset:Float, 
	rOffset:Float, 
	gOffset:Float, 
	bOffset:Float, 
	aMultiplier:Float, 
	rMultiplier:Float, 
	gMultiplier:Float, 
	bMultiplier:Float,
	colorChanged:Bool = false
):Void
{
	_colorTransform.alphaOffset = aOffset;
	_colorTransform.redOffset = rOffset;
	_colorTransform.greenOffset = gOffset;
	_colorTransform.blueOffset = bOffset;
	_colorTransform.alphaMultiplier = aMultiplier;
	_colorTransform.redMultiplier = rMultiplier;
	_colorTransform.greenMultiplier = gMultiplier;
	_colorTransform.blueMultiplier = bMultiplier;
	
	_isColorChanged = colorChanged;
}

/**
 * @private
 * Update the blend mode of the display object.
 * @param value The blend mode to use. 
 */
private function updateDisplayBlendMode(value:String):Void
{
	throw new IllegalOperationError("Abstract method needs to be implemented in subclass!");
}

/** @private When slot timeline enter a key frame, call this func*/
private function arriveAtFrame(frame:Frame, timelineState:SlotTimelineState, animationState:AnimationState, isCross:Bool):Void
{
	var displayControl:Bool = animationState.displayControl &&
				 animationState.containsBoneMask(parent.name)
	
	if(displayControl)
	{
	var slotFrame:SlotFrame = frame as SlotFrame;
	var displayIndex:Int = slotFrame.displayIndex;
	var childSlot:Slot;
	changeDisplay(displayIndex);
	updateDisplayVisible(slotFrame.visible);
	if(displayIndex >= 0)
	{
		if(!isNaN(slotFrame.zOrder) && slotFrame.zOrder != _tweenZOrder)
		{
		_tweenZOrder = slotFrame.zOrder;
		this._armature._slotsZOrderChanged = true;
		}
	}
	
	//[TODO]currently there is only gotoAndPlay belongs to frame action. In future, there will be more.  
	//后续会扩展更多的action，目前只有gotoAndPlay的含义
	if(frame.action) 
	{
		if (childArmature)
		{
		childArmature.animation.gotoAndPlay(frame.action);
		}
	}
	else
	{
		this.gotoAndPlay = slotFrame.gotoAndPlay;
	}
	}
} 

override private function updateGlobal():ParentTransformObject 
{
	calculateRelativeParentTransform();
	TransformUtil.transformToMatrix(_global, _globalTransformMatrix);
	var output:ParentTransformObject = calculateParentTransform();
	if(output != null)
	{
	//计算父骨头绝对坐标
	var parentMatrix:Matrix = output.parentGlobalTransformMatrix;
	_globalTransformMatrix.concat(parentMatrix);
	}
	TransformUtil.matrixToTransform(_globalTransformMatrix,_global,true,true);
	return output;
}

private function resetToOrigin():Void
{
	changeDisplay(_originDisplayIndex);
	updateDisplayColor(0, 0, 0, 0, 1, 1, 1, 1, true);
}

public function getMeshData(meshName:String):MeshData
{
	for (var i:Int = 0, len:Int = _displayDataList.length; i < len; i++)
	{
	if (_displayDataList[i].name == meshName && _displayDataList[i] is MeshData)
	{
		return _displayDataList[i] as MeshData;
	}
	}
	return null;
}

public function getSkinnedMeshData():Vector<MeshData>
{
	var meshList:Vector<MeshData> = new Vector();
	for (var i:Int = 0, len:Int = _displayDataList.length; i < len; i++)
	{
	if (_displayDataList[i] is MeshData && (_displayDataList[i] as MeshData).skinned)
	{
		meshList.push(_displayDataList[i]);
	}
	}
	return meshList;
}

public function getCurSkinnedMeshData():MeshData
{
	var displayData:DisplayData = _displayDataList[_currentDisplayIndex];
	if (_isShowDisplay && 
	displayData is MeshData && 
	(displayData as MeshData).skinned)
	{
	return displayData as MeshData;
	}
	return null;
}
}