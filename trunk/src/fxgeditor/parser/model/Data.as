package fxgeditor.parser.model 
{
	import flash.display.DisplayObjectContainer ;
	import flash.display.DisplayObject;
	import fxgeditor.parser.style.Style;
	import fxgeditor.parser.FxgFactory;
	
	public class Data
	{
		private var _currentXML:XML;
		private var _currentCanvas:DisplayObjectContainer;
		private var _persistent:PersistentData;
		
		public function Data(	xml:XML, canvas:DisplayObjectContainer ) 
		{
			_persistent = PersistentData.getInstance();
			_persistent.addData( this );
			_currentXML = _persistent.rootXML =  xml;
			_currentCanvas = _persistent.rootCanvas = canvas;
		}
		
		public function copy( xml:XML = null , canvas:DisplayObjectContainer = null):Data	
		{	
			if ( !xml ) xml = _currentXML;
			if ( !canvas ) canvas = _currentCanvas;
			return new Data( xml, canvas);
		}
		
		public function get xml():XML { return _persistent.rootXML; }
		public function get canvas():DisplayObjectContainer { return _persistent.rootCanvas; }
		
		public function get currentCanvas():DisplayObjectContainer  { return _currentCanvas; }
		public function set currentCanvas( value:DisplayObjectContainer ):void {
			_currentCanvas = value;
		}
		public function get currentXml():XML { return _currentXML; }
		public function set currentXml( value:XML ):void {
			_currentXML = value;
		}
		
		public function clear():void 
		{
			_currentXML = null;
			_currentCanvas = null;
		}
	}

}