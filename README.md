# Bang-iPhone-iOS-App
1. Is the current method of saving the classifier blocking to the tornado IOLoop? Justify your response.

If the current method of saving the classifier is not being executed in an asynchronous manner, it can indeed block the Tornado IOLoop. When performing a blocking operation within Tornado's main loop, it prevents the loop from doing anything else until the operation is complete. The proper approach in Tornado if we wanted to optimize runtime is to offload blocking operations to a thread pool or to use non-blocking libraries and the await keyword to handle the operation asynchronously. Asynchronous code is more difficult to write in Python than a language like Javascript, but not overwhelmingly so. 

2. Would the models saved on one server be useable by another server if we migrated the saved documents in MongoDB? Justify your response

Yes, the models, if saved using a standardized format, are indeed usable on another server. The method `model.save` is used into a serialized format that is portable and could be used by another server if the saved documents in MongoDB were migrated. The process involves serializing the model into a format that can be stored in MongoDB and then deserialized back into a model object on another server. Any application-level changes necessary to adapt to the new environment would need to be implemented.

