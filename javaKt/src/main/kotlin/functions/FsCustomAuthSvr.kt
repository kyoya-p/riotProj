package functions

/*
 Provider of custom token for device authorization
 This module should be run in backend.

 Refer:
 - https://firebase.google.com/docs/admin/setup?hl=ja

    request: GET /customToken?id={deviceId}&pw={devicePassword}

    device/{deviceId}.password == devicePassword ならばカスタム認証pass
    customTokenは、{id, clusterId}

 */

import com.google.cloud.firestore.FirestoreOptions
import com.google.cloud.functions.HttpFunction
import com.google.firebase.FirebaseApp
import com.google.firebase.auth.FirebaseAuth
import java.io.BufferedWriter
import java.io.IOException


data class Credential(val id: String, val pw: String)

class reqestToken : HttpFunction {
    @Throws(IOException::class)
    override fun service(request: com.google.cloud.functions.HttpRequest, response: com.google.cloud.functions.HttpResponse) {
        val writer: BufferedWriter = response.getWriter()
        try {
            val cr = Credential(request.queryParameters["id"]!![0]!!, request.queryParameters["pw"]!![0]!!)
            writer.write(createCustomToken(cr))
        } catch (e: Exception) {
            writer.write(e.stackTraceToString()) //TODO エラー表示してはダメ
        }
    }
}

fun createCustomToken(credential: Credential): String {
    FirebaseApp.initializeApp()

    val db = FirestoreOptions.getDefaultInstance().service ?: return ""
    val dev = db.collection("device").document(credential.id).get().get()?.data ?: return ""
    val devPw = dev.get("password") as String? ?: return ""
    if (devPw != credential.pw) return ""

    val devClusterId = dev.get("cluster") as String? ?: return ""
    val additionalClaims = mapOf(
            "id" to credential.id,
            "cluster" to devClusterId,
    )

    val mAuth = FirebaseAuth.getInstance()
    val serviceUserId = "firebase-adminsdk-rc191@road-to-iot.iam.gserviceaccount.com"
    val customJwtToken = mAuth.createCustomToken(serviceUserId, additionalClaims)
    //customJwtToken.split(".").take(2).map { println(String(Base64.getDecoder().decode(it))) }

    return customJwtToken
}

