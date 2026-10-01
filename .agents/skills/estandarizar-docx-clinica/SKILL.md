---
name: estandarizar-docx-clinica
description: Revisar, corregir y estandarizar el documento Word de la Clinica del Sur para que tenga un estilo uniforme y coherencia entre negocio, datos, AWS, KPI y OKR. Usar cuando se solicite actualizar, completar, corregir o dar formato al DOCX del proyecto.
---

# Estandarizar el documento de la Clinica del Sur

Actualizar el DOCX como un informe academico cohesivo, conservando la informacion valida y corrigiendo contenido incompleto, contradictorio o repetido. Usar tambien la skill de Documentos disponible para editar, renderizar y verificar el archivo Word.

## Fuentes y alcance

- Leer primero la consigna y la version mas reciente del DOCX.
- Tratar la consigna como fuente de requisitos y el DOCX como trabajo que debe corregirse.
- Preservar nombres de integrantes, datos verificados y evidencia real de AWS.
- No inventar despliegues, URL, politicas IAM, resultados, capturas ni recursos inexistentes.
- Guardar la version actualizada como un archivo nuevo y conservar intacto el original, salvo que el usuario pida expresamente reemplazarlo.

## Coherencia del contenido

Comprobar que el documento siga una cadena logica:

Problema del negocio -> datos necesarios -> almacenamiento RDS/S3 -> acceso IAM -> arquitectura -> KPI -> OKR -> decisiones.

Corregir especialmente:

- Diferenciar pacientes unicos de cantidad de atenciones. Si el KPI se llama `Pacientes atendidos por mes`, usar pacientes unicos; si cuenta registros, llamarlo `Atenciones mensuales`.
- No afirmar que se mide tiempo de espera sin registrar llegada e inicio efectivo de atencion. Agregar los campos requeridos o reemplazar ese Key Result por uno medible con el modelo actual.
- Alinear el objetivo del OKR con sus tres Key Results y con los KPI disponibles.
- Incluir en el modelo las entidades mencionadas como parte del negocio, por ejemplo pagos o historia clinica, o retirar esas menciones si quedan fuera del alcance.
- Explicar como los datos permiten calcular cada KPI y evaluar cada Key Result.
- Diferenciar el sitio web publico en S3 de los documentos clinicos privados.
- Eliminar nombres de responsables, instrucciones internas, notas pendientes y texto de relleno del cuerpo final.

## Estructura minima

Mantener una secuencia clara, adecuada a la consigna:

1. Portada.
2. Descripcion del negocio, problema y objetivo.
3. Tipos de datos y modelo de Amazon RDS.
4. Uso de Amazon S3.
5. Usuarios, roles y permisos de AWS IAM.
6. Diagrama de arquitectura AWS.
7. Tabla de tres KPI.
8. Un OKR con tres Key Results.
9. Relacion entre arquitectura, KPI, OKR y decisiones.
10. Conclusion.

Respetar la extension solicitada de 4 a 6 paginas. La portada cuenta dentro del limite solo si la consigna o el docente asi lo consideran; si no esta definido, informar la interpretacion utilizada.

## Estandar visual

- Usar un unico sistema tipografico profesional y legible.
- Aplicar estilos de Word: `Title` para el titulo y niveles de encabezado consistentes para las secciones.
- Mantener titulos y encabezados en negro, sin lineas decorativas innecesarias.
- Usar margenes, espaciado, sangrias, numeracion y alineacion consistentes.
- Evitar paginas saturadas, parrafos muy extensos y espacios vacios provocados por saltos deficientes.
- Dar a todas las tablas un estilo comun, encabezado distinguible, bordes visibles, anchos adecuados y texto no recortado.
- Mantener tablas y figuras cerca de su explicacion; agregar titulos breves cuando ayuden a identificarlas.
- Usar un diagrama de arquitectura legible que muestre Usuarios -> IAM -> RDS/S3 -> analisis y decisiones.
- Evitar capturas con identificadores de cuenta u otros datos sensibles; ocultarlos cuando no sean necesarios.

## Criterios tecnicos del proyecto

- RDS debe contener los datos estructurados y sus relaciones mediante claves primarias y foraneas.
- S3 debe contener documentos, imagenes, reportes, historicos y el sitio estatico, con separacion clara entre contenido publico y privado.
- IAM debe incluir al menos tres roles con permisos basicos concretos y principio de minimo privilegio.
- Cada KPI debe indicar nombre, que mide, datos necesarios, formula o metodo y fuente dentro de la arquitectura.
- El OKR debe contener un objetivo y tres resultados medibles, con periodo y criterio de exito cuando corresponda.
- La conclusion debe explicar como la arquitectura apoya decisiones; no repetir solamente las secciones anteriores.

## Flujo de edicion

1. Extraer y revisar todo el texto, las tablas, imagenes, secciones y propiedades relevantes.
2. Comparar el contenido con la consigna y registrar faltantes o contradicciones.
3. Corregir primero la estructura y la coherencia; despues normalizar el estilo visual.
4. Mantener formulas, nombres de servicios y relaciones identicos en texto, tablas y diagrama.
5. Renderizar el DOCX completo a imagenes mediante la skill de Documentos.
6. Inspeccionar cada pagina y corregir recortes, superposiciones, fuentes inconsistentes, tablas partidas y saltos deficientes.
7. Repetir el renderizado hasta que el documento sea legible y no tenga defectos visibles.

## Entrega

- Entregar el DOCX actualizado, no los archivos temporales de revision.
- Resumir los cambios de contenido y formato realizados.
- Informar cualquier dato que no haya podido verificarse o que requiera una decision del usuario.
- No declarar el documento listo si faltan el diagrama, la conclusion, la explicacion KPI-OKR o cualquier requisito obligatorio.

