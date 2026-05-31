# Guía de SEO para MiiNegocio

## Descripción
Este documento proporciona instrucciones para optimizar SEO en el proyecto MiiNegocio.

## Estructura de Implementación SEO

### 1. Meta Tags Básicos
Los meta tags están configurados en:
- `app/views/layouts/application.html.erb` - Meta tags principales
- `app/views/shared/_meta.html.erb` - Meta tags adicionales (OG, Twitter Card, Schema)

### 2. Sitemaps
Los sitemaps se generan dinámicamente en:
- `app/controllers/sitemaps_controller.rb` - Controlador
- `app/views/sitemaps/` - Vistas XML
- Accesibles en:
  - `/sitemap.xml` - Índice principal
  - `/sitemaps/pages.xml` - Páginas estáticas
  - `/sitemaps/events.xml` - Eventos
  - `/sitemaps/corps.xml` - Empresas

### 3. Robots.txt
Configurado en `public/robots.txt` con reglas para permitir/bloquear crawling

## Cómo Usar SEO Helper en Vistas

### Establecer Meta Tags en una Vista
```erb
<% set_page_meta(
  title: "Título de la Página",
  description: "Descripción breve para meta description (150-160 caracteres)",
  keywords: "palabra1, palabra2, palabra3",
  image: image_url("image.jpg")
) %>
```

### Ejemplo en Event Show View
```erb
<% set_page_meta(
  title: "#{@event.name} - Reserva tu entrada",
  description: "#{@event.description.truncate(150)}",
  keywords: "eventos, reservas, #{@event.category}",
  image: @event.image_url,
  type: "Event"
) %>
```

### Agregar Breadcrumbs Estructurados
```erb
<% set_breadcrumbs([
  { name: "Inicio", url: root_url },
  { name: "Eventos", url: events_url },
  { name: @event.name, url: event_url(@event) }
]) %>
```


## Structured Data JSON-LD


### Para Productos/Servicios
```erb
<script type="application/ld+json">
  <%= product_schema(@product).html_safe %>
</script>
```

## Recomendaciones Generales de SEO

### URL Amigables
- ✅ Mantener URLs cortas y descriptivas
- ✅ Usar guiones (-) para separar palabras
- ✅ Incluir palabras clave relevantes
- ❌ Evitar caracteres especiales y números innecesarios

### Títulos (Title Tags)
- ✅ 50-60 caracteres
- ✅ Incluir palabra clave principal al inicio
- ✅ Único para cada página

### Descripciones (Meta Description)
- ✅ 150-160 caracteres
- ✅ Llamada a la acción
- ✅ Incluir palabra clave si es posible

### Encabezados (H1, H2, H3)
- ✅ Un H1 por página
- ✅ Jerarquía clara
- ✅ Incluir palabras clave naturalmente

### Imágenes
- ✅ Optimizar tamaño (usar WebP)
- ✅ Añadir alt text descriptivo
- ✅ Nombres de archivo descriptivos

### Enlaces Internos
- ✅ Usar texto descriptivo (anchor text)
- ✅ Enlazar contenido relevante
- ✅ Mantener estructura lógica

## Checklist Antes de Publicar Contenido

- [ ] Meta title única y descriptiva (50-60 caracteres)
- [ ] Meta description (150-160 caracteres)
- [ ] Meta keywords relevantes
- [ ] H1 único y descriptivo
- [ ] Imágenes con alt text
- [ ] Enlaces internos relevantes
- [ ] URL amigable y descriptiva
- [ ] Content original y de valor
- [ ] Mobile-friendly
- [ ] Estructura de datos agregada (cuando sea aplicable)

## Monitoreo de SEO

### Google Search Console
1. Verificar propiedad en: https://search.google.com/search-console
2. Enviar sitemap.xml
3. Monitorear:
   - Páginas indexadas
   - Errores de rastreo
   - URLs removidas
   - Palabras clave

### Google Analytics
1. Configurar en: https://analytics.google.com
2. Monitorear:
   - Tráfico orgánico
   - Palabras clave principales
   - Páginas más visitadas
   - Tasa de rebote

### Herramientas Externas
- [SEMrush](https://www.semrush.com) - Análisis competitivo
- [Ahrefs](https://ahrefs.com) - Backlinks y análisis
- [Screaming Frog](https://www.screamingfrog.co.uk) - Auditoría técnica
- [PageSpeed Insights](https://pagespeed.web.dev) - Velocidad

## Mantenimiento Regular

- [ ] Revisar mensualmente el Console de Google
- [ ] Actualizar meta tags de páginas populares
- [ ] Crear contenido nuevo regularmente
- [ ] Monitorear enlaces rotos
- [ ] Revisar velocidad del sitio
- [ ] Actualizar sitemaps dinámicamente

## Palabras Clave Recomendadas (Ejemplos)

Para mejor SEO, enfocarse en palabras clave como:
- "eventos online"
- "reserva de eventos"
- "plataforma de reservas"
- "gestión de eventos"
- "[región/ciudad] eventos"
