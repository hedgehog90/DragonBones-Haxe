package dragonbones.utils;

import flash.geom.Matrix;
import openfl.geom.DBMatrix;

import dragonBones.objects.DBTransform;

/**
 * @author CG
 */
final import flash.Vector;

class TransformUtil
{
	public static inline var ANGLE_TO_RADIAN:Float = Math.PI / 180;
	public static inline var RADIAN_TO_ANGLE:Float = 180 / Math.PI;

	private static inline var HALF_PI:Float = Math.PI * 0.5;
	private static inline var DOUBLE_PI:Float = Math.PI * 2;

	private static inline var _helpTransformMatrix:Matrix = new Matrix();
	private static inline var _helpParentTransformMatrix:Matrix = new Matrix();

	//optimized by freem-trg
	private static var tmpSkewXArray:Vector<Float> = new Vector<Float>(4);
	private static var tmpSkewYArray:Vector<Float> = new Vector<Float>(4);
	private static var ACCURACY : Float = 0.0001;
	 
	public static function transformToMatrix(transform:DBTransform, matrix:DBMatrix):Void
	{
		matrix.a = transform.scaleX * Math.cos(transform.skewY)
		matrix.b = transform.scaleX * Math.sin(transform.skewY)
		matrix.c = -transform.scaleY * Math.sin(transform.skewX);
		matrix.d = transform.scaleY * Math.cos(transform.skewX);
		matrix.tx = transform.x;
		matrix.ty = transform.y;
	}

 	private static inline function isEqual(n1:Float, n2:Float):Bool
 	{
 		if (n1 >= n2)
 		{
			return (n1 - n2) <= ACCURACY;
 		}
		else
 		{
			return (n2 - n1) <= ACCURACY;
 		}
 	}
	 
	public static function formatRadian(radian:Float):Float
	{
		//radian %= DOUBLE_PI;
		if (radian > Math.PI)
		{
			radian -= DOUBLE_PI;
		}
		if (radian < -Math.PI)
		{
			radian += DOUBLE_PI;
		}
		return radian;
	}

	//这个算法如果用于骨骼间的绝对转相对请改为DBTransform.divParent()方法
	public static function globalToLocal(transform:DBTransform, parent:DBTransform):Void
	{
		transformToMatrix(transform, _helpTransformMatrix);
		transformToMatrix(parent, _helpParentTransformMatrix);
		
		_helpParentTransformMatrix.invert();
		_helpTransformMatrix.concat(_helpParentTransformMatrix);
		
		matrixToTransform(_helpTransformMatrix, transform, transform.scaleX * parent.scaleX >= 0, transform.scaleY * parent.scaleY >= 0);
	}

	public static function matrixToTransform(matrix:Matrix, transform:DBTransform, scaleXF:Bool, scaleYF:Bool):Void
	{
		transform.x = matrix.tx;
		transform.y = matrix.ty;
		transform.scaleX = Math.sqrt(matrix.a * matrix.a + matrix.b * matrix.b) * (scaleXF ? 1 : -1);
		transform.scaleY = Math.sqrt(matrix.d * matrix.d + matrix.c * matrix.c) * (scaleYF ? 1 : -1);
		
		tmpSkewXArray[0] = Math.acos(matrix.d / transform.scaleY);
		tmpSkewXArray[1] = -tmpSkewXArray[0];
		tmpSkewXArray[2] = Math.asin(-matrix.c / transform.scaleY);
		tmpSkewXArray[3] = tmpSkewXArray[2] >= 0 ? Math.PI - tmpSkewXArray[2] : tmpSkewXArray[2] - Math.PI;
		
		if(isEqual(tmpSkewXArray[0],tmpSkewXArray[2]) || isEqual(tmpSkewXArray[0],tmpSkewXArray[3]))
		{
			transform.skewX = tmpSkewXArray[0];
		}
		else 
		{
			transform.skewX = tmpSkewXArray[1];
		}
		
		tmpSkewYArray[0] = Math.acos(matrix.a / transform.scaleX);
		tmpSkewYArray[1] = -tmpSkewYArray[0];
		tmpSkewYArray[2] = Math.asin(matrix.b / transform.scaleX);
		tmpSkewYArray[3] = tmpSkewYArray[2] >= 0 ? Math.PI - tmpSkewYArray[2] : tmpSkewYArray[2] - Math.PI;
		
		if(isEqual(tmpSkewYArray[0],tmpSkewYArray[2]) || isEqual(tmpSkewYArray[0],tmpSkewYArray[3]))
		{
			transform.skewY = tmpSkewYArray[0];
		}
		else 
		{
			transform.skewY = tmpSkewYArray[1];
		}
	}
	//确保角度在-180到180之间
	public static function normalizeRotation(rotation:Float):Float
	{
		rotation = (rotation + Math.PI)%(2*Math.PI);
		rotation = rotation > 0 ? rotation : 2*Math.PI + rotation;
		return rotation - Math.PI;
	}

	public static inline function matrixToTransformPosition(matrix:Matrix, transform:DBTransform):Void
	{
		transform.x = matrix.tx;
		transform.y = matrix.ty;
	}

	public static inline function matrixToTransformScale(matrix:Matrix, transform:DBTransform, scaleXF:Bool, scaleYF:Bool):Void
	{
		transform.scaleX = Math.sqrt(matrix.a * matrix.a + matrix.b * matrix.b) * (scaleXF ? 1 : -1);
		transform.scaleY = Math.sqrt(matrix.d * matrix.d + matrix.c * matrix.c) * (scaleYF ? 1 : -1);
	}

	public static inline function matrixToTransformRotation(matrix:Matrix, transform:DBTransform, scaleX:Float, scaleY:Float):Void
	{
		tmpSkewXArray[0] = Math.acos(matrix.d / scaleY);
		tmpSkewXArray[1] = -tmpSkewXArray[0];
		tmpSkewXArray[2] = Math.asin(-matrix.c / scaleY);
		tmpSkewXArray[3] = tmpSkewXArray[2] >= 0 ? Math.PI - tmpSkewXArray[2] : tmpSkewXArray[2] - Math.PI;
		
		if(isEqual(tmpSkewXArray[0], tmpSkewXArray[2]) || isEqual(tmpSkewXArray[0], tmpSkewXArray[3]))
		{
			transform.skewX = tmpSkewXArray[0];
		}
		else 
		{
			transform.skewX = tmpSkewXArray[1];
		}
		
		tmpSkewYArray[0] = Math.acos(matrix.a / scaleX);
		tmpSkewYArray[1] = -tmpSkewYArray[0];
		tmpSkewYArray[2] = Math.asin(matrix.b / scaleX);
		tmpSkewYArray[3] = tmpSkewYArray[2] >= 0 ? Math.PI - tmpSkewYArray[2] : tmpSkewYArray[2] - Math.PI;
		
		if(isEqual(tmpSkewYArray[0],tmpSkewYArray[2]) || isEqual(tmpSkewYArray[0], tmpSkewYArray[3]))
		{
			transform.skewY = tmpSkewYArray[0];
		}
		else 
		{
			transform.skewY = tmpSkewYArray[1];
		}
	}
}