from fastapi import FastAPI
from strawberry.fastapi import GraphQLRouter

from .schema import schema

app = FastAPI(
    title="Estudiantes Service",
    version="1.0.0"
)

graphql_app = GraphQLRouter(schema)

app.include_router(
    graphql_app,
    prefix="/graphql"
)

@app.get("/health")
def health():
    return {
        "status": "ok",
        "service": "estudiantes-service"
    }

@app.get("/")
def inicio():
    return {
        "servicio": "estudiantes-service",
        "estado": "funcionando"
    }