package com.bookstoreapi.service;

import com.bookstoreapi.entity.Book;
import org.springframework.stereotype.Service;

import java.util.List;

public interface BookService {

    Book createBook(Book book);
    List<Book> createBooks(List<Book> books);
    Book getBookById(Long BookId);
    List<Book> getAllBooks();
    Book updateBook(Book book);
    void deleteBook(Long BookId);
    List<Book> getAllBooksByAuthId(Long authId);
}
