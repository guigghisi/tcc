import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:tcc/device_details_screen.dart';

class BluetoothScreen extends StatefulWidget {
  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  bool _isBluetoothOn = false;
  bool _isScanning = false;
  List<ScanResult> _scanResults = [];
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  @override
  void initState() {
    super.initState();
    _listenToBluetoothState();
    requestBluetoothPermissions();
  }

  Future<void> requestBluetoothPermissions() async {
    if (await Permission.bluetoothScan.request().isDenied ||
        await Permission.bluetoothConnect.request().isDenied ||
        await Permission.location.request().isDenied) {
      // Permissões negadas
      // Aqui você pode exibir um diálogo para o usuário ou tratar o caso de permissão negada
    }
  }

  @override
  void dispose() {
    _adapterStateSubscription?.cancel();
    super.dispose();
  }

  // Listener para mudanças no estado do adaptador Bluetooth
  void _listenToBluetoothState() {
    _adapterStateSubscription =
        FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      setState(() {
        _isBluetoothOn = state == BluetoothAdapterState.on;
      });
      if (state == BluetoothAdapterState.off) {
        _showMessage(
            "Bluetooth desligado. Ligue o Bluetooth para escanear dispositivos.");
      }
    });
  }

  // Método para ativar/desativar o Bluetooth (apenas Android)
  Future<void> _toggleBluetooth(bool value) async {
    if (Platform.isAndroid) {
      if (value) {
        await FlutterBluePlus.turnOn();
      }
    } else {
      _showMessage("No iOS, o Bluetooth só pode ser controlado pelo sistema.");
    }
  }

  // Método para escanear dispositivos Bluetooth próximos
  Future<void> _scanForDevices() async {
    if (!_isBluetoothOn) {
      _showMessage(
          "Bluetooth desligado. Ative o Bluetooth para escanear dispositivos.");
      return;
    }

    setState(() {
      _isScanning = true;
      _scanResults.clear();
    });

    var subscription = FlutterBluePlus.onScanResults.listen((results) {
      setState(() {
        _scanResults = results;
      });
      if (results.isNotEmpty) {
        ScanResult r = results.last;
        print('${r.device.remoteId}: "${r.advertisementData.localName}"');
      }
    }, onError: (e) => _showMessage("Erro ao escanear: $e"));

    // Iniciar o scan com timeout
    await FlutterBluePlus.startScan(timeout: Duration(seconds: 10));

    // Cancelar o scan após o timeout
    FlutterBluePlus.cancelWhenScanComplete(subscription);

    setState(() {
      _isScanning = false;
    });
  }

  // Mostrar mensagem ao usuário
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bluetooth Scanner"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Bluetooth",
                  style: TextStyle(fontSize: 18),
                ),
                Switch(
                  value: _isBluetoothOn,
                  onChanged: _toggleBluetooth,
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _isScanning ? null : _scanForDevices,
              child: Text(_isScanning ? "Procurando..." : "Procurar Dispositivos"),
            ),
            SizedBox(height: 16),
            Expanded(
              child: _scanResults.isEmpty
                  ? Center(child: Text("Nenhum dispositivo encontrado"))
                  : ListView.builder(
                      itemCount: _scanResults.length,
                      itemBuilder: (context, index) {
                        final result = _scanResults[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(result.device.name.isNotEmpty
                                ? result.device.name
                                : "Dispositivo desconhecido"),
                            subtitle: Text(result.device.remoteId.toString()),
                            onTap: () {
                              // Ao clicar no card, navega para a tela de detalhes
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DeviceDetailsScreen(
                                    device: result.device,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
