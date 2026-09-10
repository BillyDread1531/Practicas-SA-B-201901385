import unittest
import subprocess
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
P5 = ROOT / "P5"

NODE_SERVICES = [
    "auth-service",
    "cursos-service",
    "gateway",
]

PYTHON_SERVICES = [
    "estudiantes-service",
    "inscripciones-service",
]

DOCKER_SERVICES = [
    "auth-service",
    "cursos-service",
    "estudiantes-service",
    "inscripciones-service",
    "gateway",
    "cronjobs",
]


class TestServicios(unittest.TestCase):

    def test_dockerfiles_existen(self):
        for servicio in DOCKER_SERVICES:
            dockerfile = P5 / servicio / "Dockerfile"
            self.assertTrue(
                dockerfile.exists(),
                f"Falta Dockerfile en {servicio}"
            )

    def test_package_json_node(self):
        for servicio in NODE_SERVICES:
            package_file = P5 / servicio / "package.json"

            self.assertTrue(
                package_file.exists(),
                f"Falta package.json en {servicio}"
            )

            with open(package_file, encoding="utf-8") as archivo:
                package = json.load(archivo)

            self.assertIn("scripts", package)
            self.assertIn(
                "start",
                package["scripts"],
                f"{servicio} no tiene script start"
            )

    def test_sintaxis_javascript(self):
        for servicio in NODE_SERVICES:
            src = P5 / servicio / "src"

            archivos = list(src.rglob("*.js"))

            self.assertGreater(
                len(archivos),
                0,
                f"No se encontraron archivos JS en {servicio}"
            )

            for archivo in archivos:
                resultado = subprocess.run(
                    ["node", "--check", str(archivo)],
                    capture_output=True,
                    text=True
                )

                self.assertEqual(
                    resultado.returncode,
                    0,
                    f"Error de sintaxis en {archivo}: {resultado.stderr}"
                )

    def test_sintaxis_python(self):
        for servicio in PYTHON_SERVICES:
            carpeta = P5 / servicio / "app"

            archivos = list(carpeta.rglob("*.py"))

            self.assertGreater(
                len(archivos),
                0,
                f"No se encontraron archivos Python en {servicio}"
            )

            for archivo in archivos:
                resultado = subprocess.run(
                    ["python", "-m", "py_compile", str(archivo)],
                    capture_output=True,
                    text=True
                )

                self.assertEqual(
                    resultado.returncode,
                    0,
                    f"Error de sintaxis en {archivo}: {resultado.stderr}"
                )

    def test_cronjobs_python(self):
        carpeta = P5 / "cronjobs"

        archivos = list(carpeta.glob("*.py"))

        self.assertGreater(
            len(archivos),
            0,
            "No existen scripts Python de CronJobs"
        )

        for archivo in archivos:
            resultado = subprocess.run(
                ["python", "-m", "py_compile", str(archivo)],
                capture_output=True,
                text=True
            )

            self.assertEqual(
                resultado.returncode,
                0,
                f"Error en CronJob {archivo}: {resultado.stderr}"
            )

    def test_endpoints_health(self):
        servicios = [
            "auth-service",
            "cursos-service",
            "estudiantes-service",
            "inscripciones-service",
            "gateway",
        ]

        for servicio in servicios:
            carpeta = P5 / servicio

            contenido = ""

            for extension in ("*.js", "*.py"):
                for archivo in carpeta.rglob(extension):
                    contenido += archivo.read_text(
                        encoding="utf-8",
                        errors="ignore"
                    )

            self.assertIn(
                "/health",
                contenido,
                f"{servicio} no contiene endpoint /health"
            )


if __name__ == "__main__":
    unittest.main(verbosity=2)
