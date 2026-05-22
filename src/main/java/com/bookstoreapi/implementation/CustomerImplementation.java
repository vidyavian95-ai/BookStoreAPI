package com.bookstoreapi.implementation;

import com.bookstoreapi.entity.Order;
import com.bookstoreapi.repository.OrderRepository;
import com.bookstoreapi.service.BillingService;

import java.util.Optional;

public class CustomerImplementation {


    private OrderRepository orderRepository;

    public Order createOrder(Order order){
        return orderRepository.save(order);
    }

    public Order findOrderByCustomerId(Long orderId){
        Optional<Order> optionalOrder =  orderRepository.findById(orderId);
        return optionalOrder.get();
    }


}
