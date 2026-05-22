import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;
import java.awt.Desktop;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.URI;

public class LoginServer {
     public static void main(String[] args) throws Exception {

        // Create server on port 8080
        HttpServer server = HttpServer.create(new InetSocketAddress(9090), 0);

        // Create route
        server.createContext("/", new LoginHandler());

        // Start server
        server.setExecutor(null);
        server.start();

        System.out.println("Server started at: http://localhost:9090");

        // Open browser automatically
        if (Desktop.isDesktopSupported()) {
            Desktop.getDesktop().browse(new URI("http://localhost:9090"));
        }
    }
    static class LoginHandler implements HttpHandler {

        @Override
        public void handle(HttpExchange exchange) throws IOException {

            String html = """
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <title>Login Page</title>
                        <style>
                            body {
                                font-family: Arial, sans-serif;
                                background: #f2f2f2;
                                display: flex;
                                justify-content: center;
                                align-items: center;
                                height: 100vh;
                            }

                            .login-box {
                                background: white;
                                padding: 30px;
                                border-radius: 10px;
                                box-shadow: 0px 0px 10px gray;
                                width: 300px;
                            }

                            h2 {
                                text-align: center;
                            }

                            input {
                                width: 100%;
                                padding: 10px;
                                margin-top: 10px;
                                border: 1px solid #ccc;
                                border-radius: 5px;
                            }

                            button {
                                width: 100%;
                                padding: 10px;
                                margin-top: 15px;
                                background: #007bff;
                                color: white;
                                border: none;
                                border-radius: 5px;
                                cursor: pointer;
                            }

                            button:hover {
                                background: #0056b3;
                            }
                        </style>
                    </head>
                    <body>

                        <div class='login-box'>
                            <h2>Login</h2>

                            <form>
                                <input type='text' placeholder='Enter Username' required>

                                <input type='password' placeholder='Enter Password' required>

                                <button type='submit'>Login</button>
                            </form>
                        </div>

                    </body>
                    </html>
                    """;

            exchange.sendResponseHeaders(200, html.getBytes().length);

            try (OutputStream os = exchange.getResponseBody()) {
                os.write(html.getBytes());
            }
        }
    }
}
