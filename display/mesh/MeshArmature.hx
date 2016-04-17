package dragonbones.display.mesh;

import flash.geom.Point;
import starling.core.RenderSupport;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
/**
 * 把meshImage放在这个容器里会提高渲染效率
 * @author sukui
 */
class MeshArmature extends DisplayObjectContainer
{

public function new() 
{
	
}
override public function render(support:RenderSupport, parentAlpha:Float):Void 
{
	super.render(support, parentAlpha);
	if (MeshImage.meshBatch)
	{
	MeshImage.meshBatch.flush();
	}
}

}