package coc.view {

/****
 coc.view.CoCButton

 note that although this stores its current tool tip text,
 it does not display the text.  That is taken care of
 by whoever owns this.

 The mouse event handlers are public to facilitate reaction to
 keyboard events.
 ****/

import classes.internals.Utils;

import flash.display.MovieClip;
import flash.display.Sprite;
import flash.filters.DropShadowFilter;
import flash.text.Font;
import flash.text.TextField;
import flash.text.TextFormat;

import flash.events.MouseEvent;

public class CoCButton extends Block {

	[Embed(source='../../../res/ui/Shrewsbury-Titling_Bold.ttf',
			advancedAntiAliasing='true',
			fontName='ShrewsburyTitlingBold',
			embedAsCFF='false')]
	private static const ButtonLabelFont:Class;
	public static const ButtonLabelFontName:String = (new ButtonLabelFont() as Font).fontName;
	public static const ButtonKeyFontName:String = ButtonLabelFontName;
	public static const ButtonKeyFontColor:* = "#bbddaa";
	public static const ButtonKeyShadowColor:* = "#442266";
	public static const ButtonKeyFontSize:int = 10;


	private var _labelField:TextField,
				_key1label:TextField,
				_key2label:TextField,
				_backgroundGraphic:BitmapDataSprite,
				_enabled:Boolean = true,
				_callback:Function = null,
				_preCallback:Function = null;

	public var toolTipHeader:String,
			   toolTipText:String;

	/**
	 * @param options  enabled, labelText, bitmapClass, callback
	 */
	public function CoCButton(options:Object = null):void {
		super();
		_backgroundGraphic = addBitmapDataSprite({
			stretch: true,
			width  : MainView.BTN_W,
			height : MainView.BTN_H
		});
		_labelField        = addTextField({
			width            : MainView.BTN_W,
			embedFonts       : true,
			y                : 8,
			height           : MainView.BTN_H - 8,
			defaultTextFormat: {
				font : ButtonLabelFontName,
				size : 18,
				align: 'center'
			}
		});
		_key1label = addTextField({
			x                : 8,
			width            : MainView.BTN_W - 16,
			y                : 4,
			height           : MainView.BTN_H - 8,
			textColor        : ButtonKeyFontColor,
			defaultTextFormat: {
				font : ButtonKeyFontName,
				size : ButtonKeyFontSize,
				align: 'right'
			}
		});
		_key1label.filters = [new DropShadowFilter(
				0.0,0,ButtonKeyShadowColor,1.0,4.0,4.0,10.0
		)];
		_key2label = addTextField({
			x                : 8,
			width            : MainView.BTN_W - 16,
			y                : 4,
			height           : MainView.BTN_H - 8,
			textColor        : ButtonKeyFontColor,
			defaultTextFormat: {
				font : ButtonKeyFontName,
				size : ButtonKeyFontSize,
				align: 'left'
			}
		});
		_key2label.filters = _key1label.filters.slice();

		this.mouseChildren = true;
		this.buttonMode    = true;
		this.visible       = true;
		UIUtils.setProperties(this, options);

		this.addEventListener(MouseEvent.ROLL_OVER, this.hover);
		this.addEventListener(MouseEvent.ROLL_OUT, this.dim);
		this.addEventListener(MouseEvent.CLICK, this.click);
	}

	//////// Mouse Events... ////////

	public function hover(event:MouseEvent = null):void {
		if (this._backgroundGraphic)
			this._backgroundGraphic.alpha = enabled ? 0.5 : 0.4;
	}

	public function dim(event:MouseEvent = null):void {
		if (this._backgroundGraphic)
			this._backgroundGraphic.alpha = enabled ? 1 : 0.4;
	}

	public function click(event:MouseEvent = null):void {
		if (!this.enabled) return;
		if (this._preCallback != null)
			this._preCallback(this);
		if (this._callback != null)
			this._callback();
	}



		//////// Getters and Setters ////////

	public function get enabled():Boolean {
		return _enabled;
	}
	public function set enabled(value:Boolean):void {
		_enabled                      = value;
		this._labelField.alpha        = value ? 1 : 0.4;
		this._backgroundGraphic.alpha = value ? 1 : 0.4;
	}

	public function get labelText():String {
		return this._labelField.text;
	}

	public function set labelText(value:String):void {
		this._labelField.text = value;
	}

	public function get key1text():String {
		return this._key1label.text;
	}

	public function set key1text(value:String):void {
		this._key1label.text = value;
	}

	public function get key2text():String {
		return this._key2label.text;
	}

	public function set key2text(value:String):void {
		this._key2label.text = value;
	}

	public function set bitmapClass(value:Class):void {
		_backgroundGraphic.bitmapClass = value;
	}
	public function get bitmapClass():Class {
		return null;
	}

	public function get callback():Function {
		return this._callback;
	}

	public function set callback(value:Function):void {
		this._callback = value;
	}

	public function get preCallback():Function {
		return _preCallback;
	}
	public function set preCallback(value:Function):void {
		_preCallback = value;
	}
	//////////// Builder functions
	/**
	 * Setup (text, callback, tooltip) and show enabled button. Removes all previously set options
	 * @return this
	 */
	public function show(text:String,callback:Function,toolTipText:String="",toolTipHeader:String=""):CoCButton {
		this.labelText     = text;
		this.callback      = callback;
		this.toolTipHeader = toolTipHeader||text;
		this.toolTipText   = toolTipText;
		this.visible       = true;
		this.enabled       = true;
		this.alpha         = 1;
		return this;
	}
	/**
	 * Setup (text, tooltip, and show) disabled button. Removes all previously set options
	 * @return this
	 */
	public function showDisabled(text:String,toolTipText:String="",toolTipHeader:String=""):CoCButton {
		this.labelText     = text;
		this.callback      = null;
		this.toolTipHeader = toolTipHeader||text;
		this.toolTipText   = toolTipText;
		this.visible       = true;
		this.enabled       = false;
		this.alpha         = 1;
		return this;
	}
	/**
	 * Set text and tooltip. Don't change callback, enabled, visibility
	 * @return this
	 */
	public function text(text:String,toolTipText:String = "",toolTipHeader:String=""):CoCButton {
		this.labelText = text;
		this.toolTipText = toolTipText||labelText;
		this.toolTipHeader = toolTipHeader;
		return this;
	}
	/**
	 * Set tooltip only. Don't change text, callback, enabled, visibility
	 * @return this
	 */
	public function hint(toolTipText:String = "",toolTipHeader:String=""):CoCButton {
		this.toolTipText = toolTipText;
		this.toolTipHeader = toolTipHeader||labelText;
		return this;
	}
	/**
	 * Disable if condition is true, optionally change tooltip. Does not un-hide button.
	 * @return this
	 */
	public function disableIf(condition:Boolean, toolTipText:String=null):CoCButton {
		enabled = !condition;
		if (toolTipText!==null) this.toolTipText = condition?toolTipText:"";
		return this;
	}
	/**
	 * Disable, optionally change tooltip. Does not un-hide button.
	 * @return this
	 */
	public function disable(toolTipText:String=null):CoCButton {
		enabled = false;
		if (toolTipText!==null) this.toolTipText = toolTipText;
		return this;
	}
	/**
	 * Set callback to fn(...args)
	 * @return this
	 */
	public function call(fn:Function,...args:Array):CoCButton {
		this.callback = Utils.curry.apply(null,[fn].concat(args));
		return this;
	}
	/**
	 * Hide the button
	 * @return this
	 */
	public function hide():CoCButton {
		visible = false;
		return this;
	}
	/**
	 * Show the button with all properties from previous configuration
	 * @return this
	 */
	public function unhide():CoCButton {
		visible = true;
		return this;
	}
}
}