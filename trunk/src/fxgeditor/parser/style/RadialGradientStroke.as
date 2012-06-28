package fxgeditor.parser.style 
{
	import fxgeditor.parser.utils.StyleUtil;
	
	public class RadialGradientStroke extends RadialGradient implements IStyleParser , IGradient, IStroke , IColor
	{
		
		public static var LOCALNAME:String = "RadialGradientStroke";
		
		protected var _stroke:SolidColorStroke = new SolidColorStroke();
		
		public function RadialGradientStroke() {}
		
		override public function parse( item:XML ):void 
		{
			super.parse( item );
			_stroke.parse( item );
		}
		
		override public function getXML( localName:String = null):XML
		{
			localName = localName ? localName : LOCALNAME;
			var node:XML = super.getXML(  localName );
			var sattr:XMLList = _stroke.getXML( localName ).@*;
			for each( var a:XML in sattr )
				node.@[a.name()] = a;
			delete node.@color;
			delete node.@alpha;
			return node;
		}
		/*
		override public function toStroke( stroke:IStroke ):IStroke
		{
			setStroke( stroke );
			return this;
		}
		*/
		public function setStroke( s:IStroke ):void
		{
			_stroke.setStroke( s );
		}
		
		override protected function duplicateGradient( g:IGradient ):IGradient
		{
			var dg:IGradient = super.duplicateGradient( g );
			if ( dg is IStroke ) IStroke( dg ).setStroke( this );
			return dg;
		}
		
		public function get weight():Number { return _stroke.weight; }
		public function get miterLimit():Number { return _stroke.miterLimit; }
		public function get caps():String { return _stroke.caps; }
		public function get joints():String { return _stroke.joints; }
		
		public function set weight(value:Number):void { _stroke.weight = value; }
		public function set miterLimit(value:Number):void { _stroke.miterLimit = value; }
		public function set caps(value:String):void { _stroke.caps = value; }
		public function set joints(value:String):void { _stroke.joints = value; }
		
		public function get color():uint { return _stroke.color; }
		public function get opacity():Number { return _stroke.opacity; }
		public function set color(value:uint):void { _stroke.color = value; }
		public function set opacity(value:Number):void { _stroke.opacity = value; }
		
	}

}