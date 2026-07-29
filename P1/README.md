# P1 - Solicitudes Operativas

API REST en JavaScript para gestionar solicitudes operativas con PostgreSQL.

## Por qué PostgreSQL

Elegí PostgreSQL porque encaja mejor con este proyecto que MySQL para esta práctica:

- Tiene validaciones más fuertes en el nivel de base de datos, como `CHECK`, que ayudan a asegurar reglas de negocio.
- Maneja muy bien tipos numéricos y restricciones, útil para `prioridad` y `costo_estimado`.
- Es una opción muy estable para proyectos backend con buenas prácticas y crecimiento futuro.
- Su integración con Node.js mediante `pg` es simple y estándar.

## Estructura inicial

- `src/app.js`: configuración de Express.
- `src/server.js`: arranque del servidor.
- `src/routes/`: rutas HTTP.
- `src/controllers/`: controladores.
- `src/services/`: lógica de negocio.
- `src/repositories/`: acceso a datos.
- `src/config/`: conexión a la base de datos.
- `src/middlewares/`: manejo de errores.
- `src/validators/`: validación de entrada.
- `src/utils/`: utilidades compartidas.
- `db/schema.sql`: tabla base para PostgreSQL.

## Configuración local

1. Crear la base de datos `solicitudes_operativas` en PostgreSQL.
2. Copiar `.env.example` a `.env` y ajustar credenciales.
3. Ejecutar `db/schema.sql` para crear la tabla.
4. Instalar dependencias con `npm install`.
5. Levantar la API con `npm run dev`.

## Estado actual

La estructura base ya está lista y conectada por capas. El siguiente paso será implementar los endpoints CRUD completos y la validación de datos.


Sí. Esto es lo que te pide el proyecto, convertido en una lista práctica de trabajo:

Elegir la tecnología del backend. Puedes usar JavaScript/TypeScript o Python, pero debes decidir una sola ruta y mantenerla.
Crear el repositorio privado con el nombre indicado por la cátedra y trabajar dentro de la carpeta P1.
Configurar la base de datos PostgreSQL, ya sea local, Supabase o NeonDB, y dejarla conectada al proyecto.
Diseñar la estructura del backend con buenas prácticas y separación de responsabilidades.
Implementar la API REST para la entidad “solicitud operativa” con estos 5 endpoints:
obtener todas las solicitudes
registrar una nueva solicitud
actualizar completamente una solicitud
eliminar una solicitud
actualizar solo el estado de una solicitud
Validar los datos de entrada, manejar errores correctamente y evitar vulnerabilidades como inyección SQL.
Aplicar principios SOLID y código limpio en la implementación, no solo en teoría.
Documentar en el README los 5 principios SOLID con tus propias palabras y con evidencia real del código del proyecto.
Registrar al menos 3 prompts de IA usados en el desarrollo, junto con la respuesta obtenida y qué corregiste después.
Entregar esa documentación en un archivo PROMPTS.md o dentro del README.
Agregar al usuario KevinPozuelos con rol Developer en el repositorio o plataforma correspondiente.
Subir el proyecto final al repositorio y luego entregar el enlace en UEDI antes de la fecha límite.
Lo más importante para empezar sería este orden:

definir el stack,
montar la base de datos,
construir los 5 endpoints,
documentar SOLID y prompts,
preparar la entrega final.
Hay una inconsistencia en las fechas del documento, así que conviene confirmar con el auxiliar cuál es la fecha real de entrega. Si quieres, en el siguiente paso te lo puedo convertir en un plan de trabajo por horas o en una checklist técnica para ir marcando avance.