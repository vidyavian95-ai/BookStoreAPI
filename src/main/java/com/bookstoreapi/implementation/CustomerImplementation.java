package com.bookstoreapi.implementation;

import java.util.Optional;

import com.bookstoreapi.entity.Order;
import com.bookstoreapi.repository.OrderRepository;

public class CustomerImplementation {


    private final OrderRepository orderRepository;
    public CustomerImplementation(OrderRepository orderRepository) {
        this.orderRepository = orderRepository;
    }

    public Order createOrder(Order order){
        return orderRepository.save(order);
    }

    public Order findOrderByCustomerId(Long orderId){
        Optional<Order> optionalOrder =  orderRepository.findById(orderId);
        return optionalOrder.get();
    }


}
