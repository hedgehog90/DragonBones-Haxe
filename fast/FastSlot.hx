package dragonbones.fast;

import dragonBones.objects.ParentTransformObject;
import flash.errors.IllegalOperationError;
import flash.geom.ColorTransform;
import flash.geom.Matrix;

import dragonBones.cache.SlotFrameCache;
import dragonBones.core.IArmature;
import dragonBones.core.ISlotCacheGenerator;
import dragonBones.core.dragonBones_internal;
import dragonBones.fast.animation.FastAnimationState;
import dragonBones.objects.DisplayData;
import dragonBones.objects.Frame;
import dragonBones.objects.SlotData;
import dragonBones.objects.SlotFrame;
import dragonBones.utils.ColorTransformUtil;
import dragonBones.utils.TransformUtil;

import flash.Vector;

class FastSlot extends FastDBObject implements ISlotCacheGenerator
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
private var _isColorChanged:Bool;
private var _currentDisplay:Object;

private var _blendMode:String;

public var hasChildArmature:Bool;
public function new(self:FastSlot)
{
	super();
	
	if(self != this)
	{
	throw new IllegalOperationError("Abstract class can not be instantiated!");
	}
	hasChildArmature = false;
	_currentDisplayIndex = -1;
	
	_originZOrder = 0;
	_tweenZOrder = 0;
	_offsetZOrder = 0;
	_colorTransform = new ColorTransform();
	_isColorChanged = false;
	_displayDataList = null;
	_currentDisplay = null;
	
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
	
	_displayDataList = null;
	_displayList = null;
	_currentDisplay = null;
}

//动画
/** @private */
override private function updateByCache():Void
{
	super.updateByCache();
	updateTransform();
//颜色
	var cacheColor:ColorTransform = (this._frameCache as SlotFrameCache).colorTransform;
	var cacheColorChanged:Bool = cacheColor != null;
	if(	this.colorChanged != cacheColorChanged ||
	(this.colorChanged && cacheColorChanged && !ColorTransformUtil.isEqual(_colorTransform, cacheColor)))
	{
	cacheColor = cacheColor || ColorTransformUtil.originalColor;
	updateDisplayColor(	cacheColor.alphaOffset, 
				cacheColor.redOffset, 
				cacheColor.greenOffset, 
				cacheColor.blueOffset,
				cacheColor.alphaMultiplier, 
				cacheColor.redMultiplier, 
				cacheColor.greenMultiplier, 
				cacheColor.blueMultiplier,
				cacheColorChanged);
	}
	
//displayIndex
	changeDisplayIndex((this._frameCache as SlotFrameCache).displayIndex);
	this.gotoAndPlay = (this._frameCache as SlotFrameCache).gotoAndPlay;
}

/** @private */
private function update():Void
{
	if(this._parent._needUpdate <= 0)
	{
	return;
	}
	
	var result:ParentTransformObject = updateGlobal();
	if (result)
	{
	result.release();
	}
	updateTransform();
}

override private function calculateRelativeParentTransform():Void
{
	_global.copy(this._origin);
	_global.x += this._parent._tweenPivot.x;
	_global.y += this._parent._tweenPivot.y;
}

private function updateChildArmatureAnimation():Void
{
	if(childArmature)
	{
	if(_currentDisplayIndex >= 0)
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
		if (this.armature && this.armature.animation.lastAnimationState)
		{
			curAnimation = this.armature.animation.lastAnimationState.name;
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

private function initDisplayList(newDisplayList:Array):Void
{
	this._displayList = newDisplayList;
}

private function clearCurrentDisplay():Int
{
	if(hasChildArmature)
	{
	var targetArmature:IArmature = this.childArmature as IArmature;
	if(targetArmature)
	{
		targetArmature.resetAnimation()
	}
	}
	if (_isColorChanged)
	{
	updateDisplayColor(0, 0, 0, 0, 1, 1, 1, 1, true);
	}
	var slotIndex:Int = getDisplayIndex();
	removeDisplayFromContainer();
	return slotIndex;
}

/** @private */
private function changeDisplayIndex(displayIndex:Int):Void
{
	if(_currentDisplayIndex == displayIndex)
	{
	return;
	}
	
	var slotIndex:Int = -1;

	if(_currentDisplayIndex >=0)
	{
	slotIndex = clearCurrentDisplay();
	}
	
	_currentDisplayIndex = displayIndex;
	
	if(_currentDisplayIndex >=0)
	{
	this._origin.copy(_displayDataList[_currentDisplayIndex].transform);
	this.initCurrentDisplay(slotIndex);
	}
}

//currentDisplayIndex不变，改变内容，必须currentDisplayIndex >=0
private function changeSlotDisplay(value:Object):Void
{
	var slotIndex:Int = clearCurrentDisplay();
	_displayList[_currentDisplayIndex] = value;
	this.initCurrentDisplay(slotIndex);
}

private function initCurrentDisplay(slotIndex:Int):Void
{
	var display:Object = _displayList[_currentDisplayIndex];
	if (display)
	{
	if(display is FastArmature)
	{
		_currentDisplay = (display as FastArmature).display;
	}
	else
	{
		_currentDisplay = display;
	}
	}
	else
	{
	_currentDisplay = null;
	}
	
	updateDisplay(_currentDisplay);
	if(_currentDisplay)
	{
	if(slotIndex != -1)
	{
		addDisplayToContainer(this.armature.display, slotIndex);
	}
	else
	{
		this.armature._slotsZOrderChanged = true;
		addDisplayToContainer(this.armature.display);
	}
	
	if(_blendMode)
	{
		updateDisplayBlendMode(_blendMode);
	}
	if(_isColorChanged)
	{
		updateDisplayColor(	_colorTransform.alphaOffset, 
		_colorTransform.redOffset, 
		_colorTransform.greenOffset, 
		_colorTransform.blueOffset,
		_colorTransform.alphaMultiplier, 
		_colorTransform.redMultiplier, 
		_colorTransform.greenMultiplier, 
		_colorTransform.blueMultiplier,
		true);
	}
	updateTransform();
	
	if(display is FastArmature)
	{
		var targetArmature:FastArmature = display as FastArmature;
		
		if(	this.armature &&
		this.armature.animation.animationState &&
		targetArmature.animation.hasAnimation(this.armature.animation.animationState.name))
		{
		targetArmature.animation.gotoAndPlay(this.armature.animation.animationState.name);
		}
		else
		{
		targetArmature.animation.play();
		}
	}
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
	//todo: 考虑子骨架变化的各种情况
	if(!value)
	{
	throw new ArgumentError();
	}
	
	var newDisplay:Object = value[_currentDisplayIndex];
	var displayChanged:Bool = _currentDisplayIndex >= 0 && _displayList[_currentDisplayIndex] != newDisplay;
	
	_displayList = value;
	
	if(displayChanged)
	{
	changeSlotDisplay(newDisplay);
	}
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
	//todo: 考虑子骨架变化的各种情况进行进一步测试
	if (_currentDisplayIndex < 0)
	{
	_currentDisplayIndex = 0;
	}
	if(_displayList[_currentDisplayIndex] == value)
	{
	return;
	}
	
	changeSlotDisplay(value);
}

/**
 * The sub-armature of this Slot instance.
 */
public var childArmature(getChildArmature, setChildArmature):Object;
 	private function getChildArmature():Object
{
	return _displayList[_currentDisplayIndex] is IArmature ? _displayList[_currentDisplayIndex] : null;
}

private function setChildArmature(value:Object):Void
{
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
	if(this.armature)
	{
		this.armature._slotsZOrderChanged = true;
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

private function setGotoAndPlay(value:String):Void 
{
	if (_gotoAndPlay != value)
	{
	_gotoAndPlay = value;
	updateChildArmatureAnimation();
	}
	
}

/**
 * Indicates the Bone instance that directly contains this DBObject instance if any.
 */
public var colorTransform(getColorTransform, setColorTransform):ColorTransform;
 	private function getColorTransform():ColorTransform
{
	return _colorTransform;
}

public var display(getDisplay, setDisplay):Object;
 	private function getDisplayIndex():Int
{
	return _currentDisplayIndex;
}

public var colorChanged(getColorChanged, setColorChanged):Bool;
 	private function getColorChanged():Bool
{
	return _isColorChanged;
}

public var gotoAndPlay(getGotoAndPlay, setGotoAndPlay):String;
 	private function getGotoAndPlay():String 
{
	return _gotoAndPlay;
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
private function arriveAtFrame(frame:Frame, animationState:FastAnimationState):Void
{
	var slotFrame:SlotFrame = frame as SlotFrame;
	var displayIndex:Int = slotFrame.displayIndex;
	changeDisplayIndex(displayIndex);
	updateDisplayVisible(slotFrame.visible);
	if(displayIndex >= 0)
	{
	if(!isNaN(slotFrame.zOrder) && slotFrame.zOrder != _tweenZOrder)
	{
		_tweenZOrder = slotFrame.zOrder;
		this.armature._slotsZOrderChanged = true;
	}
	}
	//[TODO]currently there is only gotoAndPlay belongs to frame action. In future, there will be more.  
	//后续会扩展更多的action，目前只有gotoAndPlay的含义
	if(frame.action) 
	{
	var targetArmature:IArmature = childArmature as IArmature;
	if (targetArmature)
	{
		targetArmature.getAnimation().gotoAndPlay(frame.action);
	}
	}
	else
	{
	this.gotoAndPlay = slotFrame.gotoAndPlay;
	}
}

	/** @private */
private function hideSlots():Void
{
	changeDisplayIndex( -1);
	removeDisplayFromContainer();
	if (_frameCache)
	{
	this._frameCache.clear();
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
	changeDisplayIndex(_originDisplayIndex);
	updateDisplayColor(0, 0, 0, 0, 1, 1, 1, 1, true);
}
}