import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:tcc/main_screen.dart';

class DeviceDetailsScreen extends StatefulWidget {
  final BluetoothDevice device;

  DeviceDetailsScreen({required this.device});

  @override
  State<DeviceDetailsScreen> createState() => _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends State<DeviceDetailsScreen> {
  bool isloading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.device.name.isNotEmpty ? widget.device.name : "Dispositivo Bluetooth"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:isloading?Center(child: CircularProgressIndicator()): Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Informações do Dispositivo", style: TextStyle(fontSize: 20)),
            SizedBox(height: 16),
            Text(
                "Nome: ${widget.device.name.isNotEmpty ? widget.device.name : 'Desconhecido'}"),
            Text("ID: ${widget.device.remoteId}"),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  isloading = true;
                });
                await widget.device.connect().then(
                  (value) {
                    _showMessage(context, "Conectado com o dispositivo!");
                    setState(() {
                      isloading = false;
                    });
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => MainScreen(device: widget.device,)));
                  },
                ).catchError(
                  (error) {
                    _showMessage(context, "Erro ao conectar com o dispositivo!");
                    setState(() {
                      isloading = false;
                    });
                  },
                );
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
