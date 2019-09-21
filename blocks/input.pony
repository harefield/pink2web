use "collections"
use "jay"
use "../system"

trait Input[TYPE: Linkable val] is CVisitable[JObj val]
  fun ref set( newValue: TYPE)
  fun value() : this->TYPE
  fun description() : String val
  fun ref set_description( new_description:String val )

class InputImpl[TYPE: Linkable val] is Input[TYPE]
  let _name: String
  var _value: TYPE
  var _description: String
  let _descriptor:InputDescriptor
  
  new create(container_name: String val, descriptor:InputDescriptor, initialValue: TYPE, description': String val  = "") =>
    _name = container_name + "." + descriptor.name   // TODO is this the best naming system?
    _description = description'
    _descriptor = descriptor
    _value = consume initialValue

  fun value() : this->TYPE =>
    _value

  fun ref set( newValue: TYPE) =>
    _value = consume newValue

  fun description() : String val =>
    if _description == "" then 
      _descriptor.description
    else
      _description
    end

  fun ref set_description( new_description: String ) =>
    _description = new_description
    
  fun visit(): JObj val =>
    let j = JObj
      + ("id", _name)
      + ("description", _description )
      + ("descriptor", _descriptor.describe() )
    j

class val InputDescriptor
  let name:String
  let description: String
  let typ: String
  let addressable: Bool
  let required: Bool
  
  new val create( name':String, typ':String, description':String, addressable': Bool, required': Bool ) =>
    name = name'
    description = description'
    typ = typ'
    addressable = addressable'
    required = required'
    
  fun describe() : JObj val =>
    let j = JObj
      + ("id", name)
      + ("description", description)
      + ("type", typ )
      + ("required", required)
      + ("addressable", addressable )
    j
    
