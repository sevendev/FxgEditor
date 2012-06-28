package fxgeditor.parser {
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.EventDispatcher;
	import flash.events.Event;
	import fxgeditor.parser.model.Data;
	import fxgeditor.parser.model.PersistentData;
	import fxgeditor.Constants;
	
	public class FxgFactory extends EventDispatcher
	{	
		private static const PARSERS:Array = [ 	Graphic , Group , Library, 
												Path , Ellipse, Rect, Line, 
												BitmapGraphic, BitmapImage, 
												TextGraphic, RichText ];
		
		public function FxgFactory() { }
		
		public function parse( xml:XML , target:Sprite  ):void 
		{
			XML.ignoreWhitespace = false;
			xml.removeNamespace( Constants.fxg );
			xml.removeNamespace( Constants.d );
			
			insertPlaceObject( xml );
			parseData( new Data( xml , target ) );
			dispatchEvent( new Event( Event.COMPLETE ) );
		}
		
		public static function parseData( data:Data ):void 
		{
			getParser( data.currentXml ).parse( data );
		}
		
		private static function getParser( xml:XML  ):IParser 
		{
			for each( var Ps:Class in PARSERS ) 
				if ( xml.localName() == Ps["LOCALNAME"] ) return new Ps();
			return new ComplexTree();
		}
		
		private static function insertPlaceObject( xml:XML ):void 
		{
			var fxg:Namespace = Constants.fxg;
			var lib:XML = xml..fxg::Library[0];
			if ( !lib ) return;
			var definitions:XMLList = lib.fxg::Definition;
			for each( var c:XML in definitions ) 
			{
				var name:String = c.@name.toString();
				var items:XMLList = xml..fxg::[name];
				for each( var item:XML in items )
				{
					item.setLocalName( Group.LOCALNAME );
					item.appendChild( c.copy() );
				}

			}
		}
		
		//export
		public function export( fxg:Graphic ):XML {
			var xml:XML = fxg.getFxg();
			xml.normalize();
			return xml;
		}
		
	}
	
}