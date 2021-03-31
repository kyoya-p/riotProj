import kotlinx.cinterop.*
import platform.posix.WSADATA
import platform.windows.*
import platform.windows.SOCKADDR_INET

actual class TcpSocket {
    val raw = socket(AF_INET, SOCK_STREAM, 0)

    actual companion object {
        actual fun initialize() {
            var data = memScoped { alloc<WSADATA>() }
            val err_startup = WSAStartup(0x0202, data.ptr)
            println("WSAStartup:$err_startup")
        }
    }

    @ExperimentalUnsignedTypes
    actual fun isOk(): Boolean {
        return raw != 0.toULong()
    }

    actual fun connect(addr: String, port: Int): Int {
        if (raw == 0.toULong()) return -1
        println("con.1")//TODO
        val clientAddr = inet_addr(addr)
        println("con.2")//TODO
        val socketAddr = memScoped {
            println("con.3")//TODO
            alloc<SOCKADDR_INET>().apply {
                println("con.3.1")//TODO
                Ipv4.sin_family = platform.posix.AF_INET.toShort()
                Ipv4.sin_port = htons(port.toUShort())
                Ipv4.sin_addr.S_un.S_addr = clientAddr
                println("con.3.2")//TODO

            }
        }
        println("con.5")//TODO
        val r = connect(raw, socketAddr.ptr.reinterpret(), SOCKADDR_INET.size.convert())
        println("con.6")//TODO
        if (r != 0) println("Error: connect()")
        return r
    }

    actual fun close() {
        closesocket(raw)
    }

    actual fun send(buf: String): Int {
        return send(raw.convert(), buf, buf.length, 0)
    }

    actual fun recv(buf: ByteArray): Int {
        memScoped { allocArray<CVariable>(2048) }
        return recv(raw.convert(), buf., buf.size.convert(), 0)
    }
}

