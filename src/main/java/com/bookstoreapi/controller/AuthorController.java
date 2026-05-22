package com.bookstoreapi.controller;


import com.bookstoreapi.entity.Author;
import com.bookstoreapi.entity.Book;
import com.bookstoreapi.service.AuthorService;
import com.bookstoreapi.service.BookService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import org.springframework.http.MediaType;

@RestController
@RequestMapping("api/author")
public class AuthorController {

    @Autowired
    private AuthorService authorService;

    // ------------------ Create Author with multiple books ------------------
    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<?> createAuthor(@RequestBody Author author){
        try {
            // Ensure each book references this author
            if (author.getBooks() != null) {
                author.getBooks().forEach(book -> book.setAuthor(author));
            }

            Author savedAuthor = authorService.createAuthor(author);
            return new ResponseEntity<>(savedAuthor, HttpStatus.CREATED);
        } catch (Exception e) {
            // Log full error
            e.printStackTrace();
            return new ResponseEntity<>("Error creating author: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // ------------------ Get Author by ID ------------------
    @GetMapping("{id}")
    public ResponseEntity<Author> getAuthorById(@PathVariable Long id){
        Author author = authorService.getAuthorDetailsById(id);
        return new ResponseEntity<>(author, HttpStatus.OK);
    }

    // ------------------ Update Author with multiple books ------------------
    @PutMapping("{id}")
    public ResponseEntity<?> updateAuthor(@PathVariable Long id, @RequestBody Author author){
        try {
            author.setId(id);

            if (author.getBooks() != null) {
                author.getBooks().forEach(book -> book.setAuthor(author));
            }

            Author updatedAuthor = authorService.updateAuthor(author);
            return new ResponseEntity<>(updatedAuthor, HttpStatus.OK);
        } catch (Exception e) {
            e.printStackTrace();
            return new ResponseEntity<>("Error updating author: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // ------------------ Get All Authors ------------------
    @GetMapping("/all")
    public ResponseEntity<List<Author>> getAllAuthors(){
        List<Author> authors = authorService.getAllAuthor();
        return new ResponseEntity<>(authors, HttpStatus.OK);
    }

    @GetMapping("/{id}/books")
    public ResponseEntity<List<Book>> getALlBookDetailsByAuthId(@PathVariable Long id){
        List<Book> bookDetails = authorService.getALlBookDetailsByAuthId(id);
        return new ResponseEntity<>(bookDetails, HttpStatus.OK);
    }
}
