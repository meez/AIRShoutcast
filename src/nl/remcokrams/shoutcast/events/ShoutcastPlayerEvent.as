package nl.remcokrams.shoutcast.events
{
	import flash.events.Event;
	
	
	/**
	 *	Created by remcokrams
	 *	May 13, 2011	
	 **/
	
	public class ShoutcastPlayerEvent extends Event
	{
		public static const PHASE_CHANGE:String = "phase_change";
		public static const STATE_CHANGE:String = "state_change";
		public static const REDIRECT:String = "redirect";
		
		public var phase:int;
		public var state:String;
		public var errorCode:int;
		public var redirectURL:String;
		
		public function ShoutcastPlayerEvent(type:String, state:String="", phase:int=0, errorCode:int=0, redirectURL:String="")
		{
			super(type, bubbles, cancelable);
			this.phase = phase;
			this.errorCode = errorCode;
			this.state = state;
			this.redirectURL = redirectURL;
		}
		
		override public function clone():Event {
			return new ShoutcastPlayerEvent(type, state, phase, errorCode);
		}
	}
}