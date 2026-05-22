package com.bookstoreapi.service;

import com.bookstoreapi.entity.Author;
import com.bookstoreapi.entity.Book;

import java.util.List;

public interface AuthorService {

    Author createAuthor(Author author);
    Author getAuthorDetailsById(Long id);
    List<Author> getAllAuthor();
    void  deleteAuthor(Long id);
    Author updateAuthor(Author author);
    List<Book> getALlBookDetailsByAuthId(Long authId);
}
