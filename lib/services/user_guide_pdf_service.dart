import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Genera un PDF con la guía de uso completa del sistema de reservas.
/// Pensado para que lo lea el dueño del restaurante y lo pueda compartir.
class UserGuidePdfService {
  static Future<void> generateAndOpen() async {
    final pdf = pw.Document(
      title: 'Guía de Uso - Sistema de Reservas',
      author: 'programacionJJ',
    );

    final titleStyle = pw.TextStyle(
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blueGrey900,
    );
    final h1Style = pw.TextStyle(
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blueGrey900,
    );
    final h2Style = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blueGrey800,
    );
    final h3Style = pw.TextStyle(
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blueGrey700,
    );
    final body = const pw.TextStyle(fontSize: 10);
    final bodyBold = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);
    final small = const pw.TextStyle(fontSize: 9, color: PdfColors.grey700);
    final accent = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.teal800,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          padding: const pw.EdgeInsets.only(bottom: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey300, width: 0.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Guía de Uso', style: pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey400)),
              pw.Text('Sistema de Reservas', style: pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey400)),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 8),
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.blueGrey300, width: 0.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('programacionJJ  •  WhatsApp: 3413363551', style: small),
              pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: small),
            ],
          ),
        ),
        build: (context) => [
          // ═══════════════════════════════════════
          // PORTADA
          // ═══════════════════════════════════════
          pw.SizedBox(height: 40),
          pw.Center(child: pw.Text('Guía de Uso', style: titleStyle)),
          pw.SizedBox(height: 8),
          pw.Center(child: pw.Text('Sistema de Reservas para Restaurantes', style: h2Style)),
          pw.SizedBox(height: 20),
          pw.Center(child: pw.Text('Para el restaurante y sus clientes', style: small)),
          pw.SizedBox(height: 30),

          // Índice
          _box(PdfColors.blueGrey50, PdfColors.blueGrey300, [
            pw.Text('Contenido', style: h3Style),
            pw.SizedBox(height: 8),
            _indexItem('PARTE 1: Para el Cliente', 'Cómo hacer una reserva, confirmar, lista de espera'),
            _indexItem('PARTE 2: Para el Administrador', 'Configuración, áreas, horarios, operaciones, reportes, mapa'),
            _indexItem('Flujo completo de una reserva', 'El ciclo de vida desde que se crea hasta que termina'),
            _indexItem('Primeros pasos', 'Setup inicial paso a paso'),
            _indexItem('Preguntas frecuentes', 'Las dudas más comunes'),
          ]),

          pw.SizedBox(height: 40),

          // ═══════════════════════════════════════
          // PARTE 1: CLIENTE
          // ═══════════════════════════════════════
          _partHeader('PARTE 1', 'Para el Cliente'),
          pw.SizedBox(height: 16),

          pw.Text('Cómo hacer una reserva', style: h2Style),
          pw.SizedBox(height: 10),

          _step('1', 'Abrir la app', [
            'Al abrir la app ves la pantalla principal con el logo del restaurante, '
                'la dirección (tocala para abrir Google Maps) y el número de WhatsApp.',
          ], body, bodyBold),
          _step('2', 'Tocar "Hacer una reserva"', [
            'Tocá el botón grande de color turquesa.',
          ], body, bodyBold),
          _step('3', 'Elegir cantidad de personas', [
            'Aparece una grilla con números. Tocá cuántas personas van a ir.',
            'Si son más de las que aparecen, usá el link de WhatsApp para coordinar.',
          ], body, bodyBold),
          _step('4', 'Elegir la fecha', [
            'Aparece un calendario. Los días con una X están cerrados o llenos.',
            'Tocá el día que querés reservar.',
          ], body, bodyBold),
          _step('5', 'Elegir el horario', [
            'Los horarios en verde están disponibles. Los que tienen X no.',
            'Tocá el horario que prefieras.',
          ], body, bodyBold),
          _step('6', 'Completar tus datos', [
            'Nombre (obligatorio), Teléfono (obligatorio), Email y Comentarios (opcionales).',
            'Tocá "Confirmar Reserva".',
          ], body, bodyBold),
          _step('7', '¡Listo! Reserva recibida', [
            'Vas a ver un código de confirmación (ej: ABC123). ¡Guardalo!',
            'Lo vas a necesitar para confirmar tu reserva.',
            'Podés enviártelo por WhatsApp con el botón que aparece.',
          ], body, bodyBold),
          pw.SizedBox(height: 16),

          pw.Text('Cómo confirmar tu reserva', style: h2Style),
          pw.SizedBox(height: 8),
          _infoBox('El restaurante te pide que confirmes antes de ir. '
              'Esto es para asegurar que realmente vas a asistir. '
              'Si no confirmás a tiempo, la reserva se cancela automáticamente.', body),
          pw.SizedBox(height: 8),
          _bulletList([
            'Abrí la app y tocá "Tengo un código de reserva"',
            'Escribí el código que te dieron (ej: ABC123)',
            'Tocá "Confirmar" — vas a ver todos los detalles de tu reserva',
            'Tu reserva pasa de "pendiente" a "confirmada"',
          ], body),
          pw.SizedBox(height: 16),

          pw.Text('Lista de espera', style: h2Style),
          pw.SizedBox(height: 8),
          _bulletList([
            'Si el horario está lleno, el sistema te pregunta si querés anotarte en lista de espera.',
            'Si aceptás, quedás anotado con tus datos.',
            'Si alguien cancela, te avisan por WhatsApp.',
          ], body),
          pw.SizedBox(height: 8),
          _tipBox('Llegá 10 minutos antes. Si no llegás a tiempo, el restaurante '
              'puede liberar tu mesa automáticamente.', body),

          pw.SizedBox(height: 30),

          // ═══════════════════════════════════════
          // PARTE 2: ADMINISTRADOR
          // ═══════════════════════════════════════
          _partHeader('PARTE 2', 'Para el Administrador'),
          pw.SizedBox(height: 16),

          pw.Text('Cómo entrar al panel', style: h2Style),
          pw.SizedBox(height: 8),
          _bulletList([
            'Abrí la app y tocá el icono circular arriba a la derecha.',
            'Ingresá el PIN de administrador (por defecto: 1234).',
            'Vas a ver el panel con 6 pestañas.',
          ], body),
          pw.SizedBox(height: 4),
          _warningBox('¡Cambiá el PIN del 1234 por uno propio en la pestaña Config!', bodyBold),
          pw.SizedBox(height: 16),

          // ── CONFIG ──
          _tabHeader('1', 'CONFIGURACIÓN'),
          pw.SizedBox(height: 8),

          pw.Text('Datos del restaurante', style: h3Style),
          pw.SizedBox(height: 4),
          _bulletList([
            'Nombre, subtítulo, slogan — lo que ven los clientes.',
            'Dirección, ciudad, provincia, país — ubicación completa.',
            'Google Maps Query — texto para buscar tu restaurante en Maps.',
            'Email, teléfono, WhatsApp — datos de contacto.',
          ], body),
          pw.SizedBox(height: 8),

          pw.Text('Imágenes del restaurante', style: h3Style),
          pw.SizedBox(height: 4),
          pw.Text('El sistema necesita 3 imágenes para personalizar la app. '
              'Se cargan como dirección web (URL) de la imagen.', style: body),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            headerStyle: bodyBold,
            cellStyle: body,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(5)},
            headers: ['Imagen', 'Para qué se usa'],
            data: [
              ['Logo color', 'Tu logo a color. Aparece en la pantalla principal.'],
              ['Logo blanco', 'Tu logo en blanco. Se usa sobre fondos oscuros.'],
              ['Fondo', 'Foto de fondo de la pantalla principal (tu restaurante, un plato, etc.).'],
            ],
          ),
          pw.SizedBox(height: 6),
          _infoBox(
            '¿Qué es una URL de imagen?\n\n'
            'Es la dirección web de una foto. Ejemplo:\n'
            'https://mi-restaurante.com/logo.png\n\n'
            'Cómo conseguirla:\n'
            '1. Si tenés la foto en tu celular, subila a un servicio gratuito como:\n'
            '   • imgbb.com — Subís la foto y te da un link\n'
            '   • postimages.org — Igual, subís y copiás el link\n'
            '   • Google Drive — Subí la foto, compartila como "público" y copiá el link\n\n'
            '2. Si ya tenés página web o Instagram, podés usar el link directo de la imagen\n'
            '   (hacé click derecho en la foto → "Copiar dirección de imagen")\n\n'
            '3. Formatos recomendados: JPG o PNG. Tamaño ideal: menos de 1 MB.',
            body,
          ),
          pw.SizedBox(height: 4),
          _tipBox(
            'JPG es mejor para fotos (pesa menos). PNG es mejor para logos '
            '(mantiene la transparencia). Si no sabés cuál usar, JPG funciona para todo.',
            body,
          ),
          pw.SizedBox(height: 8),

          pw.Text('Colores', style: h3Style),
          pw.SizedBox(height: 4),
          pw.Text('Primario, secundario, terciario y acento. '
              'Definen la apariencia visual de toda la app.', style: body),
          pw.SizedBox(height: 8),

          pw.Text('Reglas operativas', style: h3Style),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            headerStyle: bodyBold,
            cellStyle: body,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(5)},
            headers: ['Campo', 'Qué hace'],
            data: [
              ['Mín personas', 'Mínimo de personas por reserva (ej: 2)'],
              ['Máx personas', 'Máximo de personas por reserva (ej: 15)'],
              ['Anticipo almuerzo', 'Horas antes para reservar almuerzo (ej: 2)'],
              ['Anticipo regular', 'Horas antes para reservar en general (ej: 24)'],
              ['Días adelanto máx', 'Hasta cuántos días en el futuro se puede reservar (ej: 60)'],
              ['Día cerrado', 'Qué día de la semana cierra el restaurante'],
              ['Auto-release (min)', 'Si el cliente no llega en X min, se marca no-show'],
              ['Ventana confirmación', 'Horas que tiene el cliente para confirmar con código'],
              ['Recordatorio antes', 'Horas antes para mostrar recordatorio pendiente'],
            ],
          ),
          pw.SizedBox(height: 10),

          pw.Text('Feature Flags', style: h3Style),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            headerStyle: bodyBold,
            cellStyle: body,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(5)},
            headers: ['Opción', 'Qué hace'],
            data: [
              ['Sistema de mesas', 'Activa mesas con capacidades por tipo'],
              ['Múltiples áreas', 'Permite varias zonas (terraza, salón, etc.)'],
              ['Capacidad compartida', 'Las áreas comparten capacidad entre sí'],
            ],
          ),
          pw.SizedBox(height: 10),

          pw.Text('Asignación de mesas', style: h3Style),
          pw.SizedBox(height: 4),
          _box(PdfColors.green50, PdfColors.green300, [
            pw.Text('Modo relajado (recomendado para empezar)', style: accent),
            pw.SizedBox(height: 2),
            pw.Text('Acepta todas las reservas mientras haya lugar. '
                'No importa si sobra 1 silla en una mesa.', style: body),
          ]),
          pw.SizedBox(height: 4),
          _box(PdfColors.amber50, PdfColors.amber300, [
            pw.Text('Modo estricto', style: pw.TextStyle(
              fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900,
            )),
            pw.SizedBox(height: 2),
            pw.Text('Optimiza mesas para llenar mejor. Puede rechazar reservas si no '
                'las ubica eficientemente. Para restaurantes que se llenan siempre.', style: body),
          ]),
          pw.SizedBox(height: 16),

          // ── ÁREAS ──
          _tabHeader('2', 'ÁREAS'),
          pw.SizedBox(height: 8),
          pw.Text('Un área es una sección del restaurante: salón principal, terraza, '
              'planta alta, barra, patio, etc.', style: body),
          pw.SizedBox(height: 6),
          pw.Text('Cómo crear un área:', style: h3Style),
          pw.SizedBox(height: 4),
          _bulletList([
            'Tocá el botón "+" para agregar.',
            'Nombre interno: corto, sin espacios (ej: "terraza").',
            'Nombre display: lo que ven los clientes (ej: "Terraza").',
            'Capacidad: cuántas personas entran en esa zona.',
          ], body),
          pw.SizedBox(height: 8),

          pw.Text('Mesas dentro de cada área', style: h3Style),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            headerStyle: bodyBold,
            cellStyle: body,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(5)},
            headers: ['Campo', 'Qué significa'],
            data: [
              ['Nombre', 'Cómo la llamás (ej: "Mesa 4 personas")'],
              ['Cap. mínima', 'Mínimo de comensales (ej: 2)'],
              ['Cap. máxima', 'Máximo de comensales (ej: 4 o 5 si cabe uno más apretado)'],
              ['Cantidad', 'Cuántas mesas físicas iguales tenés (ej: 5 mesas de 4)'],
              ['VIP', 'Si es mesa VIP (se muestra dorada en el mapa)'],
              ['Forma', 'Rectangular, circular o cuadrada (para el mapa visual)'],
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text('Ejemplo práctico:', style: h3Style),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            headerStyle: bodyBold,
            cellStyle: body,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            headers: ['Nombre', 'Mín', 'Máx', 'Cantidad', 'VIP'],
            data: [
              ['Mesa 2p', '1', '2', '5', 'No'],
              ['Mesa 4p', '2', '4', '8', 'No'],
              ['Mesa 6p', '4', '6', '2', 'No'],
              ['Mesa VIP 8p', '6', '8', '1', 'Sí'],
            ],
          ),
          pw.SizedBox(height: 4),
          _tipBox('Si en una mesa de 4 sillas pueden sentarse 5 apretados, '
              'poné 5 como máximo. El sistema respeta ese número.', body),
          pw.SizedBox(height: 16),

          // ── HORARIOS ──
          _tabHeader('3', 'HORARIOS'),
          pw.SizedBox(height: 8),
          pw.Text('Cada día puede tener uno o más turnos (almuerzo, cena, etc.).', style: body),
          pw.SizedBox(height: 6),
          _bulletList([
            'Tocá "+" para agregar un horario.',
            'Elegí el día de la semana.',
            'Poné hora de inicio y hora de fin.',
            'Dale un nombre al turno (ej: "Cena").',
            'Podés tener varios turnos el mismo día.',
          ], body),
          pw.SizedBox(height: 4),
          pw.Text('Ejemplo:', style: h3Style),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            headerStyle: bodyBold,
            cellStyle: body,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            headers: ['Día', 'Turno', 'Desde', 'Hasta'],
            data: [
              ['Lunes a Viernes', 'Almuerzo', '12:00', '15:00'],
              ['Lunes a Viernes', 'Cena', '20:00', '23:30'],
              ['Sábado', 'Cena', '20:00', '00:00'],
              ['Domingo', 'Cerrado', '-', '-'],
            ],
          ),
          pw.SizedBox(height: 16),

          // ── OPERACIONES ──
          _tabHeader('4', 'OPERACIONES (el día a día)'),
          pw.SizedBox(height: 8),
          pw.Text('Esta es la pestaña más importante. Acá gestionás las reservas '
              'en tiempo real.', style: body),
          pw.SizedBox(height: 8),

          pw.Text('Al abrir esta pestaña, el sistema automáticamente:', style: h3Style),
          pw.SizedBox(height: 4),
          _bulletList([
            'Libera reservas vencidas — si el cliente no llegó en los minutos configurados, '
                'se marca como "no-show".',
            'Cancela confirmaciones vencidas — si el cliente no confirmó a tiempo con su código.',
          ], body),
          pw.SizedBox(height: 8),

          pw.Text('Estados de una reserva:', style: h3Style),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            headerStyle: bodyBold,
            cellStyle: body,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(1), 2: const pw.FlexColumnWidth(4)},
            headers: ['Estado', 'Color', 'Significado'],
            data: [
              ['Pendiente confirmación', 'Azul', 'El cliente todavía no confirmó con su código'],
              ['Confirmada', 'Verde', 'Lista para atender'],
              ['En mesa', 'Turquesa', 'El cliente ya está sentado'],
              ['Completada', 'Gris', 'Ya se fue'],
              ['No-show', 'Rojo', 'No vino'],
              ['Cancelada', 'Rojo', 'Se canceló'],
              ['Tarde', 'Ámbar', 'Ya pasó la hora y no llegó'],
            ],
          ),
          pw.SizedBox(height: 8),

          pw.Text('Acciones según el estado:', style: h3Style),
          pw.SizedBox(height: 4),
          _box(PdfColors.blue50, PdfColors.blue200, [
            pw.Text('Si está "Pendiente confirmación":', style: bodyBold),
            pw.SizedBox(height: 2),
            pw.Text('• Confirmar (✓ verde) — el admin confirma manualmente\n'
                '• Cancelar (✗ roja) — cancela la reserva', style: body),
          ]),
          pw.SizedBox(height: 4),
          _box(PdfColors.green50, PdfColors.green200, [
            pw.Text('Si está "Confirmada":', style: bodyBold),
            pw.SizedBox(height: 2),
            pw.Text('• En mesa — marca que el cliente llegó y está sentado\n'
                '• Cancelar — cancela. Si hay lista de espera, te avisa', style: body),
          ]),
          pw.SizedBox(height: 4),
          _box(PdfColors.teal50, PdfColors.teal200, [
            pw.Text('Si está "En mesa":', style: bodyBold),
            pw.SizedBox(height: 2),
            pw.Text('• Completar (✓) — marca que el cliente terminó y se fue', style: body),
          ]),
          pw.SizedBox(height: 8),

          pw.Text('Recordatorios pendientes', style: h3Style),
          pw.SizedBox(height: 4),
          pw.Text('Muestra las reservas confirmadas que están cerca de la hora. '
              'Tocá el botón de WhatsApp para enviarle un recordatorio al cliente.', style: body),
          pw.SizedBox(height: 8),

          pw.Text('Lista de espera', style: h3Style),
          pw.SizedBox(height: 4),
          pw.Text('Muestra las personas anotadas para ese día. '
              'Podés notificarlas por WhatsApp si se libera un lugar, o quitarlas de la lista.', style: body),
          pw.SizedBox(height: 16),

          // ── REPORTES ──
          _tabHeader('5', 'REPORTES'),
          pw.SizedBox(height: 8),
          pw.Text('Elegí un rango de fechas y el sistema calcula todo automáticamente.', style: body),
          pw.SizedBox(height: 8),

          pw.Text('Métricas:', style: h3Style),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            headerStyle: bodyBold,
            cellStyle: body,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(5)},
            headers: ['Métrica', 'Qué te dice'],
            data: [
              ['Total reservas', 'Cuántas reservas hubo en el período'],
              ['Prom. personas', 'Promedio de personas por reserva'],
              ['No-show %', 'Gente que reservó y no vino (si es alto, activá confirmación)'],
              ['Cancelación %', 'Porcentaje de cancelaciones'],
              ['Día top', 'El día de la semana más ocupado'],
              ['Hora top', 'El horario más pedido'],
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text('También muestra gráficos de barras: por día, por horario, '
              'por estado y por área.', style: body),
          pw.SizedBox(height: 16),

          // ── MAPA ──
          _tabHeader('6', 'MAPA DE MESAS'),
          pw.SizedBox(height: 8),
          pw.Text('El mapa muestra la distribución física de las mesas. '
              'Tiene dos modos:', style: body),
          pw.SizedBox(height: 8),

          _box(PdfColors.blue50, PdfColors.blue300, [
            pw.Text('Modo Editor', style: pw.TextStyle(
              fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900,
            )),
            pw.SizedBox(height: 4),
            pw.Text('Para acomodar las mesas en su posición real:', style: body),
            pw.SizedBox(height: 2),
            pw.Text('1. Cambiá a modo "Editor"\n'
                '2. Vas a ver todas las mesas como rectángulos\n'
                '3. Arrastrá cada mesa a su posición real\n'
                '4. Podés hacer zoom con los dedos\n'
                '5. Tocá "Guardar" cuando termines', style: body),
            pw.SizedBox(height: 4),
            pw.Text('Si tenés 5 mesas de 4 personas, vas a ver 5 rectángulos '
                'separados (Mesa 4p #1, #2, etc.). Arrastrá cada uno '
                'a donde está la mesa real.', style: small),
          ]),
          pw.SizedBox(height: 8),
          _box(PdfColors.green50, PdfColors.green300, [
            pw.Text('Modo Live (en vivo)', style: pw.TextStyle(
              fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green900,
            )),
            pw.SizedBox(height: 4),
            pw.Text('Para ver en tiempo real qué pasa:', style: body),
            pw.SizedBox(height: 2),
            pw.Text('1. Cambiá a modo "Live"\n'
                '2. Elegí la fecha y hora\n'
                '3. Las mesas cambian de color según su estado', style: body),
          ]),
          pw.SizedBox(height: 8),

          pw.Text('Colores del mapa:', style: h3Style),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            headerStyle: bodyBold,
            cellStyle: body,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            headers: ['Color', 'Significado'],
            data: [
              ['Verde', 'Libre'],
              ['Amarillo', 'Tiene reserva (el cliente todavía no llegó)'],
              ['Rojo', 'Ocupada (el cliente está sentado)'],
              ['Dorado', 'Mesa VIP'],
              ['Gris', 'Bloqueada'],
            ],
          ),
          pw.SizedBox(height: 8),

          pw.Text('Asignación inteligente de mesas', style: h3Style),
          pw.SizedBox(height: 4),
          _infoBox('El sistema asigna las mesas automáticamente de forma óptima:', body),
          pw.SizedBox(height: 4),
          _bulletList([
            'Grupo chico → mesa chica (no desperdicia una mesa de 6 para 2 personas).',
            'Grupo grande → mesa grande.',
            'Si no entra en una sola mesa → junta 2 o más mesas automáticamente '
                '(se muestra en naranja en el mapa).',
            'Asigna primero los grupos grandes (los más difíciles de ubicar).',
          ], body),
          pw.SizedBox(height: 4),
          _tipBox('Tocá una mesa en modo Live para ver: nombre del cliente, '
              'cantidad de personas, hora, si está juntada con otra mesa, '
              'y cuántas sillas libres quedan.', body),

          pw.SizedBox(height: 30),

          // ═══════════════════════════════════════
          // FLUJO COMPLETO
          // ═══════════════════════════════════════
          _partHeader('', 'Flujo completo de una reserva'),
          pw.SizedBox(height: 12),
          pw.Text('Así funciona todo el ciclo de principio a fin:', style: body),
          pw.SizedBox(height: 10),

          _flowStep('1', 'Cliente reserva', 'PENDIENTE CONFIRMACIÓN',
              'El cliente abre la app, elige personas/fecha/hora, pone sus datos.', body, bodyBold, PdfColors.blue700),
          _flowStep('2', 'Cliente confirma', 'CONFIRMADA',
              'Recibe un código por WhatsApp y lo ingresa en la app.', body, bodyBold, PdfColors.green700),
          _flowStep('3', 'Recordatorio', '',
              'Horas antes de la reserva, el admin le manda un recordatorio por WhatsApp.', body, bodyBold, PdfColors.amber700),
          _flowStep('4', 'Cliente llega', 'EN MESA',
              'El admin toca "En mesa". El mapa muestra la mesa en rojo.', body, bodyBold, PdfColors.teal700),
          _flowStep('5', 'Cliente se va', 'COMPLETADA',
              'El admin toca "Completar". La mesa vuelve a verde (libre).', body, bodyBold, PdfColors.grey700),

          pw.SizedBox(height: 12),
          pw.Text('Casos alternativos:', style: h3Style),
          pw.SizedBox(height: 6),
          _box(PdfColors.red50, PdfColors.red200, [
            pw.Text('Si el cliente NO LLEGA', style: pw.TextStyle(
              fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red800,
            )),
            pw.Text('Después de X minutos se marca "No-show" automáticamente. '
                'La mesa se libera sola. Si hay lista de espera, te avisa.', style: body),
          ]),
          pw.SizedBox(height: 4),
          _box(PdfColors.orange50, PdfColors.orange200, [
            pw.Text('Si no confirma a tiempo', style: pw.TextStyle(
              fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800,
            )),
            pw.Text('La reserva se cancela sola después de la ventana de confirmación.', style: body),
          ]),
          pw.SizedBox(height: 4),
          _box(PdfColors.amber50, PdfColors.amber200, [
            pw.Text('Si NO HAY LUGAR', style: pw.TextStyle(
              fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.amber800,
            )),
            pw.Text('Se ofrece lista de espera. Si alguien cancela, '
                'el admin le manda WhatsApp.', style: body),
          ]),

          pw.SizedBox(height: 30),

          // ═══════════════════════════════════════
          // PRIMEROS PASOS
          // ═══════════════════════════════════════
          _partHeader('', 'Primeros pasos (setup inicial)'),
          pw.SizedBox(height: 12),
          pw.Text('Si es la primera vez que usás el sistema:', style: body),
          pw.SizedBox(height: 10),

          _setupStep('1', 'Configuración básica',
              'Entrá al panel (ícono arriba a la derecha, PIN: 1234). '
              'Pestaña Config: llená nombre, dirección, teléfono, WhatsApp. '
              'CAMBIÁ EL PIN. Guardá.', body, bodyBold),
          _setupStep('2', 'Crear áreas',
              'Pestaña Áreas: creá al menos 1 área (ej: "Salón Principal"). '
              'Agregá las mesas con sus capacidades y cantidades.', body, bodyBold),
          _setupStep('3', 'Configurar horarios',
              'Pestaña Horarios: agregá los turnos para cada día. '
              'Ej: Lunes Almuerzo 12:00-15:00, Cena 20:00-23:30.', body, bodyBold),
          _setupStep('4', 'Armar el mapa',
              'Pestaña Mapa → modo Editor. Arrastrá cada mesa a su posición real. '
              'Tocá "Guardar".', body, bodyBold),
          _setupStep('5', 'Probar',
              'Volvé a la pantalla principal. Hacé una reserva de prueba. '
              'Verificá que aparece en Operaciones.', body, bodyBold),
          _setupStep('6', '¡Listo!',
              'Ya podés compartir la app con tus clientes.', body, bodyBold),

          pw.SizedBox(height: 30),

          // ═══════════════════════════════════════
          // FAQ
          // ═══════════════════════════════════════
          _partHeader('', 'Preguntas frecuentes'),
          pw.SizedBox(height: 12),

          _faq('¿Qué pasa si un cliente llega tarde?',
              'El sistema espera los minutos configurados en "auto-release" (por defecto 15). '
              'Si no llega, se marca como no-show y la mesa se libera.', bodyBold, body),
          _faq('¿Puedo confirmar una reserva yo mismo?',
              'Sí. En Operaciones, cada reserva pendiente tiene un botón verde de "Confirmar" '
              'para que el admin confirme manualmente (si el cliente llamó por teléfono).', bodyBold, body),
          _faq('¿Qué es la lista de espera?',
              'Cuando un horario está lleno, el cliente se puede anotar. '
              'Si alguien cancela, vos (el admin) lo notificás por WhatsApp con un toque.', bodyBold, body),
          _faq('¿Puedo funcionar sin sistema de mesas?',
              'Sí. Desactivá "Sistema de mesas" en Config y el sistema solo usa '
              'la capacidad total del área.', bodyBold, body),
          _faq('¿Modo estricto o relajado?',
              'Relajado: acepta todo lo que entra. '
              'Estricto: optimiza mesas, puede rechazar si no ubica eficientemente. '
              'Si recién empezás, usá relajado.', bodyBold, body),
          _faq('¿Cómo sé si mi restaurante se está llenando?',
              'Usá la pestaña Reportes. Mirá "Reservas por horario" para picos '
              'y "No-show %" para saber cuántos no vienen.', bodyBold, body),

          pw.SizedBox(height: 40),

          // Firma
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey50,
              border: pw.Border.all(color: PdfColors.blueGrey300),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('Desarrollado por', style: small),
                pw.SizedBox(height: 4),
                pw.Text('programacionJJ', style: pw.TextStyle(
                  fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800,
                )),
                pw.SizedBox(height: 6),
                pw.Text('WhatsApp: 3413363551', style: body),
              ],
            ),
          ),
        ],
      ),
    );

    final Uint8List bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'guia_uso_sistema_reservas.pdf');
  }

  // ─── Helpers ───

  static pw.Widget _partHeader(String part, String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey800,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (part.isNotEmpty)
            pw.Text(part, style: pw.TextStyle(
              fontSize: 10, color: PdfColors.blueGrey200, fontWeight: pw.FontWeight.bold,
            )),
          pw.Text(title, style: pw.TextStyle(
            fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white,
          )),
        ],
      ),
    );
  }

  static pw.Widget _tabHeader(String number, String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: PdfColors.teal50,
        border: pw.Border.all(color: PdfColors.teal300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 22, height: 22,
            decoration: const pw.BoxDecoration(color: PdfColors.teal700, shape: pw.BoxShape.circle),
            child: pw.Center(child: pw.Text(number, style: pw.TextStyle(
              fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white,
            ))),
          ),
          pw.SizedBox(width: 8),
          pw.Text('Pestaña $number: $title', style: pw.TextStyle(
            fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900,
          )),
        ],
      ),
    );
  }

  static pw.Widget _step(String num, String title, List<String> bullets,
      pw.TextStyle body, pw.TextStyle bold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 20, height: 20,
            decoration: const pw.BoxDecoration(color: PdfColors.teal600, shape: pw.BoxShape.circle),
            child: pw.Center(child: pw.Text(num, style: pw.TextStyle(
              fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white,
            ))),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title, style: bold),
              ...bullets.map((b) => pw.Padding(
                padding: const pw.EdgeInsets.only(top: 1),
                child: pw.Text(b, style: body),
              )),
            ],
          )),
        ],
      ),
    );
  }

  static pw.Widget _bulletList(List<String> items, pw.TextStyle style) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items.map((b) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('•  ', style: style),
            pw.Expanded(child: pw.Text(b, style: style)),
          ],
        ),
      )).toList(),
    );
  }

  static pw.Widget _box(PdfColor bg, PdfColor border, List<pw.Widget> children) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: bg,
        border: pw.Border.all(color: border),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  static pw.Widget _infoBox(String text, pw.TextStyle style) {
    return _box(PdfColors.blue50, PdfColors.blue200, [pw.Text(text, style: style)]);
  }

  static pw.Widget _tipBox(String text, pw.TextStyle style) {
    return _box(PdfColors.green50, PdfColors.green200, [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('TIP:  ', style: pw.TextStyle(
            fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green800,
          )),
          pw.Expanded(child: pw.Text(text, style: style)),
        ],
      ),
    ]);
  }

  static pw.Widget _warningBox(String text, pw.TextStyle style) {
    return _box(PdfColors.red50, PdfColors.red200, [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('⚠  ', style: pw.TextStyle(
            fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red800,
          )),
          pw.Expanded(child: pw.Text(text, style: pw.TextStyle(
            fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red800,
          ))),
        ],
      ),
    ]);
  }

  static pw.Widget _flowStep(String num, String title, String status, String desc,
      pw.TextStyle body, pw.TextStyle bold, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border(left: pw.BorderSide(color: color, width: 3)),
          color: PdfColors.grey50,
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 20, height: 20,
              decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
              child: pw.Center(child: pw.Text(num, style: pw.TextStyle(
                fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white,
              ))),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(children: [
                  pw.Text(title, style: bold),
                  if (status.isNotEmpty) ...[
                    pw.Text('  →  ', style: body),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: pw.BoxDecoration(
                        color: color, borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Text(status, style: pw.TextStyle(
                        fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white,
                      )),
                    ),
                  ],
                ]),
                pw.SizedBox(height: 2),
                pw.Text(desc, style: body),
              ],
            )),
          ],
        ),
      ),
    );
  }

  static pw.Widget _setupStep(String num, String title, String desc,
      pw.TextStyle body, pw.TextStyle bold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 22, height: 22,
            decoration: const pw.BoxDecoration(color: PdfColors.blueGrey700, shape: pw.BoxShape.circle),
            child: pw.Center(child: pw.Text(num, style: pw.TextStyle(
              fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white,
            ))),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title, style: bold),
              pw.Text(desc, style: body),
            ],
          )),
        ],
      ),
    );
  }

  static pw.Widget _faq(String question, String answer,
      pw.TextStyle bold, pw.TextStyle body) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('P: $question', style: bold),
          pw.SizedBox(height: 2),
          pw.Text('R: $answer', style: body),
        ],
      ),
    );
  }

  static pw.Widget _indexItem(String title, String desc) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('•  ', style: const pw.TextStyle(fontSize: 10)),
          pw.Expanded(child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text(desc, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            ],
          )),
        ],
      ),
    );
  }
}
