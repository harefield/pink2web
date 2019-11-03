use "collections"
use "jay"
use "logger"
use "promises"
use "../graphs"
use "../system"

actor AddBlock is Block
  var _name: String
  let _descriptor: BlockTypeDescriptor
  let _input1: Input[Number]
  let _input2: Input[Number]
  let _output: Output[F64]
  let _context:SystemContext
  var _started:Bool = false
  var _x:I64
  var _y:I64
  
  new create(name: String, descriptor': BlockTypeDescriptor, context:SystemContext, x:I64, y:I64 ) =>
    context(Fine) and context.log("create("+name+")")
    _context = context
    _name = name
    _descriptor = descriptor'
    _x = x
    _y = y
    let zero:F64 = 0.0
    _input1 = InputImpl[Number]( name, _descriptor.input(0), zero )
    _input2 = InputImpl[Number]( name, _descriptor.input(1), zero )
    _output = OutputImpl[F64]( name, _descriptor.output(0), zero )

  be change( x:I64, y:I64 ) =>
    _x = x
    _y = y
    
  be start() =>
    _context(Fine) and _context.log("start()")
    _started = true
    refresh()
    
  be stop() =>
    refresh()
    _context(Fine) and _context.log("stop()")
    _started = false
    
  be connect( output: String, to_block: Block, to_input: String) =>
    if output == "output"  then
      _output.connect(to_block, to_input)
    end
    refresh()

  be disconnect_block( block: Block ) =>
    _output.disconnect_block( block )

  be disconnect_edge( output:String, dest_block: Block, dest_input: String ) =>
    match output
    | "output" => _output.disconnect_edge( dest_block, dest_input )
    end

  be destroy() =>
    refresh()
    _context(Fine) and _context.log("destroy()")
    _started = false
    _output.disconnect_all()
    
  be rename( new_name: String ) =>
    _name = new_name
    
  be update(input: String, new_value: Linkable) =>
    _context(Fine) and _context.log("Add[ " + _name + "." + input + " = " + new_value.string() + " ]")
    match new_value
    | let v: F64 => 
        if input == "input1" then _input1.set( v ) end
        if input == "input2" then _input2.set( v ) end
    | let v: String => 
      try
        if input == "input1" then _input1.set( v.f64()? ) end
        if input == "input2" then _input2.set( v.f64()? ) end
      end // ignore if we can't convert it. Later we introduce a error message channel.
    end
    refresh()

  be refresh() =>
    if _started then
      _context(Fine) and _context.log("refresh()")
      let value : F64 = _input1.value().f64() + _input2.value().f64()
      _output.set( value )
    end
    
  be descriptor( promise: Promise[BlockTypeDescriptor] tag ) =>
    promise(_descriptor)

  be describe( promise:Promise[JObj val] tag ) =>
    _context(Fine) and _context.log("describe")
    let in1 = _input1.describe()
    let in2 = _input2.describe()
    let out = _output.describe()
    let m = JObj
      + ("name", _name )
      + ("started", _started )
      + ("input1", in1 )
      + ("input2", in2 )
      + ("output", out )
    _context(Fine) and _context.log( "Reporting " + m.string() )
    promise(m)
    
class val AddBlockDescriptor is BlockTypeDescriptor
  let _in1:InputDescriptor
  let _in2:InputDescriptor
  let _out:OutputDescriptor

  new val create() =>
      _in1 = InputDescriptor("input1", PNum, "first term in addition", false, true )
      _in2 = InputDescriptor("input2", PNum, "second term in addition", false, true )
      _out = OutputDescriptor("output", PNum, "output=input1+input2", false, true )

  fun val inputs(): Array[InputDescriptor] val =>
    [ _in1; _in2 ]

  fun val outputs(): Array[OutputDescriptor] val =>
    [ _out ]
    
  fun in1(): InputDescriptor => _in1
  
  fun in2(): InputDescriptor => _in2
  
  fun out(): OutputDescriptor => _out
  
  fun val input( index: USize ): InputDescriptor val =>
    match index
    | 0 => _in1
    | 1 => _in2
    else
      InputDescriptor( "INVALID", PNum, "INVALID", false, false)
    end
    
  fun val output( index: USize ): OutputDescriptor val =>
    match index
    | 0 => _out
    else
      OutputDescriptor( "INVALID", PNum, "INVALID", false, false)
    end
    
  fun val name(): String =>
    "Add"
    
  fun val description(): String =>
    "Adds two input and outputs the sum."
    

class val AddBlockFactory is BlockFactory 
  let _descriptor: AddBlockDescriptor val = recover AddBlockDescriptor end
  
  new val create() => None
  
  fun val block_type_descriptor() : BlockTypeDescriptor val^ =>
    _descriptor

  fun create_block( instance_name: String, context:SystemContext val, x:I64, y:I64):Block =>
    context(Fine) and context.log("create Add")
    AddBlock( instance_name, _descriptor, context, x, y )

  fun val describe(): JObj val =>
    JObj + ("descriptor", _descriptor.describe() )
