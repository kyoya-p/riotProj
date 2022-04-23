expect class TcpSocket() {
    fun close()
    fun connect(adr: String, port: Int): Int
    fun send(buf: String): Int
    fun recv(buf: ByteArray): Int

    companion object {
        fun initialize()
    }
}
