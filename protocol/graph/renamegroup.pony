use "jay"
use "promises"
use "../../web"
use ".."
use "../../graphs"


primitive RenameGroupMessage

  fun apply( connection: WebSocketSender, graphs: Graphs, payload: JObj ) =>
    connection.send_text( Message("graph", "addgroup", payload).string() )
