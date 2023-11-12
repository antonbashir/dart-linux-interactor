#include "test.h"
#include <stdlib.h>

interactor_native_t* test_interactor_initialize()
{
    interactor_native_t* test_interactor = malloc(sizeof(interactor_native_t));
    int result = interactor_native_initialize_default(test_interactor, 0);
    if (result != 0) return NULL;
    return test_interactor;
}

void test_interactor_process(interactor_native_t* interactor)
{
    if (interactor_native_peek_timeout(interactor) > 0)
    {
        struct io_uring_cqe* cqe;
        unsigned head;
        unsigned count = 0;
        io_uring_for_each_cqe(interactor->ring, head, cqe)
        {
            count++;
            interactor_message_t* message = (interactor_message_t*)cqe->user_data;
            void (*pointer)(interactor_message_t*) = (void (*)(interactor_message_t*))message->method;
            pointer(message);
        }
        io_uring_cq_advance(interactor->ring, count);
    }
}
