package snmp

actual class SnmpSession {
    actual companion object {
        actual fun create(target: SnmpTarget): SnmpSession {
            TODO("Not yet implemented")
        }
    }

    actual fun send(pdu: PDU, callback: (pdu: PDU?) -> Any?) = Unit
    actual fun close() = Unit
}
