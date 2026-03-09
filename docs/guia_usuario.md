# Guia de Uso - Sistema de Reservas

## Para el Restaurante y sus Clientes

---

# PARTE 1: PARA EL CLIENTE (quien hace la reserva)

---

## Como hacer una reserva

### Paso 1 - Abrir la app

Al abrir la app ves la pantalla principal con:
- El logo y nombre del restaurante
- La direccion (tocala para abrir Google Maps)
- El numero de WhatsApp (tocalo para chatear)
- La capacidad total del restaurante

### Paso 2 - Tocar "Hacer una reserva"

Toca el boton grande de color turquesa que dice **"Hacer una reserva"**.

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
- Los que tienen una X no estan disponibles (ya estan llenos o el restaurante los bloqueo)
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

El restaurante te va a pedir que confirmes tu reserva antes de ir. Esto es para asegurarse de que realmente vas a asistir.

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

1. El sistema te va a preguntar si queres anotarte en la **lista de espera**
2. Si aceptas, te anotamos con tus datos
3. Si alguien cancela y se libera un lugar, **te avisamos por WhatsApp**
4. Vas a ver una pantalla que dice "En Lista de Espera" con tus datos

---

## Consejos para el cliente

- Llega **10 minutos antes** de la hora de tu reserva
- Si no llegas a tiempo, el restaurante puede liberar tu mesa automaticamente
- Si no podes ir, avisa al restaurante por WhatsApp asi liberan el lugar para otra persona
- Guarda siempre tu codigo de confirmacion

---
---

# PARTE 2: PARA EL ADMINISTRADOR DEL RESTAURANTE

---

## Como entrar al panel de administracion

1. Abri la app
2. Toca el **icono circular** arriba a la derecha (es el boton de admin)
3. Ingresa el **PIN de administrador** (por defecto es 1234, cambialo!)
4. Vas a ver el panel con 6 pestanas

---

## Pestana 1: CONFIGURACION

Aca configuras todo lo basico del restaurante.

### Datos del restaurante
- **Nombre**: el nombre que ven los clientes
- **Subtitulo**: una frase corta debajo del nombre
- **Slogan**: aparece en la pantalla principal
- **Direccion, ciudad, provincia, pais**: la ubicacion completa
- **Google Maps Query**: el texto para buscar tu restaurante en Google Maps
- **Email de contacto**: para que te escriban
- **Telefono**: aparece en la app
- **WhatsApp**: el numero con codigo de pais (ej: 5493415551234)
- **Codigo de pais**: el prefijo (ej: 54 para Argentina)

### Imagenes del restaurante

El sistema necesita 3 imagenes para personalizar la app:

| Imagen | Para que se usa |
|--------|----------------|
| Logo color | Tu logo a color. Aparece en la pantalla principal |
| Logo blanco | Tu logo en blanco. Se usa sobre fondos oscuros |
| Fondo | Foto de fondo de la pantalla principal (tu restaurante, un plato, etc.) |

**¿Que es una URL de imagen?**

Es la direccion web de una foto. Ejemplo: `https://mi-restaurante.com/logo.png`

**Como conseguirla:**

1. **Si tenes la foto en tu celular**, subila gratis a uno de estos sitios:
   - **imgbb.com** — Subis la foto y te da un link para copiar
   - **postimages.org** — Igual, subis y copias el link
   - **Google Drive** — Subi la foto, compartila como "publico" y copia el link
2. **Si tenes pagina web o Instagram**, podes usar el link directo de la imagen
   (click derecho en la foto → "Copiar direccion de imagen")

**Formato recomendado:**
- **JPG**: mejor para fotos (del restaurante, platos, fondo). Pesa menos.
- **PNG**: mejor para logos (mantiene la transparencia, sin fondo blanco).
- Si no sabes cual usar, JPG funciona para todo.
- Tamano ideal: menos de 1 MB por imagen.

### Colores
- **Color primario**: el color principal de la app
- **Color secundario**: para acentos
- **Color terciario**: para detalles
- **Color acento**: para botones importantes

### Reglas operativas
- **Min personas**: minimo de personas por reserva (ej: 2)
- **Max personas**: maximo de personas por reserva (ej: 15)
- **Anticipo almuerzo (horas)**: cuantas horas antes se puede reservar para el almuerzo (ej: 2)
- **Anticipo regular (horas)**: cuantas horas antes se puede reservar en general (ej: 24)
- **Dias adelanto maximo**: hasta cuantos dias en el futuro se puede reservar (ej: 60)
- **Dia cerrado**: que dia de la semana esta cerrado el restaurante (Ninguno, Lunes, Martes, etc.)

### Tiempos automaticos
- **Auto-release (min)**: si un cliente no llega en X minutos despues de su hora, la reserva se marca como "no-show" y la mesa se libera automaticamente (ej: 15 minutos)
- **Ventana confirmacion (hs)**: cuantas horas tiene el cliente para confirmar su reserva con el codigo (ej: 2 horas). Si no confirma, se cancela sola.
- **Recordatorio antes (hs)**: cuantas horas antes de la reserva se muestra el recordatorio pendiente para enviar por WhatsApp (ej: 24 horas)

### Feature Flags (opciones del sistema)
- **Sistema de mesas**: activa el sistema de mesas con capacidades por tipo de mesa. Si esta apagado, solo se usa la capacidad total del area.
- **Multiples areas**: activa la posibilidad de tener varias areas (ej: planta alta, terraza, salon principal)
- **Capacidad compartida**: si esta activado, las areas comparten capacidad entre si

### Asignacion de mesas
- **Modo relajado** (recomendado para empezar): acepta todas las reservas mientras haya lugar. No importa si sobra 1 silla en una mesa.
- **Modo estricto**: optimiza el uso de mesas. Si queda 1 solo lugar libre en una mesa, puede bloquear ese horario para llenar mejor despues. Ideal si el restaurante se llena siempre.

### Seguridad
- **PIN de admin**: cambia el PIN de 4 digitos para entrar al panel (CAMBIALO del 1234 por defecto!)

Despues de cambiar cualquier cosa, toca **"Guardar Configuracion"**.

---

## Pestana 2: AREAS

Aca configuras las zonas del restaurante.

### Que es un area?
Un area es una seccion del restaurante. Ejemplos:
- Salon principal
- Terraza
- Planta alta
- Barra
- Patio

### Como crear un area
1. Toca el boton **"+"** (agregar area)
2. Completa:
   - **Nombre interno**: un nombre corto sin espacios (ej: "terraza", "salon_principal")
   - **Nombre para mostrar**: lo que ven los clientes (ej: "Terraza", "Salon Principal")
   - **Capacidad**: cuantas personas entran en esa area
3. Toca **"Guardar"**

### Mesas dentro de cada area

Debajo de cada area aparece la lista de mesas. Cada mesa tiene:

- **Nombre**: como la llamas (ej: "Mesa 4 personas", "Mesa redonda grande")
- **Capacidad minima**: cuantas personas como minimo (ej: 2)
- **Capacidad maxima**: cuantas personas como maximo (ej: 4). **Ojo**: si en una mesa de 4 sillas pueden sentarse 5 apretados, pone 5 como maximo.
- **Cantidad**: cuantas mesas fisicas de este tipo tenes (ej: si tenes 5 mesas iguales de 4 personas, pone 5)
- **VIP**: si es una mesa VIP (se muestra dorada en el mapa)
- **Bloqueable**: si se puede bloquear/desbloquear desde operaciones
- **Forma**: rectangular, circular o cuadrada (para el mapa visual)

### Ejemplo practico

Si tu restaurante tiene:
- 5 mesas de 2 personas
- 8 mesas de 4 personas
- 2 mesas de 6 personas
- 1 mesa VIP de 8 personas

Creas 4 tipos de mesa:

| Nombre | Min | Max | Cantidad | VIP |
|--------|-----|-----|----------|-----|
| Mesa 2p | 1 | 2 | 5 | No |
| Mesa 4p | 2 | 4 | 8 | No |
| Mesa 6p | 4 | 6 | 2 | No |
| Mesa VIP 8p | 6 | 8 | 1 | Si |

El sistema calcula solo cuantas mesas necesita para cada reserva.

---

## Pestana 3: HORARIOS

Aca configuras los turnos de atencion.

### Como funciona
Cada dia de la semana puede tener uno o mas turnos. Por ejemplo:
- Lunes a viernes: Almuerzo 12:00-15:00, Cena 20:00-23:30
- Sabado: solo Cena 20:00-00:00
- Domingo: cerrado

### Como agregar un turno
1. Toca **"+"** para agregar un horario
2. Selecciona el **dia de la semana**
3. Pone la **hora de inicio** (ej: 20:00)
4. Pone la **hora de fin** (ej: 23:30)
5. Dale un **nombre al turno** (ej: "Cena")
6. Toca **"Guardar"**

### Tips
- Podes tener varios turnos el mismo dia (almuerzo y cena)
- Si un dia esta configurado como "dia cerrado" en la configuracion, no aparece para reservar aunque tenga horarios
- Los horarios se muestran al cliente como slots de tiempo disponibles

---

## Pestana 4: OPERACIONES

Esta es la pestana del dia a dia. Aca gestionas las reservas en tiempo real.

### Al abrir esta pestana
El sistema automaticamente:
- **Libera reservas vencidas**: si un cliente no llego en los minutos configurados (auto-release), la reserva se marca como "no-show"
- **Cancela confirmaciones vencidas**: si un cliente no confirmo con su codigo a tiempo, la reserva se cancela

Arriba aparece un cartel informativo si se hizo alguna accion automatica.

### Selector de fecha
Usa el selector de fecha para ver las reservas de cualquier dia.

### Lista de reservas

Cada reserva aparece como una tarjeta con:
- **Nombre del cliente**
- **Cantidad de personas** y **hora**
- **Area** asignada
- **Estado** (con color):
  - **Pendiente confirmacion** (azul): el cliente todavia no confirmo con su codigo
  - **Confirmada** (verde): lista para atender
  - **En mesa** (turquesa): el cliente ya esta sentado
  - **Completada** (gris): ya se fue
  - **No-show** (rojo): no vino
  - **Cancelada** (rojo oscuro): se cancelo
  - **Tarde** (ambar): la hora ya paso y no llego, muestra cuantos minutos tarde

### Acciones por reserva

Segun el estado, aparecen botones diferentes:

**Si esta "pendiente confirmacion":**
- **Confirmar** (check verde): el admin confirma manualmente (por si el cliente llamo por telefono)
- **Cancelar** (X roja): cancela la reserva

**Si esta "confirmada":**
- **En mesa** (silla): marca que el cliente llego y esta sentado
- **Cancelar** (X): cancela la reserva. Si hay gente en lista de espera para ese horario, te avisa

**Si esta "en mesa":**
- **Completar** (check): marca que el cliente ya termino y se fue

### Seccion de recordatorios

Debajo de las reservas hay una seccion **"Recordatorios Pendientes"**. Muestra las reservas confirmadas que estan dentro de la ventana de recordatorio (ej: faltan menos de 24 horas).

Para cada una podes:
- Tocar el **boton de WhatsApp** para enviarle un recordatorio al cliente

### Seccion de lista de espera

Al final aparece la **"Lista de Espera"** con las personas anotadas para ese dia.

Para cada persona en espera:
- **Notificar**: envia un WhatsApp avisando que se libero un lugar
- **Quitar**: saca a la persona de la lista

---

## Pestana 5: REPORTES

Aca ves estadisticas del restaurante.

### Como usarlo
1. Toca la fecha arriba para elegir el **periodo** que queres ver (ej: ultimo mes, ultima semana)
2. El sistema calcula todo automaticamente

### Que muestra

**Metricas principales:**
- **Total reservas**: cuantas reservas hubo en el periodo
- **Promedio personas**: cuantas personas en promedio por reserva
- **No-show**: porcentaje de gente que reservo y no vino
- **Cancelacion**: porcentaje de cancelaciones
- **Dia top**: el dia de la semana mas ocupado
- **Hora top**: el horario mas pedido

**Graficos:**
- **Reservas por dia**: cuantas reservas tiene cada dia de la semana
- **Reservas por horario**: que horarios son los mas pedidos
- **Por estado**: cuantas confirmadas, canceladas, no-show, etc.
- **Por area**: ocupacion de cada zona del restaurante

### Para que sirve
- Si el no-show es alto (mas del 10%), conviene activar la confirmacion por codigo
- Si un horario tiene muchas reservas, quizas conviene poner mas mesas en esa franja
- Si un area esta siempre vacia, quizas conviene sacarla o reducir su capacidad

---

## Pestana 6: MAPA DE MESAS

El mapa muestra la distribucion fisica de las mesas en el restaurante. Tiene dos modos.

### Modo Editor

Para acomodar las mesas en su posicion real:

1. Cambia a modo **"Editor"** con el boton arriba
2. Vas a ver todas las mesas del area como rectangulos
3. **Arrastra cada mesa** a su posicion real en el plano del restaurante
4. Podes hacer zoom con los dedos (pinch)
5. Cuando termines, toca **"Guardar"**

Cada mesa muestra:
- Su nombre (ej: "Mesa 4p #1", "Mesa 4p #2")
- Su capacidad

**Importante**: si tenes 5 mesas de 4 personas, vas a ver 5 rectangulos separados. Arrastra cada uno a donde esta la mesa real.

### Modo Live (en vivo)

Para ver en tiempo real que pasa con las mesas:

1. Cambia a modo **"Live"**
2. Selecciona la **fecha** y la **hora** que queres ver
3. Las mesas cambian de color segun su estado:
   - **Verde**: libre
   - **Amarillo**: tiene reserva (todavia no llego el cliente)
   - **Rojo**: ocupada (el cliente esta sentado)
   - **Dorado**: mesa VIP
   - **Gris**: bloqueada

4. Si tocas una mesa, ves el detalle:
   - Nombre del cliente asignado
   - Cuantas personas
   - Hora de la reserva
   - Si la mesa esta **juntada con otra** (cuando un grupo grande necesita varias mesas)
   - Cuantas sillas libres quedan

### Como asigna las mesas el sistema (automatico)

El sistema es inteligente y asigna las mesas solo:

1. **Grupo chico → mesa chica**: si vienen 2 personas, les da la mesa mas chica disponible (no desperdicia una mesa de 6)
2. **Grupo grande → mesa grande**: si vienen 6, les da la mesa de 6 si hay
3. **Si no entra en una sola mesa → junta mesas**: si vienen 5 y las mesas son de 4, el sistema junta 2 mesas automaticamente y lo muestra en el mapa
4. **Primero los grupos dificiles**: asigna primero los grupos grandes (que son mas dificiles de ubicar) y despues los chicos

Esto es mejor que una recepcionista porque:
- Nunca desperdicia mesas grandes para grupos chicos
- Siempre encuentra la combinacion optima
- Junta mesas automaticamente cuando hace falta

---

## Flujo completo de una reserva (de principio a fin)

Asi funciona todo el ciclo:

```
1. CLIENTE RESERVA
   El cliente abre la app → elige personas, fecha, hora → pone sus datos
   Estado: PENDIENTE CONFIRMACION

2. CLIENTE CONFIRMA
   El cliente recibe un codigo por WhatsApp → lo ingresa en la app
   Estado: CONFIRMADA
   (Si no confirma a tiempo, se cancela sola)

3. RECORDATORIO
   Horas antes de la reserva, aparece en "Recordatorios Pendientes"
   El admin toca el boton de WhatsApp y le manda un recordatorio

4. CLIENTE LLEGA
   El cliente llega al restaurante → el admin toca "En mesa"
   Estado: EN MESA
   El mapa muestra la mesa en rojo (ocupada)

5. CLIENTE SE VA
   El admin toca "Completar"
   Estado: COMPLETADA
   La mesa vuelve a verde (libre)

--- CASOS ALTERNATIVOS ---

Si el cliente NO LLEGA:
   Despues de X minutos, el sistema marca "No-show" automaticamente
   La mesa se libera sola
   Si hay alguien en lista de espera, aparece la opcion de notificarlo

Si el cliente CANCELA:
   El admin toca "Cancelar"
   Si hay gente en lista de espera para ese horario, el sistema avisa

Si NO HAY LUGAR:
   El cliente ve que no hay disponibilidad
   Se le ofrece anotarse en lista de espera
   Si alguien cancela, el admin le manda WhatsApp desde la lista de espera
```

---

## Primeros pasos (setup inicial)

Si es la primera vez que usas el sistema, segui estos pasos en orden:

### 1. Configuracion basica
- Entra al panel de admin (icono arriba a la derecha, PIN: 1234)
- Pestana **Config**: llena nombre, direccion, telefono, WhatsApp
- **Cambia el PIN** del 1234 a uno propio
- Toca "Guardar Configuracion"

### 2. Crear areas
- Pestana **Areas**: crea al menos 1 area (ej: "Salon Principal")
- Agrega las mesas de esa area con sus capacidades y cantidades

### 3. Configurar horarios
- Pestana **Horarios**: agrega los turnos para cada dia de la semana
- Ejemplo: Lunes Almuerzo 12:00-15:00, Lunes Cena 20:00-23:30

### 4. Armar el mapa
- Pestana **Mapa** → modo Editor
- Arrastra cada mesa a su posicion real
- Toca "Guardar"

### 5. Probar
- Volve a la pantalla principal
- Hace una reserva de prueba para verificar que todo funciona
- Entra al panel de admin → Operaciones y verifica que aparece

### 6. Listo!
Ya podes compartir la app con tus clientes.

---

## Preguntas frecuentes

**P: Que pasa si un cliente llega tarde?**
R: El sistema espera la cantidad de minutos configurada en "auto-release" (por defecto 15 min). Si no llega, se marca como no-show y la mesa se libera.

**P: Puedo confirmar una reserva yo mismo sin que el cliente ponga el codigo?**
R: Si. En la pestana Operaciones, cada reserva pendiente tiene un boton verde de "Confirmar" para que el admin confirme manualmente.

**P: Que pasa si necesito bloquear un horario por evento privado?**
R: Podes bloquear mesas individuales desde el sistema de bloqueos. Las mesas bloqueadas aparecen en gris en el mapa.

**P: Como saber si el restaurante se esta llenando?**
R: Usa la pestana Reportes para ver estadisticas. Mira el grafico "Reservas por horario" para identificar picos.

**P: Que es la lista de espera?**
R: Cuando un horario esta lleno y un cliente quiere reservar, se le ofrece anotarse en la lista de espera. Si alguien cancela, vos (el admin) podes notificarlo por WhatsApp con un toque.

**P: Puedo tener el restaurante sin sistema de mesas?**
R: Si. Desactiva "Sistema de mesas" en Config y el sistema solo usa la capacidad total del area, sin distinguir mesas individuales.

**P: Para que sirve "Modo estricto" vs "Modo relajado"?**
R: En modo relajado, se aceptan todas las reservas mientras haya lugar. En modo estricto, el sistema optimiza el uso de mesas para llenar mejor el restaurante, pero puede rechazar alguna reserva si no la puede ubicar eficientemente. Si recien empezas, usa el modo relajado.

---

*Sistema de Reservas - Guia de uso v1.0*
