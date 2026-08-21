import strawberry
from typing import List
from sqlalchemy import text

from .database import SessionLocal


@strawberry.type
class Estudiante:
    id: int
    nombre: str
    apellido: str
    email: str
    carnet: str


@strawberry.type
class Query:

    @strawberry.field
    def estudiantes(self) -> List[Estudiante]:
        db = SessionLocal()

        try:
            resultado = db.execute(
                text("""
                    SELECT
                        id,
                        nombre,
                        apellido,
                        email,
                        carnet
                    FROM estudiantes
                    ORDER BY id
                """)
            )

            filas = resultado.mappings().all()

            return [
                Estudiante(
                    id=fila["id"],
                    nombre=fila["nombre"],
                    apellido=fila["apellido"],
                    email=fila["email"],
                    carnet=fila["carnet"],
                )
                for fila in filas
            ]

        finally:
            db.close()


@strawberry.type
class Mutation:

    @strawberry.mutation
    def crear_estudiante(
        self,
        nombre: str,
        apellido: str,
        email: str,
        carnet: str
    ) -> Estudiante:

        db = SessionLocal()

        try:
            resultado = db.execute(
                text("""
                    INSERT INTO estudiantes
                    (
                        nombre,
                        apellido,
                        email,
                        carnet
                    )
                    VALUES
                    (
                        :nombre,
                        :apellido,
                        :email,
                        :carnet
                    )
                    RETURNING
                        id,
                        nombre,
                        apellido,
                        email,
                        carnet
                """),
                {
                    "nombre": nombre,
                    "apellido": apellido,
                    "email": email,
                    "carnet": carnet,
                }
            )

            fila = resultado.mappings().one()

            db.commit()

            return Estudiante(
                id=fila["id"],
                nombre=fila["nombre"],
                apellido=fila["apellido"],
                email=fila["email"],
                carnet=fila["carnet"],
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