package fxgeditor.parser 
{
	import flash.display.Shape;
	import flash.display.Graphics;
	import fxgeditor.parser.model.Data;
	import fxgeditor.parser.style.Style;
	import fxgeditor.parser.abstract.AbstractPaint;
	import fxgeditor.parser.utils.StyleUtil;
	import fxgeditor.parser.style.BitmapFill;
	
	public class BitmapImage extends Rect implements IParser
	{
		public static var LOCALNAME:String = "BitmapImage";
		
		public function BitmapImage() {}
		
		override public function parse( data:Data ):void 
		{
			if ( data.currentXml.localName() == "Rect" )
			{
				super.parse( data );
				return;
			}
			
			style = new Style( data.currentXml );
			
			_width = style.width * style.scaleX;
			_height = style.height * style.scaleY;
			style.scaleX = style.scaleY = 1.0;
			
			style.fill = new BitmapFill();
			var fillxml:XML = data.currentXml.copy();
			delete fillxml.@x;
			delete fillxml.@y;
			delete fillxml.@rotation;
			style.fill.parse( fillxml );
			
			data.currentCanvas.addChild( this );
			paint();
		}
	}

}