
use blocks = "./blocks"

// Other stuff

use "../app"
use "../system"
use "../blocks"
use "../blocktypes"


use "collections"
use "debug"
use "files"
use "jay"
use "logger"
use "ponytest"
use "promises"

actor Main is TestList

  new create(env: Env) =>
    PonyTest(env, this)

  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    blocks.Main.make().tests( test )
    test(_BlockTest("add/add-test.json"))

  
class iso _BlockTest is UnitTest
  let _pathname: String 

  new iso create( pathname:String ) =>
    _pathname = pathname
    
  fun name():String => _pathname

  fun apply(h: TestHelper)? =>
  
    // 0. set up test application
    let testcase:Array[(Array[(String,String)] val,Assertion, Application)] = setup( h )?
    h.long_test(1000000000)  // indicate long test.
    
    // 1. For each topology
    for (inputs,assertion,app) in testcase.values() do
      
      // The following construct is to ensure that all blocks in the topology has started before we start inputting data
      let promise = Promise[JArr]
      promise.next[None]( { (json: JArr) => 
        assertion.run( inputs, app )
      } )
      app.describe( promise )
      
    end
    
    None

  fun setup(h: TestHelper): Array[(Array[(String,String)] val,Assertion, Application)] ?=>
    let env:Env = h.env
    let context = SystemContext(env, Fine)
    let blocktypes = BlockTypes(context)
    let loader = Loader(blocktypes, context)
    let root: JObj = parse_test(_pathname, env)?
    let result = Array[(Array[(String,String)] val,Assertion, Application)]
    for test_descr in root.keys() do
      let unittest = root(test_descr) as JObj
      let topology = unittest("topology") as String
      (let dir, let file) = Path.split(_pathname)
      let testdefinition = Path.join(dir,topology)
      let test_app = loader.load( testdefinition )?

      let factory = AssertionFactory(h)
      let assertion_block = factory.create_block("assertions", context) as Assertion
      test_app.register_block( assertion_block, "assertions", factory.block_type_descriptor() )
      
      let inputs: JArr val = unittest("inputs") as JArr
      let feed = recover val 
        let f = Array[(String,String)]
        for inp' in inputs.values() do
          let inp = inp' as JObj
          let input_name = inp.keys().next()?
          let input_value = inp(input_name) as String
          f.push( (input_name, input_value) )
        end
        f
      end
      let expects: JArr val = unittest("expects") as JArr
      let assertions = Set[String]
      for expectation in expects.values() do
        let exp = expectation as JObj
        let expectations:Array[Linkable] val = recover
          let e = Array[Linkable]
          for output_ref in exp.keys() do
            assertions.set(output_ref)
            let output_value = exp(output_ref) as JObj
            let typ:String = output_value("type") as String
            let expected:String = output_value("value") as String
            match typ
            | "F64" => e.push( expected.f64()? )
            | "U64" => e.push( expected.u64()? )
            | "I32" => e.push( expected.i32()? )
            | "Bool" => e.push( expected.bool()? )
            | "String" => e.push( expected )
            else
              h.fail("Test harness contains unknown type: " + typ )
            end
          end
          e
        end
        assertion_block.add_expectation( expectations )
      end
      for output_name in assertions.values() do
        (let src_block, let src_output) = BlockName(output_name)?
        test_app.connect( src_block, src_output, "assertions", "equality" )
      end
      test_app.start()
      result.push((feed,assertion_block, test_app))
    end
    result
    
  fun parse_test(pathname:String, env:Env): JObj ? =>
    try
      let content = Files.read_lines_from_pathname(pathname, env.root)?
      try
        let json = JParse.from_string( content )?
          try
            json as JObj
          else
            env.err.print("The root object in test document is not an Object.")
            error
          end
      else
        env.err.print("Test document is not a correctly formatted JSON document." )
        error
      end
    else
      env.err.print("Unable to read" + _pathname )
      error
    end
