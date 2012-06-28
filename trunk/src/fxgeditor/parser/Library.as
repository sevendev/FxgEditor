package fxgeditor.parser 
{
	import flash.display.DisplayObject;
	import fxgeditor.parser.IParser;
	import fxgeditor.parser.model.Data;
	import fxgeditor.parser.style.Style;
	import flash.display.Sprite;

	public class Library implements IParser
	{
		public static var LOCALNAME:String = "Library";
		
		public function Library() { }
		
		public function parse( data:Data ):void {}
	}

}