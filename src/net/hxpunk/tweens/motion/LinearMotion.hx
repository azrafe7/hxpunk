﻿package net.hxpunk.tweens.motion;

import net.hxpunk.graphics.Spritemap.VoidCallback;
import net.hxpunk.Tween.TweenType;
import net.hxpunk.utils.Ease.EasingFunction;

/**
 * Determines motion along a line, from one point to another.
 */
class LinearMotion extends Motion
{
	/**
	 * Constructor.
	 * @param	complete	Optional completion callback.
	 * @param	type		Tween type.
	 */
	public function new(complete:VoidCallback = null, type:TweenType = null)
	{
		super(0, complete, type, null);
	}
	
	/**
	 * Starts moving along a line.
	 * @param	fromX		X start.
	 * @param	fromY		Y start.
	 * @param	toX			X finish.
	 * @param	toY			Y finish.
	 * @param	duration	Duration of the movement.
	 * @param	ease		Optional easer function.
	 */
	public function setMotion(fromX:Float, fromY:Float, toX:Float, toY:Float, duration:Float, ease:EasingFunction = null):Void
	{
		_distance = -1;
		x = _fromX = fromX;
		y = _fromY = fromY;
		_moveX = toX - fromX;
		_moveY = toY - fromY;
		_target = duration;
		_ease = ease;
		start();
	}
	
	/**
	 * Starts moving along a line at the speed.
	 * @param	fromX		X start.
	 * @param	fromY		Y start.
	 * @param	toX			X finish.
	 * @param	toY			Y finish.
	 * @param	speed		Speed of the movement.
	 * @param	ease		Optional easer function.
	 */
	public function setMotionSpeed(fromX:Float, fromY:Float, toX:Float, toY:Float, speed:Float, ease:EasingFunction = null):Void
	{
		_distance = -1;
		x = _fromX = fromX;
		y = _fromY = fromY;
		_moveX = toX - fromX;
		_moveY = toY - fromY;
		_target = distance / speed;
		_ease = ease;
		start();
	}
	
	/** @private Updates the Tween. */
	override public function update():Void 
	{
		super.update();
		if (delay > 0) return;
		x = _fromX + _moveX * _t;
		y = _fromY + _moveY * _t;
	}
	
	/**
	 * Length of the current line of movement.
	 */
	public var distance(get, null):Float;
	private function get_distance():Float
	{
		if (_distance >= 0) return _distance;
		return (_distance = Math.sqrt(_moveX * _moveX + _moveY * _moveY));
	}
	
	// Line information.
	/** @private */ private var _fromX:Float = 0;
	/** @private */ private var _fromY:Float = 0;
	/** @private */ private var _moveX:Float = 0;
	/** @private */ private var _moveY:Float = 0;
	/** @private */ private var _distance:Float = - 1;
}