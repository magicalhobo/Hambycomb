package com.hambycomb.swf
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	public class SWF
	{
		private var bytes:ByteArray;
		private var bitPosition:uint = 0;
		
		public function SWF(bytes:ByteArray)
		{
			bytes.endian = Endian.LITTLE_ENDIAN;
			
			this.bytes = bytes;
		}
		
		public function alignBytes():void
		{
			if(bitPosition != 0)
			{
				bytes.position++;
				bitPosition = 0;
			}
		}
		
		public function decompress():void
		{
			var uncompressedContent:ByteArray = new ByteArray();
			bytes.position = 8;
			bytes.readBytes(uncompressedContent);
			uncompressedContent.uncompress();
			uncompressedContent.readBytes(bytes, 8);
			bytes.position = 0;
			bytes.writeByte(0x46);
			bytes.position = 0;
		}

		public function readSI32():int
		{
			alignBytes();
			return bytes.readInt();
		}
		
		public function readUI16():uint
		{
			alignBytes();
			return bytes.readUnsignedShort();
		}

		public function readSB(length:uint):int
		{
			return int(readUB(length));
		}
		
		public function readUB(length:uint):uint
		{
			var bitsInFirstByte:uint = Math.min(length, 8 - bitPosition);
			var remainingBits:uint = length >= bitsInFirstByte ? length - bitsInFirstByte : 0; 
			var bytesToRead:uint = Math.floor(remainingBits / 8);
			var bitsInLastByte:uint = remainingBits % 8;
			
			var byteRead:uint;
			var filter:uint;
			
			byteRead = bytes.readUnsignedByte();
			filter = ((1 << bitsInFirstByte) - 1);
			byteRead = byteRead >> (8 - bitsInFirstByte - bitPosition);
			var result:uint = byteRead & filter;
			
			var i:uint = 0;
			while(i < bytesToRead)
			{
				byteRead = bytes.readUnsignedByte();
				result = result << 8 | byteRead;
				i++;
			}
			if(bitsInLastByte > 0)
			{
				filter = ((1 << bitsInLastByte) - 1);
				byteRead = bytes.readUnsignedByte();
				result = result << bitsInLastByte | ((byteRead >> (8 - bitsInLastByte)) & filter);
			}
			
			bitPosition = bitsInLastByte > 0 ? bitsInLastByte : bitPosition + bitsInFirstByte;
			if(bitPosition > 0)
			{
				bytes.position--;
			}
			
			return result;
		}
	}
}
