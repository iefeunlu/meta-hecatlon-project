import 'package:flutter_test/flutter_test.dart';
import 'package:afet_destek/models/shipment_model.dart';
import 'package:afet_destek/services/logistics_service.dart';

void main() {
  test('recommends the area with the lowest stock for the selected cargo', () {
    final service = LogisticsService();

    expect(
      service.getAIRecommendedDestination('Mama'),
      'Kamil Ocak 1 Nolu Çadır Kent',
    );
  });

  test('increases destination stock once after sequential delivery', () {
    final service = LogisticsService();
    final destination = service.getAIRecommendedDestination('Su');
    final shipment = ShipmentModel(
      id: 'shipment-1',
      plateNumber: '34 ABC 123',
      vehicleType: 'Tır',
      category: 'Su',
      quantity: 500,
      destination: destination,
    );
    final startingStock = service.centerStocks[destination]!['Su']!;

    service.addShipment(shipment);
    service.updateShipmentStatus(shipment.id, ShipmentStatus.teslimEdildi);
    expect(shipment.status, ShipmentStatus.hazir);
    expect(service.centerStocks[destination]!['Su'], startingStock);

    service.updateShipmentStatus(shipment.id, ShipmentStatus.yolaCikti);
    service.updateShipmentStatus(shipment.id, ShipmentStatus.bolgeyeUlasti);
    service.updateShipmentStatus(shipment.id, ShipmentStatus.teslimEdildi);
    service.updateShipmentStatus(shipment.id, ShipmentStatus.teslimEdildi);

    expect(service.centerStocks[destination]!['Su'], startingStock + 500);
    expect(shipment.status, ShipmentStatus.teslimEdildi);
    service.dispose();
  });
}