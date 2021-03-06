package net.hxpunk.masks;

import flash.display.BitmapData;
import flash.display.Graphics;
import flash.errors.Error;
import flash.geom.Point;
import net.hxpunk.Entity;
import net.hxpunk.HP;
import net.hxpunk.Mask;
import net.hxpunk.masks.Circle;
import net.hxpunk.masks.Grid;
import net.hxpunk.masks.Hitbox;
import net.hxpunk.masks.Pixelmask;
import net.hxpunk.utils.Draw;


/** 
 * Uses polygonal structure to check for collisions.
 */
class Polygon extends Hitbox
{
	private static var init:Bool = initStaticVars();
	
	/**
	 * X coord to use for rotations.
	 * Defaults to top-left corner.
	 */
	public var originX:Float = 0;
	
	/**
	 * Y coord to use for rotations.
	 * Defaults to top-left corner.
	 */
	public var originY:Float = 0;
	
	
	/**
	 * Constructor.
	 * @param	points		An array of coordinates that define the polygon (must have at least 3)
	 * @param	x			X offset of the polygon.
	 * @param	y			Y offset of the polygon.
	 * @param	originX		X pivot for rotations.
	 * @param	originY		Y pivot for rotations.
	 */
	public function new(points:Array<Point>, x:Int = 0, y:Int = 0, originX:Float = 0, originY:Float = 0)
	{
		super();
		if (points.length < 3) throw new Error("The polygon needs at least 3 sides.");
		_points = points;
		_projection = { min:0.0, max:0.0 };
		_indicesToRemove = new Array<Int>();
		_fakeEntity = new Entity();
		_fakeTileHitbox = new Hitbox();
		_fakePixelmask = new Pixelmask(new BitmapData(1, 1));

		_check.set(Type.getClassName(Mask), collideMask);
		_check.set(Type.getClassName(Hitbox), collideHitbox);
		_check.set(Type.getClassName(Grid), collideGrid);
		_check.set(Type.getClassName(Pixelmask), collidePixelmask);
		_check.set(Type.getClassName(Circle), collideCircle);
		_check.set(Type.getClassName(Polygon), collidePolygon);

		_x = x;
		_y = y;
		this.originX = originX;
		this.originY = originY;
		_angle = 0;

		updateAxes();
	}
	
	private static function initStaticVars():Bool 
	{
		firstProj = { min:0.0, max:0.0 };
		secondProj = { min:0.0, max:0.0 };

		verticalAxis = new Point(0, 1);
		horizontalAxis = new Point(1, 0);
		
		return true;
	}

	/**
	 * Checks for collisions with an Entity.
	 */
	override private function collideMask(other:Mask):Bool
	{
		var offset:Float,
			offsetX:Float = parent.x + _x - other.parent.x,
			offsetY:Float = parent.y + _y - other.parent.y;

		// project on the vertical axis of the hitbox/mask
		project(verticalAxis, firstProj);
		other.project(verticalAxis, secondProj);

		firstProj.min += offsetY;
		firstProj.max += offsetY;

		// if firstProj not overlaps secondProj
		if (firstProj.min > secondProj.max || firstProj.max < secondProj.min)
		{
			return false;
		}
		
		// project on the horizontal axis of the hitbox/mask
		project(horizontalAxis, firstProj);
		other.project(horizontalAxis, secondProj);

		firstProj.min += offsetX;
		firstProj.max += offsetX;

		// if firstProj not overlaps secondProj
		if (firstProj.min > secondProj.max || firstProj.max < secondProj.min)
		{
			return false;
		}

		var a:Point;
		
		// project hitbox/mask on polygon axes
		// for a collision to be present all projections must overlap
		for (i in 0..._axes.length)
		{
			a = _axes[i];
			project(a, firstProj);
			other.project(a, secondProj);

			offset = offsetX * a.x + offsetY * a.y;
			firstProj.min += offset;
			firstProj.max += offset;

			// if firstProj not overlaps secondProj
			if (firstProj.min > secondProj.max || firstProj.max < secondProj.min)
			{
				return false;
			}
		}
		return true;
	}

	/**
	 * Checks for collisions with a Hitbox.
	 */
	override private function collideHitbox(hitbox:Hitbox):Bool
	{
		var offset:Float,
			offsetX:Float = parent.x + _x - hitbox.parent.x,
			offsetY:Float = parent.y + _y - hitbox.parent.y;

		// project on the vertical axis of the hitbox
		project(verticalAxis, firstProj);
		hitbox.project(verticalAxis, secondProj);

		firstProj.min += offsetY;
		firstProj.max += offsetY;

		// if firstProj not overlaps secondProj
		if (firstProj.min > secondProj.max || firstProj.max < secondProj.min)
		{
			return false;
		}

		// project on the horizontal axis of the hitbox
		project(horizontalAxis, firstProj);
		hitbox.project(horizontalAxis, secondProj);

		firstProj.min += offsetX;
		firstProj.max += offsetX;

		// if firstProj not overlaps secondProj
		if (firstProj.min > secondProj.max || firstProj.max < secondProj.min)
		{
			return false;
		}

		var a:Point;
		
		// project hitbox on polygon axes
		// for a collision to be present all projections must overlap
		for (i in 0..._axes.length)
		{
			a = _axes[i];
			project(a, firstProj);
			hitbox.project(a, secondProj);

			offset = offsetX * a.x + offsetY * a.y;
			firstProj.min += offset;
			firstProj.max += offset;

			// if firstProj not overlaps secondProj
			if (firstProj.min > secondProj.max || firstProj.max < secondProj.min)
			{
				return false;
			}
		}
		return true;
	}

	/**
	 * Checks for collisions with a Grid.
	 * May be slow, added for completeness sake.
	 * 
	 * Internally sets up an Hitbox out of each solid Grid tile and uses that for collision check.
	 */
	private function collideGrid(grid:Grid):Bool
	{
		var tileW:Int = grid.tileWidth;
		var tileH:Int = grid.tileHeight;
		var solidTile:Bool;
		
		_fakeEntity.width = tileW;
		_fakeEntity.height = tileH;
		_fakeEntity.x = parent.x;
		_fakeEntity.y = parent.y;
		_fakeEntity.originX = grid.parent.originX + grid._x;
		_fakeEntity.originY = grid.parent.originY + grid._y;
		
		_fakeTileHitbox._width = tileW;
		_fakeTileHitbox._height = tileH;
		_fakeTileHitbox.parent = _fakeEntity;
		
		for (r in 0...grid.rows) {
			for (c in 0...grid.columns) {
				_fakeEntity.x = grid.parent.x + grid._x + c * tileW;
				_fakeEntity.y = grid.parent.y + grid._y + r * tileH;
				solidTile = grid.getTile(c, r);
				
				if (solidTile && collideHitbox(_fakeTileHitbox)) return true;
			}
		}
		return false;
	}

	/**
	 * Checks for collision with a Pixelmask.
	 * May be slow (especially with big polygons), added for completeness sake.
	 * 
	 * Internally sets up a Pixelmask using the polygon representation and uses that for collision check.
	 */
	@:access(net.hxpunk.masks.Pixelmask)
	private function collidePixelmask(pixelmask:Pixelmask):Bool
	{
		var data:BitmapData = _fakePixelmask._data;
		
		_fakeEntity.width = _width;
		_fakeEntity.height = _height;
		_fakeEntity.x = parent.x - _x;
		_fakeEntity.y = parent.y - _y;
		_fakeEntity.originX = parent.originX;
		_fakeEntity.originY = parent.originY;

		_fakePixelmask._x = _x - parent.originX;
		_fakePixelmask._y = _y - parent.originY;
		_fakePixelmask.parent = _fakeEntity;
		
		if (data == null || (data.width < _width || data.height < _height)) {
			data = new BitmapData(_width, height, true, 0);
		} else {
			data.fillRect(data.rect, 0);
		}
		
		var graphics:Graphics = HP.sprite.graphics;
		graphics.clear();

		graphics.beginFill(0xFFFFFF, 1);
		graphics.lineStyle(1, 0xFFFFFF, 1);
		
		var offsetX:Float = _x + parent.originX;
		var offsetY:Float = _y + parent.originY;
		
		graphics.moveTo(points[_points.length - 1].x + offsetX, _points[_points.length - 1].y + offsetY);
		for (i in 0..._points.length)
		{
			graphics.lineTo(_points[i].x + offsetX, _points[i].y + offsetY);
		}
		
		graphics.endFill();

		data.draw(HP.sprite);
		
		_fakePixelmask.data = data;
		
		return pixelmask.collide(_fakePixelmask);
	}
	
	/**
	 * Checks for collision with a circle.
	 */
	private function collideCircle(circle:Circle):Bool
	{			
		var edgesCrossed:Int = 0;
		var p1:Point, p2:Point;
		var i:Int, j:Int;
		var nPoints:Int = _points.length;
		var offsetX:Float = parent.x + _x;
		var offsetY:Float = parent.y + _y;
		

		// check if circle center is inside the polygon
		i = 0;
		j = nPoints - 1;
		while (i < nPoints) {
			p1 = _points[i];
			p2 = _points[j];
			
			var distFromCenter:Float = (p2.x - p1.x) * (circle._y + circle.parent.y - p1.y - offsetY) / (p2.y - p1.y) + p1.x + offsetX;
			
			if ((p1.y + offsetY > circle._y + circle.parent.y) != (p2.y + offsetY > circle._y + circle.parent.y)
				&& (circle._x + circle.parent.x < distFromCenter))
			{
				edgesCrossed++;
			}
			j = i;
			i++;
		}
		
		if (edgesCrossed & 1 > 0) return true;
		
		// check if minimum distance from circle center to each polygon side is less than radius
		var radiusSqr:Float = circle.radius * circle.radius;
		var cx:Float = circle._x + circle.parent.x;
		var cy:Float = circle._y + circle.parent.y;
		var minDistanceSqr:Float = 0;
		var closestX:Float;
		var closestY:Float;
		
		i = 0;
		j = nPoints - 1;
		while (i < nPoints) {
			p1 = _points[i];
			p2 = _points[j];

			var segmentLenSqr:Float = (p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y);
			
			// find projection of center onto line (extended segment)
			var t:Float = ((cx - p1.x - offsetX) * (p2.x - p1.x) + (cy - p1.y - offsetY) * (p2.y - p1.y)) / segmentLenSqr;
			
			if (t < 0) {
				closestX = p1.x;
				closestY = p1.y;
			} else if (t > 1) {
				closestX = p2.x;
				closestY = p2.y;
			} else {
				closestX = p1.x + t * (p2.x - p1.x);
				closestY = p1.y + t * (p2.y - p1.y);
			}
			closestX += offsetX;
			closestY += offsetY;
			
			minDistanceSqr = (cx - closestX) * (cx - closestX) + (cy - closestY) * (cy - closestY);
			
			if (minDistanceSqr <= radiusSqr) return true;
			
			j = i;
			i++;
		}

		return false;
	}

	/**
	 * Checks for collision with a polygon.
	 */
	private function collidePolygon(other:Polygon):Bool
	{
		var offset:Float;
		var offsetX:Float = parent.x + _x - other.parent.x;
		var offsetY:Float = parent.y + _y - other.parent.y;
		var a:Point;
		
		// project other on this polygon axes
		// for a collision to be present all projections must overlap
		for (i in 0..._axes.length)
		{
			a = _axes[i];
			project(a, firstProj);
			other.project(a, secondProj);

			// shift the first info with the offset
			offset = offsetX * a.x + offsetY * a.y;
			firstProj.min += offset;
			firstProj.max += offset;

			// if firstProj not overlaps secondProj
			if (firstProj.min > secondProj.max || firstProj.max < secondProj.min)
			{
				return false;
			}
		}

		// project this polygon on other polygon axes
		// for a collision to be present all projections must overlap
		for (j in 0...other._axes.length)
		{
			a = other._axes[j];
			project(a, firstProj);
			other.project(a, secondProj);

			// shift the first info with the offset
			offset = offsetX * a.x + offsetY * a.y;
			firstProj.min += offset;
			firstProj.max += offset;

			// if firstProj not overlaps secondProj
			if (firstProj.min > secondProj.max || firstProj.max < secondProj.min)
			{
				return false;
			}
		}
		return true;
	}

	/** @private Projects this polygon points on axis and returns min and max values in projection object. */
	override public function project(axis:Point, projection:Projection):Void
	{
		var p:Point = _points[0];
		
		var min:Float = axis.x * p.x + axis.y * p.y,	// dot product
			max:Float = min;

		for (i in 1..._points.length)
		{
			p = _points[i];
			var cur:Float = axis.x * p.x + axis.y * p.y;	// dot product

			if (cur < min)
			{
				min = cur;
			}
			else if (cur > max)
			{
				max = cur;
			}
		}
		projection.min = min;
		projection.max = max;
	}

	override public function renderDebug(graphics:Graphics):Void
	{
		if (parent != null)
		{
			var	offsetX:Float = parent.x + _x - HP.camera.x,
				offsetY:Float = parent.y + _y - HP.camera.y;

			var sx:Float = HP.screen.scaleX * HP.screen.scale;
			var sy:Float = HP.screen.scaleY * HP.screen.scale;
			
			graphics.beginFill(0xFFFFFF, .25);
			graphics.lineStyle(1, 0xFFFFFF, 0.35);
			
			graphics.moveTo((points[_points.length - 1].x + offsetX) * sx , (_points[_points.length - 1].y + offsetY) * sy);
			for (i in 0..._points.length)
			{
				graphics.lineTo((_points[i].x + offsetX) * sx, (_points[i].y + offsetY) * sy);
			}
			
			graphics.endFill();
			
			// draw pivot
			graphics.lineStyle(1, 0xFFFFFF, 0.75);
			graphics.drawCircle((offsetX + originX) * sx, (offsetY + originY) * sy, 2); 
		}
	}

	/**
	 * Rotation angle (in degress) of the polygon (rotates around origin point).
	 */
	public var angle(get, set):Float;
	private inline function get_angle():Float { return _angle; }
	private function set_angle(value:Float):Float
	{
		if (value != _angle) {
			rotate(value - _angle);
			if (list != null || parent != null) update();
		}
		return value;
	}

	/**
	 * The points representing the polygon.
	 * 
	 * If you need to set a point yourself instead of passing in a new Array<Point> you need to call update() 
	 * to make sure the axes update as well.
	 */
	public var points(get, set):Array<Point>;
	private inline function get_points():Array<Point> { return _points; }
	private function set_points(value:Array<Point>):Array<Point>
	{
		if (_points != value) {
			_points = value;
			if (list != null || parent != null) updateAxes();
		}
		return value;
	}

	/** Updates the parent's bounds for this mask. */
	override public function update():Void
	{
		project(horizontalAxis, firstProj); // width
		var projX:Int = Math.round(firstProj.min);
		_width = Math.round(firstProj.max - firstProj.min);
		project(verticalAxis, secondProj); // height
		var projY:Int = Math.round(secondProj.min);
		_height = Math.round(secondProj.max - secondProj.min);

		if (list != null)
		{
			// update parent list
			list.update();
		}
		else if (parent != null)
		{
			parent.originX = -_x - projX;
			parent.originY = -_y - projY;
			parent.width = _width;
			parent.height = _height;
		}
		
	}

	/**
	 * Creates a regular polygon (edges of same length).
	 * @param	sides	The number of sides in the polygon.
	 * @param	radius	The distance that the vertices are at.
	 * @param	angle	How much the polygon is rotated (in degrees).
	 * @return	The polygon
	 */
	public static function createRegular(sides:Int = 3, radius:Float = 100, angle:Float = 0):Polygon
	{
		if (sides < 3) throw new Error("The polygon needs at least 3 sides.");

		// figure out the angle required for each step
		var rotationAngle:Float = (Math.PI * 2) / sides;

		// loop through and generate each point
		var points:Array<Point> = new Array<Point>();

		for (i in 0...sides)
		{
			var tempAngle:Float = Math.PI + i * rotationAngle;
			var p:Point = new Point();
			p.x = Math.cos(tempAngle) * radius + radius;
			p.y = Math.sin(tempAngle) * radius + radius;
			points.push(p);
		}
		
		// return the polygon
		var poly:Polygon = new Polygon(points);
		poly.originX = radius;
		poly.originY = radius;
		poly.angle = angle;
		return poly;
	}

	/**
	 * Creates a polygon from an array were even numbers are x and odd are y
	 * @param	points	Array containing the polygon's points.
	 * 
	 * @return	The polygon
	 */
	public static function createFromFloats(points:Array<Float>):Polygon
	{
		var p:Array<Point> = new Array<Point>();

		var i:Int = 0;
		while (i < points.length)
		{
			p.push(new Point(points[i++], points[i++]));
		}
		return new Polygon(p);
	}

	private function rotate(angleDelta:Float):Void
	{
		_angle += angleDelta;
		
		angleDelta *= HP.RAD;

		var p:Point;
		
		for (i in 0..._points.length)
		{
			p = _points[i];
			var dx:Float = p.x - originX;
			var dy:Float = p.y - originY;

			var pointAngle:Float = Math.atan2(dy, dx);
			var length:Float = Math.sqrt(dx * dx + dy * dy);

			p.x = Math.cos(pointAngle + angleDelta) * length + originX;
			p.y = Math.sin(pointAngle + angleDelta) * length + originY;
		}
		var a:Point;
		
		for (j in 0..._axes.length)
		{
			a = _axes[j];

			var axisAngle:Float = Math.atan2(a.y, a.x);

			a.x = Math.cos(axisAngle + angleDelta);
			a.y = Math.sin(axisAngle + angleDelta);
		}
	}

	private function generateAxes():Void
	{
		_axes = new Array<Point>();
		var temp:Float;
		var nPoints:Int = _points.length;
		var edge:Point;
		var i:Int, j:Int;
		
		i = 0;
		j = nPoints - 1;
		while (i < nPoints) {
			edge = new Point();
			edge.x = _points[i].x - _points[j].x;
			edge.y = _points[i].y - _points[j].y;

			// get the axis which is perpendicular to the edge
			temp = edge.y;
			edge.y = -edge.x;
			edge.x = temp;
			edge.normalize(1);

			_axes.push(edge);
			
			j = i;
			i++;
		}
	}

	private function removeDuplicateAxes():Void
	{
		var nAxes:Int = _axes.length;
		HP.removeAll(_indicesToRemove);
		
		for (i in 0...nAxes)
		{
			for (j in 0...nAxes)
			{
				if (i == j || Math.max(i, j) >= nAxes) continue;
				
				// if the first vector is equal or similar to the second vector,
				// add it to the remove list. (for example, [1, 1] and [-1, -1]
				// represent the same axis)
				if ((_axes[i].x == _axes[j].x && _axes[i].y == _axes[j].y)
					|| ( -_axes[i].x == _axes[j].x && -_axes[i].y == _axes[j].y))	// first axis inverted
				{
					_indicesToRemove.push(j);
				}
			}
		}
		
		// remove duplicate axes
		var indexToRemove:Null<Int>;
		while ((indexToRemove = _indicesToRemove.pop()) != null) _axes.splice(indexToRemove, 1);
	}

	private function updateAxes():Void
	{
		generateAxes();
		removeDuplicateAxes();
		update();
	}

	// Hitbox information.
	private var _angle:Float;
	private var _points:Array<Point>;
	private var _axes:Array<Point>;
	private var _projection:Projection;

	private var _fakeEntity:Entity;				// used for Grid and Pixelmask collision
	private var _fakeTileHitbox:Hitbox;			// used for Grid collision
	private var _fakePixelmask:Pixelmask;		// used for Pixelmask collision
	
	private var _indicesToRemove:Array<Int>;	// used in removeDuplicateAxes()
	
	private static var firstProj:Projection;
	private static var secondProj:Projection;

	public static var verticalAxis:Point;
	public static var horizontalAxis:Point;
}