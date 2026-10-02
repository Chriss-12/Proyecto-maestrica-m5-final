# Agentes frontend del proyecto

Usar estos perfiles como subtareas coordinadas cuando la creacion o renovacion del sitio sea suficientemente amplia. Cada perfil analiza el mismo contenido aprobado del proyecto, pero no modifica el `index.html` definitivo. El agente principal integra y verifica el resultado.

## direccion-visual-ux

Objetivo: convertir el trabajo academico en una pagina clara, atractiva y profesional.

- Proponer una direccion visual coherente con salud, datos y AWS sin copiar interfaces de terceros.
- Definir jerarquia, ritmo, paleta, tipografia segura, secciones, componentes y comportamiento responsive.
- Favorecer una portada convincente, tarjetas informativas, KPI legibles y un diagrama de arquitectura comprensible.
- Evitar decoracion excesiva, apariencia generica de plantilla, fondos que reduzcan contraste y animaciones distractoras.
- Entregar una especificacion breve con tokens visuales y un esquema de pagina.

## html-accesibilidad

Objetivo: asegurar estructura semantica, contenido completo y uso accesible.

- Revisar encabezados, landmarks, enlaces internos, tablas, listas, botones, textos alternativos y orden de lectura.
- Mantener en el HTML la informacion esencial incluso si JavaScript no se ejecuta.
- Verificar foco visible, etiquetas accesibles y controles utilizables con teclado.
- Contrastar el contenido con negocio, RDS, S3, IAM, KPI y OKR; no inventar despliegues ni resultados.
- Entregar observaciones concretas o un fragmento HTML aislado para que el agente principal lo integre.

## css-responsive

Objetivo: producir un sistema visual moderno, consistente y adaptable.

- Definir variables CSS para colores, espacios, radios, sombras y tipografia.
- Usar Grid y Flexbox con puntos de quiebre guiados por el contenido, no por dispositivos concretos.
- Comprobar que tablas, tarjetas, navegacion y diagramas no desborden en pantallas estrechas.
- Respetar `prefers-reduced-motion`, contraste suficiente y estados `hover`, `focus-visible` y `active`.
- Preferir CSS mantenible y evitar selectores fragiles, valores arbitrarios repetidos o efectos que dificulten la lectura.
- Entregar tokens y reglas CSS aisladas; no sustituir directamente el archivo final.

## javascript-interaccion-qa

Objetivo: añadir interaccion progresiva y comprobar la calidad del sitio terminado.

- Usar JavaScript nativo para navegacion movil, detalles expandibles, filtros, resaltado o mejoras equivalentes.
- Mantener el contenido principal disponible sin JavaScript y evitar dependencias externas innecesarias.
- No incluir credenciales, datos sensibles ni conexiones directas a RDS.
- Revisar consola, enlaces, foco, teclado, tamanos de pantalla, preferencias de movimiento y carga local.
- Entregar codigo modular dentro de un fragmento aislado y una lista de verificaciones con resultados observables.

## Contrato de integracion

El agente principal debe:

1. Resolver contradicciones entre propuestas usando el documento final y las reglas del proyecto como fuente de verdad.
2. Integrar HTML, CSS y JavaScript en un unico `index.html`, salvo que el usuario solicite otra estructura.
3. Abrir o renderizar el sitio y revisarlo en vista amplia y movil.
4. Corregir desbordamientos, texto ilegible, errores de consola y controles inaccesibles antes de entregarlo.
5. Informar que fue implementado y que quedo solo como propuesta; no afirmar publicacion en AWS sin evidencia verificada.
