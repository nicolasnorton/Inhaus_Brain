# Video Production Master Prompt

## English
### Description
Master prompt for generating high-quality video content using Veo. Distinguishes between fast prototyping and cinematic final rendering.

### Prompt Structure
[Subject] performing [Action] in [Style]. Duration: [Duration]. Resolution: [Resolution]. Cultural Context: [Cultural Notes].

### Modes

#### 1. Prototype / Preview (Fast)
**Model**: veo-3.0-fast
**Focus**: Composition, movement check, quick turnaround.
**Template**: 
"Create a quick [Style] preview of [Subject] [Action]. Duration: Short (~5s). Quality: Draft. Cultural: Ecuador/LatAm neutral."

#### 2. Final Render (High Quality)
**Model**: veo-3.1 (or latest flagship)
**Focus**: Photorealism, lighting, textures, cinematic fidelity.
**Template**: 
"Cinematic [Style] shot of [Subject] [Action]. Lighting: Professional studio/natural. Resolution: 4K. Duration: [Duration]. Cultural: Authentically Ecuador/LatAm friendly, safe, and respectful."

### Cultural & Linguistic Guidelines
- **Geography**: Neutral or recognizable Ecuadorian landscapes (Andes, Coast, Amazon) if context implies location.
- **People**: Diverse representation, respectful of local indigenous and mestizo cultures.
- **Tone**: Optimistic, warm, family-oriented (where applicable), professional.
- **Captions (Bilingual)**: If subtitles requested, use English and Spanish (Ecuador/LatAm neutral). Format: "Top: English | Bottom: Spanish". Style: Elegant, legible sans-serif.
- **Restrictions**: No violence, no political controversy, no offensive slang or gestures common in other regions.

### Routing Logic
- IF (user_intent == 'explore' OR 'draft' OR 'test') -> USE Preview Mode
- IF (user_intent == 'finalize' OR 'export' OR user_confirmed_high_quality) -> USE Final Render Mode

---

## Español
### Descripción
Prompt maestro para generar contenido de video de alta calidad usando Veo. Distingue entre prototipado rápido y renderizado final cinematográfico.

### Estructura del Prompt
[Sujeto] realizando [Acción] en [Estilo]. Duración: [Duración]. Resolución: [Resolución]. Contexto Cultural: [Notas Culturales].

### Modos

#### 1. Prototipo / Vista Previa (Rápido)
**Modelo**: veo-3.0-fast
**Enfoque**: Composición, chequeo de movimiento, respuesta rápida.
**Plantilla**: 
"Crear una vista previa rápida estilo [Estilo] de [Sujeto] [Acción]. Duración: Corta (~5s). Calidad: Borrador. Cultural: Ecuador/LatAm neutral."

#### 2. Render Final (Alta Calidad)
**Modelo**: veo-3.1 (o último flagship)
**Enfoque**: Fotorealismo, iluminación, texturas, fidelidad cinematográfica.
**Plantilla**: 
"Toma cinematográfica estilo [Estilo] de [Sujeto] [Acción]. Iluminación: Estudio profesional/natural. Resolución: 4K. Duración: [Duración]. Cultural: Auténticamente amigable, seguro y respetuoso para Ecuador/LatAm."

### Guías Culturales y Lingüísticas
- **Geografía**: Paisajes neutrales o reconocibles de Ecuador (Andes, Costa, Amazonía) si el contexto implica ubicación.
- **Gente**: Representación diversa, respetuosa de culturas locales indígenas y mestizas.
- **Tono**: Optimista, cálido, orientado a la familia (donde aplique), profesional.
- **Subtítulos (Bilingües)**: Si se solicitan, usar Inglés y Español (Ecuador/LatAm neutral). Formato: "Arriba: Inglés | Abajo: Español". Estilo: Elegante, sans-serif legible.
- **Restricciones**: Sin violencia, sin controversia política, sin jerga ofensiva o gestos comunes en otras regiones.

### Lógica de Enrutamiento
- SI (intención_usuario == 'explorar' O 'borrador' O 'probar') -> USAR Modo Vista Previa
- SI (intención_usuario == 'finalizar' O 'exportar' O usuario_confirmó_alta_calidad) -> USAR Modo Render Final
