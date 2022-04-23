package snmp

import firebaseInterOp.require

/*
 https://github.com/markabrahams/node-net-snmp
 */

actual class SnmpSession(val raw: dynamic) {
    actual companion object {
        val snmp = require("net-snmp")
        actual fun create(target: SnmpTarget): SnmpSession {
            return SnmpSession(snmp.createSession(host = target.addr, community = target.credential.v1commStr))
        }
    }

    actual fun close(): Unit = raw.close()

    actual fun send(pdu: PDU, callback: (PDU?) -> Any?) {

        val oid = pdu.vbl.map { it.oid }.toTypedArray()
        val _callback = { error: dynamic, varbinds: dynamic ->
            //if (error != null) {
            //    println("cb1=$error")
            //    println("cb2=${error.constructor.name}")
            //    println("cb2=${error.name}")
            //} TODO
            when {
                error == null -> callback(PDU(vbl = convVBL(varbinds)))
                error.name == "RequestTimedOutError" -> callback(null)
                error.name == "RequestFailedError" -> callback(PDU(vbl = convVBL(varbinds), errSt = error.status))
                else -> throw Exception("Unknown Error Status")
            }
        }

        when (pdu.type) {
            PDU.GET -> raw.get(oid, _callback)
            else -> raw.getNext(oid, _callback)
        }

    }
}

fun convVBL(vbl: dynamic) =
    if (vbl != null) List(vbl.length) { VarBind.from(vbl[it]) } else listOf()

fun VarBind.Companion.from(varbind: dynamic) = VarBind(varbind.oid, Variable.from(varbind))

external fun parseInt(x: Any): Int

fun Variable.Companion.from(varbind: dynamic): Variable {
    val stx: Byte = varbind.type
    val v: dynamic = varbind.value
    fun Int.toByteArray() = ByteArray(4) { i -> ((this ushr (i * 8)) and 0xff).toByte() }
    fun Long.toByteArray() = ByteArray(8) { i -> ((this ushr (i * 8)) and 0xff).toByte() }

    val buff = when (v.constructor.name) {
        "Number" -> (v as Int).toByteArray()
        "Buffer" -> ByteArray(v.length) { v[it] }
        else -> throw IllegalArgumentException("Unsupported variable type: ${v.constructor.name} ${stx} ${v}")
    }
    println("buff=${buff.joinToString()}")

    /*
    val value = when (stx) {
        Variable.INTEGER32 -> ByteArray(v.length) { v[it] }
        Variable.BITSTRING -> ByteArray(v.length) { v[it] }
        Variable.OCTETSTRING -> ByteArray(v.length) { v[it] }
        Variable.OID -> (v as Long).toByteArray()
        Variable.IPADDRESS -> (v as Int).toByteArray()
        Variable.COUNTER32 -> (v as Int).toByteArray()
        Variable.GAUGE32 -> (v as Long).toByteArray()
        Variable.TIMETICKS -> (v as Long).toByteArray()
        Variable.OPAQUE -> ByteArray(v.length) { v[it] }
        Variable.COUNTER64 -> (v as Long).toByteArray()
        Variable.NOSUCHOBJECT -> ByteArray(0)
        Variable.NOSUCHINSTANCE -> ByteArray(0)
        Variable.ENDOFMIBVIEW -> ByteArray(0)
        else -> throw IllegalArgumentException("Unsupported variable syntax: ${stx} ${v}")
    }
     */
    return Variable(stx, buff)
}
