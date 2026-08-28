import os
from datetime import datetime
from zoneinfo import ZoneInfo

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

    fecha = datetime.now(
        ZoneInfo("America/Guatemala")
    )

    carnet = os.getenv(
        "STUDENT_CARNET",
        "201901385"
    )

    cursor.execute(
        """
        INSERT INTO cron_ejecuciones
        (
            carnet,
            fecha_hora
        )
        VALUES (%s, %s)
        """,
        (
            carnet,
            fecha.replace(tzinfo=None)
        )
    )

    conexion.commit()

    print(
        f"Ejecucion registrada: "
        f"{carnet} - {fecha.isoformat()}"
    )

    cursor.close()
    conexion.close()


if __name__ == "__main__":
    main()