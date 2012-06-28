package fxgeditor.parser.style
{
	import fxgeditor.parser.utils.StyleUtil;
	
	public class SolidColorStroke extends SolidColor implements IStyleParser , IStroke
	{
		public static var LOCALNAME:String = "SolidColorStroke";
		
		private var _weight:Number;
		private var _miterLimit:Number;
		private var _caps:String;
		private var _joints:String;
		
		public function SolidColorStroke() {}
		
		override public function parse( item:XML ) :void
		{
			super.parse( item );
			
			_weight = StyleUtil.toNumber( item.@weight );
			_miterLimit = StyleUtil.toNumber( item.@miterLimit );
			_caps = item.@caps.toString();
			_joints = item.@joints.toString();
		}
		
		override public function getXML( localName:String = null ):XML
		{
			localName = localName ? localName : LOCALNAME;
			var node:XML = super.getXML( localName );
			if ( !isNaN(_weight) ) node.@weight = StyleUtil.fromNumber( _weight );
			if ( !isNaN(_miterLimit) ) node.@miterLimit = StyleUtil.fromNumber( _miterLimit );
			if ( _caps != null && _caps != "" ) node.@caps = _caps;
			if ( _joints != null && _joints != "" ) node.@joints = _joints;
			return node;
		}
		
		override public function toStroke( stroke:IStroke = null ):IStroke
		{
			setStroke( stroke );
			return this;
		}
		
		public function setStroke( s:IStroke ):void
		{
			if ( !s ) return;
			if( !isNaN( s.weight ) ) _weight = s.weight;
			if( !isNaN( s.miterLimit ) ) _miterLimit = s.miterLimit;
			if( s.caps ) _caps = s.caps;
			if( s.joints ) _joints = s.joints;
		}
		
		public function get weight():Number { return _weight; }
		public function get miterLimit():Number { return _miterLimit; }
		public function get caps():String { return _caps; }
		public function get joints():String { return _joints; }
		
		public function set weight(value:Number):void { _weight = value; }
		public function set miterLimit(value:Number):void { _miterLimit = value; }
		public function set caps(value:String):void { _caps = value; }
		public function set joints(value:String):void { _joints = value; }
		
	}

}