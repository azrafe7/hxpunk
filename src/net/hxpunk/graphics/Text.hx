﻿package net.hxpunk.graphics;

import flash.display.BitmapData;
import flash.errors.Error;
import flash.text.Font;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.text.TextLineMetrics;
import net.hxpunk.HP;
import openfl.Assets;


// TODO fix TextField class for html5
#if html5
@:final extern class TextField {
	inline function getLineMetrics(lineIndex : Int) : TextLineMetrics {
		return new TextLineMetrics(0, 0, 0, 0, 0, 0);
	}
}
#end


/**
 * Used for drawing text using embedded fonts.
 * 
 * Note that users of Flex 3 must edit this class to get FlashPunk games to compile.
 * The details of this can be found at the bottom of the file net/flashpunk/graphics/Text.as
 */
class Text extends Image
{
	private static var init:Bool = Text.initStaticVars();
	
	/**
	 * The font to assign to new Text objects.
	 */
	public static var FONT:String;
	
	/**
	 * The font size to assign to new Text objects.
	 */
	public static var SIZE:UInt = 16;
	
	/**
	 * The alignment to assign to new Text objects.
	 */
#if (flash || html5)
	public static var ALIGN:TextFormatAlign = TextFormatAlign.LEFT;
#else
	public static var ALIGN:String = TextFormatAlign.LEFT;
#end

	/**
	 * The leading to assign to new Text objects.
	 */
	public static var DEFAULT_LEADING:Float = 0;
	
	/**
	 * The wordWrap property to assign to new Text objects.
	 */
	public static var WORD_WRAP:Bool = false;
	
	/**
	 * The resizable property to assign to new Text objects.
	 */
	public static var RESIZABLE:Bool = true;
	
	/**
	 * If the text field can automatically resize if its contents grow.
	 */
	public var resizable:Bool;
	
	/**
	 * Constructor.
	 * @param	text		Text to display.
	 * @param	x			X offset.
	 * @param	y			Y offset.
	 * @param	options		An object containing key/value pairs of the following optional parameters:
	 * 						font		Font family.
	 * 						size		Font size.
	 * 						align		Alignment ("left", "center" or "right").
	 * 						wordWrap	Automatic word wrapping.
	 * 						resizable	If the text field can automatically resize if its contents grow.
	 * 						width		Initial buffer width.
	 * 						height		Initial buffer height.
	 * 						color		Text color.
	 * 						alpha		Text alpha.
	 * 						angle		Rotation angle (see Image.angle).
	 * 						blend		Blend mode (see Image.blend).
	 * 						visible		Visibility (see Graphic.visible).
	 * 						scrollX		See Graphic.scrollX.
	 * 						scrollY		See Graphic.scrollY.
	 * 						relative	See Graphic.relative.
	 *				For backwards compatibility, if options is a Float, it will determine the initial buffer width.
	 * @param	h		Deprecated. For backwards compatibility: if set and there is no options.height parameter set, will determine the initial buffer height.
	 */
	public function new(text:String, x:Float = 0, y:Float = 0, options:Dynamic = null, h:Float = 0)
	{
		super(new BitmapData(1, 1));
		
		// Text information.
		_field = new TextField();
		_styles = new Map<String, TextFormat>();
		
		_font = Text.FONT;
		_size = Text.SIZE;
		_align = Text.ALIGN;
		_leading = Text.DEFAULT_LEADING;
		_wordWrap = Text.WORD_WRAP;
		resizable = Text.RESIZABLE;
		var width:UInt = 0;
		var height:UInt = Std.int(h);
		
		if (options)
		{
			if (Std.is(options, Float)) // Backwards compatibility: options parameter has replaced width
			{
				width = options;
				options = null;
			}
			else
			{
				if (Reflect.hasField(options, "font")) _font = Reflect.getProperty(options, "font");
				if (Reflect.hasField(options, "size")) _size = Reflect.getProperty(options, "size");
				if (Reflect.hasField(options, "align")) _align = Reflect.getProperty(options, "align");
				if (Reflect.hasField(options, "wordWrap")) _wordWrap = Reflect.getProperty(options, "wordWrap");
				if (Reflect.hasField(options, "resizable")) resizable = Reflect.getProperty(options, "resizable");
				if (Reflect.hasField(options, "width")) width = Reflect.getProperty(options, "width");
				if (Reflect.hasField(options, "height")) height = Reflect.getProperty(options, "height");
			}
		}
		
		_field.embedFonts = true;
		_field.wordWrap = _wordWrap;
		_form = new TextFormat(_font, _size, 0xFFFFFF);
		_form.align = _align;
		_form.leading = _leading;
		_field.defaultTextFormat = _form;
		_field.text = _text = text;
		_width = width > 0 ? width : Std.int(_field.textWidth + 4);
		_height = height > 0 ? height : Std.int(_field.textHeight + 4);
		_source = new BitmapData(_width, _height, true, 0);
		super(_source);
		updateTextBuffer();
		this.x = x;
		this.y = y;
		
		if (options)
		{
			for (property in Reflect.fields(options)) {
				if (Reflect.hasField(this, property)) {
					Reflect.setProperty(this, property, Reflect.getProperty(options, property));
				} else {
					throw new Error('"' + property + '" is not a property of Text');
				}
			}
		}
	}
	
	public static function initStaticVars():Bool 
	{
		// Font
		_FONT_DEFAULT = HP.defaultFont;
		FONT = _FONT_DEFAULT.fontName;
		//FONT = "default";
		
		// Styles vars
		_styleIndices = new Array<Int>();
		_styleMatched = new Array<Bool>();
		_styleFormats = new Array<TextFormat>();
		_styleFrom = new Array<Int>();
		_styleTo = new Array<Int>();
	
		return true;
	}
	
	/**
	 * Set the style for a subset of the text, for use with
	 * the richText property.
	 * Usage:
	   text.setStyle("red", {color: 0xFF0000});
	   text.setStyle("big", {size: text.size*2});
	   text.richText = "<big>Hello</big> <red>world</red>";
	 */
	public function setStyle(tagName:String, ?params:Dynamic):Void
	{
		var format:TextFormat;
		
		if (Std.is(params, TextFormat) || params == null) {
			format = params;
		} else {
			format = new TextFormat();
			
			for (key in Reflect.fields(params)) {
				if (Reflect.hasField(format, key)) {
					Reflect.setProperty(format, key, Reflect.getProperty(params, key));
				} else {
					throw new Error('"' + key + '" is not a TextFormat property');
				}
			}
		}
		
		_styles[tagName] = format;
		
		if (_richText != null) updateTextBuffer();
	}
	
	private function matchStyles():Void
	{
		var _j:Int = 0;
		
		var fragments:Array<String> = _richText.split("<");
		
	#if (flash)
		untyped _styleIndices.length = 0;
		untyped _styleMatched.length = 0;
		untyped _styleFormats.length = 0;
		untyped _styleFrom.length = 0;
		untyped _styleTo.length = 0;
	#else
		_styleIndices.splice(0, _styleIndices.length);
		_styleMatched.splice(0, _styleMatched.length);
		_styleFormats.splice(0, _styleFormats.length);
		_styleFrom.splice(0, _styleFrom.length);
		_styleTo.splice(0, _styleTo.length);
	#end
	
		for (i in 1...fragments.length) {
			if (_styleMatched[i]) continue;
			
			var substring:String = fragments[i];
		
			var tagLength:Int = substring.indexOf(">");
			
			if (tagLength > 0) {
				var tagName:String = substring.substr(0, tagLength);
				if (_styles.exists(tagName)) {
					fragments[i] = substring.substr(tagLength + 1);
			
					var endTagString:String = "/" + tagName + ">";
			
					for (j in (i + 1)...fragments.length) {
						if (fragments[j].substr(0, tagLength + 2) == endTagString) {
							fragments[j] = fragments[j].substr(tagLength + 2);
							_styleMatched[j] = true;
						
							_j = j;
							break;
						}
					}
					
					_styleFormats.push(_styles[tagName]);
					_styleFrom.push(i);
					_styleTo.push(_j);
					
					continue;
				}
			}
			
			fragments[i-1] = fragments[i-1] + "<";
		}
		
		_styleIndices[0] = 0;
		_j = 0;
		
		for (i in 0...fragments.length) {
			_j += fragments[i].length;
			_styleIndices[i+1] = _j;
		}
		
		_field.text = _text = fragments.join("");
		
		_field.setTextFormat(_form);
		
		for (i in 0..._styleFormats.length) {
			var start:Int = _styleIndices[_styleFrom[i]];
			var end:Int = _styleIndices[_styleTo[i]];
			
			if (start != end) _field.setTextFormat(_styleFormats[i], start, end);
		}
	}
	
	override function updateColorTransform():Void {
		if (_richText != null) {
			if (_alpha == 1) {
				_tint = null;
			} else {
				_tint = _colorTransform;
				_tint.redMultiplier   = 1;
				_tint.greenMultiplier = 1;
				_tint.blueMultiplier  = 1;
				_tint.redOffset       = 0;
				_tint.greenOffset     = 0;
				_tint.blueOffset      = 0;
				_tint.alphaMultiplier = _alpha;
			}
			
			if (_form.color != _color) {
				updateTextBuffer();
			} else {
				updateBuffer();
			}
			
			return;
		}
		
		super.updateColorTransform();
	}
	
	/** Updates the text buffer, which is the source for the image buffer. */
	public function updateTextBuffer():Void
	{
		if (_richText != null) {
			_form.color = _color;
			matchStyles();
		} else {
			_form.color = 0xFFFFFF;
			_field.setTextFormat(_form);
		}
		
		_field.width = _width;
		_field.width = _textWidth = Math.ceil(_field.textWidth + 4);
		_field.height = _textHeight = Math.ceil(_field.textHeight + 4);
		
		if (resizable && (_textWidth > _width || _textHeight > _height))
		{
			if (_width < _textWidth) _width = _textWidth;
			if (_height < _textHeight) _height = _textHeight;
		}
		
		if (Std.int(_width) > _source.width || Std.int(_height) > _source.height)
		{
			_source = new BitmapData(
				Std.int(Math.max(_width, _source.width)),
				Std.int(Math.max(_height, _source.height)),
				true, 0);
			
			_sourceRect = _source.rect;
			createBuffer();
		}
		else
		{
			_source.fillRect(_sourceRect, 0);
		}
		
		_field.width = _width;
		_field.height = _height;
		
		var offsetRequired: Bool = false;
		
		var i:Int = 0;
		
		var tlm: TextLineMetrics;
		var remainder: Float;
		var tlm_y:Float = 2;
		for (i in 0..._field.numLines) {
			tlm = _field.getLineMetrics(i);
			tlm = _field.getLineMetrics(i);
			remainder = tlm.x % 1;
			if (remainder > 0.1 && remainder < 0.9) {
				offsetRequired = true;
				break;
			}
		}
		
		if (offsetRequired) {
			for (i in 0..._field.numLines) {
				tlm = _field.getLineMetrics(i);
				remainder = tlm.x % 1;
				_field.x = -remainder;
				
				HP.rect.x = 0;
				HP.rect.y = tlm_y;
				HP.rect.width = _width;
				HP.rect.height = tlm.height;
				
				_source.draw(_field, _field.transform.matrix, null, null, HP.rect);
				
				tlm_y += tlm.height;
			}
		} else {
			_source.draw(_field);
		}
		
		super.updateBuffer();
	}
	
	/** @private Centers the Text's originX/Y to its center. */
	override public function centerOrigin():Void 
	{
		originX = _width / 2;
		originY = _height / 2;
	}
	
	/**
	 * Text string.
	 */
	public var text(get, set):String;
	private inline function get_text() { return _text; }
	private inline function set_text(value:String):String
	{
		if (_text == value && _richText == null) return value;
		_field.text = _text = value;
		if (_richText != null) {
			_richText = null;
			super.updateColorTransform();
		}
		updateTextBuffer();
		return value;
	}
	
	/**
	 * Rich-text string with markup.
	 * Use setStyle() to control the appearance of marked-up text.
	 */
	public var richText(get, set):String;
	private inline function get_richText() { return _richText != null ? _richText : _text; }
	private inline function set_richText(value:String):String
	{
		if (_richText == value) return value;
		var fromPlain:Bool = (_richText == null);
		_richText = value;
		if (_richText == null) _field.text = _text = "";
		if (fromPlain && _richText != null) {
			/*
			 * N.B. if _form.color != _color we call
			 * updateTextBuffer() from updateColorTransform().
			 * 
			 * _color always has most significant byte 0 so
			 * setting _form.color = 0xFFFFFFFF will always trigger this.
			 */
			_form.color = 0xFFFFFFFF;
			updateColorTransform();
		} else {
			updateTextBuffer();
		}
		return value;
	}
	
	/**
	 * Font family.
	 */
	public var font(get, set):String;
	private inline function get_font() { return _font; }
	private inline function set_font(value:String):String
	{
		if (_font == value) return value;
		value = Assets.getFont(value).fontName;
		_form.font = _font = value;
		updateTextBuffer();
		return value;
	}
	
	/**
	 * Font size.
	 */
	public var size(get, set):UInt;
	private inline function get_size() { return _size; }
	private inline function set_size(value:UInt):UInt
	{
		if (_size == value) return value;
		_form.size = _size = value;
		updateTextBuffer();
		return value;
	}
	
	/**
	 * Alignment ("left", "center" or "right").
	 */
#if (flash || html5)
	public var align(get, set):TextFormatAlign;
	private inline function get_align() { return _align; }
	private inline function set_align(value:TextFormatAlign):TextFormatAlign
#else
	public var align(get, set):String;
	private inline function get_align() { return _align; }
	private inline function set_align(value:String):String
#end
	{
		if (_align == value) return value;
		_form.align = _align = value;
		updateTextBuffer();
		return value;
	}
	
	/**
	 * Leading (amount of vertical space between lines).
	 */
	public var leading(get, set):Float;
	private inline function get_leading() { return _leading; }
	private inline function set_leading(value:Float):Float
	{
		if (_leading == value) return value;
		_form.leading = _leading = value;
		updateTextBuffer();
		return value;
	}
	
	/**
	 * Automatic word wrapping.
	 */
	public var wordWrap(get, set):Bool;
	private inline function get_wordWrap() { return _wordWrap; }
	private inline function set_wordWrap(value:Bool):Bool
	{
		if (_wordWrap == value) return value;
		_field.wordWrap = _wordWrap = value;
		updateTextBuffer();
		return value;
	}
	
	/**
	 * Width of the text image.
	 */
	override private function get_width() { return _width; }
	override private function set_width(value:UInt):UInt
	{
		if (_width != value) {
			_width = value;
			updateTextBuffer();
		}
		return value;
	}
	
	/**
	 * Height of the text image.
	 */
	override private function get_height() { return _height; }
	override private function set_height(value:UInt):UInt
	{
		if (_height != value) {
			_height = value;
			updateTextBuffer();
		}
		return value;
	}
	
	/**
	 * The scaled width of the text.
	 */
	override private function get_scaledWidth() { return _width * scaleX * scale; }
	
	/**
	 * Set the scaled width of the text.
	 */
	override private function set_scaledWidth(w:Float):Float { return scaleX = w / scale / _width; }
	
	/**
	 * The scaled height of the text.
	 */
	override private function get_scaledHeight() { return _height * scaleY * scale; }
	
	/**
	 * Set the scaled height of the text.
	 */
	override private function set_scaledHeight(h:Float):Float { return scaleY = h / scale / _height; }
	
	/**
	 * Width of the text within the image.
	 */
	public var textWidth(get, null):UInt;
	private inline function get_textWidth() { return _textWidth; }
	
	/**
	 * Height of the text within the image.
	 */
	public var textHeight(get, null):UInt;
	private inline function get_textHeight() { return _textHeight; }
	
	/** 
	 * Set TextField or TextFormat property
	 * returns true on success and false if property not found on either
	 */
	public function setTextProperty(name:String, value:Dynamic):Bool {
		if (Reflect.hasField(_field, name)) {
			Reflect.setProperty(_field, name, value);
		} else if (Reflect.hasField(_form, name)) {
			Reflect.setProperty(_form, name, value);
			_field.setTextFormat(_form);
		} else {
			return false;
		}
		updateTextBuffer();
		return true;
	}
	
	/** 
	 * Get TextField or TextForm property
	 */ 
	public function getTextProperty(name:String):Dynamic {
		if (Reflect.hasField(_field, name)) {
			return Reflect.getProperty(_field, name);
		} else if (Reflect.hasField(_form, name)) {
			return Reflect.getProperty(_form, name);
		} else {
			// TODO need a better "cannot get" value here
			return null;
		}
	}

	// Text information.
	/** @private */ private var _field:TextField;
	/** @private */ private var _width:UInt = 0;
	/** @private */ private var _height:UInt = 0;
	/** @private */ private var _textWidth:UInt = 0;
	/** @private */ private var _textHeight:UInt = 0;
	/** @private */ private var _form:TextFormat;
	/** @private */ private var _text:String;
	/** @private */ private var _richText:Null<String> = null;
	/** @private */ private var _font:String;
	/** @private */ private var _size:UInt = 0;
#if (flash || html5)
	/** @private */ private var _align:TextFormatAlign;
#else
	/** @private */ private var _align:String;
#end
	/** @private */ private var _leading:Float = 0;
	/** @private */ private var _wordWrap:Bool;
	
	// Style vars
	private var _styles:Map<String, TextFormat>;
	private static var _styleIndices:Array<Int>;
	private static var _styleMatched:Array<Bool>;
	private static var _styleFormats:Array<TextFormat>;
	private static var _styleFrom:Array<Int>;
	private static var _styleTo:Array<Int>;
	
	// Default font family.
	// Use this option when compiling with Flex SDK 3 or lower
	// [Embed(source = '04B_03__.TTF', fontFamily = 'default')]
	// Use this option when compiling with Flex SDK 4
	//Embed[('04B_03__.TTF', embedAsCFF="false", fontFamily = 'default')]
	/** @private */ private static var _FONT_DEFAULT:Font;
}
