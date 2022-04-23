import kotlinx.cinterop.*
import platform.posix.*
import platform.windows.htons


actual class TcpSocket {
    val raw: SOCKET = socket(AF_INET, SOCK_STREAM, 0)

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
            alloc<sockaddr_in>().apply {
                println("con.3.1")//TODO
                sin_family = AF_INET.toShort()
                sin_port = htons(port.toUShort())
                sin_addr.S_un.S_addr = clientAddr
                println("con.3.2")//TODO

            }
        }
        println("con.5")//TODO
        val r = connect(raw, socketAddr.ptr.reinterpret(), sockaddr_in.size.convert())
        println("con.6")//TODO
        if (r != 0) println("Error: connect() errno=${errno}")
        return r
    }

    actual fun write(buf: ByteArray): Int {
        return write(raw.convert(), buf.toCValues(), buf.size.convert())
    }
    actual fun read(buf:ByteArray):Int {
        return read(raw.convert(), buf.toCValues(), buf.size.convert())
    }
}

