package fxgeditor.parser.abstract
{
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.LineScaleMode;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import fxgeditor.parser.model.Data;
	import fxgeditor.parser.style.*;
	import fxgeditor.Constants;
	
	public class AbstractPaint extends AbstractEditable
	{
		public function AbstractPaint() {}
		
		protected function paint():void 
		{
			if ( _outline ) 
			{
				drawOutLine();
				return;
			}
			
			this.graphics.clear();
			//var itemRect:Rectangle = new Rectangle( style.x, style.y, style.width, style.height );
			
			if ( style.hasStroke  ) 
			{
				var stroke:IStroke = style.stroke as IStroke;
				this.graphics.lineStyle( 	stroke.weight , IColor( stroke ).color, IColor( stroke ).opacity, 
											Constants.LINE_PIXEL_HINTING, Constants.LINE_SCALE_MODE , 
											stroke.caps ,stroke.joints, stroke.miterLimit  );
			}
			if ( style.hasGradientStroke ) 
			{
				var sgrad:IGradient = style.stroke as IGradient;
				sgrad.setSize( style.bounds );
				if( sgrad ) this.graphics.lineGradientStyle( 	sgrad.type, sgrad.colors, sgrad.alphas, 
																sgrad.ratios, sgrad.matrix , sgrad.method );
			}
		
			if ( style.hasFill ) 
			{
				var fill:IColor = style.fill as IColor;
				this.graphics.beginFill( fill.color , fill.opacity );
			}
			if ( style.hasGradientFill ) 
			{
				var grad:IGradient = style.fill as IGradient;
				grad.setSize( style.bounds );
				if ( grad ) this.graphics.beginGradientFill( 	grad.type, grad.colors, grad.alphas , 
																grad.ratios , grad.matrix , grad.method  );
			}
			if ( style.hasBitmapFill )
			{
				var bfill:BitmapFill = style.fill as BitmapFill;
				if ( bfill.loading ) 
				{
					bfill.addEventListener( Event.COMPLETE , function( e:Event ):void { 
						paint();
						bfill.removeEventListener( Event.COMPLETE, arguments.callee );
					});
					return;
				}
				if ( bfill.bitmapdata )
				{
					bfill.setSize( style.bounds );
					this.graphics.beginBitmapFill( bfill.bitmapdata, bfill.matrix , bfill.repeat );
				}
			}
			
			draw( this.graphics );	//draw graphics
			
			if ( style.hasFill || style.hasGradientFill || style.hasBitmapFill || style.hasStroke ) this.graphics.endFill();
			applyStyle();
		}
		
		protected function draw( graphics:Graphics ):void 
		{
			throw new Error( "AbstractPaint draw method" );
		}
		
		protected function drawOutLine():void
		{
			this.graphics.clear();
			this.graphics.lineStyle( 1, Constants.OUTLINE_COLOR , 1 , false, LineScaleMode.NONE );
			this.graphics.beginFill( 0 , 0 );

			draw( this.graphics );	//draw graphics
			
			this.graphics.endFill();
			this.filters = [];
			this.mask = null;
		}
		
		protected function drawEditLine():void 
		{
			_pathLayer.graphics.clear();
			_pathLayer.graphics.lineStyle( 1 , Constants.EDIT_LINE_COLOR , 1 , false, LineScaleMode.NONE );
			draw( _pathLayer.graphics );	//draw graphics
			
		}
	}

}