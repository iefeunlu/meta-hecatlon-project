import 'package:flutter/foundation.dart';
import '../models/shipment_model.dart';

class LogisticsService extends ChangeNotifier {
  final List<ShipmentModel> _shipments = [];
  final Set<String> _stockUpdatedShipmentIds = {};

  // Toplanma alanlarının mevcut stok durumları (Meta AI & Stok Takibi için)
  final Map<String, Map<String, int>> _centerStocks = {
    'Atatürk Parkı Güvenli Toplanma Alanı': {
      'Su': 1200,
      'Çadır': 0,
      'İlaç': 0,
      'Mama': 90,
      'Battaniye': 350,
    },
    'Kamil Ocak 1 Nolu Çadır Kent': {
      'Su': 0,
      'Çadır': 15,
      'İlaç': 0,
      'Mama': 0,
      'Battaniye': 0,
    },
    'Kızılay Aşevi ve Temel İhtiyaç Noktası': {
      'Su': 3000,
      'Çadır': 0,
      'İlaç': 0,
      'Mama': 0,
      'Battaniye': 0,
    },
    'Sahra Acil Müdahale ve İlk Yardım Merkezi': {
      'Su': 0,
      'Çadır': 0,
      'İlaç': 150,
      'Mama': 0,
      'Battaniye': 0,
    },
    'Masal Parkı 2. Toplanma Bölgesi': {
      'Su': 2000,
      'Çadır': 0,
      'İlaç': 0,
      'Mama': 0,
      'Battaniye': 600,
    },
  };

  List<ShipmentModel> get shipments => List.unmodifiable(_shipments);
  Map<String, Map<String, int>> get centerStocks => Map.unmodifiable(
        _centerStocks.map(
          (center, stocks) => MapEntry(center, Map.unmodifiable(stocks)),
        ),
      );

  // Görev 2.3: Meta AI Akıllı Yük-İhtiyaç Eşleştirme Algoritması
  // Girilen kategoriye (örn: Battaniye) göre stoğu en az olan toplanma alanını bulur
  String getAIRecommendedDestination(String category) {
    String lowestStockCenter = _centerStocks.keys.first;
    int minStock = 999999;

    _centerStocks.forEach((center, stocks) {
      int currentStock = stocks[category] ?? 0;
      if (currentStock < minStock) {
        minStock = currentStock;
        lowestStockCenter = center;
      }
    });

    return lowestStockCenter;
  }

  // Yeni Sevkiyat Ekleme
  void addShipment(ShipmentModel shipment) {
    if (shipment.plateNumber.trim().isEmpty || shipment.quantity <= 0) {
      throw ArgumentError('Shipment needs a plate number and positive quantity.');
    }
    _shipments.add(shipment);
    notifyListeners();
  }

  // Görev 2.2: 3 Adımlı Canlı Sevkiyat Durumu & Otomatik Stok Artırma
  void updateShipmentStatus(String id, ShipmentStatus newStatus) {
    final index = _shipments.indexWhere((s) => s.id == id);
    if (index != -1) {
      final shipment = _shipments[index];
      if (newStatus.index != shipment.status.index + 1) return;

      shipment.status = newStatus;

      // Tırcı "Teslim Ettim" butonuna bastığında hedef alanın stoğu otomatik artar
      if (newStatus == ShipmentStatus.teslimEdildi) {
        // Tekrarlanan teslim güncellemeleri stok miktarını birden fazla artırmamalı.
        if (_stockUpdatedShipmentIds.add(shipment.id)) {
          _increaseStock(shipment.destination, shipment.category, shipment.quantity);
        }
      }
      notifyListeners();
    }
  }

  void _increaseStock(String center, String category, int amount) {
    if (_centerStocks.containsKey(center)) {
      _centerStocks[center]![category] = (_centerStocks[center]![category] ?? 0) + amount;
    }
  }
}