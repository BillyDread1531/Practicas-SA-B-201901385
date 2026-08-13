# Estrategia de almacenamiento de archivos CSV

## Ubicación
Se utilizará **AWS S3** como servicio de almacenamiento en la nube. La razón principal es su alta disponibilidad, durabilidad y la integración nativa con servicios de AWS para logging y monitoreo.

## Estructura de carpetas
bucket-bancario/
└── lotes/
└── YYYY/
└── MM/
└── DD/
└── lote-{idLote}-{timestamp}.csv


## Política de retención
- Los archivos se conservan por **90 días**.
- Después de 90 días, se mueven a **S3 Glacier** para almacenamiento de largo plazo.
- Los archivos se eliminan definitivamente después de **1 año**.

## Acceso
- Solo el **Servicio de Transacciones** tiene permisos de escritura (put) y lectura (get) sobre el bucket.
- El acceso se controla mediante **IAM roles** y políticas de AWS.

## Seguridad
- Los archivos se cifran en reposo usando **SSE-S3** (Server-Side Encryption).
- El acceso a los archivos se audita mediante **CloudTrail**.