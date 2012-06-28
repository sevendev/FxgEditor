package fxgeditor.parser.model 
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.display.DisplayObject;
	import flash.events.EventDispatcher;
	import fxgeditor.parser.style.Style;
	import fxgeditor.event.ZoomEvent;
		
	public class PersistentData extends EventDispatcher
	{
		private var _rootXML:XML;
		private var _rootCanvas:DisplayObjectContainer;
		private var _controlCanvas:DisplayObjectContainer;
		private var _datas:Array = [];
		private var _currentZoom:Number = 1;
		private var _currentStyle:Style;
		
		private var _masks:Vector.<DisplayObject>;
		
		public function PersistentData( enforcer:SingletonEnforcer ) { }
		
		private static var _instance:PersistentData;
		public static function getInstance():PersistentData 
		{
			if ( _instance == null )
				_instance = new PersistentData( new SingletonEnforcer() );
				
			return _instance;
		}
				
		public function get rootXML():XML { return _rootXML; }
		public function set rootXML(value:XML):void 
		{
			if ( !_rootXML ) _rootXML = value;
		}
		
		public function get rootCanvas():DisplayObjectContainer { return _rootCanvas; }
		public function set rootCanvas(value:DisplayObjectContainer):void 
		{
			if( !_rootCanvas ) _rootCanvas = value;
		}
		
		public function get controlCanvas():DisplayObjectContainer { return _controlCanvas; }
		public function set controlCanvas(value:DisplayObjectContainer):void 
		{
			_controlCanvas = value;
		}
		
		public function get currentZoom():Number { return _currentZoom; }
		public function set currentZoom(value:Number):void 
		{
			_currentZoom = value;
			dispatchEvent( new ZoomEvent( value ) );
		}
		
		public function get currentStyle():Style 
		{ 
			if ( !_currentStyle ) 
				_currentStyle = new Style();
			return _currentStyle; 
		}
		public function set currentStyle(value:Style):void 
		{
			if ( !_currentStyle ) 
				_currentStyle = new Style();
			_currentStyle = value;
		}
		
		public function addData( data:Data ):void 
		{
			if ( !_datas ) _datas = [];
			if( _datas.indexOf( data ) == -1 )
				_datas.push( data );
		}
		
		public function addMask( m:DisplayObject ):void
		{
			if ( !_masks )_masks = new Vector.<DisplayObject>;
			if ( _masks.indexOf( m ) == -1 )
				_masks.push( m );
		}
		
		public function get masks():Vector.<DisplayObject> { return _masks; }

		public function reset():void 
		{
			_rootXML = null;
			_rootCanvas = null;
			_controlCanvas = null;
			_masks = null;
			_currentStyle = null;
			for each( var d:Data in _datas ) 
				d.clear();
			_datas = null;
			
		}
	}

}

class SingletonEnforcer {}