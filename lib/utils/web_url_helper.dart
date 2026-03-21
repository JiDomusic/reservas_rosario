import 'web_url_helper_stub.dart'
    if (dart.library.html) 'web_url_helper_web.dart' as impl;

/// Actualiza la URL del browser sin recargar la página.
/// Solo funciona en Web; en otras plataformas no hace nada.
void updateBrowserUrl(String tenantId) => impl.updateBrowserUrl(tenantId);
