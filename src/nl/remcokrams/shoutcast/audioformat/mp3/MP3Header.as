package nl.remcokrams.shoutcast.audioformat.mp3
{
    import flash.utils.ByteArray;
    import flash.utils.IDataInput;

    /**
    *	Created by remcokrams
    *  
    *  Documentation mp3:
    *  - http://www.mp3-tech.org/programmer/frame_header.html
    *  - http://www.codeproject.com/KB/audio-video/mpegaudioinfo.aspx
    * 
    *	Apr 28, 2011	
    **/

    public class MP3Header
    {
        public static const VERSION_25:int = 0;
        public static const VERSION_2:int = 2;
        public static const VERSION_1:int = 3;

        public static const LAYER_1:int = 3;
        public static const LAYER_2:int = 2;
        public static const LAYER_3:int = 1;

        private static const FrameSyncMask:uint = 0xffe00000;
        private static const AudioVersionIdMask:uint = 0x180000;
        private static const LayerMask:uint = 0x60000;
        private static const ProtectionMask:uint = 0x10000;
        private static const BitrateMask:uint = 0xf000;
        private static const SamplingRateMask:uint = 0xc00;
        private static const PaddingMask:uint = 0x200;

        private static const BitRateV1L1:Array = [0, 32000, 64000, 96000, 128000, 160000, 192000, 224000, 256000, 288000, 320000, 352000, 384000, 416000, 448000, -1];
        private static const BitRateV1L2:Array = [0, 32000, 48000, 56000, 64000, 80000, 96000, 112000, 128000, 160000, 192000, 224000, 256000, 320000, 384000, -1];
        private static const BitRateV1L3:Array = [0, 32000, 40000, 48000, 56000, 64000, 80000, 96000, 112000, 128000, 160000, 192000, 224000, 256000, 320000, -1];
        private static const BitRateV2L1:Array = [0, 32000, 48000, 56000, 64000, 80000, 96000, 112000, 128000, 144000, 160000, 176000, 192000, 224000, 256000, -1];
        private static const BitRateV2L2L3:Array = [0, 8000, 16000, 24000, 32000, 40000, 48000, 56000, 64000, 80000, 96000, 112000, 128000, 144000, 160000, -1];        

        public var versionID:uint;
        public var layer:uint;
        public var padding:uint;
        public var bitRateIndex:uint; //meaning of this property. Check: http://www.mp3-tech.org/programmer/frame_header.html
        public var actualBitRate:uint;
        public var protectionAbsense:uint;
        public var sampleRateIndex:uint;
        public var actualSampleRate:uint;
        public var isStereo:Boolean;
        public var channels:uint;
        public var frameLength:uint;
        public var duration:uint;

        public function MP3Header()
        {
        }

        /**
        *
        * Shoutcast streams start with mp3 frames which are not byte aligned.
        * Easiest (and best) way is to wait for a byte aligned frame and start processing from there
        *  
        * @param buffer
        * @param mustEqualHeader the header to match (if not matching then the stream is corrupt or we have a bug in the parsing process)
        * @return 
        * 
        */		
        public function findAndParse(buffer:ByteArray, mustEqualHeader:MP3Header):Boolean
        {
            var byte:uint;

            while(buffer.bytesAvailable)
            {
                byte = buffer.readUnsignedByte();

                if (byte == 0xFF) 
                {
                    buffer.position--;

                    if(buffer.bytesAvailable >= 4)
                    {
                        if(parse(buffer, mustEqualHeader) )
                            return true;
                        else
                            buffer.position++;
                    }
                    else
                    {
                        break;
                    }
                }

            }

            return false;
        }

        public function clone():MP3Header 
        {
            var cloneHeader:MP3Header = new MP3Header();

            cloneHeader.actualBitRate = actualBitRate;
            cloneHeader.actualSampleRate = actualSampleRate;
            cloneHeader.bitRateIndex = bitRateIndex;
            cloneHeader.channels = channels;
            cloneHeader.isStereo = isStereo;
            cloneHeader.layer = layer;
            cloneHeader.versionID = versionID;

            return cloneHeader;
        }

        public function equals(otherHeader:MP3Header):Boolean
        {
            return  versionID == otherHeader.versionID && 
                    layer == otherHeader.layer &&
                    actualSampleRate == otherHeader.actualSampleRate;
        }

        public function parse(stream:ByteArray, mustEqualHeader:MP3Header):Boolean
        {
            // Rewrote parse method. See http://www.datavoyage.com/mpgscript/mpeghdr.htm for details -DW

            if (stream.bytesAvailable < 4)  // not enough data available to read uint
                return false;	

            var header:uint = stream.readUnsignedInt();
            stream.position -= 4;

            if ((header & FrameSyncMask) ^ FrameSyncMask)
                return false;

            this.layer = (header & LayerMask) >> 17;
            if (this.layer==0)  // 00 is reserved
                return false;

            this.protectionAbsense = (header & ProtectionMask) >> 16;

            this.channels = (header >>> 6) & 3;
            this.isStereo = this.channels < 3;

            this.bitRateIndex = (header & BitrateMask) >> 12;
            if (this.bitRateIndex==15)  // binary 1111 is 'bad'
                return false;

            this.versionID = (header & AudioVersionIdMask) >> 19;	
            if (this.versionID==1)  // 01 is reserved
                return false;

            if (this.versionID==VERSION_1)
            {
                switch (this.layer)
                {
                    case LAYER_1:
                        this.actualBitRate = BitRateV1L1[this.bitRateIndex];
                        break;
                    case LAYER_2:
                        this.actualBitRate = BitRateV1L2[this.bitRateIndex];
                        break;
                    case LAYER_3:
                        this.actualBitRate = BitRateV1L3[this.bitRateIndex];
                        break;
                }
            }
            else if (this.versionID==VERSION_2 || this.versionID==VERSION_25)
            {
                switch (this.layer)
                {
                    case LAYER_1:
                        this.actualBitRate = BitRateV2L1[bitRateIndex];
                        break;
                    case LAYER_2:
                    case LAYER_3:
                        this.actualBitRate = BitRateV2L2L3[bitRateIndex];
                        break;
                }
            }

            this.sampleRateIndex = (header & SamplingRateMask) >> 10;
            if (this.sampleRateIndex==3)    // binary 11 is reserved
                return false;

            switch (versionID)
            {
                case VERSION_1:
                    switch (sampleRateIndex)
                    {
                        case 0:
                            this.actualSampleRate = 44100;
                            break;
                        case 1:
                            this.actualSampleRate = 48000;
                            break;
                        case 2:
                            this.actualSampleRate = 32000;
                            break;
                    }
                    break;

                case VERSION_2:
                    switch (sampleRateIndex)
                    {
                        case 0:
                            this.actualSampleRate = 22050;
                            break;
                        case 1:
                            this.actualSampleRate = 24000;
                            break;
                        case 2:
                            this.actualSampleRate = 16000;
                            break;
                    }
                    break;

                case VERSION_25:
                    switch (sampleRateIndex)
                    {
                        case 0:
                            this.actualSampleRate = 11025;
                            break;
                        case 1:
                            this.actualSampleRate = 12000;
                            break;
                        case 2:
                            this.actualSampleRate = 8000;
                            break;
                    }
                    break;
            }

            if(!actualBitRate || !actualSampleRate) //invalid bitrate or samplerate
                return false;

            if(mustEqualHeader && !mustEqualHeader.equals(this)) //some fields which should be the same have changed
                return false;

            this.padding = (header & PaddingMask) >> 9;

            if (this.layer==LAYER_1)
                this.frameLength = (12 * this.actualBitRate / this.actualSampleRate + this.padding) * 4;	
            else if (this.layer==LAYER_2 || this.layer==LAYER_3)
                this.frameLength = 144 * this.actualBitRate / this.actualSampleRate + this.padding;

            var samplesPerFrame:int = (this.layer==LAYER_1) ? 384 : 1152;

            this.duration = 1000 * samplesPerFrame / this.actualSampleRate;

            return true;    
        }


        public function toString():String {
        return "MP3 Version: " + versionID + ", Layer: " + layer + ", Padding: " + padding + ", Bitrate: " + actualBitRate + ", Samplerate: " + actualSampleRate + ", Size: " + frameLength + ", Duration: " + duration;
        }
    }
}