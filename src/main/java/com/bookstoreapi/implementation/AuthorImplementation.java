package com.bookstoreapi.implementation;

import com.bookstoreapi.entity.Author;
import com.bookstoreapi.entity.Book;
import com.bookstoreapi.repository.AuthorRepository;
import com.bookstoreapi.repository.BookRepository;
import com.bookstoreapi.service.AuthorService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
public class AuthorImplementation implements AuthorService {

    @Autowired
    private AuthorRepository authorRepository;

    @Autowired
    private BookRepository bookRepository;

    private  final Map<String, List<Book>> BookDetails = new HashMap<>();

    @Override
    public Author createAuthor(Author author){
        return authorRepository.save(author);
    }

    @Override
    public  Author getAuthorDetailsById(Long id){
        Optional<Author> optionalAuthor = authorRepository.findById(id);
        return optionalAuthor.get();
    }


    @Override
    public void deleteAuthor(Long id) {
       authorRepository.deleteById(id);
    }

    @Override
    public List<Author> getAllAuthor(){
        return authorRepository.findAll();
    }

    @Override
    public Author updateAuthor(Author author){
        Author existingAuthor = authorRepository.findById(author.getId()).get();
        existingAuthor.setName(author.getName());
        existingAuthor.setTitle(author.getTitle());
        existingAuthor.setAddress(author.getAddress());
        existingAuthor.setPhoneNo(author.getPhoneNo());
        existingAuthor.setBooks(author.getBooks());
        return authorRepository.save(existingAuthor);
    }

    @Override
    public List<Book> getALlBookDetailsByAuthId(Long authId) {
        return bookRepository.findAll();
    }
}