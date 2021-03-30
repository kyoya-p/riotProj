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

    actual fun connecta() {
        val clientAddr = inet_addr("10.36.102.191")
        val socketAddr = memScoped {
            alloc<sockaddr_in>().apply {
                sin_family = AF_INET.convert()
                sin_port = htons(10008.convert())
                sin_addr.S_un.S_addr = clientAddr
            }
        }
        //connect(raw, socketAddr.ptr.reinterpret(), socketAddr.)
    }
}

