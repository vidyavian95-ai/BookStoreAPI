package com.bookstoreapi.Kafka;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class KafkaController {

    @Autowired
    private KafkaProducerService producerService;

    @GetMapping("/send")
    public String sendMessageToKafka(@RequestParam("message") String message) {
        producerService.sendMessage("my-topic", message);
        return "Message sent to Kafka!";
    }
}
