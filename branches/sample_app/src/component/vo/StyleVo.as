package component.vo 
{
	import flash.display.CapsStyle;
	import flash.display.JointStyle;
	import flash.display.BlendMode;
	import flash.filters.BitmapFilterType;
	import flash.geom.ColorTransform;
	import fxgeditor.parser.style.IGradient;
	import fxgeditor.StyleObject;
	import fxgeditor.parser.style.*;
	import fxgeditor.parser.filters.*;
	
	
	[Bindable]
	public class StyleVo
	{
		public static const BLEND_MODE:Array = [BlendMode.NORMAL, BlendMode.ADD, BlendMode.ALPHA , BlendMode.DARKEN, BlendMode.DIFFERENCE, 
												BlendMode.ERASE, BlendMode.HARDLIGHT, BlendMode.INVERT, BlendMode.LAYER, BlendMode.LIGHTEN, 
												BlendMode.MULTIPLY, BlendMode.OVERLAY, BlendMode.SCREEN, BlendMode.SHADER, BlendMode.SUBTRACT];
		
		public static const CAP_STYLES:Array = [ CapsStyle.NONE , CapsStyle.ROUND , CapsStyle.SQUARE ] ;
		public static const JOINT_STYLES:Array = [ JointStyle.BEVEL , JointStyle.MITER , JointStyle.ROUND ] ;
		public static const FILTERS:Array = [ 	BlurFilter.LOCALNAME , DropShadowFilter.LOCALNAME, GlowFilter.LOCALNAME, BevelFilter.LOCALNAME , 
												ColorMatrixFilter.LOCALNAME , GradientBevelFilter.LOCALNAME , GradientGlowFilter.LOCALNAME ];
		
		public static const FILL_MODE:Array = [ "scale", "repeat" ];
		
		public static const GRADATION_FILTER_TYPE:Array = [BitmapFilterType.INNER, BitmapFilterType.OUTER, BitmapFilterType.FULL ];
		
		public var itemType:String = "Path";
		
		public var fillColorValue:uint;
		public var fillAlphaValue:Number;
		public var strokeColorValue:uint;
		public var strokeAlphaValue:Number;
		
		public var fillGradation:IGradient;
		public var strokeGradation:IGradient;
		
		public var fillBitmap:BitmapFill;
		
		public var strokeWidthValue:Number;
		public var strokeMiterlimitValue:Number;
		
		public var strokeLinecap:String = CapsStyle.NONE ;
		public var strokeLineJoin:String = JointStyle.ROUND;
		
		public var textColorValue:uint;
		public var fontSizeValue:Number;
		public var letterSpacingValue:Number;

		public var alphaValue:Number = 1;
		
		public var blendMode:String = BlendMode.NORMAL;
		
		public var filters:Array;
		
		public var colorTransform:ColorTransform;
		
		public var href:String;
		
	}

}