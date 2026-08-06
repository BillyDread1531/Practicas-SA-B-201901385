# Orden de trabajo - Práctica 2

## Resumen rápido
- Fecha de entrega: 06/08/2026 para elaboración y 08/08/2026 para calificación.
- Ponderación: 1.5 puntos.
- Meta principal: entregar una práctica funcional, segura y bien documentada.

## Checklist general
- [ ] Crear el repositorio privado con el nombre correcto.
- [ ] Agregar a KevinPozuelos con rol Developer.
- [ ] Implementar la base de datos y el modelo de usuario.
- [ ] Hacer registro y login.
- [ ] Configurar JWT en cookie HTTP-only.
- [ ] Crear el microservicio de autorización.
- [ ] Escribir el README con documentación y diagrama.
- [ ] Subir el enlace a UEDI antes de la fecha límite.

---

## Paso 1 — Preparar todo antes de programar
Lo más práctico para ti es usar:
- Node.js + Express
- PostgreSQL
- GitHub como repositorio privado

Haz esto primero:
1. Crea el repositorio con el nombre: Practicas-SA-<<SECCIÓN>>-<<CARNE>>.
2. Dentro del repo, crea la carpeta P2.
3. Agrega al usuario KevinPozuelos con rol Developer desde el inicio.

> Importante: esto es un requisito de cumplimiento, no lo dejes para el final.

---

## Paso 2 — Base de datos y modelo de usuario
Diseña una tabla de usuarios con estos campos:
- id
- nombre
- correo
- contraseña
- rol (Admin o Cliente)

Recomendaciones:
- La contraseña debe almacenarse hasheada con bcrypt.
- El nombre y el correo deben cifrarse con AES.
- Debes poder desencriptarlos al leerlos.

---

## Paso 3 — Registro y login
Este es el corazón de la práctica.

### Registro
Crea el endpoint POST /register para:
- recibir los datos del usuario,
- encriptar los datos sensibles,
- hashear la contraseña,
- guardar todo en la base de datos.

### Login
Crea el endpoint POST /login para:
- validar correo y contraseña,
- generar un JWT,
- autenticar al usuario correctamente.

### Extra recomendado
Agrega una página o vista de confirmación después de un login exitoso.

---

## Paso 4 — JWT en cookie HTTP-only y renovación
Implementa lo siguiente:
- El JWT debe enviarse en una cookie HTTP-only.
- No lo pongas en localStorage ni en el body visible.
- El tiempo de vida del token debe controlarse con una variable de entorno: JWT_EXPIRATION.
- Crea un middleware que detecte si el token expiró y, si aún está dentro del tiempo de gracia, lo renueve automáticamente.

---

## Paso 5 — Microservicio de autorización por roles
Este punto es el más nuevo y debe hacerse bien.

### Qué debes construir
- Un segundo servicio independiente (puede ser otro proyecto Express en otro puerto).
- Ese servicio debe recibir el token o el rol y responder si el acceso está permitido o no.

### Reglas de acceso
- Ruta 1: solo Admin
- Ruta 2: Admin y Cliente

### Recomendación técnica
El backend principal debe consultar este microservicio con un retry loop y backoff.
Esto significa:
- reintentar varias veces si hay fallo o timeout,
- usar un número máximo de intentos configurable,
- antes de denegar el acceso por error de comunicación.

---

## Paso 6 — Documentación
No dejes esto para el final.

Tu README debe incluir:
- instrucciones para ejecutar el proyecto,
- explicación propia de JWT, AES y cookies HTTP-only,
- ventajas y desventajas de cada tecnología,
- diagrama de secuencia con Mermaid,
- explicación de los 5 principios SOLID con evidencia real del código.

---

## Paso 7 — Revisión final
Antes de entregar, revisa esto:
- el repositorio está bien creado,
- KevinPozuelos tiene acceso,
- todo está subido a UEDI,
- el trabajo es individual,
- el último commit se hizo a tiempo.

---

## En resumen
Si sigues este orden, te será mucho más fácil completar la práctica sin perder tiempo.
Empieza por el repositorio, luego la base de datos, después el registro/login, luego JWT, luego autorización y finalmente la documentación.