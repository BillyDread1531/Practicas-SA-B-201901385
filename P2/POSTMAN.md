# Pruebas para Postman

Este archivo tiene los casos listos para probar el backend de la práctica. La idea es que solo copies los datos en Postman y ejecutes cada request.

## Datos base

- Base URL: `http://localhost:3001`
- Formato: `Content-Type: application/json`
- Cookie usada en login: `token`

## Orden recomendado

1. Probar `GET /health`
2. Registrar un usuario con `POST /register`
3. Hacer login con `POST /login`
4. Probar `GET /me`
5. Probar `GET /admin-only`
6. Probar `GET /dashboard`
7. Probar el servicio de autorización con `POST /authorize`

---

## 1) Health

### Request

- Método: `GET`
- URL: `http://localhost:3001/health`

### Esperado

- Código: `200`
- Respuesta parecida a:

```json
{
  "ok": true,
  "service": "auth-service"
}
```

---

## 2) Registro

### Request

- Método: `POST`
- URL: `http://localhost:3001/register`
- Body: `raw` / `JSON`

### Body para Cliente

```json
{
  "name": "Juan Perez",
  "email": "juan@example.com",
  "password": "123456",
  "role": "Cliente"
}
```

### Body para Admin

```json
{
  "name": "Admin Uno",
  "email": "admin@example.com",
  "password": "123456",
  "role": "Admin"
}
```

### Credenciales de admin para probar

- Correo: `admin@example.com`
- Contraseña: `123456`

### Esperado

- Código: `201`
- Respuesta parecida a:

```json
{
  "ok": true,
  "message": "Usuario registrado correctamente"
}
```

### Nota

- Si el correo ya existe, puede fallar.
- Si falla, cambia el correo y vuelve a probar.

---

## 3) Login

### Request

- Método: `POST`
- URL: `http://localhost:3001/login`
- Body: `raw` / `JSON`

### Body

```json
{
  "email": "juan@example.com",
  "password": "123456"
}
```

### Esperado

- Código: `200`
- Respuesta parecida a:

```json
{
  "ok": true,
  "message": "Login exitoso"
}
```

### Importante

- El token también se guarda en una cookie HTTP-only.
- En Postman, revisa la pestaña de cookies si quieres ver que sí se guardó.
- El token ya no debe salir en el body de respuesta.

---

## 4) Ruta protegida general

### Request

- Método: `GET`
- URL: `http://localhost:3001/me`

### Esperado

- Código: `200`
- Respuesta parecida a:

```json
{
  "ok": true,
  "user": {
    "id": 1,
    "role": "Cliente"
  }
}
```

### Nota

- Esta ruta necesita la cookie `token`.
- Si no está la cookie, debe responder `401`.

---

## 5) Ruta solo Admin

### Request

- Método: `GET`
- URL: `http://localhost:3001/admin-only`

### Esperado si entra Admin

- Código: `200`
- Respuesta parecida a:

```json
{
  "ok": true,
  "message": "Acceso permitido solo para administradores"
}
```

### Esperado si entra Cliente

- Código: `403`
- Respuesta parecida a:

```json
{
  "ok": false,
  "message": "No autorizado"
}
```

---

## 6) Ruta Admin y Cliente

### Request

- Método: `GET`
- URL: `http://localhost:3001/dashboard`

### Esperado

- Admin: `200`
- Cliente: `200`

### Respuesta parecida

```json
{
  "ok": true,
  "message": "Acceso permitido para admin y cliente"
}
```

### Si no te funciona

- Primero haz `POST /login` y luego prueba esta ruta en la misma sesión de Postman.
- Revisa que la cookie `token` sí esté guardada en `Cookies` para `localhost`.
- Si no la ves, vuelve a hacer login antes de probar `GET /dashboard`.

---

## 7) Servicio de autorización

### Request

- Método: `POST`
- URL: `http://localhost:3002/authorize`
- Body: `raw` / `JSON`

### Caso Admin

```json
{
  "role": "Admin",
  "requiredRole": "Admin"
}
```

### Caso Cliente

```json
{
  "role": "Cliente",
  "requiredRole": "Cliente"
}
```

### Esperado

- Respuesta parecida a:

```json
{
  "ok": true,
  "allowed": true
}
```

### Nota

- Si mandas un rol que no tiene permiso, debe regresar `allowed: false`.
- Este servicio es el que consulta el backend principal para validar permisos por rol.

---

## Cómo probar bien en Postman

1. Crea una colección nueva.
2. Agrega estas 6 requests en ese orden.
3. En cada request usa `Body > raw > JSON` cuando toque.
4. Activa `cookies` para que Postman guarde el token después del login.
5. Primero prueba con un usuario Cliente y luego con un usuario Admin.

## Casos que debes mostrar en la entrega

- Registro exitoso
- Login exitoso
- Acceso a `/me`
- Admin entrando a `/admin-only`
- Cliente recibiendo `403` en `/admin-only`
- Admin y Cliente entrando a `/dashboard`

## Si algo falla

- Revisa que el backend esté corriendo en `http://localhost:3001`
- Revisa que PostgreSQL esté arriba
- Revisa que el usuario exista en la base de datos
- Revisa que el token esté llegando en la cookie
