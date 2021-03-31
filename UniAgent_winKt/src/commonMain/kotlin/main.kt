expect class TcpSocket() {
    fun isOk(): Boolean
    fun close()
    fun connect(addr: String, port: Int): Int
    fun send(buf: String): Int
    fun recv(buf: ByteArray): Int

    companion object {
        fun initialize()
    }
}

fun main() {
    TcpSocket.initialize()
    println("1")//TODO
    val sock = TcpSocket()
    println("2")//TODO
    if (!sock.isOk()) throw Exception("Error: socket()")
    println("3")//TODO
    if (sock.connect("10.36.102.191", 10008) != 0) {
        println("Error: connect() ")
    }
    println("4")//TODO
    var buf = ByteArray(2048)

    val len = sock.recv(buf)
    println("len=$len") //TODO
    //buf.forEach { println("$it:") }//TODO
    //if (!buf.decodeToString().startsWith("login:", ignoreCase = true)) return
    //sock.send("\u000d\u000a")
    //sock.recv(buf)
    //if (!buf.decodeToString().startsWith("password:", ignoreCase = true)) return
    //sock.send("\u000d\u000a")

    //sock.send("SRNO????")
    println("5")//TODO
    //sock.recv(buf)
    //println(buf.decodeToString())
    println("6")//TODO


    //ssock.close()
}


