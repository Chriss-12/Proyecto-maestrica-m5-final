---
name: crear-presentacion-clinica
description: Crear o actualizar la presentacion final de la arquitectura de datos de la Clinica del Sur en AWS para una exposicion academica de hasta 15 minutos. Usar para PowerPoint, PPTX, diapositivas o guion de exposicion de este proyecto.
---

# Presentacion de la arquitectura AWS

Crear una presentacion visual, breve y coherente con el documento final y el sitio web. Cuando se genere un archivo de diapositivas, usar la skill de Presentaciones disponible y seguir su flujo de renderizado y verificacion visual.

## Objetivo y audiencia

La presentacion debe permitir que un grupo explique en un maximo de 15 minutos la relacion:

Estrategia del negocio -> Datos -> Arquitectura AWS -> KPI -> OKR -> Toma de decisiones.

No presentar como implementado aquello que solo sea una propuesta.

## Estructura recomendada

Usar aproximadamente 9 a 11 diapositivas:

1. Portada y equipo.
2. Clinica, contexto y problema.
3. Objetivo estrategico y necesidades de informacion.
4. Tipos de datos y modelo de Amazon RDS.
5. Contenido y finalidad de Amazon S3.
6. Roles, permisos y principio de minimo privilegio en AWS IAM.
7. Diagrama integral de arquitectura.
8. Tres KPI con formulas y fuentes.
9. OKR con tres Key Results y forma de medicion.
10. Uso de los datos para decisiones y conclusion.
11. Evidencia del sitio en S3, solo si existe y fue verificada.

Ajustar la cantidad cuando una idea necesite mas espacio; evitar comprimir tablas o diagramas para conservar un numero fijo.

## Reglas de contenido

- Mantener las mismas definiciones, formulas, roles y nombres de componentes que el documento aprobado.
- Corregir la diferencia entre pacientes unicos y cantidad de atenciones.
- No usar un KR de tiempo de espera sin campos que permitan medirlo o sin explicar la ampliacion requerida del modelo.
- Mostrar permisos IAM con lenguaje concreto: recurso, accion y nivel de acceso.
- Explicar que S3 aloja tanto el sitio publico como archivos clinicos privados, pero en ubicaciones separadas y con controles distintos.
- El diagrama debe mostrar usuarios, IAM, RDS, S3 y el consumo analitico de los datos.

## Diseno y exposicion

- Priorizar diagramas, tablas pequenas y mensajes breves sobre parrafos extensos.
- Mantener tipografia legible, contraste alto y jerarquia visual consistente.
- Usar iconografia AWS solo si esta disponible legalmente y no compromete la legibilidad.
- Incluir notas del presentador o un guion breve con reparto aproximado del tiempo.
- Preparar transiciones naturales entre estrategia, datos, arquitectura e indicadores.

## Verificacion

- Renderizar y revisar todas las diapositivas antes de entregar.
- Confirmar que no existan recortes, superposiciones, texto diminuto, marcadores de posicion ni instrucciones internas.
- Verificar que la exposicion completa pueda realizarse en 15 minutos.
- Validar contra la consigna y el documento fuente, sin inventar URL, capturas o resultados de AWS.

