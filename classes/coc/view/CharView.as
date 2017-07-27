/**
 * Coded by aimozg on 10.07.2017.
 */
package coc.view {
import coc.script.Eval;
import coc.view.charview.CaseBlock;
import coc.view.charview.IfBlock;
import coc.view.charview.LayerPart;
import coc.view.charview.ModelPart;
import coc.view.charview.PartList;
import coc.view.charview.SwitchPart;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.display.Sprite;
import flash.events.Event;
import flash.geom.Point;
import flash.geom.Rectangle;

public class CharView extends Sprite {

	private var loading:Boolean;
	private var xml:XML;
	private var bitmaps:Object = {}; // layer.@file -> BitmapData
	private var composite:CompositeImage;
	private var ss_total:int;
	private var ss_loaded:int;
	private var file_total:int;
	private var file_loaded:int;
	private var _width:uint;
	private var _height:uint;
	private var pendingRedraw:Boolean;
	private var loaderLocation:String;
	private var parts:ModelPart;
	public function CharView() {
		clearAll();
	}
	/**
	 * @param location "external" or "internal"
	 */
	public function reload(location:String = "external"):void {
		loaderLocation = location;
		if (loading) return;
		try {
			loading = true;
			clearAll();
			if (loaderLocation == "external") trace("loading XML res/model.xml");
			CoCLoader.loadText("res/model.xml", function (success:Boolean, result:String, e:Event):void {
				if (success) {
					init(XML(result));
				} else {
					trace("XML file not found: " + e);
					loading = false;
				}
			}, loaderLocation);
		} catch (e:Error) {
			loading = false;
			trace("[ERROR]\n" + e.getStackTrace());
		}
	}
	private function clearAll():void {
		this.xml           = null;
		this.bitmaps       = {};
		this.composite     = null;
		this.ss_total      = 0;
		this.ss_loaded     = 0;
		this.file_total    = 0;
		this.file_loaded   = 0;
		this._width        = 1;
		this._height       = 1;
		this.pendingRedraw = false;
		this.parts         = new PartList([]);
	}
	private function init(xml:XML):void {
		this.xml  = xml;
		_width    = xml.@width;
		_height   = xml.@height;
		composite = new CompositeImage(_width, _height);
		ss_loaded = 0;
		ss_total  = -1;
		var _parts:/*ModelPart*/Array = [];
		var item:XML;
		for each(item in xml.layers.*) {
			_parts.push(loadPart(item));
		}
		this.parts = new PartList(_parts);
		var n:int = 0;
		for each(item in xml.spritesheet) {
			n++;
			loadSpritesheet(item);
		}
		ss_total = n;
		if (n == 0) loadLayers();
		var g:Graphics = graphics;
		g.clear();
		g.beginFill(0, 0);
		g.drawRect(0, 0, _width, _height);
		g.endFill();
		loading = false;
		if (pendingRedraw) redraw();
	}
	private function loadLayers():void {
		file_loaded = 0;
		var item:XML;
		var n:int   = 0;
		file_total  = -1;
		for each(item in xml.layers..layer) {
			n++;
			loadBitmapsFrom(item);
		}
		file_total = n;
		if (pendingRedraw) redraw();
	}
	private var _character:Object = {};
	public function setCharacter(value:Object):void {
		_character = value;
	}
	// Calcualte palette ( "hair" -> actual color }
	private function calcPalette(obj:*):Object {
		var palette:Object = {};
		for each (var prop:XML in xml.palette.property) {
			var pn:String        = prop.@name;
			var pv:String        = String(Eval.eval(obj, prop.@src));
			var colorval:XMLList = prop.color.(@name == pv);
			if (colorval.length() == 0) {
				// Try default
				colorval = xml.palette.common.color.(@name == pv);
			}
			if (colorval.length() == 0) {
				trace("CharView: not found palette>property[name=" + pn + "]>color[name='" + pv + "']");
				colorval = prop.default;
			}
			if (colorval.length() > 0) palette[pn] = Color.convertColor(colorval[0].toString());
		}
		return palette;
	}
	// Calculate colors ( key color -> actual color }
	private function calcKeyColors(palette:Object):Object {
		var keyColors:Object = {};
		for each (var key:XML in xml.colorkeys.key) {
			var src:uint  = Color.convertColor(key.@src.toString());
			var base:uint = palette[key.@base];
			var tf:String = key.@transform;
			if (tf) {
				var tfs:/*String*/Array = tf.split(";");
				for each (var transform:String in tfs) {
					var fn:Array      = transform.match(/^(\w+)\(([\d.]+)\)/);
					var fname:String  = fn ? fn[1] : undefined;
					var fvalue:Number = fn ? fn[2] : undefined;
					switch (fname) {
						case "darken":
							base = Color.darken(base, fvalue);
							break;
						case "lighten":
							base = Color.lighten(base, fvalue);
							break;
						default:
							trace("Error: invalid color transform '" + transform + "'");
							break;
					}
				}
			}
			keyColors[src] = base & 0x00ffffff;
		}
		return keyColors;
	}
	public function redraw():void {
		if (!xml && !loading) {
			reload();
		}
		pendingRedraw = true;
		if (!xml || ss_loaded != ss_total || file_loaded != file_total || file_loaded == 0) {
			return;
		}
		pendingRedraw = false;


		// Mark visible layers
		composite.hideAll();
		parts.display(_character);

		var palette:Object   = calcPalette(_character);
		var keyColors:Object = calcKeyColors(palette);
		var bd:BitmapData    = composite.draw(keyColors);
		var g:Graphics       = graphics;
		g.clear();
		g.beginBitmapFill(bd);
		g.drawRect(0, 0, _width, _height);
		g.endFill();
	}
	private function loadPart(x:XML):ModelPart {
		var item:XML;
		switch(x.localName()) {
			case 'layer':
				return new LayerPart(composite,x.@id || x.@file);
			case 'if':
				var thenBlock:/*ModelPart*/Array = [];
				for each(item in x.*) {
					thenBlock.push(loadPart(item));
				}
				return new IfBlock(x.@test.toString(),thenBlock);
			case 'switch':
				var hasval:Boolean = x.attribute("value").length() > 0;
				var cases:/*CaseBlock*/Array = [];
				for each(var xcase:XML in x.elements("case")) {
					var caseItems:/*ModelPart*/Array = [];
					for each(item in xcase.*) {
						caseItems.push(loadPart(item));
					}
					var hasval2:Boolean = xcase.attribute("value").length() > 0;
					var hastest:Boolean = xcase.attribute("test").length() > 0;
					cases.push(new CaseBlock(
							hastest ? xcase.@test.toString() : null,
							hasval2 ? xcase.@value.toString() : null,
							caseItems));
				}
				var defBlock:/*ModelPart*/Array = [];
				for each (item in x.elements("default").*) {
					defBlock.push(loadPart(item));
				}
				return new SwitchPart(hasval?x.@value.toString():null,cases,defBlock);
			default:
				throw new Error("Expected <layer>, <if>, or <switch>, got "+x.localName());
		}
	}
	private function drawItem(x:XML):void {
		var testval:*;
		var layer:XML;
		switch (x.localName()) {
			case 'layer':
				const lid:String = x.@file;
				composite.setVisibility(lid, true);
				break;
			case 'if':
				testval = Eval.eval(_character, x.@test.toString());
				if (testval) {
					for each (layer in x.*) drawItem(layer);
				}
				break;
			case 'switch':
				var found:Boolean  = false;
				var xcase:XML;
				var hasval:Boolean = x.attribute("value").length() > 0;
				var switchval:*;
				if (hasval) switchval = Eval.eval(_character, x.@value.toString());
				for each (xcase in x.elements("case")) {
					if (hasval) {
						var hasval2:Boolean = xcase.attribute("value").length() > 0;
						if (hasval2) {
							testval = Eval.eval(_character, xcase.@value.toString());
							if (switchval == testval) {
								found = true;
							}
						}
					}
					var hastest:Boolean = xcase.attribute("test").length() > 0;
					if (!found && hastest) {
						testval = Eval.eval(_character, xcase.@test.toString());
						if (testval) {
							found = true;
						}
					}
					if (found) {
						for each (layer in xcase.*) {
							drawItem(layer);
						}
						break;
					}
				}
				if (!found) {
					for each (layer in x.elements("default").*) {
						drawItem(layer);
					}
				}
				break;
		}
	}
	private function loadSpritesheet(ss:XML):void {
		const filename:String = ss.@file;
		const cellwidth:int   = ss.@cellwidth;
		const cellheight:int  = ss.@cellheight;
		var path:String       = xml.@dir + filename;
		if (loaderLocation == "external") trace('loading spritesheet ' + path);
		CoCLoader.loadImage(path, function (success:Boolean, result:BitmapData, e:Event):void {
			if (!success) {
				trace("Spritesheet file not found: " + e);
				ss_loaded++;
				if (pendingRedraw) redraw();
				return;
			}
			var y:int = 0;
			for each (var row:XML in ss.row) {
				var x:int                 = 0;
				var files:/*String*/Array = row.text().toString().split(",");
				for each (var f:String in files) {
					if (f) {
						var bd:BitmapData = new BitmapData(cellwidth, cellheight, true, 0);
						bd.copyPixels(result, new Rectangle(x, y, cellwidth, cellheight), new Point(0, 0));
						bitmaps[f] = bd;
					}
					x += cellwidth;
				}
				y += cellheight;
			}
			ss_loaded++;
			if (ss_loaded == ss_total) loadLayers();
		}, loaderLocation);
	}
	private function loadBitmapsFrom(item:XML):void {
		const filename:String = item.@file;
		if (filename in bitmaps) {
			file_loaded++;
			composite.addLayer(filename, bitmaps[filename], false);
			if (pendingRedraw) redraw();
			return;
		}
		bitmaps[filename] = new BitmapData(1, 1);
		composite.addLayer(filename, bitmaps[filename], false);
		var path:String = xml.@dir + filename;
		if (loaderLocation == "external") trace('loading layer ' + path);
		CoCLoader.loadImage(path, function (success:Boolean, bmp:BitmapData, e:Event):void {
			if (!success) {
				trace("Layer file not found: " + e);
				file_loaded++;
				if (pendingRedraw) redraw();
				return;
			}
			bitmaps[filename] = bmp;
			composite.replaceLayer(filename, bitmaps[filename]);
			file_loaded++;
			if (pendingRedraw) redraw();
		});
	}

}
}
