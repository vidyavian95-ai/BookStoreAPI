package com.bookstoreapi;

import static org.assertj.core.api.AssertionsForClassTypes.assertThat;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;

import com.bookstoreapi.entity.Book;
import com.bookstoreapi.repository.BookRepository;
import org.springframework.test.context.ActiveProfiles;

@ActiveProfiles("test")
@DataJpaTest
public class BookRepositoryTest {

    @Autowired
    BookRepository repo;

    @Test
    void saveAndFind() {

        Book b = new Book(
                null,
                "Title",
                null,
                "Description",
                "Fiction",
                "2026"
        );

        Book saved = repo.save(b);

        var found = repo.findById(saved.getId());

        assertThat(found).isPresent();
        assertThat(found.get().getTitle()).isEqualTo("Title");
    }
}