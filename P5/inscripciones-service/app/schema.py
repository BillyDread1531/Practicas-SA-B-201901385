import strawberry
from typing import List
from sqlalchemy import text
from .rabbitmq import publicar_evento

from .database import SessionLocal


@strawberry.type
class Inscripcion:
    id: int
    usuario_id: int
    curso_id: int
    estado: str


@strawberry.type
class Query:

    @strawberry.field
    def inscripciones(self) -> List[Inscripcion]:

        db = SessionLocal()

        try:
            resultado = db.execute(
                text("""
                    SELECT
                        id,
                        usuario_id,
                        curso_id,
                        estado
                    FROM inscripciones
                    ORDER BY id
                """)
            )

            filas = resultado.mappings().all()

            return [
                Inscripcion(
                    id=fila["id"],
                    usuario_id=fila["usuario_id"],
                    curso_id=fila["curso_id"],
                    estado=fila["estado"],
                )
                for fila in filas
            ]

        finally:
            db.close()


@strawberry.type
class Mutation:

    @strawberry.mutation
    def crear_inscripcion(
        self,
        usuario_id: int,
        curso_id: int
    ) -> Inscripcion:

        db = SessionLocal()

        try:
            resultado = db.execute(
                text("""
                    INSERT INTO inscripciones
                    (
                        usuario_id,
                        curso_id,
                        estado
                    )
                    VALUES
                    (
                        :usuario_id,
                        :curso_id,
                        'ACTIVA'
                    )
                    RETURNING
                        id,
                        usuario_id,
                        curso_id,
                        estado
                """),
                {
                    "usuario_id": usuario_id,
                    "curso_id": curso_id,
                }
            )

            fila = resultado.mappings().one()

            db.commit()

            publicar_evento({
                "tipo": "inscripcion.creada",
                "inscripcion_id": fila["id"],
                "usuario_id": fila["usuario_id"],
                "curso_id": fila["curso_id"],
                "estado": fila["estado"]
            })

            return Inscripcion(
                id=fila["id"],
                usuario_id=fila["usuario_id"],
                curso_id=fila["curso_id"],
                estado=fila["estado"],
            )

        except Exception:
            db.rollback()
            raise

        finally:
            db.close()


schema = strawberry.Schema(
    query=Query,
    mutation=Mutation
)