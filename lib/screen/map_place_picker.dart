import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPlaceResult {
  const MapPlaceResult({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class MapPlacePicker extends StatefulWidget {
  const MapPlacePicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  final double? initialLatitude;
  final double? initialLongitude;

  @override
  State<MapPlacePicker> createState() => _MapPlacePickerState();
}

class _MapPlacePickerState extends State<MapPlacePicker> {
  late LatLng _selectedPoint;

  @override
  void initState() {
    super.initState();
    _selectedPoint = LatLng(
      widget.initialLatitude ?? 41.2995,
      widget.initialLongitude ?? 69.2401,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выберите место'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(
                MapPlaceResult(
                  latitude: _selectedPoint.latitude,
                  longitude: _selectedPoint.longitude,
                ),
              );
            },
            child: const Text('Готово'),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _selectedPoint,
              initialZoom: 13,
              onTap: (_, point) => setState(() => _selectedPoint = point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'sexpedition_application_1',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedPoint,
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.location_on,
                      color: Theme.of(context).colorScheme.primary,
                      size: 44,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Коснитесь карты, чтобы поставить точку. '
                  'Координаты: ${_selectedPoint.latitude.toStringAsFixed(5)}, '
                  '${_selectedPoint.longitude.toStringAsFixed(5)}',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
