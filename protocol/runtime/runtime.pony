
use "jay"
use "websocket"

class val RuntimeMessage 
  let _id: String
  let _label: String
  let _version: String
  let _all_capabilities: JArr
  let _capabilities: JArr
  let _graph: String
  let _type: String
  let _namespace: String   
  let _repository: String
  let _repository_version: String

  new val create( 
      id: String, label: String, version: String, 
      all_capabilities: Array[String val] val, capabilities: Array[String val] val,
      graph: String, type': String, namespace: String,
      repository: String, repository_version: String ) =>
      
    _id = id
    _label = label
    _version = version
    _graph = graph
    _type = type'
    _namespace = namespace
    _repository = repository
    _repository_version = repository_version 
    _capabilities = create_jarr( capabilities )
    _all_capabilities = create_jarr( capabilities )
    
  fun format(): JObj val =>
    JObj
      + ("id", _id )
      + ("label", _label )
      + ("version", _version )
      + ("allCapabilities", _all_capabilities )
      + ("capabilities", _capabilities )
      + ("graph", _graph )    
      + ("type", _type )    
      + ("namespace", _namespace )    
      + ("repository", _repository )    
      + ("repositoryVersion", _repository_version )
    
    
  fun tag create_jarr( array: Array[String val] val ): JArr val =>
    recover val
      var arr: JArr = JArr 
      for element in array.values() do
        arr = arr + element
      end
      arr
    end
    
  fun string(): String val =>
    format().string()
