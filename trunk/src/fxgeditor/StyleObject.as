package fxgeditor 
{
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.display.BlendMode;
	import flash.utils.*;
	import fxgeditor.parser.style.*;

	public class StyleObject
	{
		
		public var id:String;

		public var fillColor:uint = 0xffffffff;
		public var fill_opacity:Number;
		
		public var strokeColor:uint = 0xffffffff;
		public var stroke_opacity:Number;
		public var stroke_width:Number;
		public var stroke_miterlimit:Number;
		public var stroke_linecap:String;
		public var stroke_linejoin:String;
		
		public var opacity:Number;
		public var noFill:Boolean = false;
		public var matrix:Matrix;
		public var colorTransform:ColorTransform;
		
		public var fillGradient:IGradient;
		public var strokeGradient:IGradient;
		
		public var fillBitmap:BitmapFill;
		
		public var font_color:uint = 0xffffffff;
		public var font_size:Number;
		public var font_style:String;
		public var font_family:String;
		public var font_weight:String;
		public var letter_spacing:Number;
		public var kerning:*;
		public var text_align:String;
		public var line_height:Number;
		
		public var blendMode:String;
		public var filters:Array;
		
		public var href:String;
		
		public function parseStyle( s:Style ):void
		{
			id = s.id;
			
			if ( s.fill is IColor ) 
			{
				var fill:IColor = s.fill as IColor;
				fillColor = fill.color;
				fill_opacity = fill.opacity;
			}
			else if ( s.fill is BitmapFill ) 
				fillBitmap = s.fill as BitmapFill;
			else if ( s.fill is IGradient ) 
				fillGradient = s.fill as IGradient;
			else 
				noFill = true;
			
				
			if ( s.stroke is IGradient ) 
				strokeGradient = s.stroke as IGradient;	
			else if ( s.stroke is IColor ) 
			{
				var strokeCol:IColor = s.stroke as IColor;
				strokeColor = strokeCol.color;
				stroke_opacity = strokeCol.opacity;
			}	
			
			if ( s.stroke is IStroke ) {
				var stroke:IStroke = s.stroke as IStroke; 
				stroke_width = stroke.weight;
				stroke_miterlimit = stroke.miterLimit;
				stroke_linecap = stroke.caps;
				stroke_linejoin = stroke.joints;
			}
			
			if ( s.text ) {
				font_color = s.text.color;
				font_size = s.text.fontSize;
				font_style = s.text.fontStyle;
				font_family = s.text.fontFamily;
				font_weight = s.text.fontWeight;
				letter_spacing = s.text.trackingRight;
				kerning = s.text.kerning;
				text_align = s.text.textAlign;
				line_height = s.text.lineHeight;
			}
			
			if ( s.blendMode != BlendMode.NORMAL )
				blendMode = s.blendMode;
			
			if ( s.filters.length )
				filters = s.filters.concat();
			
			if ( s.hasColorTransform )
				colorTransform = s.transform.colorTransform;
			
			opacity = s.alpha;
			href = s.href
		}
		
		public function setStyle( s:Style ):void
		{
			if ( id != null ) s.id = id;
			
			if ( fillColor < 0xffffff && ( !s.fill || s.fill.colorType != ColorType.FLAT )  ) 
				s.fill = new SolidColor();
			else if ( fillBitmap ) 
				s.fill = fillBitmap as IStyleParser;
			else if ( fillGradient ) 
				s.fill = fillGradient as IStyleParser;
			else if ( noFill )
				s.fill = null;
			
			if ( ( strokeColor < 0xffffff && ( !s.stroke || s.stroke.colorType != ColorType.FLAT ) ) || 
				 ( stroke_width > 0 && !s.stroke ) )
				s.stroke = new SolidColorStroke().toStroke( s.stroke as IStroke ) as IStyleParser;
			else if ( strokeGradient ) 
				s.stroke = strokeGradient is IStroke ? strokeGradient : strokeGradient.toStroke( s.stroke as IStroke ) as IStyleParser;
			else if ( stroke_width <= 0 && s.stroke )
				s.stroke = null;
			
			if ( s.fill && s.fill.colorType == ColorType.FLAT )
			{
				if ( fillColor < 0xffffff ) IColor( s.fill ).color = fillColor;
				if( !isNaN( fill_opacity ) )IColor( s.fill ).opacity = fill_opacity;
			}
			
			if ( s.stroke )
			{
				if ( strokeColor < 0xffffff ) IColor( s.stroke ).color =  strokeColor;
				if ( !isNaN( stroke_opacity ) ) IColor( s.stroke ).opacity =  stroke_opacity;
				if ( !isNaN( stroke_width ) ) IStroke( s.stroke ).weight = stroke_width;
				if ( !isNaN( stroke_miterlimit ) ) IStroke( s.stroke ).miterLimit  = stroke_miterlimit;
				if ( stroke_linecap !=null ) IStroke( s.stroke ).caps  = stroke_linecap;
				if ( stroke_linejoin != null ) IStroke( s.stroke ).joints  = stroke_linejoin;
			}
			
			if ( s.text ) {
				if ( font_color < 0xffffff ) s.text.color = font_color;
				if ( !isNaN( font_size ) )  s.text.fontSize = font_size;
				if ( !isNaN( letter_spacing ) ) s.text.trackingRight = letter_spacing;
				if ( !isNaN( line_height ) ) s.text.lineHeight = line_height;
				if ( font_weight !=null ) s.text.fontWeight = font_weight;
				if ( font_style !=null ) s.text.fontStyle = font_style;
				if ( font_family !=null ) s.text.fontFamily = font_family;
				if ( text_align != null ) s.text.textAlign = text_align;
				if ( kerning !=null ) s.text.kerning = kerning;
			}
			
			if ( colorTransform ) s.transform.colorTransform = colorTransform;
			if ( blendMode != null ) s.blendMode = blendMode;
			if ( !isNaN( opacity ) ) s.alpha = opacity;
			if ( matrix ) s.setMatrix( matrix );
			if ( href != null ) s.href = href;
			if ( filters ) s.filters = filters.concat();
			
			exit();
		}
		
		public function exit():void 
		{
			fillGradient = null;
			strokeGradient = null;
			fillBitmap = null;
			matrix = null;
			filters = null;
			colorTransform = null;
		}
	}

}