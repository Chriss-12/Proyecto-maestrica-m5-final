# Instrucciones del proyecto

Este proyecto desarrolla la propuesta de arquitectura de datos para la Clinica del Sur y sus entregables academicos.

## Skills del proyecto

- Para revisar, corregir y estandarizar el documento Word, usar `.agents/skills/estandarizar-docx-clinica/SKILL.md`.
- Para crear o actualizar el sitio web estatico de una sola pagina, usar `.agents/skills/crear-sitio-clinica/SKILL.md`.
- Para crear o actualizar la presentacion final, usar `.agents/skills/crear-presentacion-clinica/SKILL.md`.

## Reglas comunes

- Mantener coherencia entre el caso de negocio, los datos, Amazon RDS, Amazon S3, AWS IAM, los KPI y el OKR.
- No inventar recursos desplegados, URL, resultados, politicas IAM ni evidencia de AWS. Diferenciar claramente propuesta, implementacion y evidencia verificada.
- Nunca guardar credenciales, claves, tokens, identificadores sensibles o contrasenas dentro del repositorio, HTML, JavaScript, presentaciones o capturas publicas.
- La pagina estatica no debe conectarse directamente a Amazon RDS. Si se requiere informacion dinamica, proponer una API segura como capa intermedia y solicitar autorizacion antes de desplegarla.
- Antes de publicar o modificar recursos AWS, mostrar el alcance, verificar la cuenta y region activas, y usar credenciales temporales con los permisos minimos necesarios.
- Preservar los archivos fuente del usuario y colocar nuevos entregables en carpetas claramente nombradas.
