package dragonbones.fast;

import flash.geom.Point;

import dragonBones.objects.IKData;

import flash.Vector;

class FastIKConstraint
{
private var ikdata:IKData;
private var armature:FastArmature;

public var bones:Vector<FastBone>;
public var target:FastBone;
public var bendDirection:Int;
public var weight:Float;

public var animationCacheBend:Int=0;	
public var animationCacheWeight:Float=-1;	

public function new(data:IKData,armatureData:FastArmature)
{
	this.ikdata = data;
	this.armature = armatureData
	
	weight = data.weight;
	bendDirection = (data.bendPositive?1:-1);
	bones = new Vector();
	var bone:FastBone;
	if(data.chain){
	bone = armatureData.getBone(data.bones).parent;
	bone.isIKConstraint = true;
	bones.push(bone);
	}
	bone = armatureData.getBone(data.bones);
	bone.isIKConstraint = true;
	bones.push(bone);
	target = armatureData.getBone(data.target);
}
public function dispose():Void
{
	
}
public function compute():Void
{
	switch (bones.length) {
	case 1:
		var weig1:Float = animationCacheWeight>=0?animationCacheWeight:weight;
		compute1(bones[0], target, weig1);
		break;
	case 2:
		var bend:Int = animationCacheBend!=0?animationCacheBend:bendDirection;
		var weig:Float = animationCacheWeight>=0?animationCacheWeight:weight;
		var tt:Point = compute2(bones[0],bones[1],target.global.x,target.global.y, bend, weig);
		bones[0].rotationIK = tt.x;
		bones[1].rotationIK = tt.y+tt.x;
		break;
	}
}
public function compute1 (bone:FastBone, target:FastBone, weightA:Float) : Void {
	var parentRotation:Float = (!bone.inheritRotation || bone.parent == null) ? 0 : bone.parent.global.rotation;
	var rotation:Float = bone.global.rotation;
	var rotationIK:Float = Math.atan2(target.global.y - bone.global.y, target.global.x - bone.global.x);
	bone.rotationIK = rotation + (rotationIK - rotation) * weightA;
}
public function compute2(parent:FastBone, child:FastBone, targetX:Float,targetY:Float, bendDirection:Int, weightA:Float):Point
{
	//添加斜切后的算法，现在用的
	if (weightA == 0) {
	return new Point(parent.global.rotation,child.global.rotation);
	}
	var tt:Point = new Point();
	/**父的绝对坐标**/
	var p1:Point = new Point(parent.global.x,parent.global.y);
	/**子的绝对坐标**/
	var p2:Point = new Point(child.global.x,child.global.y);
	var psx:Float = parent.global.scaleX;
	var psy:Float = parent.global.scaleY;
	var csx:Float = child.global.scaleX;
	var csy:Float = child.global.scaleY;
	
	var cx:Float = child.origin.x*psx;
	var cy:Float = child.origin.y*psy;
	var initalRotation:Float = Math.atan2(cy, cx);//差值等于子在父落点到父的角度
	
	var childX:Float = p2.x-p1.x;
	var childY:Float = p2.y-p1.y;
	/**d1的长度**/
	var len1:Float = Math.sqrt(childX * childX + childY* childY);
	var parentAngle:Float;
	var childAngle:Float;
	outer:
	if (Math.abs(psx - psy) <= 0.001) {
	var childlength:Float = child.length;
	var len2:Float = childlength*csx;
	targetX = targetX-p1.x;
	targetY = targetY-p1.y;
	var cosDenom:Float = 2 * len1 * len2;
	if (cosDenom < 0.0001) {
		var temp:Float = Math.atan2(targetY, targetX);
		tt.x = temp  * weightA - initalRotation;
		tt.y = temp  * weightA + initalRotation//+ tt.x ;
		normalize(tt.x);
		normalize(tt.y);
		return tt;
	}
	var cos:Float = (targetX * targetX + targetY * targetY - len1 * len1 - len2 * len2) / cosDenom;
	if (cos < -1)
		cos = -1;
	else if (cos > 1)
		cos = 1;
	childAngle = Math.acos(cos) * bendDirection;//o2
	var adjacent:Float = len1 + len2 * cos;  //ae
	var opposite:Float = len2 * Math.sin(childAngle);//be
	parentAngle = Math.atan2(targetY * adjacent - targetX * opposite, targetX * adjacent + targetY * opposite);//o1
	tt.x = parentAngle * weightA-initalRotation;
	tt.y = childAngle* weightA+initalRotation;//+tt.x;
	}else{//一旦父已经扭曲，子重新计算长度
	var l1:Float = len1;
	var tx:Float = targetX-p1.x;
	var ty:Float = targetY-p1.y;
	var l2:Float = child.length*child.origin.scaleX;//child.currentLocalTransform.scaleX;
	var a:Float = psx * l2;
	var b:Float = psy * l2;
	var ta:Float = Math.atan2(ty, tx);
	var aa:Float = a * a;
	var bb:Float = b * b;
	var ll:Float = l1 * l1;
	var dd:Float = tx * tx + ty * ty;
	var c0:Float = bb * ll + aa * dd - aa * bb;
	var c1:Float = -2 * bb * l1;
	var c2:Float = bb - aa;
	var d:Float = c1 * c1 - 4 * c2 * c0;
	if (d >= 0) {
		var q:Float =Math.sqrt(d);
		if (c1 < 0) q = -q;
		q = -(c1 + q) / 2;
		var r0:Float = q / c2
		var r1:Float = c0 / q;
		var r:Float = Math.abs(r0) < Math.abs(r1) ? r0 : r1;
		if (r * r <= dd) {
		var y1:Float = Math.sqrt(dd - r * r) * bendDirection;
		parentAngle = ta - Math.atan2(y1, r);
		childAngle = Math.atan2(y1 / psy, (r - l1) / psx);
		tt.x = parentAngle* weightA-initalRotation;
		tt.y = childAngle* weightA+initalRotation;//+tt.x;
		break outer;
		}
	}
	var minAngle:Float = 0;
	var minDist:Float = Number.MAX_VALUE;
	var minX:Float = 0;
	var minY:Float = 0;
	var maxAngle:Float = 0;
	var maxDist:Float = 0;
	var maxX:Float = 0;
	var maxY:Float = 0;
	var x2:Float = l1 + a;
	var dist:Float = x2 * x2;
	if (dist > maxDist) {
		maxAngle = 0;
		maxDist = dist;
		maxX = x2;
	}
	x2 = l1 - a;
	dist = x2 * x2;
	if (dist < minDist) {
		minAngle = Math.PI;
		minDist = dist;
		minX = x2;
	}
	var angle1:Float = Math.acos(-a * l1 / (aa - bb));
	x2 = a * Math.cos(angle1) + l1;
	var y2:Float = b * Math.sin(angle1);
	dist = x2 * x2 + y2 * y2;
	if (dist < minDist) {
		minAngle = angle1;
		minDist = dist;
		minX = x2;
		minY = y2;
	}
	if (dist > maxDist) {
		maxAngle = angle1;
		maxDist = dist;
		maxX = x2;
		maxY = y2;
	}
	if (dd <= (minDist + maxDist) / 2) {
		parentAngle = ta - Math.atan2(minY * bendDirection, minX);
		childAngle = minAngle * bendDirection;
	} else {
		parentAngle = ta - Math.atan2(maxY * bendDirection, maxX);
		childAngle = maxAngle * bendDirection;
	}
	tt.x = parentAngle* weightA-initalRotation;
	tt.y = childAngle* weightA+initalRotation;//;
	}
	normalize(tt.x);
	normalize(tt.y);
	return tt;
}
private function normalize(rotation:Float):Void
{
	if (rotation > Math.PI)
	rotation -= Math.PI*2;
	else if (rotation < -Math.PI)
	rotation += Math.PI*2;
}
}