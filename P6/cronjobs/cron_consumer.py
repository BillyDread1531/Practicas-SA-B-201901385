import json
import os
import time

import pika
import psycopg2


QUEUE_NAME = os.getenv(
    "CRON_QUEUE",
    "cron.resumenes"
)


def procesar(channel, method, properties, body):
    conexion = None

    try:
        evento = json.loads(
            body.decode("utf-8")
        )

        conexion = psycopg2.connect(
            host=os.getenv("DB_HOST"),
            port=os.getenv("DB_PORT"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
            dbname=os.getenv("DB_NAME"),
        )

        cursor = conexion.cursor()

        cursor.execute(
            """
            INSERT INTO cron_resumenes
            (
                hora,
                total_ejecuciones
            )
            VALUES (%s, %s)
            """,
            (
                evento["hora"],
                evento["total_ejecuciones"],
            )
        )

        conexion.commit()

        cursor.close()
        conexion.close()
        conexion = None

        print(
            f"Resumen almacenado: {evento}"
        )

        channel.basic_ack(
            delivery_tag=method.delivery_tag
        )

    except Exception as error:
        if conexion:
            conexion.rollback()
            conexion.close()

        print(
            f"Error procesando resumen: {error}"
        )

        channel.basic_nack(
            delivery_tag=method.delivery_tag,
            requeue=True
        )


def main():
    while True:
        try:
            credentials = pika.PlainCredentials(
                os.getenv("RABBITMQ_USERNAME"),
                os.getenv("RABBITMQ_PASSWORD")
            )

            connection = pika.BlockingConnection(
                pika.ConnectionParameters(
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
                    heartbeat=30,
                )
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
                on_message_callback=procesar,
                auto_ack=False
            )

            print(
                f"Esperando resúmenes en {QUEUE_NAME}"
            )

            channel.start_consuming()

        except Exception as error:
            print(
                f"RabbitMQ no disponible: {error}"
            )

            time.sleep(5)


if __name__ == "__main__":
    main()