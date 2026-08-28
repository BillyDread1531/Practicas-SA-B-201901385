import json
import os
import time

import pika
from sqlalchemy import text

from .database import SessionLocal


QUEUE_NAME = os.getenv(
    "RABBITMQ_QUEUE",
    "inscripciones.events"
)


def procesar_mensaje(channel, method, properties, body):
    db = SessionLocal()

    try:
        evento = json.loads(body.decode("utf-8"))

        db.execute(
            text("""
                INSERT INTO eventos_inscripciones
                (
                    inscripcion_id,
                    usuario_id,
                    curso_id,
                    tipo
                )
                VALUES
                (
                    :inscripcion_id,
                    :usuario_id,
                    :curso_id,
                    :tipo
                )
            """),
            {
                "inscripcion_id": evento["inscripcion_id"],
                "usuario_id": evento["usuario_id"],
                "curso_id": evento["curso_id"],
                "tipo": evento["tipo"],
            }
        )

        db.commit()

        print(
            f"Evento procesado: "
            f"{evento['tipo']} "
            f"#{evento['inscripcion_id']}"
        )

        channel.basic_ack(
            delivery_tag=method.delivery_tag
        )

    except Exception as error:
        db.rollback()

        print(
            f"Error procesando mensaje: {error}"
        )

        channel.basic_nack(
            delivery_tag=method.delivery_tag,
            requeue=True
        )

    finally:
        db.close()


def iniciar_consumidor():
    while True:
        try:
            credentials = pika.PlainCredentials(
                os.getenv("RABBITMQ_USERNAME"),
                os.getenv("RABBITMQ_PASSWORD")
            )

            parameters = pika.ConnectionParameters(
                host=os.getenv(
                    "RABBITMQ_HOST",
                    "rabbitmq"
                ),
                port=int(
                    os.getenv(
                        "RABBITMQ_PORT",
                        "5672"
                    )
                ),
                credentials=credentials,
                heartbeat=30
            )

            connection = pika.BlockingConnection(
                parameters
            )

            channel = connection.channel()

            channel.queue_declare(
                queue=QUEUE_NAME,
                durable=True
            )

            channel.basic_qos(
                prefetch_count=1
            )

            channel.basic_consume(
                queue=QUEUE_NAME,
                on_message_callback=procesar_mensaje,
                auto_ack=False
            )

            print(
                f"Esperando mensajes en {QUEUE_NAME}"
            )

            channel.start_consuming()

        except Exception as error:
            print(
                f"RabbitMQ no disponible: {error}"
            )

            time.sleep(5)


if __name__ == "__main__":
    iniciar_consumidor()