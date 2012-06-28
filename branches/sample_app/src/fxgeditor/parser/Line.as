package fxgeditor.parser 
{
	import flash.display.Shape;
	import flash.display.Graphics;
	import flash.display.GraphicsPathCommand;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import fxgeditor.parser.IParser;
	import fxgeditor.parser.abstract.AbstractPaint;
	import fxgeditor.parser.model.Data;
	import fxgeditor.parser.style.Style;
	import fxgeditor.parser.utils.StyleUtil;
	import fxgeditor.parser.path.EditPoint;
	import fxgeditor.event.PathEditEvent;
	
	public class Line extends AbstractPaint implements IParser
	{
		
		public function Line() { }
		
		public static var LOCALNAME:String = "Line";
		
		private var _x1:Number;
		private var _y1:Number;
		private var _x2:Number;
		private var _y2:Number;
		
		private var _commands:Vector.<int>;
		private var _vertices:Vector.<Number>;
		
		private var pt1:EditPoint;
		private var pt2:EditPoint;
		
		/* IEditable methods*/
		override public function redraw():void 
		{ 
			style.bounds = new Rectangle( _x1, _y2, _x2 - _x1, _y2 - _y1 );
			paint();
		}
		
		override public function edit():void 
		{
			createControl();
			pt1 = new EditPoint( _controlLayer, _pathLayer , 0, _x1, _y1 );
			pt2 = new EditPoint( _controlLayer, _pathLayer , 1, _x2, _y2 );
			pt1.addEventListener( PathEditEvent.PATH_EDIT , onPathEdit );
			pt1.addEventListener( PathEditEvent.PATH_EDIT_FINISH , onPathEditFinish );
			pt2.addEventListener( PathEditEvent.PATH_EDIT , onPathEdit );
			pt2.addEventListener( PathEditEvent.PATH_EDIT_FINISH , onPathEditFinish );
			drawEditLine();
		}
		
		override public function getFxg():XML 
		{
			if ( _isMask ) return new XML;
			var node:XML = <{LOCALNAME} />;
			node.@xFrom = _x1;
			node.@xTo = _x2;
			node.@yFrom = _y1;
			node.@yTo = _y2;
			style.setFxgAttr( node );
			delete node.fill;
			return node;
		}
		
		override public function get convertible():Boolean { return true ; };
		
		/* IParser methods*/
		override public function exit():void
		{
			pt1.removeEventListener( PathEditEvent.PATH_EDIT , onPathEdit );
			pt1.removeEventListener( PathEditEvent.PATH_EDIT_FINISH , onPathEditFinish );
			pt1.exit();
			pt2.removeEventListener( PathEditEvent.PATH_EDIT , onPathEdit );
			pt2.removeEventListener( PathEditEvent.PATH_EDIT_FINISH , onPathEditFinish );
			pt2.exit();
			removeControl();
		}
		
		public function parse( data:Data ):void 
		{
			style = new Style( data.currentXml );
			
			_x1 = StyleUtil.toNumber( data.currentXml.@xFrom );
			_x2 = StyleUtil.toNumber( data.currentXml.@xTo  );
			_y1 = StyleUtil.toNumber( data.currentXml.@yFrom );
			_y2 = StyleUtil.toNumber( data.currentXml.@yTo  );
			
			_vertices = Vector.<Number>([ _x1, _y1 , _x2 , _y2 ]);
			_commands  = Vector.<int>([GraphicsPathCommand.MOVE_TO , GraphicsPathCommand.LINE_TO ]);
			
			data.currentCanvas.addChild( this );
			paint();
		}
		
		override protected function draw( graphics:Graphics ):void {
			graphics.drawPath( _commands, _vertices );
		}
		
		/* Private */
		override protected function onCreationUpdate( e:Event ):void
		{
			transform.matrix = new Matrix();
			_x1 = _creationBox.rect.x;
			_y1 = _creationBox.rect.y;
			_x2 = _creationBox.rect.width + _x1;
			_y2 = _creationBox.rect.height + _y1;
			_vertices = Vector.<Number>([ _x1, _y1 , _x2 , _y2 ]);
			_commands  = Vector.<int>([GraphicsPathCommand.MOVE_TO , GraphicsPathCommand.LINE_TO ]);
			redraw();
		}
		
		override protected function getPathString():String 
		{ 
			var d:String = 	"M" + _x1 + "," + _y1 + "L" + _x2 + "," + _y2 ;
			return d;
		}
		
		private function onPathEdit( e:PathEditEvent ):void 
		{
			_x1 = pt1.ax;
			_y1 = pt1.ay;
			_x2 = pt2.ax;
			_y2 = pt2.ay;
			_vertices = Vector.<Number>([ _x1, _y1 , _x2 , _y2 ]);
			drawEditLine();
		}
		
		private function onPathEditFinish( e:PathEditEvent ):void 
		{
			redraw();
		}
		
	}

}