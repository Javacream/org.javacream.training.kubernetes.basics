package org.javacream.training.todo;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
class TodoApplicationTests {
    @Autowired
    TodoRepository repository;

    @Test
    void savesTodo() {
        Todo todo = new Todo();
        todo.setDescription("Test");
        todo.setPriority(1);
        todo.setStatus("OPEN");
        Todo saved = repository.save(todo);
        assertThat(saved.getId()).isNotNull();
        assertThat(repository.findById(saved.getId())).isPresent();
        repository.delete(saved);
    }
}
