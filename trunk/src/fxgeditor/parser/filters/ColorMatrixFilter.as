package fxgeditor.parser.filters 
{
	import flash.filters.BitmapFilter;
	import flash.geom.Matrix;
	import fxgeditor.FilterParameters;
	
	public class ColorMatrixFilter implements IFilter
	{
		
		public static var LOCALNAME:String = "ColorMatrixFilter";
		
		private var _matrix:Array = [ 1, 0, 0, 0, 0,
									  0, 1, 0, 0, 0,
									  0, 0, 1, 0, 0,
									  0, 0, 0, 1, 0 ];
		
		public function ColorMatrixFilter() { }
		
		public function parse( xml:XML ):void
		{
			var m:String = xml.@matrix.toString();
			_matrix = m.split( "," );
		}
		
		public function getFlashFilter():BitmapFilter 
		{
			return new flash.filters.ColorMatrixFilter( _matrix );
		}
		
		public function getXML():XML
		{
			var node:XML = <{LOCALNAME} />;
			node.@matrix = _matrix.join(",");
			return node;
		}
		
		public function parsePrameters( o:FilterParameters ):void 
		{
			_matrix = o.matrix;
		}
		
		public function getPrameters():FilterParameters 
		{
			var o:FilterParameters = new FilterParameters();
			o.matrix = _matrix;
			return o;
		}
		
	}

}