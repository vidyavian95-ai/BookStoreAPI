package com.bookstoreapi;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import org.mockito.junit.jupiter.MockitoExtension;

import com.bookstoreapi.entity.Book;
import com.bookstoreapi.implementation.BookImplementation;
import com.bookstoreapi.repository.BookRepository;

@ExtendWith(MockitoExtension.class)
public class BookServiceTest {

    @Mock
    BookRepository repo;

    @InjectMocks
    BookImplementation service;

    @Test
    void getBook_existingId_returnsBook() {

        Book b = new Book();
        b.setId(1L);
        b.setTitle("Title");
        b.setDescription("Demo Description");
        b.setGenre("Fiction");
        b.setPublication_date("2026");

        when(repo.findById(1L)).thenReturn(Optional.of(b));

        Book result = service.getBookById(1L);

        assertThat(result.getTitle()).isEqualTo("Title");

        verify(repo).findById(1L);
    }
}