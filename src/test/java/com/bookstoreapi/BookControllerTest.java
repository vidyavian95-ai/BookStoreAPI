package com.bookstoreapi;

import com.bookstoreapi.controller.BookController;
import com.bookstoreapi.entity.Book;
import com.bookstoreapi.service.BookService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

import static java.lang.reflect.Array.get;
import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(BookController.class)
public class BookControllerTest {

    @Autowired
    MockMvc mockMvc;

    @MockBean
    BookService service;

    @Test
    void getBook_returnsJson() throws Exception {
        Book book = new Book();
        book.setId(1L);
        book.setTitle("Title");
        book.setDescription("Demo Description");
        book.setGenre("Technology");
        book.setPublication_date("2026");
    
        given(service.getBookById(1L)).willReturn(book);
    
       /* mockMvc.perform(get("/books/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.title").value("Title"));

        mockMvc.perform(get("/books/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.title").value("Title"));*/
    }
    /*Notes:

@WebMvcTest loads only MVC components.

@MockBean replaces beans in Spring context with mocks.*/
    //Why: test request/response and serialization without starting a server.
}
