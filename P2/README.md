# Práctica 2 - Autenticación y Autorización

## Estructura del proyecto

- `auth-service/`: servicio principal de autenticación y JWT
- `authorization-service/`: microservicio independiente de autorización
- `frontend/`: interfaz simple para registro/login

## Requisitos

- Node.js
- PostgreSQL
- npm

## Arranque rápido

### 1) Auth service
```bash
cd auth-service
npm install
npm run dev
```

### 2) Authorization service
```bash
cd authorization-service
npm install
npm run dev
```

### 3) Frontend
Abre `frontend/index.html` en el navegador.

## Variables de entorno

Se incluyen valores base en los archivos `.env` de cada servicio.

## Nota

Esta es la base inicial del proyecto. A partir de aquí se implementará el registro, login, JWT, cookies HTTP-only, AES y autorización por roles.
