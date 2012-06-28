package fxgeditor.parser 
{

	import flash.display.Shape;
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import fxgeditor.parser.style.Style;
	import fxgeditor.parser.model.Data;
	import fxgeditor.parser.abstract.AbstractPaint;
	import fxgeditor.parser.utils.StyleUtil;
	import fxgeditor.event.PathEditEvent;
	import fxgeditor.parser.path.EditPoint;
	import fxgeditor.parser.utils.GeomUtil;
	
	public class Ellipse extends AbstractPaint implements IParser
	{
		public static var LOCALNAME:String = "Ellipse";
		
		private var _rx:Number;
		private var _ry:Number;
		
		private var sizePt:EditPoint;
		
		public function Ellipse() {	}
		
		/* IEditable methods*/
		override public function redraw():void 
		{ 
			paint();
		}
		
		override public function edit():void 
		{
			createControl();
			sizePt = new EditPoint( _controlLayer, _pathLayer , 1, _rx * 2 , _ry * 2 );
			sizePt.addEventListener( PathEditEvent.PATH_EDIT , onPathEdit );
			sizePt.addEventListener( PathEditEvent.PATH_EDIT_FINISH , onPathEditFinish );
			drawEditLine();
		}
		
		override public function exit():void
		{
			sizePt.removeEventListener( PathEditEvent.PATH_EDIT , onPathEdit );
			sizePt.removeEventListener( PathEditEvent.PATH_EDIT_FINISH , onPathEditFinish );
			sizePt.exit();
			removeControl();
		}
		
		override public function getFxg():XML
		{
			if ( _isMask ) return new XML;
			var node:XML = <{LOCALNAME} />;
			node.@width = _rx * 2;
			node.@height = _ry * 2;
			style.setFxgAttr( node );
			return node;
		}
		
		override protected function onCreationUpdate( e:Event ):void
		{
			if ( !style.hasMatrix ) 
			{
				style.x = _creationBox.rect.x;
				style.y = _creationBox.rect.y;
			}
			_rx = _creationBox.rect.width / 2;
			_ry = _creationBox.rect.height / 2;
			redraw();
		}
		
		override public function get convertible():Boolean { return true ; };
		
		/* IParser methods*/
		public function parse( data:Data ):void 
		{
			style = new Style( data.currentXml );
			
			_rx = style.width  / 2;
			_ry = style.height / 2;
			
			data.currentCanvas.addChild( this );
			paint();
		}
		
		override protected function draw( graphics:Graphics ):void {
			graphics.drawEllipse( 0  , 0 , _rx * 2, _ry * 2 );
		}
		
		override protected function getPathString():String 
		{ 
			var r:Rectangle = new Rectangle( 0 , 0 ,  _rx * 2 , _ry * 2   );
			var pts:Vector.<Point> = GeomUtil.getBezierPointsOnCircle( r , 1.8 );
			var d:String = "M";
			pts.forEach( function ( pt:Point, index:Number, vec:Vector.<Point> ):void {
				var s:String = ( index % 3 == 0 ) ? ( index == vec.length-1 ) ? "Z" :"C" : " ";
				d += pt.x + "," + pt.y + s;
			});
			return d;
		}
		
		private function onPathEdit( e:PathEditEvent ):void 
		{
			style.width = sizePt.ax;
			style.height = sizePt.ay;
			_rx = sizePt.ax / 2;
			_ry = sizePt.ay / 2;
			drawEditLine();
		}
		
		private function onPathEditFinish( e:PathEditEvent ):void 
		{
			redraw();
		}
		
	}

}