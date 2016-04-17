package dragonbones.display;

import flash.display.BlendMode;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;

import dragonBones.core.dragonBones_internal;
import dragonBones.fast.FastSlot;

use namespace dragonBones_internal;

class NativeFastSlot extends FastSlot
{
private var _nativeDisplay:DisplayObject;

public function new()
{
	super(this);
	_nativeDisplay = null;
}

override public function dispose():Void
{
	super.dispose();
	
	_nativeDisplay = null;
}


//Abstract method

/** @private */
override dragonBones_private function updateDisplay(value:Object):Void
{
	_nativeDisplay = value as DisplayObject;
}

/** @private */
override dragonBones_private function getDisplayIndex():Int
{
	if(_nativeDisplay && _nativeDisplay.parent)
	{
	return _nativeDisplay.parent.getChildIndex(_nativeDisplay);
	}
	return -1;
}

/** @private */
override dragonBones_private function addDisplayToContainer(container:Object, index:Int = -1):Void
{
	var nativeContainer:DisplayObjectContainer = container as DisplayObjectContainer;
	if(_nativeDisplay && nativeContainer)
	{
	if (index < 0)
	{
		nativeContainer.addChild(_nativeDisplay);
		
	}
	else
	{
		nativeContainer.addChildAt(_nativeDisplay, Math.min(index, nativeContainer.numChildren));
	}
	}
}

/** @private */
override dragonBones_private function removeDisplayFromContainer():Void
{
	if(_nativeDisplay && _nativeDisplay.parent)
	{
	_nativeDisplay.parent.removeChild(_nativeDisplay);
	}
}

/** @private */
override dragonBones_private function updateTransform():Void
{
	if(_nativeDisplay)
	{
	_nativeDisplay.transform.matrix = this._globalTransformMatrix;
	}
}

/** @private */
override dragonBones_private function updateDisplayVisible(value:Bool):Void
{
	//if(_nativeDisplay)
	//{
	//_nativeDisplay.visible = this._parent.visible && this._visible && value;
	//}
}

/** @private */
override dragonBones_private function updateDisplayColor(
	aOffset:Float, 
	rOffset:Float, 
	gOffset:Float, 
	bOffset:Float, 
	aMultiplier:Float, 
	rMultiplier:Float, 
	gMultiplier:Float, 
	bMultiplier:Float,
	colorChanged:Bool = false):Void
{
	if(_nativeDisplay)
	{
	super.updateDisplayColor(aOffset, rOffset, gOffset, bOffset, aMultiplier, rMultiplier, gMultiplier, bMultiplier,colorChanged);
	
	
	_nativeDisplay.transform.colorTransform = _colorTransform;
	}
}

/** @private */
override dragonBones_private function updateDisplayBlendMode(value:String):Void
{
	if(_nativeDisplay)
	{
	switch(blendMode)
	{
		case BlendMode.ADD:
		case BlendMode.ALPHA:
		case BlendMode.DARKEN:
		case BlendMode.DIFFERENCE:
		case BlendMode.ERASE:
		case BlendMode.HARDLIGHT:
		case BlendMode.INVERT:
		case BlendMode.LAYER:
		case BlendMode.LIGHTEN:
		case BlendMode.MULTIPLY:
		case BlendMode.NORMAL:
		case BlendMode.OVERLAY:
		case BlendMode.SCREEN:
		case BlendMode.SHADER:
		case BlendMode.SUBTRACT:
		_nativeDisplay.blendMode = blendMode;
		break;
		
		default:
		//_nativeDisplay.blendMode = BlendMode.NORMAL;
		break;
	}
	}
}
}