expect fun winDialog_SAMPLE()
expect fun readFile_SAMPLE()

expect class TcpSocket() {
    fun isOk(): Boolean
    fun connect(addr: String, port: Int): Int
    fun write(buf: ByteArray): Int
}

fun main() {
    //winDialog_SAMPLE()
    //readFile_SAMPLE()

    val sock = TcpSocket()
    sock.connect("127.0.0.1", 8080)
    sock.write("ABCD".encodeToByteArray())
}
