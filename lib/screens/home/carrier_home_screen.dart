import 'package:flutter/material.dart';
import '../../models/relief_area_model.dart';
import '../../models/shipment_model.dart';
import '../../models/user_model.dart';
import '../../services/logistics_service.dart';

class CarrierHomeScreen extends StatefulWidget {
  final UserModel user;
  final void Function(ReliefAreaModel? area)? onNavigateToMap;

  const CarrierHomeScreen({
    super.key,
    required this.user,
    this.onNavigateToMap,
  });

  @override
  State<CarrierHomeScreen> createState() => _CarrierHomeScreenState();
}

class _CarrierHomeScreenState extends State<CarrierHomeScreen> {
  final LogisticsService _logisticsService = LogisticsService();

  final _plateController = TextEditingController();
  final _quantityController = TextEditingController();
  String _selectedVehicle = 'Tır';
  String _selectedCategory = 'Su';

  @override
  void dispose() {
    _plateController.dispose();
    _quantityController.dispose();
    _logisticsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _logisticsService,
      builder: (context, child) {
        final aiRecommendedDestination =
            _logisticsService.getAIRecommendedDestination(_selectedCategory);
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Lojistik & Sürücü Kokpiti'),
                Text(
                  widget.user.name,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Yeni Yük Ekleme Butonu
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _showAddShipmentBottomSheet(context),
                    icon: const Icon(Icons.add_location_alt),
                    label: const Text(
                      'YENİ YÜK & SEVKİYAT EKLE',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Görev 2.3: Meta AI Akıllı Yük-İhtiyaç Eşleştirme Kartı
                Card(
                  color: Colors.orange.shade50,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.deepOrange, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.auto_awesome, color: Colors.deepOrange),
                            SizedBox(width: 8),
                            Text(
                              'Meta AI Önerilen Rota',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Seçili Yük Türü: $_selectedCategory',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'İhtiyacı En Yüksek Alan: $aiRecommendedDestination',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mevcut $_selectedCategory stoku: '
                          '${_logisticsService.centerStocks[aiRecommendedDestination]?[_selectedCategory] ?? 0}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        if (widget.onNavigateToMap != null)
                          TextButton.icon(
                            onPressed: () {
                              final area = ReliefAreaModel.demoAreas.firstWhere(
                                (area) => area.name == aiRecommendedDestination,
                              );
                              widget.onNavigateToMap!(area);
                            },
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('Hedefi Haritada Aç'),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Mevcut Taşımalarınız (Shipments)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Sevkiyat Listesi (Görev 2.2)
                _logisticsService.shipments.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('Henüz aktif bir sevkiyat kaydı yok.'),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _logisticsService.shipments.length,
                        itemBuilder: (context, index) {
                          final shipment = _logisticsService.shipments[index];
                          return _buildShipmentCard(shipment);
                        },
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Sevkiyat Kartı ve 3 Adımlı Durum Butonları (Görev 2.2)
  Widget _buildShipmentCard(ShipmentModel shipment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${shipment.vehicleType} - ${shipment.plateNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                _buildStatusChip(shipment.status),
              ],
            ),
            const Divider(),
            Text('Yük: ${shipment.quantity} Adet ${shipment.category}'),
            Text('Hedef: ${shipment.destination}'),
            Text(
              'Hedef stok: '
              '${_logisticsService.centerStocks[shipment.destination]?[shipment.category] ?? 0}',
            ),
            const SizedBox(height: 12),

            // 3 Adımlı Canlı Butonlar
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: shipment.status.index >= ShipmentStatus.yolaCikti.index
                          ? Colors.orange
                          : Colors.grey.shade300,
                    ),
                    onPressed: shipment.status == ShipmentStatus.hazir
                        ? () => _logisticsService.updateShipmentStatus(
                              shipment.id,
                              ShipmentStatus.yolaCikti,
                            )
                        : null,
                    icon: const Icon(Icons.local_shipping_outlined),
                    label: const Text('1. Yola Çıktım'),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: shipment.status.index >= ShipmentStatus.bolgeyeUlasti.index
                          ? Colors.blue
                          : Colors.grey.shade300,
                    ),
                    onPressed: shipment.status == ShipmentStatus.yolaCikti
                        ? () => _logisticsService.updateShipmentStatus(
                              shipment.id,
                              ShipmentStatus.bolgeyeUlasti,
                            )
                        : null,
                    icon: const Icon(Icons.place_outlined),
                    label: const Text('2. Bölgeye Ulaştım'),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: shipment.status == ShipmentStatus.teslimEdildi
                          ? Colors.green
                          : Colors.grey.shade300,
                    ),
                    onPressed: shipment.status == ShipmentStatus.bolgeyeUlasti
                        ? () => _logisticsService.updateShipmentStatus(
                              shipment.id,
                              ShipmentStatus.teslimEdildi,
                            )
                        : null,
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('3. Teslim Ettim'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ShipmentStatus status) {
    String label;
    Color color;
    switch (status) {
      case ShipmentStatus.yolaCikti:
        label = 'Yola Çıktı';
        color = Colors.orange;
        break;
      case ShipmentStatus.hazir:
        label = 'Sevkiyat Hazır';
        color = Colors.blueGrey;
        break;
      case ShipmentStatus.bolgeyeUlasti:
        label = 'Bölgeye Ulaştı';
        color = Colors.blue;
        break;
      case ShipmentStatus.teslimEdildi:
        label = 'Teslim Edildi (+Stok Artırıldı)';
        color = Colors.green;
        break;
    }
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      backgroundColor: color,
    );
  }

  // Yeni Yük Ekleme Formu
  void _showAddShipmentBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Yeni Sevkiyat Kaydı',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _plateController,
                decoration: const InputDecoration(
                  labelText: 'Plaka (Örn: 34 ABC 123)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedVehicle,
                      items: ['Tır', 'Kamyonet', 'Kamyon']
                          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedVehicle = val);
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Araç Tipi'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      items: ['Su', 'Çadır', 'İlaç', 'Mama', 'Battaniye']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCategory = val);
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Yük Türü'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Miktar',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final quantity = int.tryParse(_quantityController.text.trim());
                    if (_plateController.text.trim().isEmpty ||
                        quantity == null ||
                        quantity <= 0) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Plaka ve pozitif bir miktar girin.'),
                        ),
                      );
                      return;
                    }

                    final newShipment = ShipmentModel(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      plateNumber: _plateController.text.trim(),
                      vehicleType: _selectedVehicle,
                      category: _selectedCategory,
                      quantity: quantity,
                      destination: _logisticsService
                          .getAIRecommendedDestination(_selectedCategory),
                    );

                    _logisticsService.addShipment(newShipment);
                    Navigator.pop(context);
                    _plateController.clear();
                    _quantityController.clear();
                  },
                  child: const Text('SEVKİYATI BAŞLAT'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}