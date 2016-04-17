package dragonbones.display.mesh;

import dragonBones.objects.MeshData;
import starling.textures.Texture;
/**
 * ...
 * @author sukui
 */
import flash.Vector;

class MeshQuadImage extends MeshImage
{

public function new(texture:Texture) 
{
	var w:Float = texture.width;
	var h:Float = texture.height;
	
	var meshData:MeshData = new MeshData();
	var vertices:Vector<Float> = new Vector();
	vertices.push(0, 0, 0, 0);
	vertices.push(0, h, 0, 1);
	vertices.push(w, 0, 1, 0);
	vertices.push(w, h, 1, 1);
	var triangles:Vector<Int> = new Vector();
	triangles.push(0, 1, 2);
	triangles.push(1, 3, 2);
	meshData.vertices = vertices;
	meshData.triangles = triangles;
	super(texture, meshData);
}

}