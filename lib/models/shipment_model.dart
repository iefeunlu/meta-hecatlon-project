enum ShipmentStatus { hazir, yolaCikti, bolgeyeUlasti, teslimEdildi }

class ShipmentModel {
  final String id;
  final String plateNumber; // Plaka
  final String vehicleType; // Araç Tipi (Tır, Kamyon vb.)
  final String category;    // Su, Çadır, İlaç, Gıda
  final int quantity;       // Miktar
  final String destination; // Varış Bölgesi
  ShipmentStatus status;

  ShipmentModel({
    required this.id,
    required this.plateNumber,
    required this.vehicleType,
    required this.category,
    required this.quantity,
    required this.destination,
    this.status = ShipmentStatus.hazir,
  });
}

   