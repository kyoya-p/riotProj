fun main() {
    TcpSocket.initialize()
    val sock = TcpSocket()
    println("3")//TODO
    check(sock.connect("10.36.102.191", 10008) != 0) { "Error: connect()" }

    println("4")//TODO
    var buf = ByteArray(16)
    val len = sock.recv(buf)
    println("len=$len") //TODO
    buf.forEachIndexed { i, e -> println("$i:$e") }//TODO
    if (!buf.decodeToString(0, len).startsWith("login:", ignoreCase = true)) return
    sock.send("\u000d\u000a")
    sock.recv(buf)
    if (!buf.decodeToString().startsWith("password:", ignoreCase = true)) return
    sock.send("\u000d\u000a")

    sock.send("SRNO????")
    println("5")//TODO
    sock.recv(buf)
    println(buf.decodeToString())
    println("6")//TODO

    sock.close()
}


