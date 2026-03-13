# Reserva Template

## Descripción
Sistema de reservas para restaurantes, multi-tenant, hecho con Flutter + Supabase.

## Stack
- **Frontend:** Flutter (Dart SDK ^3.10.0, Material Design 3)
- **Backend:** Supabase (PostgreSQL con RLS)
- **Hosting:** Firebase (`reserva-jj`)
- **Estado:** StatefulWidgets + setState (sin Provider/Riverpod)

## Estructura
```
lib/
├── main.dart              # Entry point, resolución de tenant
├── config/                # AppConfig (singleton), Environment
├── models/                # area_config, table_definition, operating_hours
├── services/              # ~23 servicios (Supabase, reservas, mesas, PDF, WhatsApp...)
├── screens/               # 12 pantallas (home, admin, reservas, super_admin...)
└── widgets/               # calendar, table_map_editor, charts...
sql/                       # Schema, funciones, seeds, RLS policies
```

## Convenciones
- Nombres de variables/métodos en **español** (fecha, hora, personas, estado)
- Clases en PascalCase, métodos en camelCase
- Servicios como singletons
- Servicios retornan `{'success': bool, ...}`
- Tema oscuro (Color 0xFF1A1E25)

## Multi-tenancy
- Tenant resuelto por: URL param `?tenant=`, fragment `#/nombre`, usuario logueado, o default `'demo'`
- Todas las queries filtradas por tenant

## Funcionalidades clave
- Reservas con código de confirmación (6 chars alfanuméricos)
- Mapa visual de mesas con editor canvas
- Algoritmo "Smart Host" para asignación de mesas
- Auto-release de reservas no confirmadas
- Waitlist automática
- Generación de PDFs
- Notificaciones WhatsApp
- Admin dashboard con 6 tabs: Reservas, Mesas, Config, Reportes, Acceso, Bloques

## Comandos
```bash
cd /home/jido/AndroidStudioProjects/reserva_template
flutter run -d chrome    # Web
flutter build web        # Build
```
