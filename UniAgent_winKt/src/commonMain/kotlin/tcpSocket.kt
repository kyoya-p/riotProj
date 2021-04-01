expect class TcpSocket() {
    fun isOk(): Boolean
    fun close()
    fun connect(adr: String, port: Int): Int
    fun send(buf: String): Int
    fun recv(buf: ByteArray): Int

    companion object {
        fun initialize()
    }
}

fun TcpSocket.recv() :String {
    val buf=ByteArray(2048)
    while
}