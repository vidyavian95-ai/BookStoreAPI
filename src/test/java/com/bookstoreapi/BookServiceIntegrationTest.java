package com.bookstoreapi;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import com.bookstoreapi.entity.Book;
import com.bookstoreapi.service.BookService;


@SpringBootTest
@Transactional
class BookServiceIntegrationTest {

    @Autowired
    private BookService service;

      @Test
    void testSaveBook() {

        Book book = new Book();
        book.setTitle("Java");
        book.setDescription("Java Programming Book");
        book.setGenre("Programming");
        book.setPublication_date("2025-01-01");
        Book saved =
                service.createBook(book);

        assertNotNull(saved.getId());
    }

    @Test
    void testGetBook() {

        Book book = new Book();
        book.setTitle("Spring Boot");
        book.setDescription("Spring Boot Guide");
        book.setGenre("Programming");
        book.setPublication_date("2025-01-01");

        Book saved =
                service.createBook(book);

        Book result =
                service.getBookById(saved.getId());

        assertEquals(
                "Spring Boot",
                result.getTitle());
    }
    
}
