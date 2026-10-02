---
name: crear-sitio-clinica
description: Crear o actualizar el sitio web estatico de una sola pagina para presentar la arquitectura de datos de la Clinica del Sur en AWS. Usar cuando se solicite el index, la pagina informativa o su publicacion en Amazon S3.
---

# Sitio web de la Clinica del Sur

Crear una pagina informativa profesional que explique la propuesta academica de forma clara y verificable.

## Coordinacion de agentes

Para una creacion completa, una renovacion visual importante o una revision amplia, leer
[references/agentes-frontend.md](references/agentes-frontend.md). Distribuir el analisis entre los
perfiles de direccion visual, HTML/accesibilidad, CSS responsive y JavaScript/QA cuando el trabajo
paralelo aporte valor. Para cambios pequenos, aplicar directamente las mismas perspectivas sin
delegacion.

Los perfiles especializados no deben editar simultaneamente el `index.html`. El agente principal
conserva la responsabilidad de integrar una unica version, resolver contradicciones y verificarla.

## Entregable

- Producir un unico archivo `index.html` con HTML5 semantico, CSS y JavaScript integrados.
- No usar frameworks, procesos de compilacion ni dependencias externas obligatorias.
- Mantener el sitio funcional al abrirlo localmente y al alojarlo como sitio estatico en Amazon S3.
- Usar diseno responsive, navegacion por secciones, contraste legible, foco visible y controles accesibles por teclado.

## Contenido minimo

La pagina debe cubrir:

1. Descripcion de la Clinica del Sur y el problema de negocio.
2. Tipos de datos relevantes.
3. Separacion entre datos estructurados en Amazon RDS y archivos en Amazon S3.
4. Roles de AWS IAM: Medico, Recepcionista, Administrador TI y Analista de datos.
5. Diagrama comprensible del flujo Usuarios -> IAM -> RDS/S3 -> KPI y decisiones.
6. Tabla con los tres KPI, incluyendo medida, datos, formula y fuente.
7. Un OKR con tres Key Results coherentes con los datos disponibles.
8. Conclusion sobre el apoyo a la toma de decisiones.

## Coherencia tecnica

- Si el KPI se denomina `Pacientes atendidos por mes`, contar pacientes unicos; si cuenta registros de atencion, llamarlo `Atenciones mensuales`.
- No afirmar que se calcula el tiempo de espera si el modelo no registra llegada e inicio efectivo de atencion.
- Explicar que los documentos clinicos de S3 son privados y que solo los roles autorizados pueden consultarlos.
- Separar el contenido del sitio web publico de los archivos medicos privados, idealmente en buckets distintos.
- Nunca incluir credenciales, claves de acceso, contrasenas de base de datos ni llamadas directas desde JavaScript hacia RDS.

## Interaccion

Usar JavaScript solo cuando mejore la comprension, por ejemplo para navegacion, filtros de KPI, detalles expandibles o resaltado del diagrama. La informacion principal debe seguir disponible sin JavaScript.

## Verificacion

- Revisar el archivo en vista de escritorio y movil.
- Confirmar que no hay desbordamientos, enlaces rotos, texto de relleno ni instrucciones internas del equipo.
- Verificar que los nombres de servicios AWS, formulas y relaciones coincidan con el documento final.
- Confirmar que el HTML sea valido, que la consola no muestre errores y que la pagina siga siendo comprensible sin JavaScript.
- Revisar contraste, foco visible, navegacion por teclado y `prefers-reduced-motion`.
- No publicar en AWS hasta que el usuario lo solicite expresamente y autorice la operacion.

## Publicacion en S3

Cuando se autorice la publicacion:

- Usar un perfil o credenciales temporales; no escribirlas en archivos del proyecto.
- Verificar primero identidad, cuenta, region y bucket de destino.
- Mostrar el plan de cambios antes de crear, reemplazar o hacer publico un recurso.
- Aplicar acceso publico solo al bucket o prefijo del sitio. Mantener completamente privados los documentos clinicos.
- Tras publicar, comprobar la URL y conservar evidencia no sensible del resultado.
