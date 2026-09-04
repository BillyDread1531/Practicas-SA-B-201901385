import json
import os

import pika
import psycopg2


def main():
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
        SELECT
            date_trunc('hour', fecha_hora) AS hora,
            COUNT(*) AS total
        FROM cron_ejecuciones
        GROUP BY date_trunc('hour', fecha_hora)
        ORDER BY hora DESC
        LIMIT 1
        """
    )

    fila = cursor.fetchone()

    cursor.close()
    conexion.close()

    if not fila:
        print("No hay ejecuciones para resumir.")
        return

    evento = {
        "tipo": "cron.resumen",
        "hora": fila[0].isoformat(),
        "total_ejecuciones": fila[1],
    }

    credentials = pika.PlainCredentials(
        os.getenv("RABBITMQ_USERNAME"),
        os.getenv("RABBITMQ_PASSWORD"),
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
        )
    )

    channel = connection.channel()

    queue = os.getenv(
        "CRON_QUEUE",
        "cron.resumenes"
    )

    channel.queue_declare(
        queue=queue,
        durable=True
    )

    channel.basic_publish(
        exchange="",
        routing_key=queue,
        body=json.dumps(evento),
        properties=pika.BasicProperties(
            delivery_mode=2
        ),
    )

    print(f"Resumen publicado: {evento}")

    connection.close()


if __name__ == "__main__":
    main()