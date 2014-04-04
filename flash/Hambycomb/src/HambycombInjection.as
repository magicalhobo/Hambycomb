package 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.net.FileReference;
	import flash.system.ApplicationDomain;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	
	import by.blooddy.crypto.image.PNGEncoder;
	
	public class HambycombInjection extends Sprite
	{
		private var active:Boolean;
		private var colorPickerBitmap:Bitmap;
		private var canvas:*;
		private var colorPicker:Sprite;
		private var drawInProcess:Boolean;
		private var imageLoader:Loader;
		
		private function colorPickerClickHandler(ev:*):void
		{
			if(active)
			{
				if(canvas)
				{
					var color:uint = colorPickerBitmap.bitmapData.getPixel(colorPickerBitmap.mouseX, colorPickerBitmap.mouseY);
					canvas.model.color = color;
				}
				colorPicker.visible = false;
			}
		}
		
		private function keyDownHandler(ev:KeyboardEvent):void
		{
			try
			{
				if(drawInProcess)
				{
					trace('keydown: '+ev.keyCode);
				}
				switch(ev.keyCode)
				{
					case Keyboard.UP:
						setColor(multiplyColor(canvas.model.color, 8));
						break;
					case Keyboard.DOWN:
						setColor(multiplyColor(canvas.model.color, -8));
						break;
					case Keyboard.LEFT:
						setBrushSize(canvas.model.tool.brush.size / 1.4);
						break;
					case Keyboard.RIGHT:
						setBrushSize(canvas.model.tool.brush.size * 1.4);
						break;
					default:
						if(canvas && canvas.model)
						{
							switch(ev.keyCode)
							{
								case Keyboard.BACKQUOTE:
									if(ev.ctrlKey)
									{
										saveScreenshot();
									}
									else
									{
										if(colorPicker.visible)
										{
											colorPicker.visible = false;
										}
										else
										{
											colorPicker.visible = true;
											colorPicker.x = stage.mouseX;
											colorPicker.y = stage.mouseY;
										}
									}
									break;
								case Keyboard.NUMBER_0:
									//Discover more about the available brush properties
									trace(describeType(canvas.model).toXMLString());
									break;
								case Keyboard.NUMBER_1:
									setColor(0x000000);
									break;
								case Keyboard.NUMBER_2:
									setColor(0xFF0000);
									break;
								case Keyboard.NUMBER_3:
									setColor(0x00FF00);
									break;
								case Keyboard.NUMBER_4:
									setColor(0x0000FF);
									break;
								case Keyboard.NUMBER_5:
									setColor(0x00FFFF);
									break;
								case Keyboard.NUMBER_6:
									setColor(0xFF00FF);
									break;
								case Keyboard.NUMBER_7:
									setColor(0xFFFF00);
									break;
								case Keyboard.NUMBER_8:
									setColor(0xFFFFFF);
									break;
							}
						}
						break;
				}
			}
			catch(e:*)
			{
				trace('Error handling keydown: '+e);
			}
		}
		
		private function mouseDownHandler(ev:MouseEvent):void
		{
			if(active && ev.target != colorPicker)
			{
				drawInProcess = false;
				if(ev.target.hasOwnProperty('model'))
				{
					drawInProcess = true;
					canvas = ev.target;
				}
			}
		}			
		
		protected function multiplyColor(color:uint, multiplier:Number):uint
		{
			var r:Number = (color >> 16) & 0xFF;
			var g:Number = (color >> 8) & 0xFF;
			var b:Number = (color >> 0) & 0xFF;
			r = Math.max(0, Math.min(int(r + multiplier), 0xFF)) & 0xFF;
			g = Math.max(0, Math.min(int(g + multiplier), 0xFF)) & 0xFF;
			b = Math.max(0, Math.min(int(b + multiplier), 0xFF)) & 0xFF;
			return r << 16 | g << 8 | b;
		}
		
		protected function saveScreenshot():void
		{
			var bitmapData:BitmapData = new BitmapData(canvas.width, canvas.height);
			try
			{
				bitmapData.draw(canvas, null, null, null, null, true);
				var bytes:ByteArray = PNGEncoder.encode(bitmapData);
				var fileReference:FileReference = new FileReference();
				fileReference.save(bytes, 'Draw My Thing '+(new Date().getTime())+'.png');
			}
			catch(e:*)
			{
				trace('Unable to save screenshot: ', e);
			}
		}

		protected function setBrushSize(value:Number):void
		{
			try
			{
				canvas.model.tool.brush.size = value;
				trace('Set brush size to: ', value);
			}
			catch(e:*)
			{
				trace('Unable to set brush size: ', e);
			}
		}
		
		protected function setColor(value:uint):void
		{
			try
			{
				canvas.model.color = value;
				trace('Set color to: ' + value.toString(16));
			}
			catch(e:*)
			{
				trace('Unable to set color: ', e);
			}
		}

		public function activate(website:*, websiteDomain:ApplicationDomain):void
		{
			try
			{
				active = true;
				
				colorPickerBitmap = new Embedded.COLOR_PICKER();
				colorPickerBitmap.x = -colorPickerBitmap.width / 2;
				colorPickerBitmap.y = -colorPickerBitmap.height / 2;
				
				colorPicker = new Sprite();
				colorPicker.buttonMode = true;
				colorPicker.visible = false;
				
				colorPicker.addChild(colorPickerBitmap);
				stage.addChild(colorPicker);
				
				colorPicker.addEventListener(MouseEvent.CLICK, colorPickerClickHandler);
				stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler, false, int.MAX_VALUE);
				stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, false, int.MAX_VALUE);
				
				trace('Website: ', website);
			}
			catch(e:*)
			{
				trace('Error during activation: ', e);
			}
		}

		public function deactivate():void
		{
			active = false;
			stage.removeChild(colorPicker);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
		}
	}
}

class Embedded
{
	[Embed(source="/colors.png")]
	public static const COLOR_PICKER:Class;
}