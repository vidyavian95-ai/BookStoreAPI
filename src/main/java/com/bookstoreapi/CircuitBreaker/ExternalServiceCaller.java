package com.bookstoreapi.CircuitBreaker;

import org.springframework.stereotype.Service;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;

@Service
public class ExternalServiceCaller {
    @CircuitBreaker(name = "myServiceCircuitBreaker", fallbackMethod = "fallbackForExternalService")
    public String callExternalService() {
        // Logic to call an external service
        // ...
        return "Data from external service";
    }

    public String fallbackForExternalService(Throwable t) {
        // Fallback logic, e.g., return default data or a cached response
        return "Fallback data due to external service failure: " + t.getMessage();
    }
}
