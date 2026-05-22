package com.bookstoreapi.repository;

import com.bookstoreapi.entity.Customer;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BillingRepository extends JpaRepository<Customer, Long> {

}
