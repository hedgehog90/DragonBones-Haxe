package dragonbones.objects;

import dragonBones.Armature;
import dragonBones.Bone;
import dragonBones.Slot;
import dragonBones.utils.TransformUtil;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.utils.Dictionary;
/**
 * ...
 * @author sukui
 */
import flash.Vector;

class MeshData extends DisplayData
{

private var _helpMatrix:Matrix;
private var _helpPoint:Point;
/**
 * 仅包含点坐标
 */
public var rawVertices:Vector<Float>;
public var triangles:Vector<Int>;
public var uvs:Vector<Float>;
public var edges:Vector<Int>;
public var updated:Bool;

private var _bones:Array;
private var _rigVertices:Vector<MeshRigData>

private var _boneMatrixDict:Dictionary = new Dictionary();
private var _skinned:Bool;

/**
 * 包含点坐标和uv
 */
public var vertices:Vector<Float>;
	
public function new() 
{
	super();
	_helpMatrix = new Matrix();
	_helpPoint = new Point();
}

public function updateVertices(offset:Int, offsetVertices:Vector<Float>):Void
{
	var i:Int = offset;
	var len:Int = offset + offsetVertices.length;
	var index:Int;
	for (; i < len; i++)
	{
	index = int(i / 2) * 4 + (i % 2);
	if (skinned)
	{
		vertices[index] += offsetVertices[i - offset];
	}
	else
	{
		vertices[index] = rawVertices[i] + offsetVertices[i - offset];
	}
	}
	updated = true;
}

public var skinned(getSkinned, setSkinned):Bool;
 	private function getSkinned():Bool
{
	return _skinned;
}

public var bones(null, setBones):Array;
 	private function setBones(value:Array):Void 
{
	_bones = value;
	_skinned = _bones != null && _bones.length > 0;
}

public function updateSkinnedMesh():Void
{	
	var vertex:Point;
	for (var i:Int = 0, len:Int = _rigVertices.length; i < len; i++)
	{
	vertex = _rigVertices[i].getFinalVertex();
	vertices[i * 4] = vertex.x;
	vertices[i * 4 + 1] = vertex.y;
	}
	updated = true;
}

/**
 * 此方法应在armature处于骨架状态下仅调用一次
 * @param	armature
 */
public function rig(armature:Armature, slot:Slot):Void
{
	_skinned = true;
	var boneName:String;
	var weight:Float;
	var bone:Bone;
	var meshRigData:MeshRigData;
	
	_rigVertices = new Vector();
	
	var vertexRigData:Array = getVertexRigData();
	var i:Int;
	while (vertexRigData)
	{
	trace(vertexRigData);
	_rigVertices.push(createRigVertex(i, vertexRigData, armature, slot));
	
	vertexRigData = getVertexRigData();
	i++;
	}
}

private function createRigVertex(index:Int, vertexRigData:Array, armature:Armature, slot:Slot):MeshRigData
{
	var meshRigData:MeshRigData = new MeshRigData();
	var num:Int = vertexRigData[0];
	
	var bone:Bone;
	var mat:Matrix;
	
	for (var i:Int = 0; i < num; i++)
	{
	bone = armature.getBone(vertexRigData[i * 2 + 1]);
	meshRigData.bones.push(bone);
	meshRigData.weights.push(vertexRigData[1 + i * 2 + 1]);
	
	mat = getBoneRelativeMatrix(bone, slot);
	_helpPoint.x = rawVertices[index * 2];
	_helpPoint.y = rawVertices[index * 2 + 1];
	_helpPoint = mat.transformPoint(_helpPoint);
	meshRigData.vertices.push(_helpPoint.x, _helpPoint.y);
	}
	trace(meshRigData.vertices);
	return meshRigData;
}

private function getVertexRigData():Array
{
	if (_bones.length == 0)
	{
	return null;
	}
	var num:Int = _bones[0];
	var arr:Array = _bones.splice(0, num * 2 + 1);
	return arr;
}

private function getBoneRelativeMatrix(bone:Bone, slot:Slot):Matrix
{
	if (_boneMatrixDict[bone] == null)
	{
	_boneMatrixDict[bone] = getRelativeMatrix(bone.global, slot.parent.global);
	}
	
	return _boneMatrixDict[bone] as Matrix;
}

private function getRelativeMatrix(boneTransform:DBTransform, slotTransform:DBTransform):Matrix
{
	var relativeMatrix:Matrix = new Matrix();
	if (boneTransform === slotTransform)
	{
	return relativeMatrix;
	}
	
	var boneMatrix:Matrix = new Matrix();
	TransformUtil.transformToMatrix(boneTransform, boneMatrix);
	var slotMatrix:Matrix = new Matrix();
	TransformUtil.transformToMatrix(slotTransform, slotMatrix);
	var absMatrix:Matrix = new Matrix;
	TransformUtil.transformToMatrix(this.transform, absMatrix);
	
	absMatrix.concat(slotMatrix);
	
	boneMatrix.invert();
	
	relativeMatrix.copyFrom(absMatrix);
	relativeMatrix.concat(boneMatrix);
	
	return relativeMatrix;
}

}