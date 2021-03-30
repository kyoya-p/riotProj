
expect fun winDialog_SAMPLE()
expect fun readFile_SAMPLE()

expect class TcpSocket() {
    fun isOk(): Boolean
    fun connecta()
}

fun main() {
    //winDialog_SAMPLE()
    //readFile_SAMPLE()

    val sock = TcpSocket()
    sock.connecta()
}
