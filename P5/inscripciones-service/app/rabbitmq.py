import json
import os
import pika


def publicar_evento(evento: dict):
    credentials = pika.PlainCredentials(
        os.getenv("RABBITMQ_USERNAME"),
        os.getenv("RABBITMQ_PASSWORD")
    )

    parameters = pika.ConnectionParameters(
        host=os.getenv("RABBITMQ_HOST", "rabbitmq"),
        port=int(os.getenv("RABBITMQ_PORT", "5672")),
        credentials=credentials
    )

    connection = pika.BlockingConnection(parameters)
    channel = connection.channel()

    queue_name = os.getenv(
        "RABBITMQ_QUEUE",
        "inscripciones.events"
    )

    channel.queue_declare(
        queue=queue_name,
        durable=True
    )

    channel.basic_publish(
        exchange="",
        routing_key=queue_name,
        body=json.dumps(evento),
        properties=pika.BasicProperties(
            delivery_mode=2
        )
    )

    connection.close()