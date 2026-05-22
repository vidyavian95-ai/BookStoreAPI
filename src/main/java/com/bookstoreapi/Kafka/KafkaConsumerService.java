package com.bookstoreapi.Kafka;

import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
public class KafkaConsumerService {

    @KafkaListener(topics = "my-topic", groupId = "my-group-id")
    public void listen(String message) { // Or MyObject object for custom objects
        System.out.println("Received message: " + message);
    }
}
