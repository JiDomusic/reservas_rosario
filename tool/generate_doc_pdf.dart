import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() async {
  final pdf = pw.Document();

  final headerStyle = pw.TextStyle(
    fontSize: 22,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.blueGrey800,
  );

  final h2Style = pw.TextStyle(
    fontSize: 16,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.blueGrey700,
  );

  final h3Style = pw.TextStyle(
    fontSize: 13,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.blueGrey600,
  );

  final bodyStyle = const pw.TextStyle(
    fontSize: 11,
    lineSpacing: 4,
  );

  final smallStyle = pw.TextStyle(
    fontSize: 9,
    color: PdfColors.grey600,
  );

  final codeStyle = pw.TextStyle(
    fontSize: 10,
    font: pw.Font.courier(),
    color: PdfColors.grey800,
  );

  pw.Widget sectionTitle(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 16, bottom: 6),
        child: pw.Text(text, style: h2Style),
      );

  pw.Widget subTitle(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
        child: pw.Text(text, style: h3Style),
      );

  pw.Widget body(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Text(text, style: bodyStyle),
      );

  pw.Widget bullet(String text, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.only(left: 16, bottom: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('•  ', style: bodyStyle),
            pw.Expanded(
              child: pw.Text(text,
                  style: bold
                      ? bodyStyle.copyWith(fontWeight: pw.FontWeight.bold)
                      : bodyStyle),
            ),
          ],
        ),
      );

  pw.Widget divider() => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 8),
        child: pw.Divider(color: PdfColors.blueGrey200, thickness: 0.5),
      );

  // Helper para tabla
  pw.TableRow tableRow(List<String> cells, {bool header = false}) {
    return pw.TableRow(
      decoration: header
          ? const pw.BoxDecoration(color: PdfColors.blueGrey50)
          : null,
      children: cells.map((c) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(c,
              style: header
                  ? pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold)
                  : const pw.TextStyle(fontSize: 10)),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════
  // PÁGINA 1: Portada + Estados
  // ═══════════════════════════════════════════════
  pdf.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(40),
    header: (context) => pw.Column(children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Programación JJ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700)),
          pw.Text('WhatsApp: 3413363551', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ],
      ),
      pw.SizedBox(height: 4),
      pw.Divider(color: PdfColors.blueGrey300, thickness: 0.5),
      pw.SizedBox(height: 8),
    ]),
    footer: (context) => pw.Column(children: [
      pw.Divider(color: PdfColors.blueGrey200, thickness: 0.3),
      pw.SizedBox(height: 4),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Programación JJ — Sistema de Reservas', style: smallStyle),
          pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: smallStyle),
        ],
      ),
    ]),
    build: (context) => [
      // Portada
      pw.SizedBox(height: 40),
      pw.Center(child: pw.Text('Sistema de Reservas', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800))),
      pw.SizedBox(height: 8),
      pw.Center(child: pw.Text('Documentación Técnica', style: pw.TextStyle(fontSize: 16, color: PdfColors.blueGrey500))),
      pw.SizedBox(height: 6),
      pw.Center(child: pw.Text('Programación JJ', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey600))),
      pw.Center(child: pw.Text('WhatsApp: 3413363551', style: pw.TextStyle(fontSize: 12, color: PdfColors.blueGrey400))),
      pw.SizedBox(height: 40),
      pw.Divider(color: PdfColors.blueGrey300),
      pw.SizedBox(height: 20),

      // ESTADOS
      sectionTitle('1. Estados de una Reserva'),
      body('Cada reserva pasa por distintos estados durante su ciclo de vida:'),
      pw.SizedBox(height: 8),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.5),
        children: [
          tableRow(['Color', 'Estado', 'Significado'], header: true),
          tableRow(['Violeta', 'pendiente_confirmacion', 'Recién creada, esperando confirmación del cliente']),
          tableRow(['Azul', 'confirmada', 'El cliente o admin confirmó, se espera que llegue']),
          tableRow(['Verde', 'en_mesa', 'El cliente llegó y está sentado']),
          tableRow(['Teal', 'completada', 'Terminó la comida, mesa liberada']),
          tableRow(['Naranja', 'no_show', 'No vino (automático o manual)']),
          tableRow(['Rojo', 'cancelada', 'Cancelada por cliente, admin o por tiempo expirado']),
        ],
      ),

      divider(),

      // FLUJO COMPLETO
      sectionTitle('2. Flujo Completo de una Reserva'),

      subTitle('Paso 1: Cliente hace la reserva'),
      bullet('Estado inicial: pendiente_confirmacion (violeta)'),
      bullet('Se genera código de 6 caracteres (ej: ABC123)'),
      bullet('Se abre WhatsApp con el mensaje pre-armado para enviar al cliente'),

      subTitle('Paso 2: Ventana de confirmación (2 horas por defecto)'),
      bullet('El cliente tiene 2 horas para confirmar con su código'),
      bullet('Si confirma → pasa a confirmada (azul)'),
      bullet('Si no confirma en 2 horas → pasa automáticamente a cancelada (rojo)'),
      bullet('El admin también puede confirmar manualmente con el botón "Confirmar"'),

      subTitle('Paso 3: Día de la reserva — Auto-release (15 minutos)'),
      bullet('Si el cliente no aparece en 15 minutos después de su hora → se marca como no_show (naranja)'),
      bullet('La mesa se libera automáticamente'),
      bullet('El sistema busca gente en lista de espera para notificar'),

      subTitle('Paso 4: El cliente llega'),
      bullet('Admin toca "Llegó" → cambia a en_mesa (verde)'),
      bullet('Cuando termina → admin toca "Completar" → pasa a completada (teal)'),

      divider(),

      // BOTONES DEL ADMIN
      sectionTitle('3. Botones del Admin en el Dashboard'),

      subTitle('Reserva en Violeta (pendiente_confirmacion)'),
      bullet('Confirmar — confirma manualmente sin esperar al cliente'),
      bullet('Cancelar — cancela la reserva'),

      subTitle('Reserva en Azul (confirmada)'),
      bullet('Llegó — cambia a en_mesa (verde)'),
      bullet('No show — marca como no-show manualmente'),
      bullet('Cancelar — cancela y notifica lista de espera'),

      subTitle('Reserva en Verde (en_mesa)'),
      bullet('Completar — marca como completada'),

      divider(),

      // LÓGICA DE DISPONIBILIDAD
      sectionTitle('4. Lógica de Disponibilidad'),
      body('Se basa en personas por horario por área, no en mesas individuales.'),

      subTitle('Capacidad por Área'),
      bullet('capacidadReal — las personas que realmente entran en el área'),
      bullet('capacidadFrontend — el límite que se muestra al público (puede ser menor para dejar margen)'),

      subTitle('Cómo se calcula'),
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        margin: const pw.EdgeInsets.symmetric(vertical: 8),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('capacidad del área     = 40 personas (capacidadFrontend)', style: codeStyle),
            pw.Text('personas reservadas    = suma de personas en reservas activas', style: codeStyle),
            pw.Text('disponible             = 40 - personas reservadas', style: codeStyle),
          ],
        ),
      ),

      subTitle('Qué cuenta como reserva activa (resta capacidad)'),
      bullet('pendiente_confirmacion (violeta) — SÍ cuenta'),
      bullet('confirmada (azul) — SÍ cuenta'),
      bullet('en_mesa (verde) — SÍ cuenta'),

      subTitle('Qué NO cuenta (libera capacidad)'),
      bullet('cancelada — se libera la capacidad'),
      bullet('no_show — se libera la capacidad'),
      bullet('completada — se libera la capacidad'),

      divider(),

      // EJEMPLO
      sectionTitle('5. Ejemplo Práctico'),
      body('Horario 21:00 — Área con capacidad de 40 personas:'),
      pw.SizedBox(height: 6),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.5),
        children: [
          tableRow(['Reserva', 'Personas', 'Estado', '¿Cuenta?'], header: true),
          tableRow(['Reserva A', '4', 'confirmada', 'Sí']),
          tableRow(['Reserva B', '2', 'pendiente_confirmacion', 'Sí']),
          tableRow(['Reserva C', '6', 'cancelada', 'No']),
          tableRow(['Reserva D', '3', 'en_mesa', 'Sí']),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.green50,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          border: pw.Border.all(color: PdfColors.green200, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Capacidad del área: 40', style: codeStyle),
            pw.Text('Personas reservadas: 4 + 2 + 3 = 9', style: codeStyle),
            pw.Text('Disponible: 40 - 9 = 31', style: codeStyle),
            pw.SizedBox(height: 4),
            pw.Text('Si alguien quiere reservar para 8 personas → PASA (8 ≤ 31)', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
          ],
        ),
      ),

      divider(),

      // VALIDACIONES
      sectionTitle('6. Validaciones Adicionales'),
      body('Antes de confirmar una reserva, el sistema verifica:'),
      pw.SizedBox(height: 4),
      bullet('Día cerrado — si es el día de cierre configurado, no se puede reservar'),
      bullet('Anticipación almuerzo (12:00-15:00) — requiere X horas de anticipación (configurable)'),
      bullet('Anticipación cena/noche — requiere Y horas de anticipación (configurable)'),
      bullet('Mínimo y máximo de personas — entre 2 y 15 por defecto'),
      bullet('Capacidad disponible — que haya lugar suficiente en ese horario'),
      bullet('Sistema de mesas (opcional) — si está activado, busca combinación de mesas que quepa el grupo'),

      divider(),

      // CONFIGURACIÓN
      sectionTitle('7. Configuración del Sistema'),
      pw.SizedBox(height: 6),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.5),
        children: [
          tableRow(['Parámetro', 'Valor por defecto', 'Descripción'], header: true),
          tableRow(['Auto-release', '15 minutos', 'Tiempo de espera antes de marcar no-show']),
          tableRow(['Ventana confirmación', '2 horas', 'Tiempo para confirmar con el código']),
          tableRow(['Recordatorio', '24 horas antes', 'Cuándo aparece el recordatorio pendiente']),
          tableRow(['Mínimo personas', '2', 'Mínimo por reserva']),
          tableRow(['Máximo personas', '15', 'Máximo por reserva']),
          tableRow(['Anticipo almuerzo', '2 horas', 'Anticipación para horarios de almuerzo']),
          tableRow(['Anticipo regular', '24 horas', 'Anticipación para otros horarios']),
          tableRow(['Días adelanto máximo', '60 días', 'Hasta cuántos días en el futuro se puede reservar']),
        ],
      ),
      pw.SizedBox(height: 8),
      body('Todos estos valores se pueden modificar desde el Panel de Administración en la pestaña de Configuración.'),

      divider(),

      // RECORDATORIOS Y WHATSAPP
      sectionTitle('8. Recordatorios y WhatsApp'),
      body('El sistema genera mensajes pre-armados para WhatsApp. El admin los envía manualmente desde el dashboard tocando el botón correspondiente. Se abre WhatsApp con el mensaje listo.'),
      pw.SizedBox(height: 4),
      subTitle('Tipos de mensajes'),
      bullet('Confirmación — se envía cuando se crea la reserva, incluye el código'),
      bullet('Recordatorio — aparece en el dashboard 24 horas antes de la reserva'),
      bullet('Cancelación — se genera cuando se cancela una reserva'),
      bullet('Lista de espera — se notifica cuando se libera un lugar'),

      pw.SizedBox(height: 20),
    ],
  ));

  // Guardar
  final outputDir = Directory('/home/jido/AndroidStudioProjects/reserva_template/docs');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final file = File('${outputDir.path}/sistema_reservas_documentacion.pdf');
  await file.writeAsBytes(await pdf.save());
  print('PDF generado: ${file.path}');
}
