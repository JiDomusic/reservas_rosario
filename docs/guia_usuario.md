# Guia de Uso - Sistema de Reservas JJ

## Industria Nacional - Programacion JJ

---

# PARA EL CLIENTE (quien hace la reserva)

---

## Como hacer una reserva

### Paso 1 - Abrir la app

Al abrir la app ves la pantalla principal con:
- El logo y nombre del restaurante
- La direccion (tocala para abrir Google Maps)
- El numero de WhatsApp (tocalo para chatear)
- La capacidad total del restaurante

### Paso 2 - Tocar "Hacer una reserva"

Toca el boton grande que dice **"Hacer una reserva"**.

### Paso 3 - Elegir cantidad de personas

- Aparece una grilla con numeros
- Toca la cantidad de personas que van a ir
- Si son mas personas que las que aparecen, toca el link de WhatsApp para coordinar

### Paso 4 - Elegir la fecha

- Aparece un calendario
- Los dias con una X o en gris estan cerrados o llenos
- Toca el dia que queres reservar
- No se puede reservar mas alla de cierta cantidad de dias (lo configura el restaurante)

### Paso 5 - Elegir el horario

- Aparecen los horarios disponibles
- Los que estan en verde estan libres
- Los que tienen una X no estan disponibles
- Toca el horario que prefieras

### Paso 6 - Completar tus datos

Llena los campos:
- **Nombre** (obligatorio): tu nombre para la reserva
- **Telefono** (obligatorio): para que el restaurante te contacte
- **Email** (opcional): para recibir confirmacion
- **Comentarios** (opcional): alergias, cumpleanos, silla de bebe, etc.

Toca **"Confirmar Reserva"**.

### Paso 7 - Listo! Reserva recibida

Vas a ver una pantalla con:
- Un codigo de confirmacion (ejemplo: ABC123)
- El resumen de tu reserva (nombre, fecha, hora, personas)
- Un boton para enviarte el codigo por WhatsApp

**IMPORTANTE**: Guarda el codigo! Lo vas a necesitar para confirmar tu reserva.

---

## Como confirmar tu reserva

El restaurante te va a pedir que confirmes tu reserva antes de ir.

1. Abri la app
2. Toca **"Tengo un codigo de reserva"** (esta debajo del boton de reservar)
3. Escribi el codigo que te dieron (ejemplo: ABC123)
4. Toca **"Confirmar"**
5. Si el codigo es correcto, vas a ver todos los detalles de tu reserva
6. Tu reserva pasa de "pendiente" a "confirmada"

**Si no confirmas a tiempo**, la reserva se cancela automaticamente y tu lugar se libera para otra persona.

---

## Lista de espera

Si el horario que querias esta lleno:

1. El sistema te pregunta si queres anotarte en la **lista de espera**
2. Si aceptas, te anotamos con tus datos
3. Si alguien cancela y se libera un lugar, **te avisamos por WhatsApp**

---

## Consejos para el cliente

- Llega **10 minutos antes** de la hora de tu reserva
- Si no llegas a tiempo, el restaurante puede liberar tu mesa automaticamente
- Si no podes ir, avisa al restaurante por WhatsApp asi liberan el lugar para otra persona
- Guarda siempre tu codigo de confirmacion

---
---

# PARA EL ADMINISTRADOR DEL RESTAURANTE

---

## Primeros pasos (setup rapido)

### 1. Contactanos por WhatsApp

Escribinos al **3413363551** y te creamos tu restaurante en el sistema. Te damos:
- Un email de administrador
- Una contraseña temporal
- El link a tu restaurante

### 2. Entrar al panel de admin

1. Abri el link de tu restaurante
2. Toca el **icono circular** arriba a la derecha (es el boton de admin)
3. Ingresa el email y contraseña que te dimos
4. Vas a ver el panel con 6 pestanas

### 3. Personalizar tu restaurante

En la pestana **Config** podes cambiar todo:

**Datos basicos:**
- Nombre, subtitulo, slogan
- Direccion, ciudad, provincia
- WhatsApp, email, telefono

**Imagenes (tu marca):**
- Logo a color
- Logo blanco (para fondos oscuros)
- Foto de fondo (tu local, un plato, etc.)

**Colores:**
- Color primario, secundario, terciario y de acento
- Hacen que la app tenga los colores de tu marca

**Reglas:**
- Minimo y maximo de personas por reserva
- Anticipacion para reservar
- Dia de descanso semanal
- Tiempo de auto-liberacion si no llegan

### 4. Crear areas y mesas

En la pestana **Areas**:
- Crea zonas (Salon, Terraza, Barra, etc.)
- Agrega mesas con capacidades (mesa de 2, de 4, de 6...)
- Indica cuantas mesas de cada tipo tenes

### 5. Configurar horarios

En la pestana **Horarios**:
- Agrega turnos para cada dia (Almuerzo 12:00-15:00, Cena 20:00-23:30)
- Los dias cerrados no aparecen para reservar

### 6. Armar el mapa de mesas

En la pestana **Mapa** → modo Editor:
- Arrastra cada mesa a su posicion real
- Guarda y listo

### 7. Probar!

Volve a la pantalla principal, hace una reserva de prueba y verificala en Operaciones.

---

## El panel de administracion

### Pestana CONFIGURACION

Aca configuras todo lo basico. Despues de cambiar algo, toca **"Guardar Configuracion"**.

**Imagenes del restaurante:**

| Imagen | Para que se usa |
|--------|----------------|
| Logo color | Tu logo a color. Aparece en la pantalla principal |
| Logo blanco | Tu logo en blanco. Se usa sobre fondos oscuros |
| Fondo | Foto de fondo de la pantalla principal |

**Como subir una imagen:**

1. Subi la foto gratis a **imgbb.com** o **postimages.org**
2. Copia el link que te dan
3. Pega el link en el campo correspondiente

**Formato recomendado:**
- **JPG**: para fotos (del local, platos, fondo)
- **PNG**: para logos (mantiene la transparencia)
- Tamano ideal: menos de 1 MB

**Feature Flags (opciones del sistema):**
- **Sistema de mesas**: activa mesas con capacidades individuales
- **Multiples areas**: varias zonas (salon, terraza, etc.)
- **Capacidad compartida**: las areas comparten capacidad entre si
- **Modo estricto vs relajado**: estricto optimiza mesas, relajado acepta todo mientras haya lugar

**Seguridad:**
- Cambia la contraseña desde "Olvide mi contraseña" en el login

---

### Pestana AREAS

Cada area es una zona del restaurante (Salon, Terraza, Barra, Patio...).

**Como crear un area:**
1. Toca **"+"**
2. Pone nombre interno (sin espacios) y nombre para mostrar
3. Pone la capacidad

**Mesas dentro de cada area:**
- Nombre, capacidad minima y maxima, cantidad
- VIP (se muestra dorada en el mapa)
- Forma: rectangular, circular o cuadrada

**Ejemplo:**

| Nombre | Min | Max | Cantidad | VIP |
|--------|-----|-----|----------|-----|
| Mesa 2p | 1 | 2 | 5 | No |
| Mesa 4p | 2 | 4 | 8 | No |
| Mesa 6p | 4 | 6 | 2 | No |
| Mesa VIP 8p | 6 | 8 | 1 | Si |

---

### Pestana HORARIOS

Cada dia puede tener uno o mas turnos. Ejemplo:
- Lunes a viernes: Almuerzo 12:00-15:00, Cena 20:00-23:30
- Sabado: solo Cena 20:00-00:00
- Domingo: cerrado

---

### Pestana OPERACIONES

La pestana del dia a dia. Al abrirla:
- **Libera automaticamente** reservas vencidas (no-show)
- **Cancela** confirmaciones que no llegaron a tiempo

**Estados de reserva:**
- **Pendiente** (azul): esperando confirmacion con codigo
- **Confirmada** (verde): lista para atender
- **En mesa** (turquesa): cliente sentado
- **Completada** (gris): ya se fue
- **No-show** (rojo): no vino
- **Cancelada** (rojo oscuro): se cancelo
- **Tarde** (ambar): paso la hora y no llego

**Acciones:**
- Confirmar manualmente (por telefono)
- Marcar "En mesa" cuando llega
- Completar cuando se va
- Cancelar (si hay lista de espera, te avisa)
- Enviar recordatorio por WhatsApp

**Secciones adicionales:**
- Recordatorios pendientes (para enviar por WhatsApp)
- Lista de espera (notificar o quitar personas)

---

### Pestana REPORTES

Estadisticas del restaurante:
- Total reservas en el periodo
- Promedio personas por reserva
- Porcentaje de no-show y cancelaciones
- Dia y horario mas pedidos
- Graficos por dia, horario, estado y area

**Para que sirve:**
- Si el no-show es alto (>10%), activa confirmacion por codigo
- Si un horario tiene muchas reservas, pone mas mesas
- Si un area esta siempre vacia, reducila

---

### Pestana MAPA DE MESAS

**Modo Editor:** arrastra cada mesa a su posicion real y guarda.

**Modo Live (en vivo):**
- Verde: libre
- Amarillo: reservada (no llego)
- Rojo: ocupada
- Dorado: VIP
- Gris: bloqueada

Toca una mesa para ver: cliente, personas, hora, si esta juntada con otra.

**Asignacion inteligente:**
- Grupo chico → mesa chica (no desperdicia)
- Grupo grande → mesa grande o junta varias automaticamente
- Primero ubica los grupos dificiles

---

## Flujo completo de una reserva

```
1. CLIENTE RESERVA → Estado: PENDIENTE

2. CLIENTE CONFIRMA (con codigo) → Estado: CONFIRMADA
   (Si no confirma a tiempo, se cancela sola)

3. RECORDATORIO → Admin envia WhatsApp

4. CLIENTE LLEGA → Admin toca "En mesa" → Estado: EN MESA

5. CLIENTE SE VA → Admin toca "Completar" → Estado: COMPLETADA

--- Si no llega ---
Despues de X minutos → No-show automatico → Mesa libre

--- Si cancela ---
Admin toca Cancelar → Lista de espera notificada
```

---

## Preguntas frecuentes

**P: Que pasa si un cliente llega tarde?**
R: El sistema espera los minutos configurados. Si no llega, marca no-show automaticamente.

**P: Puedo confirmar una reserva yo mismo?**
R: Si. En Operaciones cada reserva pendiente tiene un boton de confirmar manual.

**P: Como bloqueo un horario por evento privado?**
R: Podes bloquear mesas individuales desde el sistema de bloqueos.

**P: Puedo tener el restaurante sin sistema de mesas?**
R: Si. Desactiva "Sistema de mesas" en Config y el sistema usa solo la capacidad total.

**P: Modo estricto vs relajado?**
R: Relajado acepta todo mientras haya lugar. Estricto optimiza mesas pero puede rechazar alguna reserva. Si recien empezas, usa relajado.

---

## Contacto y soporte

**Programacion JJ** - Industria Nacional

WhatsApp: **3413363551**
Sistema: **Reservas-JJ**

Escribinos por WhatsApp para:
- Crear tu restaurante
- Soporte tecnico
- Consultas sobre el sistema

---

*Sistema de Reservas JJ - Guia de uso v2.0*
*Programacion JJ - Industria Nacional*
