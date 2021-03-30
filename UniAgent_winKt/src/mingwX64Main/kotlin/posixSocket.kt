import kotlinx.cinterop.*
import platform.posix.*
import platform.windows.htons

actual fun readFile_SAMPLE() {
    val fd: Int = open("README.md", O_RDONLY)

    val buf = nativeHeap.allocArray<ByteVar>(2048)
    buf.usePinned {
        read(fd, buf, 2048)
    }
    val contents = buf.toKString()
    nativeHeap.free(buf)
    println("file: $contents")
}

actual class TcpSocket {
    val raw: SOCKET = socket(AF_INET, SOCK_STREAM, 0)


    @ExperimentalUnsignedTypes
    actual fun isOk(): Boolean {
        return raw != 0.toULong()
    }

    actual fun connect(addr: String, port: Int): Int {
        if (raw == 0.convert()) return -1
        val clientAddr = inet_addr(addr)
        val socketAddr = memScoped {
            alloc<sockaddr_in>().apply {
                sin_family = AF_INET.convert()
                sin_port = htons(port.convert())
                sin_addr.S_un.S_addr = clientAddr
            }
        }
        return connect(raw, socketAddr.ptr.reinterpret(), sockaddr_in.size.convert())
    }

    actual fun write(buf: ByteArray): Int {
        return write(raw.convert(), buf.toCValues(), buf.size.convert())
    }
}

