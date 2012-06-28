package fxgeditor.parser 
{
	
	import flash.display.*;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import fxgeditor.parser.abstract.AbstractPaint;
	import fxgeditor.parser.model.Data;
	import fxgeditor.parser.style.*;
	import fxgeditor.Constants;
	import fxgeditor.parser.path.PathManager;
	import fxgeditor.ui.PathCreationPoint;
	import fxgeditor.ui.DrawingCanvas;
	import fxgeditor.event.PathEditEvent;
	import fxgeditor.event.ItemEditEvent;
	import fxgeditor.parser.model.PersistentData;
	import fxgeditor.parser.utils.StyleUtil;
	
	public class Path extends AbstractPaint implements IParser
	{
		
		public static var LOCALNAME:String = "Path";
		
		private var _data:Data;
		private var _path:GraphicsPath;
		private var _pathManager:PathManager;
		private var _creationPoint:PathCreationPoint;
		private var _drawingCanvas:DrawingCanvas;
		private var _winding:String = "nonZero";
		
		public function Path() { }
		
		/* IEditable methods*/
		override public function redraw():void 
		{
			style.bounds = getPathBounds();
			paint();
		}
		
		override public function edit():void 
		{
			createControl();
			drawEditLine();
			_pathManager.addEventListener( PathEditEvent.PATH_EDIT, onEdit );
			_pathManager.addEventListener( PathEditEvent.PATH_EDIT_FINISH, onEditFinish );
			_pathManager.createPoints( _controlLayer, _pathLayer );
			_pathLayer.addEventListener( MouseEvent.DOUBLE_CLICK , addNewPoint );
			_pathLayer.doubleClickEnabled = true;
		}
		
		override public function exit():void 
		{
			_pathLayer.removeEventListener( MouseEvent.DOUBLE_CLICK , addNewPoint );
			_pathManager.removeEventListener( PathEditEvent.PATH_EDIT, onEdit );
			_pathManager.removeEventListener( PathEditEvent.PATH_EDIT_FINISH, onEditFinish );
			_pathManager.exit();
			removeControl();
		}
		
		override public function getFxg():XML 
		{
			if ( _isMask ) return new XML;
			var node:XML = <{LOCALNAME} />;
			node.@data = _pathManager.getXMLAttr();
			node.@winding = _winding;
			style.setFxgAttr( node );
			return node;
		}
		
		override public function newPrimitive():void 
		{ 
			newInstance();
			_creationPoint = new PathCreationPoint( _controlLayer , _pathLayer );
			_creationPoint.addEventListener( Event.CHANGE , onCreationUpdate );
			_creationPoint.addEventListener( Event.COMPLETE , onCreationComplete );
			_creationPoint.addEventListener( Event.CANCEL , onCreationCanceled );
		}
		
		public function newDrawing():void
		{
			newInstance();
			_drawingCanvas = new DrawingCanvas( _controlLayer, _pathLayer );
			_drawingCanvas.addEventListener( Event.COMPLETE , onDrawingComplete );
			_drawingCanvas.addEventListener( Event.CANCEL , onCreationCanceled );
		}
		
		override public function cancelCreation():void
		{
			onCreationCanceled( null );
		}
		
		override public function getPathManager():PathManager 
		{ 
			return _pathManager; 
		}
		
		/* IParser methods*/
		public function parse( data:Data ):void 
		{
			style = new Style( data.currentXml );
			_data = data;
			if( data.currentXml.@winding.length() ) _winding = data.currentXml.@winding;
			
			_pathManager = new PathManager();
			var d:String = data.currentXml.@data.toString();
			parsePath( d );
			_path = _pathManager.getCommands();
			
			style.bounds = getPathBounds();
			
			data.currentCanvas.addChild( this );
			paint();
		}
		
		/* Path Specific methods*/
		public function convertFrom( d:String , style:Style ):void 
		{
			this.style = style;
			_pathManager = new PathManager();
			parsePath( d );
			_path = _pathManager.getCommands();
			redraw();
		}
		
		public function mixPath( p:Path ):void
		{
			_pathManager.convetToGlobal( this , p ); 
			var d:String = 	p.getPathManager().getXMLAttr().replace( /Z/, "") + 
							_pathManager.getXMLAttr().replace(/M/, "L" ).replace( /Z/, "");
			_pathManager = new PathManager();
			parsePath( d );
			_path = _pathManager.getCommands();
			style = p.style;
			redraw();
		}
				
		override protected function draw( graphics:Graphics ):void 
		{
			graphics.drawPath( _path.commands, _path.data , _winding );
		}
		
		override protected function drawEditLine():void 
		{
			super.drawEditLine();
			_pathLayer.graphics.lineStyle( 8 , 0, 0 );
			draw( _pathLayer.graphics );
			
		}
		
		override protected function onCreationUpdate( e:Event ):void 
		{  
			_pathManager = _creationPoint.getPathManager();
			_path = _pathManager.getCommands();
			redraw();
		}
		
		override protected function onCreationComplete( e:Event ):void
		{
			_creationPoint.removeEventListener( Event.CHANGE , onCreationUpdate );
			_creationPoint.removeEventListener( Event.COMPLETE , onCreationComplete );
			_creationPoint.removeEventListener( Event.CANCEL , onCreationCanceled );
			_creationPoint.exit();
			removeControl();
			dispatchEvent( new ItemEditEvent( ItemEditEvent.CREATION_COMPLETE ) );
		}
		
		protected function onDrawingComplete( e:Event ):void
		{
			_drawingCanvas.removeEventListener( Event.COMPLETE , onCreationComplete );
			_drawingCanvas.removeEventListener( Event.CANCEL , onCreationCanceled );
			_pathManager = _drawingCanvas.getPathManager();
			_path = _pathManager.getCommands();
			redraw();
			_drawingCanvas.exit();
			removeControl();
			dispatchEvent( new ItemEditEvent( ItemEditEvent.CREATION_COMPLETE ) );
		}
		
		protected function onCreationCanceled( e:Event ):void
		{
			_pathManager = new PathManager();
			if ( _creationPoint ) 
			{
				_creationPoint.removeEventListener( Event.CHANGE , onCreationUpdate );
				_creationPoint.removeEventListener( Event.COMPLETE , onCreationComplete );
				_creationPoint.removeEventListener( Event.CANCEL , onCreationCanceled );
				_creationPoint.exit();
			}
			if ( _drawingCanvas )
			{
				_drawingCanvas.removeEventListener( Event.COMPLETE , onCreationComplete );
				_drawingCanvas.removeEventListener( Event.CANCEL , onCreationCanceled );
				_drawingCanvas.exit();
			}
			removeControl();
			dispatchEvent( new ItemEditEvent( ItemEditEvent.CREATION_CANCELED ) );
			this.parent.removeChild( this );
		}

		protected function newInstance():void
		{
			createControl();
			_pathManager = new PathManager();
			_style = new Style();
			style.stroke = PersistentData.getInstance().currentStyle.stroke;
			if ( !style.stroke ) {
				style.stroke =  new SolidColorStroke();
				IColor( style.stroke ).color = StyleUtil.getRandomColor();
				IStroke( style.stroke ).weight = Constants.DEFAULT_LINE_WIDTH;
			}
		}
		
		private function onEdit( e:PathEditEvent = null ):void 
		{
			_path =  _pathManager.getCommands();
			drawEditLine();
			dispatchEvent( e );
		}
		
		private function onEditFinish( e:PathEditEvent = null ):void 
		{
			redraw();
			dispatchEvent( e );
		}
		
		private function addNewPoint( e:MouseEvent ):void
		{
			_pathManager.addNewPoint( _pathLayer.mouseX, _pathLayer.mouseY );
		}
		
		protected function getPathBounds():Rectangle 
		{
			if ( !_path.data ) return null;
			var xmin:Number = 1000000;
			var xmax:Number = 0;
			var ymin:Number = 1000000;
			var ymax:Number = 0;
			var length:int = _path.data.length;
			for ( var i:int = 0; i < length; i ++ ) {
				if ( i % 2 ) {
					ymin = Math.min( _path.data[i] , ymin );
					ymax = Math.max( _path.data[i] , ymax );
				}else {
					xmin = Math.min( _path.data[i] , xmin );
					xmax = Math.max( _path.data[i] , xmax );
				}
			}
			return new Rectangle( xmin, ymin, xmax-xmin, ymax- ymin );
		}
		
		private function parsePath( data:String ):void
		{
			var d:Array = data.match( /[MmZzLlHhVvCcSsQqTtAa]|-?[\d.]+/g );
			
			var len:int   = d.length;
			var pcm:String = ""; //pre command
			var px:Number = 0;  //pre x
			var py:Number = 0;  //pre y
			var sx:Number = 0;
			var sy:Number = 0;
			var cx:Number;
			var cy:Number;
			var cx0:Number;
			var cy0:Number;
			var x0:Number;
			var y0:Number;
			var rx:Number;
			var ry:Number;
			var rote:Number;
			var large:Boolean;
			var sweep:Boolean;
			
			for ( var i:int = 0; i < len; i++ )
			{
				var c:String = d[i];
				if ( c.charCodeAt(0) > 64 ) {
					pcm = c;
				}else {
					i--;
				}
				
				if( ( pcm == "M" || pcm == "m" )  && _pathManager.getLastPoint() &&  _pathManager.getLastPoint().isMoveTo() )
					pcm = ( pcm == "M" ) ? "L" : "l";
				
				switch( pcm )
				{
					case "M":
						sx = px = Number( String(d[int(i + 1)]) );
						sy = py = Number( String(d[int(i + 2)]) );
						_pathManager.addPoint( px, py, GraphicsPathCommand.MOVE_TO );
						i += 2;
						break;
					case "m":
						sx = px += Number( String(d[int(i + 1)]) );
						sy = py += Number( String(d[int(i + 2)]) );
						_pathManager.addPoint( px, py, GraphicsPathCommand.MOVE_TO );
						i += 2;
						break;
					case "L":
						px = Number( String(d[int(i + 1)]) );
						py = Number( String(d[int(i + 2)]) );
						_pathManager.addPoint( px, py, GraphicsPathCommand.LINE_TO );
						i += 2;
						break;
					case "l":
						px += Number( String(d[int(i + 1)]) );
						py += Number( String(d[int(i + 2)]) );
						_pathManager.addPoint( px, py, GraphicsPathCommand.LINE_TO );
						i += 2;
						break;
					case "H":
						px = Number( String(d[int(i + 1)]) );
						_pathManager.addPoint( px, py, GraphicsPathCommand.LINE_TO );
						i ++;
						break;
					case "h":
						px += Number( String(d[int(i + 1)]) );
						_pathManager.addPoint( px, py, GraphicsPathCommand.LINE_TO );
						i ++;
						break;
					case "V":
						py = Number( String(d[int(i + 1)]) );
						_pathManager.addPoint( px, py, GraphicsPathCommand.LINE_TO );
						i ++;
						break;
					case "v":
						py += Number( String(d[int(i + 1)]) );
						_pathManager.addPoint( px, py, GraphicsPathCommand.LINE_TO );
						i ++;
						break;
					case "C": //cubic bezier curve
						cx0 = Number( String(d[int(i + 1)]) );
						cy0 = Number( String(d[int(i + 2)]) );
						cx = Number( String(d[int(i + 3)]) );
						cy = Number( String(d[int(i + 4)]) );
						px = Number( String(d[int(i + 5)]) );
						py = Number( String(d[int(i + 6)]) );
						_pathManager.addBezierCurve( cx0, cy0, cx, cy, px, py  );
						i += 6;
						break;
					case "c":
						cx0 = px + Number( String(d[int(i + 1)]) );
						cy0 = py + Number( String(d[int(i + 2)]) );
						cx = px + Number( String(d[int(i + 3)]) );
						cy = py + Number( String(d[int(i + 4)]) );
						px += Number( String(d[int(i + 5)]) );
						py += Number( String(d[int(i + 6)]) );
						_pathManager.addBezierCurve( cx0, cy0, cx, cy, px, py  );
						i += 6;
						break;
					case "S": //short hand cubic bezier curve
						cx0 = px + px - cx;
						cy0 = py + py - cy;
						cx = Number( String(d[int(i + 1)]) );
						cy = Number( String(d[int(i + 2)]) );
						px = Number( String(d[int(i + 3)]) );
						py = Number( String(d[int(i + 4)]) );
						_pathManager.addBezierCurve( cx0, cy0, cx, cy, px, py  );
						i += 4;
						break;
					case "s":
						cx0 = px + px - cx;
						cy0 = py + py - cy;
						cx = px + Number( String(d[int(i + 1)]) );
						cy = py + Number( String(d[int(i + 2)]) );
						px += Number( String(d[int(i + 3)]) );
						py += Number( String(d[int(i + 4)]) );
						_pathManager.addBezierCurve( cx0, cy0, cx, cy, px, py  );
						i += 4;
						break;
					case "Q": //quadratic bezier curve
						cx = Number( String(d[int(i + 1)]) );
						cy = Number( String(d[int(i + 2)]) );
						px = Number( String(d[int(i + 3)]) );
						py = Number( String(d[int(i + 4)]) );
						_pathManager.addQuadPoints( cx, cy, px, py );
						i += 4;
						break;
					case "q":
						cx = px + Number( String(d[int(i + 1)]) );
						cy = px + Number( String(d[int(i + 2)]) );
						px += Number( String(d[int(i + 3)]) );
						py += Number( String(d[int(i + 4)]) );
						_pathManager.addQuadPoints( cx, cy, px, py );
						i += 4;
						break;
					case "T": //short hand quadratic bezier curve
						cx = 2*px - cx;;
						cy = 2*py - cy;
						px = Number( String(d[int(i + 1)]) );
						py = Number( String(d[int(i + 2)]) );
						_pathManager.addQuadPoints( cx, cy, px, py );
						i += 2;
						break;
					case "t":
						cx = 2*px - cx;;
						cy = 2*py - cy;
						px += Number( String(d[int(i + 1)]) );
						py += Number( String(d[int(i + 2)]) );
						_pathManager.addQuadPoints( cx, cy, px, py );
						i += 2;
						break;
					case "A": //arc to
						x0    = px;
						y0    = py;
						rx    = Number( String(d[int(i + 1)]) );
						ry    = Number( String(d[int(i + 2)]) );
						rote  = Number( String(d[int(i + 3)]) )*Math.PI/180;
						large = ( String(d[int(i + 4)])=="1" );
						sweep = ( String(d[int(i + 5)])=="1" );
						px    = Number( String(d[int(i + 6)]) );
						py    = Number( String(d[int(i + 7)]) );
						_pathManager.addArcPoint( px, py, rx, ry, large, sweep, rote );
						i += 7;
						break;
					case "a": //arc to
						x0    = px;
						y0    = py;
						rx    = Number( String(d[int(i + 1)]) );
						ry    = Number( String(d[int(i + 2)]) );
						rote  = Number( String(d[int(i + 3)]) )*Math.PI/180;
						large = ( String(d[int(i + 4)])=="1" );
						sweep = ( String(d[int(i + 5)])=="1" );
						px   += Number( String(d[int(i + 6)]) );
						py   += Number( String(d[int(i + 7)]) );
						_pathManager.addArcPoint( px, py, rx, ry, large, sweep, rote );
						i += 7;
						break;
					case "Z":
						_pathManager.closePath();
						break;
					case "z":
						_pathManager.closePath();
						break;
					default:
						break;
				}
			}
		}
		
	}
	
}