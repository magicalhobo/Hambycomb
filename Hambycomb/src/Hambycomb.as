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
		private static const TESTING:Boolean = false;
		
		private var currentInjection:Loader;
		private var loader:Loader;
		private var overlay:Overlay;
		private var urlLoader:URLLoader;
		private var website:*;
		
		public function Hambycomb()
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			var hambycombMenuItem:ContextMenuItem = new ContextMenuItem('About Hambycomb...', true);
			
			hambycombMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, hambycombMenuItemSelectHandler);
			
			contextMenu = new ContextMenu();
			contextMenu.customItems = [hambycombMenuItem];
			
			overlay = new Overlay();
			stage.addChild(overlay);

			loadMain();
		}
		
		private function buttonClickHandler(ev:MouseEvent):void
		{
			loadInjection();
		}
		
		private function fullscreenClickHandler(ev:MouseEvent):void
		{
			if(stage.displayState == StageDisplayState.FULL_SCREEN_INTERACTIVE)
			{
				stage.displayState = StageDisplayState.NORMAL;
			}
			else
			{
				stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			}
		}

		private function hambycombMenuItemSelectHandler(event:ContextMenuEvent):void
		{
			navigateToURL(new URLRequest('https://github.com/magicalhobo/Hambycomb'), '_blank');
		}

		private function injectionInitHandler(ev:Event):void
		{
			var injection:* = currentInjection.content;
			injection.activate(website, loader.contentLoaderInfo.applicationDomain);
		}

		private function mainLoaderCompleteHandler(ev:Event):void
		{
			trace('Main swf loaded');
			
			var bytes:ByteArray = read(urlLoader.data as ByteArray);
			
			loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.INIT, mainLoaderInitHandler);
			loader.loadBytes(bytes, new LoaderContext(false, ApplicationDomain.currentDomain));
		}
		
		private function mainLoaderInitHandler(ev:Event):void
		{
			trace('Main swf initialized');
			
			var Website:Class = getDefinitionByName('iilwy.versions.website.Website') as Class;
			website = new Website() as Sprite;
			
			var reloadButton:Sprite = new Sprite();
			reloadButton.graphics.beginFill(0x00FF00);
			reloadButton.graphics.drawCircle(5, 5, 5);
			reloadButton.graphics.endFill();
			reloadButton.y = 40;
			
			if(TESTING)
			{
				reloadButton.addEventListener(MouseEvent.CLICK, buttonClickHandler);
			}
			else
			{
				reloadButton.addEventListener(MouseEvent.CLICK, fullscreenClickHandler);
			}
				
			stage.addChild(website);
			stage.addChild(reloadButton);
			stage.setChildIndex(overlay, stage.numChildren - 1);
			
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

import flash.display.Bitmap;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.net.URLRequest;
import flash.net.navigateToURL;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;

class Embedded
{
	[Embed(source="../bin-debug/HambycombInjection.swf", mimeType="application/octet-stream")]
	public static const INJECTION:Class;

	[Embed(source="/sketchport.png")]
	public static const SKETCHPORT_LOGO:Class;
}

class Overlay extends Sprite
{
	private var broughtToYouBy:TextField;
	private var content:Sprite;
	private var sketchportLogo:Bitmap;
	private var tagline:TextField;

	public function Overlay()
	{
		buttonMode = true;
		
		var textFormat1:TextFormat = new TextFormat('Arial', 10, 0xFFFFFF, false, true);
		var textFormat2:TextFormat = new TextFormat('Arial', 20, 0xFFFFFF);
		
		content = new Sprite();
		
		broughtToYouBy = new TextField();
		broughtToYouBy.autoSize = TextFieldAutoSize.LEFT;
		broughtToYouBy.defaultTextFormat = textFormat1;
		broughtToYouBy.mouseEnabled = false;
		broughtToYouBy.text = 'HAMBYCOMB IS BROUGHT TO YOU BY';
		
		sketchportLogo = new Embedded.SKETCHPORT_LOGO();
		
		tagline = new TextField();
		tagline.autoSize = TextFieldAutoSize.LEFT;
		tagline.defaultTextFormat = textFormat2;
		tagline.mouseEnabled = false;
		tagline.text = 'A free social drawing application for iOS, Android, Mac and PC';
		
		content.addChild(broughtToYouBy);
		content.addChild(sketchportLogo);
		content.addChild(tagline);
		
		broughtToYouBy.x = (content.width - broughtToYouBy.width) / 2;
		broughtToYouBy.y = 0;
		sketchportLogo.x = (content.width - sketchportLogo.width) / 2;
		sketchportLogo.y = broughtToYouBy.height + 10;
		tagline.x = (content.width - tagline.width) / 2;
		tagline.y = broughtToYouBy.height + sketchportLogo.height + 20;
		
		addChild(content);
		
		addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
		addEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler);
		addEventListener(MouseEvent.CLICK, clickHandler);
		
		content.addEventListener(MouseEvent.CLICK, logoClickHandler);
	}
	
	protected function resize():void
	{
		graphics.clear();
		graphics.beginFill(0x000000, 0.90);
		graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
		graphics.endFill();
		
		content.x = (stage.stageWidth - content.width) / 2;
		content.y = (stage.stageHeight - content.height) / 2;
	}
	
	private function addedToStageHandler(ev:Event):void
	{
		stage.addEventListener(Event.RESIZE, resizeHandler);
		resize();
	}
	
	private function clickHandler(ev:Event):void
	{
		stage.removeChild(this);
	}
	
	private function logoClickHandler(ev:Event):void
	{
		navigateToURL(new URLRequest('http://www.sketchport.com/browse'), '_blank');
	}
	
	private function removedFromStageHandler(ev:Event):void
	{
		stage.removeEventListener(Event.RESIZE, resizeHandler);
	}
	
	private function resizeHandler(ev:Event):void
	{
		resize();
	}
}
