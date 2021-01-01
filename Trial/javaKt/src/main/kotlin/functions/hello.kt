package functions

import com.google.cloud.functions.HttpFunction
import java.io.BufferedWriter
import java.io.IOException

class HelloWorldKt : HttpFunction {
    // Simple function to return "Hello World"
    @Throws(IOException::class)
    override fun service(request: com.google.cloud.functions.HttpRequest, response: com.google.cloud.functions.HttpResponse) {
        val writer: BufferedWriter = response.getWriter()
        writer.write("Hello Kt World! ")
    }
}
