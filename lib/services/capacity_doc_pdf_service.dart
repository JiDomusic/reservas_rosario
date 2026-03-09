import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Genera un PDF documentando el sistema de capacidad de reservas.
class CapacityDocPdfService {
  static Future<void> generateAndOpen() async {
    final pdf = pw.Document(
      title: 'Reservas JJ Rosario - Manual del Sistema',
      author: 'programacionJJ',
    );

    final headerStyle = pw.TextStyle(
      fontSize: 22,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blueGrey900,
    );
    final h2Style = pw.TextStyle(
      fontSize: 16,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blueGrey800,
    );
    final h3Style = pw.TextStyle(
      fontSize: 13,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blueGrey700,
    );
    final bodyStyle = const pw.TextStyle(fontSize: 11);
    final boldBody = pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold);
    final smallStyle = const pw.TextStyle(fontSize: 10, color: PdfColors.grey700);
    final codeStyle = pw.TextStyle(
      fontSize: 10,
      font: pw.Font.courier(),
      color: PdfColors.grey800,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey300, width: 0.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Reservas JJ Rosario', style: pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey400)),
              pw.Text('Sistema de Capacidad', style: pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey400)),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 8),
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.blueGrey300, width: 0.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('programacionJJ  •  WhatsApp: 3413363551', style: smallStyle),
              pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: smallStyle),
            ],
          ),
        ),
        build: (context) => [
          // ─── Título ───
          pw.Center(
            child: pw.Text('Reservas JJ Rosario', style: headerStyle),
          ),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              'Manual del Sistema de Capacidad de Reservas',
              style: smallStyle,
            ),
          ),
          pw.SizedBox(height: 24),

          // ─── Resumen ───
          pw.Text('Resumen General', style: h2Style),
          pw.SizedBox(height: 8),
          pw.Text(
            'El sistema de capacidad controla cuántas reservas se aceptan en el restaurante. '
            'Antes de confirmar cualquier reserva, se ejecutan 3 validaciones en cadena. '
            'Si alguna falla, la reserva se rechaza.',
            style: bodyStyle,
          ),
          pw.SizedBox(height: 8),
          _buildInfoBox(
            'Archivo principal: lib/services/reservation_capacity_service.dart\n'
            'Método clave: checkAvailabilityWithFloorCapacity()',
            codeStyle,
          ),
          pw.SizedBox(height: 20),

          // ─── Modelos ───
          pw.Text('Modelos de Datos', style: h2Style),
          pw.SizedBox(height: 12),

          pw.Text('AreaConfig (Configuración de Área)', style: h3Style),
          pw.SizedBox(height: 6),
          pw.Text(
            'Cada área del restaurante (ej: Planta Baja, Terraza, VIP) se define con estos campos:',
            style: bodyStyle,
          ),
          pw.SizedBox(height: 6),
          _buildFieldTable([
            ['Campo', 'Tipo', 'Descripción'],
            ['nombre', 'String', 'Identificador interno (ej: "planta_baja")'],
            ['nombreDisplay', 'String', 'Nombre visible al cliente (ej: "Planta Baja")'],
            ['capacidadReal', 'int', 'Capacidad física real del área'],
            ['capacidadFrontend', 'int', 'Capacidad que se ofrece online (puede ser menor)'],
            ['horaInicio', 'String?', 'Hora de inicio de operación (ej: "09:00")'],
            ['horaFin', 'String?', 'Hora de fin de operación (ej: "15:00")'],
          ], boldBody, bodyStyle),
          pw.SizedBox(height: 6),
          pw.Text(
            'Nota: capacidadFrontend puede ser menor que capacidadReal para reservar '
            'lugares para walk-ins o eventos especiales.',
            style: smallStyle,
          ),
          pw.SizedBox(height: 14),

          pw.Text('TableDefinition (Definición de Mesa)', style: h3Style),
          pw.SizedBox(height: 6),
          _buildFieldTable([
            ['Campo', 'Tipo', 'Descripción'],
            ['nombre', 'String', 'Nombre de la mesa (ej: "Mesa 1")'],
            ['area', 'String', 'Área a la que pertenece'],
            ['minCapacidad', 'int', 'Mínimo de comensales'],
            ['maxCapacidad', 'int', 'Máximo de comensales'],
            ['cantidad', 'int', 'Cantidad de mesas iguales'],
            ['esVip', 'bool', 'Si es mesa VIP'],
          ], boldBody, bodyStyle),
          pw.SizedBox(height: 24),

          // ─── Las 3 validaciones ───
          pw.Text('Las 3 Validaciones', style: h2Style),
          pw.SizedBox(height: 8),
          pw.Text(
            'Cuando un cliente intenta reservar, el sistema ejecuta estas 3 comprobaciones '
            'en orden. Todas deben pasar para que la reserva sea aceptada.',
            style: bodyStyle,
          ),
          pw.SizedBox(height: 14),

          // Paso 1
          _buildStepBox(
            '1',
            'Validación de Anticipación',
            'canReserveWithAnticipation(hora, fecha)',
            [
              'Verifica que el cliente reserve con suficiente tiempo de anticipación.',
              'Si el horario cae entre 12:00 y 15:00, se considera horario de ALMUERZO '
                  'y se requieren "lunchAdvanceHours" (ej: 2 horas).',
              'Para el resto de horarios, se requieren "regularAdvanceHours" (ej: 24 horas).',
              'También verifica que el día no esté marcado como cerrado (closedDay).',
            ],
            h3Style, bodyStyle, codeStyle,
          ),
          pw.SizedBox(height: 12),

          // Paso 2
          _buildStepBox(
            '2',
            'Capacidad Diaria Total',
            'getDailyOccupancy(fecha) + personas ≤ totalCapacity',
            [
              'Suma todas las personas reservadas en ese día completo.',
              'totalCapacity = suma de capacidadFrontend de todas las áreas.',
              'Si agregar estas personas supera el total diario, se rechaza.',
              'Esto evita sobrecargar el restaurante aunque quede espacio en un slot.',
            ],
            h3Style, bodyStyle, codeStyle,
          ),
          pw.SizedBox(height: 12),

          // Paso 3
          _buildStepBox(
            '3',
            'Capacidad del Slot Horario por Área',
            'getOccupancyForSlot(fecha, hora) + personas ≤ capacidadFrontend',
            [
              'Determina a qué área corresponde la hora usando los rangos horaInicio/horaFin.',
              'Obtiene la capacidadFrontend de esa área específica.',
              'Cuenta cuántas personas ya tienen reserva para ese slot horario.',
              'Si agregar las personas nuevas supera la capacidad del área, se rechaza.',
            ],
            h3Style, bodyStyle, codeStyle,
          ),
          pw.SizedBox(height: 24),

          // ─── Ejemplo ───
          pw.Text('Ejemplo Práctico', style: h2Style),
          pw.SizedBox(height: 10),

          pw.Text('Configuración del restaurante:', style: h3Style),
          pw.SizedBox(height: 6),
          _buildExampleTable(boldBody, bodyStyle),
          pw.SizedBox(height: 6),
          pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(text: 'Capacidad total diaria: ', style: bodyStyle),
                pw.TextSpan(text: '30 + 20 = 50 personas', style: boldBody),
              ],
            ),
          ),
          pw.SizedBox(height: 4),
          pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(text: 'Anticipo almuerzo: ', style: bodyStyle),
                pw.TextSpan(text: '2 horas', style: boldBody),
                pw.TextSpan(text: '  |  Anticipo regular: ', style: bodyStyle),
                pw.TextSpan(text: '24 horas', style: boldBody),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          pw.Text('Solicitud de reserva:', style: h3Style),
          pw.SizedBox(height: 4),
          _buildInfoBox(
            '4 personas  •  Jueves a las 13:00  •  Hora actual: Jueves 10:30',
            boldBody,
          ),
          pw.SizedBox(height: 14),

          // Paso 1 del ejemplo
          _buildExampleStep(
            'Paso 1 — Anticipación',
            PdfColors.green800,
            'PASA',
            [
              '13:00 está entre 12:00-15:00 → es horario de almuerzo',
              'Se requieren 2 horas de anticipo mínimo',
              'Diferencia: 13:00 - 10:30 = 2.5 horas ≥ 2 horas',
            ],
            boldBody, bodyStyle,
          ),
          pw.SizedBox(height: 8),

          // Paso 2 del ejemplo
          _buildExampleStep(
            'Paso 2 — Capacidad diaria',
            PdfColors.green800,
            'PASA',
            [
              'Reservas totales del día: 40 personas',
              '40 + 4 = 44 ≤ 50 (capacidad diaria)',
            ],
            boldBody, bodyStyle,
          ),
          pw.SizedBox(height: 8),

          // Paso 3 del ejemplo
          _buildExampleStep(
            'Paso 3 — Capacidad del slot',
            PdfColors.red800,
            'NO PASA',
            [
              '13:00 → Área: Planta Baja (09:00 a 15:00)',
              'capacidadFrontend de Planta Baja: 30',
              'Reservas existentes a las 13:00: 28 personas',
              '28 + 4 = 32 > 30 → Reserva RECHAZADA',
            ],
            boldBody, bodyStyle,
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              border: pw.Border.all(color: PdfColors.green300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'Si en cambio hubiera solo 24 personas a las 13:00:\n'
              '24 + 4 = 28 ≤ 30 → la reserva sería ACEPTADA.',
              style: bodyStyle,
            ),
          ),
          pw.SizedBox(height: 24),

          // ─── Diagrama de flujo textual ───
          pw.Text('Diagrama de Flujo', style: h2Style),
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              '  Nueva reserva (fecha, hora, personas)\n'
              '          │\n'
              '          ▼\n'
              '  ┌─────────────────────────┐\n'
              '  │ ¿Día cerrado?           │── Sí ──▶ RECHAZADA\n'
              '  └───────────┬─────────────┘\n'
              '              │ No\n'
              '              ▼\n'
              '  ┌─────────────────────────┐\n'
              '  │ ¿Suficiente anticipo?   │── No ──▶ RECHAZADA\n'
              '  └───────────┬─────────────┘\n'
              '              │ Sí\n'
              '              ▼\n'
              '  ┌─────────────────────────┐\n'
              '  │ ¿Capacidad diaria OK?   │── No ──▶ RECHAZADA\n'
              '  │ (total + N ≤ totalCap)  │\n'
              '  └───────────┬─────────────┘\n'
              '              │ Sí\n'
              '              ▼\n'
              '  ┌─────────────────────────┐\n'
              '  │ ¿Capacidad slot OK?     │── No ──▶ RECHAZADA\n'
              '  │ (slot + N ≤ areaCap)    │\n'
              '  └───────────┬─────────────┘\n'
              '              │ Sí\n'
              '              ▼\n'
              '        ✓ ACEPTADA',
              style: codeStyle,
            ),
          ),
          pw.SizedBox(height: 24),

          // ─── Archivos relacionados ───
          pw.Text('Archivos Relacionados', style: h2Style),
          pw.SizedBox(height: 8),
          _buildFileTable(boldBody, bodyStyle),
          pw.SizedBox(height: 40),

          // ─── Firma ───
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
                pw.Text('Desarrollado por', style: smallStyle),
                pw.SizedBox(height: 4),
                pw.Text('programacionJJ', style: pw.TextStyle(
                  fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800,
                )),
                pw.SizedBox(height: 6),
                pw.Text('WhatsApp: 3413363551', style: bodyStyle),
              ],
            ),
          ),
        ],
      ),
    );

    final Uint8List bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'reservas_jj_rosario_manual.pdf');
  }

  // ─── Helpers de construcción ───

  static pw.Widget _buildInfoBox(String text, pw.TextStyle style) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(text, style: style),
    );
  }

  static pw.Widget _buildStepBox(
    String number,
    String title,
    String code,
    List<String> bullets,
    pw.TextStyle h3Style,
    pw.TextStyle bodyStyle,
    pw.TextStyle codeStyle,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blueGrey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 24,
                height: 24,
                decoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey700,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(number, style: pw.TextStyle(
                    fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white,
                  )),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(title, style: h3Style),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: PdfColors.grey100,
            child: pw.Text(code, style: codeStyle),
          ),
          pw.SizedBox(height: 8),
          ...bullets.map((b) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('•  ', style: bodyStyle),
                pw.Expanded(child: pw.Text(b, style: bodyStyle)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  static pw.Widget _buildExampleStep(
    String title,
    PdfColor resultColor,
    String result,
    List<String> details,
    pw.TextStyle boldStyle,
    pw.TextStyle bodyStyle,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(title, style: boldStyle),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: resultColor == PdfColors.green800 ? PdfColors.green100 : PdfColors.red100,
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Text(result, style: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold, color: resultColor,
                )),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          ...details.map((d) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('→  ', style: bodyStyle),
                pw.Expanded(child: pw.Text(d, style: bodyStyle)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  static pw.Widget _buildFieldTable(
    List<List<String>> rows,
    pw.TextStyle headerStyle,
    pw.TextStyle bodyStyle,
  ) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      headerStyle: headerStyle,
      cellStyle: bodyStyle,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(4),
      },
      headers: rows.first,
      data: rows.skip(1).toList(),
    );
  }

  static pw.Widget _buildExampleTable(pw.TextStyle headerStyle, pw.TextStyle bodyStyle) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      headerStyle: headerStyle,
      cellStyle: bodyStyle,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      headers: ['Área', 'capacidadFrontend', 'horaInicio', 'horaFin'],
      data: [
        ['Planta Baja', '30', '09:00', '15:00'],
        ['Terraza', '20', '16:00', '23:00'],
      ],
    );
  }

  static pw.Widget _buildFileTable(pw.TextStyle headerStyle, pw.TextStyle bodyStyle) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      headerStyle: headerStyle,
      cellStyle: bodyStyle,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(4),
      },
      headers: ['Archivo', 'Responsabilidad'],
      data: [
        ['reservation_capacity_service.dart', 'Motor de validación (3 checks)'],
        ['area_config.dart', 'Modelo de áreas con capacidades y horarios'],
        ['table_definition.dart', 'Modelo de mesas con capacidad min/max'],
        ['app_config.dart', 'Singleton con toda la configuración del restaurante'],
        ['local_reservation_service.dart', 'Consulta de ocupación por slot y por día'],
      ],
    );
  }
}
