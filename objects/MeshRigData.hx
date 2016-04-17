package dragonbones.objects;

import dragonBones.Bone;
import dragonBones.utils.TransformUtil;
import flash.geom.Matrix;
import flash.geom.Point;
/**
 * ...
 * @author sukui
 */
import flash.Vector;

class MeshRigData 
{	
public var bones:Vector<Bone>;
public var weights:Vector<Float>;
public var vertices:Vector<Float>;

private var _vertex:Point;

private var _helpMatrix:Matrix;
private var _helpPoint:Point;

public function new() 
{
	bones = new Vector();
	weights = new Vector();
	vertices = new Vector();
	_vertex = new Point();
	
	_helpMatrix = new Matrix();
	_helpPoint = new Point();
}

public function getFinalVertex():Point
{
	var weight:Float;
	_vertex.x = 0;
	_vertex.y = 0;
	for (var i:Int = 0, len:Int = bones.length; i < len; i++)
	{
	TransformUtil.transformToMatrix(bones[i].global, _helpMatrix);
	weight = weights[i];
	_helpPoint.x = vertices[i * 2];
	_helpPoint.y = vertices[i * 2 + 1];
	_helpPoint = _helpMatrix.transformPoint(_helpPoint);
	_vertex.x += _helpPoint.x * weight;
	_vertex.y += _helpPoint.y * weight;
	}
	return _vertex;
}

}