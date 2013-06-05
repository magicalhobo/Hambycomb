package 
{
	import com.hambycomb.swf.SWF;
	
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.getDefinitionByName;
	
	[SWF(scriptTimeLimit="15")]
	
	public class Hambycomb extends Sprite
	{
		private static const TESTING:Boolean = true;
		
		private var currentInjection:Loader;
		private var loader:Loader;
		private var urlLoader:URLLoader;
		private var website:*;
		
		public function Hambycomb()
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			var fullScreenMenuItem:ContextMenuItem = new ContextMenuItem('Enter Fullscreen');
			var hambycombMenuItem:ContextMenuItem = new ContextMenuItem('Hambycomb version 2.0');
			
			fullScreenMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, fullScreenMenuItemSelectHandler);
			hambycombMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, hambycombMenuItemSelectHandler);
			
			contextMenu = new ContextMenu();
			contextMenu.customItems = [hambycombMenuItem, fullScreenMenuItem];
			
			loadMain();
		}
		
		protected function fullScreenMenuItemSelectHandler(event:ContextMenuEvent):void
		{
			stage.displayState = StageDisplayState.FULL_SCREEN;
		}
		
		protected function hambycombMenuItemSelectHandler(event:ContextMenuEvent):void
		{
			navigateToURL(new URLRequest('https://github.com/magicalhobo/Hambycomb'), '_blank');
		}
		
		private function buttonClickHandler(ev:MouseEvent):void
		{
			loadInjection();
		}
		
		private function injectionInitHandler(ev:Event):void
		{
			trace(currentInjection.contentLoaderInfo.bytesTotal);
			var injection:* = currentInjection.content;
			injection.activate(website, loader.contentLoaderInfo.applicationDomain);
		}

		private function mainLoaderCompleteHandler(ev:Event):void
		{
			var bytes:ByteArray = read(urlLoader.data as ByteArray);
			
			loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.INIT, mainLoaderInitHandler);
			loader.loadBytes(bytes, new LoaderContext(false, ApplicationDomain.currentDomain));
		}
		
		private function mainLoaderInitHandler(ev:Event):void
		{
			var Website:Class = getDefinitionByName('iilwy.versions.website.Website') as Class;
			website = new Website() as Sprite;
			
			stage.addChild(website);
			
			if(TESTING)
			{
				var reloadButton:Sprite = new Sprite();
				reloadButton.graphics.beginFill(0x00FF00);
				reloadButton.graphics.drawCircle(5, 5, 5);
				reloadButton.graphics.endFill();
				reloadButton.y = 40;
				
				reloadButton.addEventListener(MouseEvent.CLICK, buttonClickHandler);
				
				stage.addChild(reloadButton);
			}
			
			loadInjection();
		}

		public function loadInjection():void
		{
			try
			{
				Object(currentInjection.content).deactivate();
			}
			catch(e:*)
			{
				trace('Error unloading injection: ', e);
			}
				
			if(currentInjection)
			{
				stage.removeChild(currentInjection);
				currentInjection.unloadAndStop();
			}
			
			currentInjection = new Loader();
			currentInjection.contentLoaderInfo.addEventListener(Event.INIT, injectionInitHandler);
			stage.addChild(currentInjection);
			
			var context:LoaderContext = new LoaderContext(false, new ApplicationDomain(ApplicationDomain.currentDomain));
			
			if(TESTING)
			{
				currentInjection.load(new URLRequest('HambycombInjection.swf?nocache='+(new Date().getTime())), context);
			}
			else
			{
				var injectionBytes:ByteArray = new Embedded.INJECTION() as ByteArray;
				currentInjection.loadBytes(injectionBytes, context);
			}
		}
		
		public function loadMain():void
		{
			urlLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, mainLoaderCompleteHandler);
			urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			
			urlLoader.load(new URLRequest('http://flashcdn.iminlikewithyou.com/Main.swf'));
		}
		
		public function read(bytes:ByteArray):ByteArray
		{
			var swf:SWF = new SWF(bytes);
			
			bytes.position = 0;
			
			var compressed:Boolean = (bytes.readUnsignedByte() == 0x43);
			if(compressed)
			{
				swf.decompress();
			}
			
			bytes.position = 8;
			
			var nBits:uint = swf.readUB(5);
			var xMin:int = swf.readSB(nBits);
			var xMax:int = swf.readSB(nBits);
			var yMin:int = swf.readSB(nBits);
			var yMax:int = swf.readSB(nBits);
			
			bytes.position += 2;
			
			var frameCountLocation:uint = bytes.position;
			
			bytes.position += 2;
			
			var tagsToRemove:Array = [0];
			var foundFrameLabel:Boolean;
			var foundShowFrame:Boolean;
			
			while(bytes.bytesAvailable > 0)
			{
				var tagStart:uint = bytes.position;
				
				var tagInfo:uint = swf.readUI16();
				var type:uint = tagInfo >> 6;
				var length:uint = tagInfo & ((1 << 6) - 1);
				if(length == 0x3F)
				{
					length = swf.readSI32();
				}
				
				var originalPosition:uint = bytes.position;
				
				if(!foundFrameLabel)
				{
					if(type == 43)
					{
						foundFrameLabel = true;
					}
				}
				else if(!foundShowFrame)
				{
					switch(type)
					{
						case 1:
						case 76:
							tagsToRemove.push(tagStart, originalPosition + length);
							break;
					}
					if(type == 1)
					{
						foundShowFrame = true;
					}
				}
				
				swf.alignBytes();
				bytes.position = originalPosition + length;
			}
			
			tagsToRemove.push(bytes.length);
			
			var newBytes:ByteArray;
			newBytes = new ByteArray();
			newBytes.endian = Endian.LITTLE_ENDIAN;
			for(var iter:uint = 0; iter < tagsToRemove.length; iter += 2)
			{
				var begin:uint = tagsToRemove[iter];
				var end:uint = tagsToRemove[iter + 1];
				if(end == begin)
				{
					continue;
				}
				bytes.position = begin;
				bytes.readBytes(newBytes, newBytes.length, (end - begin));
			}
			newBytes.position = 4;
			newBytes.writeUnsignedInt(newBytes.length);
			newBytes.position = frameCountLocation;
			newBytes.writeShort(uint(1));
			
			return newBytes;
		}
	}
}

class Embedded
{
	[Embed(source="../bin-debug/HambycombInjection.swf", mimeType="application/octet-stream")]
	public static const INJECTION:Class;
}
