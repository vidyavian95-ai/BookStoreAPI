package com.bookstoreapi.service;

import com.bookstoreapi.entity.Order;
import com.bookstoreapi.repository.BillingRepository;
import com.bookstoreapi.repository.OrderRepository;

import java.util.List;

public interface BillingService {

   Order findOrdersByCustomerId(Long orderId);
   List<Order> findAllOrder();
   Order createOrder(Order order);
   List<Order> createOrders(List<Order> orders);
}
