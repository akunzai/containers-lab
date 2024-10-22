package com.example.demo;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import org.springframework.util.StreamUtils;
import jakarta.servlet.ServletInputStream;
import jakarta.servlet.ReadListener;

import java.io.*;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.time.OffsetDateTime;
import java.util.*;
import java.util.stream.Collectors;

@SpringBootApplication
@RestController
public class DemoApplication {
    private static final Logger logger = LoggerFactory.getLogger(DemoApplication.class);

    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }

    @RequestMapping(value = {"/**", "/"}, produces = MediaType.TEXT_PLAIN_VALUE, method = {RequestMethod.GET,
            RequestMethod.POST, RequestMethod.PUT,
            RequestMethod.DELETE, RequestMethod.PATCH})
    public String handleRoot(HttpServletRequest request) throws IOException {
        var response = new StringBuilder();
        response.append(String.format("Hostname: %s\r\n", getHostname()));
        response.append(String.format("DateTime: %s\r\n", OffsetDateTime.now()));
        response.append(String.format("OS Version: %s\r\n", System.getProperty("os.version")));
        response.append(String.format("Runtime Version: %s\r\n", Runtime.version()));
        getIpAddresses().forEach(ip -> response.append(String.format("Server IP: %s\r\n", ip)));
        response.append(String.format("Client IP: %s\r\n", request.getRemoteAddr()));
        response.append(String.format("Protocol: %s\r\n", request.getProtocol()));
        response.append(String.format("Scheme: %s\r\n", request.getScheme()));
        response.append(String.format("Host: %s:%d\r\n",
                request.getServerName(), request.getServerPort()));
        response.append(String.format("Path: %s\r\n", request.getRequestURI()));
        if (request.getQueryString() != null) {
            response.append(String.format("Query String: %s\r\n", request.getQueryString()));
        }
        response.append(String.format("Method: %s\r\n", request.getMethod()));
        response.append("Headers:\r\n");
        Collections.list(request.getHeaderNames())
                .stream()
                .sorted()
                .forEach(headerName -> response.append(String.format("- %s: %s\r\n",
                        headerName, request.getHeader(headerName))));
        return response.toString();
    }

    @GetMapping(value = "/env", produces = MediaType.TEXT_PLAIN_VALUE)
    public String handleEnv() {
        var response = new StringBuilder();
        System.getenv().entrySet().stream()
                .sorted(Map.Entry.comparingByKey())
                .forEach(entry -> response.append(String.format("%s=%s\r\n",
                        entry.getKey(), entry.getValue())));
        return response.toString();
    }

    @RequestMapping(value = "/api", method = {RequestMethod.GET, RequestMethod.POST, RequestMethod.PUT,
            RequestMethod.DELETE, RequestMethod.PATCH})
    public Map<String, Object> handleApi(HttpServletRequest request) throws IOException {
        var cachedRequest = new CachedBodyHttpServletRequest(request);
        var response = new HashMap<String, Object>();
        response.put("hostname", getHostname());
        response.put("dateTime", OffsetDateTime.now());
        response.put("osVersion", System.getProperty("os.version"));
        response.put("runtimeVersion", Runtime.version());
        response.put("serverIP", getIpAddresses());
        response.put("clientIP", cachedRequest.getRemoteAddr());
        response.put("protocol", cachedRequest.getProtocol());
        response.put("scheme", cachedRequest.getScheme());
        response.put("host", cachedRequest.getServerName() + ":" + cachedRequest.getServerPort());
        response.put("method", cachedRequest.getMethod());
        response.put("path", cachedRequest.getRequestURI());
        response.put("query", cachedRequest.getQueryString());
        response.put("headers", Collections.list(cachedRequest.getHeaderNames()).stream()
                .collect(Collectors.toMap(
                        headerName -> headerName,
                        cachedRequest::getHeader)));
        return response;
    }

    private String getHostname() {
        try {
            return InetAddress.getLocalHost().getHostName();
        } catch (Exception e) {
            logger.error("Error getting hostname", e);
            return "unknown";
        }
    }

    private List<String> getIpAddresses() {
        var addresses = new ArrayList<String>();
        try {
            var interfaces = NetworkInterface.getNetworkInterfaces();
            while (interfaces.hasMoreElements()) {
                var networkInterface = interfaces.nextElement();
                if (!networkInterface.isUp())
                    continue;

                networkInterface.getInetAddresses().asIterator().forEachRemaining(address -> {
                    if (address instanceof java.net.Inet4Address) {
                        addresses.add(address.getHostAddress());
                    }
                });
            }
        } catch (Exception e) {
            logger.error("Error getting IP addresses", e);
        }
        return addresses;
    }

    private boolean isMethodWithBody(String method) {
        return method.equals("POST") || method.equals("PUT") || method.equals("PATCH");
    }

    private String getRequestBody(HttpServletRequest request) throws IOException {
        try (var reader = request.getReader()) {
            return reader.lines().collect(Collectors.joining("\n"));
        }
    }
}

class CachedBodyHttpServletRequest extends HttpServletRequestWrapper {
    private final byte[] cachedBody;

    public CachedBodyHttpServletRequest(HttpServletRequest request) throws IOException {
        super(request);
        var requestInputStream = request.getInputStream();
        this.cachedBody = StreamUtils.copyToByteArray(requestInputStream);
    }

    @Override
    public ServletInputStream getInputStream() {
        return new CachedServletInputStream(this.cachedBody);
    }

    @Override
    public BufferedReader getReader() {
        var byteArrayInputStream = new ByteArrayInputStream(this.cachedBody);
        return new BufferedReader(new InputStreamReader(byteArrayInputStream));
    }
}

class CachedServletInputStream extends ServletInputStream {
    private static final Logger logger = LoggerFactory.getLogger(CachedServletInputStream.class);
    private final ByteArrayInputStream buffer;

    public CachedServletInputStream(byte[] contents) {
        this.buffer = new ByteArrayInputStream(contents);
    }

    @Override
    public int read() throws IOException {
        return buffer.read();
    }

    @Override
    public boolean isFinished() {
        return buffer.available() == 0;
    }

    @Override
    public boolean isReady() {
        return true;
    }

    @Override
    public void setReadListener(ReadListener listener) {
        var message = "Non-blocking I/O not supported";
        logger.error(message);
        throw new UnsupportedOperationException(message);
    }
}