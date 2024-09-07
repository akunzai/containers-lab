package com.example.demo;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public final class DemoApplication {

  /**
   * Main entry point.
   * 
   * @param args
   */
  public static void main(final String[] args) {
    SpringApplication.run(
        DemoApplication.class, args);
  }

  /**
   * root path.
   * 
   * @param req
   * @return response
   */
  @GetMapping("/")
  public String index(final HttpServletRequest req) {
    return "Hello from server: "
        + req.getServerName()
        + " via scheme: "
        + req.getScheme();
  }
}
