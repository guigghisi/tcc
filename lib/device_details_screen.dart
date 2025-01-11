import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceDetailsScreen extends StatelessWidget {
  final BluetoothDevice device;

  DeviceDetailsScreen({required this.device});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.name.isNotEmpty ? device.name : "Dispositivo Bluetooth"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Informações do Dispositivo", style: TextStyle(fontSize: 20)),
            SizedBox(height: 16),
            Text("Nome: ${device.name.isNotEmpty ? device.name : 'Desconhecido'}"),
            Text("ID: ${device.remoteId}"),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await device.connect();
                _showMessage(context, "Conectado com o dispositivo!");
              },
              child: Text("Conectar"),
            ),
          ],
        ),
      ),
    );
  }

  // Função para mostrar uma mensagem
  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}