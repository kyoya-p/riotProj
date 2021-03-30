expect fun winDialog_SAMPLE()

expect class TcpSocket() {
    fun isOk(): Boolean
    fun connect(addr: String, port: Int): Int
    fun write(buf: ByteArray): Int

    companion object {
        fun initialize()
    }
}

fun main() {
    //winDialog_SAMPLE()
    //readFile_SAMPLE()
    TcpSocket.initialize()
    println("1")//TODO
    val sock = TcpSocket()
    println("2")//TODO
    if (sock.isOk()) {
        println("3")//TODO
        if (sock.connect("127.0.0.1", 8765) != 0) {
            println("Error: connect() ")
        }
        println("4")//TODO

        sock.write("ABCD".encodeToByteArray())
        println("success")
    } else {
        println("Error: socket()")
    }
}
