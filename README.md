# 📱 FashionStore Móvil (Flutter)

Aplicación móvil oficial para la plataforma **FashionStore**, desarrollada en Flutter con arquitectura modular y conectada directamente a los endpoints de la API REST en FastAPI.

---

## 🚀 Módulos Implementados

1. **Gestión de Autenticación y Perfil (`lib/screens/auth/`)**:
   - Inicio de sesión con tokens JWT (Access Token y Refresh Token).
   - Registro de nuevos clientes.
   - Perfil de usuario con historial de reservas y compras.
   - Almacenamiento local seguro persistente.

2. **Consultas de Catálogo y Disponibilidad en Tiempo Real (`lib/screens/catalogo/`)**:
   - Conectado a `/api/v1/catalogo-disponibilidad/`.
   - Búsqueda predictiva y filtrado por categorías.
   - Indicador de stock en tiempo real (`DISPONIBLE`, `ÚLTIMAS UNIDADES`, `AGOTADO`) por sucursal.
   - Galería de fotos y selección interactiva de tallas y colores.

3. **Gestión de Reservas Web-to-Store (`lib/screens/reservas/`)**:
   - Conectado a `/api/v1/reservas/`.
   - Apartado de prendas para prueba y retiro en sucursales físicas.
   - Selección de tienda y vigencia (días para retirar).
   - Cancelación y seguimiento de estado de reservas activas.

4. **Gestión de Carrito de Compras Persistente (`lib/screens/carrito/`)**:
   - Conectado a `/api/v1/carrito-persistente/`.
   - Sincronización automática cross-device y soporte offline en local (`SharedPreferences`).
   - Cálculo en tiempo real de subtotales, totales y control de cantidades.

5. **Procesamiento de Ventas Digitales E-Commerce (`lib/screens/ventas/`)**:
   - Conectado a `/api/v1/ventas/ecommerce`.
   - Pasarela de Checkout completa con dirección de entrega.
   - Métodos de pago digital (QR Simple, Tarjeta de Crédito/Débito, Transferencia Bancaria).
   - Emisión de comprobante y factura digital con confirmación.

6. **Vestidor Virtual Inteligente (`lib/screens/vestidor/`)**:
   - Conectado a `/api/v1/ar/catalogo-3d` y la API de **Google Gemini 2.5 Flash Image**.
   - Captura directa desde la cámara del teléfono o selección desde la galería.
   - Prueba fotorrealista de ropa generada por Inteligencia Artificial.
   - Comparativa interactiva Antes (foto personal) vs Después (vestido con IA).

7. **Recomendador Inteligente IA & Estilista Virtual (`lib/screens/ia/`)**:
   - Conectado a `/api/v1/ia/chat` y `/api/v1/ia/generar-outfit`.
   - Asistente conversacional tipo chatbot para consultas de moda y estilos.
   - Sugerencia de combinaciones de prendas y generador de outfits completos.

8. **Gestión de Reseñas y Calificaciones (`lib/screens/resenas/`)**:
   - Conectado a `/api/v1/resenas/`.
   - Calificación por estrellas (1 a 5) y comentarios de clientes verificados.
   - Formulario para publicar opiniones sobre la calidad de las telas y ajuste.

---

## ⚙️ Configuración del Entorno (`lib/config/environment.dart`)

Configura la URL de tu backend según el dispositivo en el que vayas a ejecutar la app:

```dart
class Environment {
  // Emulador Android:
  static const String baseUrl = 'http://10.0.2.2:8000';
  
  // Dispositivo Físico (mismo WiFi):
  // static const String baseUrl = 'http://192.168.1.100:8000';
  
  // Web / iOS Simulator:
  // static const String baseUrl = 'http://127.0.0.1:8000';

  static const String geminiApiKey = 'TU_GEMINI_API_KEY_AQUI';
}
```

---

## 🛠️ Cómo Ejecutar el Proyecto

1. **Instalar dependencias**:
   ```bash
   cd fashionstore-movil
   flutter pub get
   ```

2. **Ejecutar en tu dispositivo o emulador**:
   ```bash
   flutter run
   ```

3. **Ejecutar en Chrome (Web)**:
   ```bash
   flutter run -d chrome
   ```

