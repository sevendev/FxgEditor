package fxgeditor.parser 
{
	import flash.display.*;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.events.Event;
	import fxgeditor.parser.abstract.AbstractPaint;
	import fxgeditor.parser.model.Data;
	import fxgeditor.parser.style.Style;
	import fxgeditor.parser.utils.StyleUtil;
	import fxgeditor.parser.path.EditPoint;
	import fxgeditor.event.PathEditEvent;
	import fxgeditor.parser.utils.GeomUtil;
	
	public class Rect extends AbstractPaint implements IParser
	{
		public static var LOCALNAME:String = "Rect";
		
		public function Rect() { }
		
		protected var _width:Number;
		protected var _height:Number;
		
		protected var _topLeftRadius:Point;
		protected var _topRightRadius:Point;
		protected var _bottomLeftRadius:Point;
		protected var _bottomRightRadius:Point;
		
		protected var sizePt:EditPoint;
		protected var cornerPt:EditPoint;
		
		/* IEditable methods*/
		override public function redraw():void 
		{ 
			paint();
		}
		
		override public function edit():void 
		{
			createControl();
			sizePt = new EditPoint( _controlLayer, _pathLayer , 0, _width , _height );
			sizePt.addEventListener( PathEditEvent.PATH_EDIT , onPathEdit );
			sizePt.addEventListener( PathEditEvent.PATH_EDIT_FINISH , onPathEditFinish );
			
			cornerPt = new EditPoint( _controlLayer, _pathLayer , 1, _topLeftRadius?  _topLeftRadius.x : 0 , 0  );
			cornerPt.addEventListener( PathEditEvent.PATH_EDIT , onCornerEdit );
			cornerPt.addEventListener( PathEditEvent.PATH_EDIT_FINISH , onCornerEditFinish );
			
			drawEditLine(); 
		}
		override public function exit():void
		{
			cornerPt.exit();
			sizePt.exit();
			removeControl();
		}
		
		override public function getFxg():XML 
		{
			if ( _isMask ) return new XML;
			var node:XML = <{LOCALNAME} />;
			node.@width = _width;
			node.@height = _height;
			
			if ( isRounded )
			{
				if (_topLeftRadius) node.@topLeftRadiusX = _topLeftRadius.x;
				if ( _topRightRadius ) node.@topRightRadiusX = _topRightRadius.x;
				if ( _bottomLeftRadius ) node.@bottomLeftRadiusX = _bottomLeftRadius.x;
				if ( _bottomRightRadius ) node.@bottomRightRadiusX = _bottomRightRadius.x;
			}
			
			style.setFxgAttr( node );
			return node;
		}
		
		override public function get convertible():Boolean { return true ; };
		
		/* IParser methods*/
		public function parse( data:Data ):void 
		{
			var xml:XML = data.currentXml;
			style = new Style( xml );
			_width = style.width;
			_height = style.height;
			setCornerRadiuses( xml );
			data.currentCanvas.addChild( this );
			paint();
		}
		
		override protected function draw( graphics:Graphics ):void 
		{
			if ( isRounded )
				graphics.drawRoundRectComplex( 0, 0 , _width, _height, _topLeftRadius.x, _topRightRadius.x, _bottomLeftRadius.x, _bottomRightRadius.x );
			else
				graphics.drawRect( 0, 0, _width, _height );
		}
		
		/* Radius */
		protected function setCornerRadiuses( item:XML ):void
		{
			if ( item.@radiusX.length() ) 
			{
				var radius:Point = getRadius( StyleUtil.toNumber( item.@radiusX ), StyleUtil.toNumber( item.@radiusY ) );
				_topLeftRadius = _topRightRadius = _bottomLeftRadius = _bottomRightRadius = radius.clone();
			}else
				_topLeftRadius = _topRightRadius = _bottomLeftRadius = _bottomRightRadius = new Point();
			
			if ( item.@topLeftRadiusX.length() ) 
				_topLeftRadius = getRadius( StyleUtil.toNumber( item.@topLeftRadiusX ), StyleUtil.toNumber( item.@topLeftRadiusY ) );
			if ( item.@topRightRadiusX.length() ) 
				_topRightRadius = getRadius( StyleUtil.toNumber( item.@topRightRadiusX ), StyleUtil.toNumber( item.@topRightRadiusY ) );
			if ( item.@bottomLeftRadiusX.length() ) 
				_bottomLeftRadius = getRadius( StyleUtil.toNumber( item.@bottomLeftRadiusX ), StyleUtil.toNumber( item.@bottomLeftRadiusY ) );
			if ( item.@bottomRightRadiusX.length() ) 
				_bottomRightRadius = getRadius( StyleUtil.toNumber( item.@bottomRightRadiusX ), StyleUtil.toNumber( item.@bottomRightRadiusY ) );
		}
		
		protected function getRadius( radiusX:Number, radiusY:Number  ):Point
		{
			if ( !isNaN( radiusX ) && isNaN ( radiusY ) )
				return new Point( radiusX, radiusX ) ;
			if ( !isNaN( radiusX ) && !isNaN ( radiusY ) )
				return new Point( radiusX, radiusY ) ;
			return null;
		}
		
		/* Private */
		override protected function onCreationUpdate( e:Event ):void
		{
			if ( !style.hasMatrix ) 
			{
				style.x = _creationBox.rect.x;
				style.y = _creationBox.rect.y;
			}
			style.width = _width = _creationBox.rect.width;
			style.height = _height = _creationBox.rect.height;
			redraw();
		}
		
		override protected function getPathString():String 
		{ 
			var r:Rectangle = new Rectangle( style.x, style.y , _width, _height );
			var d:String = "M";
			if( !isRounded ){
				d += 	r.x + "," + r.y + "L" + 
						r.right +"," + r.top + " " + 
						r.right + "," + r.bottom + " " + 
						r.left + "," + r.bottom + " " + 
						r.x + "," + r.y + "Z" ;
			}else {
				r.offset(1, 1); //Bezier control point ignores 0 cordinate;
				var pts:Vector.<Point> = GeomUtil.getBezierPointsOnRect( r, _topLeftRadius, _topRightRadius, _bottomLeftRadius, _bottomRightRadius );
				pts.forEach( function ( pt:Point, index:Number, vec:Vector.<Point> ):void {
					var s:String = ( index % 3 == 0 ) ? ( index == vec.length-1 ) ? "Z" :"C" : " ";
					d += pt.x + "," + pt.y + s;
				});
			}
			return d;
		}
		
		protected function onPathEdit( e:PathEditEvent ):void 
		{
			_width = sizePt.ax - style.x;
			_height = sizePt.ay - style.y;
			
			drawEditLine();
		}
		
		protected function onPathEditFinish( e:PathEditEvent ):void 
		{
			redraw();
		}
		
		protected function onCornerEdit( e:PathEditEvent ):void 
		{
			var radius:Point = cornerPt.asPoint.clone();
			if ( radius.x <= 0 ) radius = null;
			_topLeftRadius = _topRightRadius = _bottomLeftRadius = _bottomRightRadius = radius;
			drawEditLine();
		}
		
		protected function onCornerEditFinish( e:PathEditEvent ):void 
		{
			redraw();
		}
		
		protected function get isRounded():Boolean
		{
			return ( _topLeftRadius || _topRightRadius || _bottomLeftRadius || _bottomRightRadius );
		}
	}

}