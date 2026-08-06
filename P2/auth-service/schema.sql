SELECT 'CREATE DATABASE practica2' WHERE NOT EXISTS (
  SELECT FROM pg_database WHERE datname = 'practica2'
)\gexec

\c practica2

DROP TABLE IF EXISTS usuarios;

CREATE TABLE usuarios (
  id SERIAL PRIMARY KEY,
  nombre TEXT NOT NULL,
  correo TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  rol VARCHAR(20) NOT NULL DEFAULT 'Cliente'
);
