package dragonbones.objects;

import dragonBones.utils.TransformUtil;
import openfl.geom.DBMatrix;

/**
* Copyright 2012-2013. DragonBones. All Rights Reserved.
* @playerversion Flash 10.0
* @langversion 3.0
* @version 2.0
*/
class DBTransform
{
	/**
	 * Position on the x axis.
	 */
	public var x:Float;
	/**
	 * Position on the y axis.
	 */
	public var y:Float;
	/**
	 * Skew on the x axis.
	 */
	public var skewX:Float;
	/**
	 * skew on the y axis.
	 */
	public var skewY:Float;
	/**
	 * Scale on the x axis.
	 */
	public var scaleX:Float;
	/**
	 * Scale on the y axis.
	 */
	public var scaleY:Float;
	/**
	 * The rotation of that DBTransform instance.
	 */
	public var rotation(getRotation, setRotation):Float;
		private function getRotation():Float
	{
		return skewX;
	}
	private function setRotation(value:Float):Void
	{
		skewX = skewY = value;
	}
	/**
	 * Creat a new DBTransform instance.
	 */
	public function new()
	{
		x = 0;
		y = 0;
		skewX = 0;
		skewY = 0;
		scaleX = 1
		scaleY = 1;
	}
	/**
	 * Copy all properties from this DBTransform instance to the passed DBTransform instance.
	 * @param node
	 */
	public function copy(transform:DBTransform):Void
	{
		x = transform.x;
		y = transform.y;
		skewX = transform.skewX;
		skewY = transform.skewY;
		scaleX = transform.scaleX;
		scaleY = transform.scaleY;
	}

	public function add(transform:DBTransform):Void
	{
		x += transform.x;
		y += transform.y;
		skewX += transform.skewX;
		skewY += transform.skewY;
		scaleX *= transform.scaleX;
		scaleY *= transform.scaleY;
	}

	public function minus(transform:DBTransform):Void
	{
		x -= transform.x;
		y -= transform.y;
		skewX -= transform.skewX;
		skewY -= transform.skewY;
		scaleX /= transform.scaleX;
		scaleY /= transform.scaleY;
	}

	public function divParent(transform:DBTransform, createNew:Bool = false):DBTransform
	{
		var output:DBTransform = createNew ? new DBTransform() : this;
		var parentMatrix:DBMatrix = new DBMatrix();
		
		TransformUtil.transformToMatrix(transform, parentMatrix);
		var xtx:Float = x - parentMatrix.tx;
		var yty:Float = y - parentMatrix.ty;
		var adcb:Float = parentMatrix.a * parentMatrix.d - parentMatrix.c * parentMatrix.b;
		
		output.x = (xtx * parentMatrix.d - yty * parentMatrix.c)/adcb;
		output.y = (yty * parentMatrix.a - xtx * parentMatrix.b)/adcb;
		output.scaleX = scaleX / transform.scaleX;
		output.scaleY = scaleY / transform.scaleY;
		output.skewX = skewX - transform.skewX;
		output.skewY = skewY - transform.skewY;
		return output;
	}

	public function normalizeRotation():Void
	{
		skewX = TransformUtil.normalizeRotation(skewX);	
		skewY = TransformUtil.normalizeRotation(skewY);	
	}

	public function clone():DBTransform
	{
		var output:DBTransform = new DBTransform();
		output.copy(this);
		return output;
	}

	/**
	 * Get a string representing all DBTransform property values.
	 * @return String All property values in a formatted string.
	 */
	public function toString():String
	{
		var string:String = "x:" + x + " y:" + y + " skewX:" + skewX + " skewY:" + skewY + " scaleX:" + scaleX + " scaleY:" + scaleY;
		return string;
	}

}