import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class MainScreen extends StatefulWidget {
  final BluetoothDevice device;

  const MainScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Característica que vamos usar para enviar comandos
  BluetoothCharacteristic? targetCharacteristic;

  // Nome da característica (UUID) que você definiu no ESP32
  static const String characteristicUuid =
      "87654321-4321-4321-4321-0987654321ba";

  // Nome do serviço (UUID) que você definiu no ESP32
  static const String serviceUuid = "12345678-1234-1234-1234-1234567890ab";

  // Itens que aparecem no Grid
  final List<String> items = [
    'rele 1',
    'rele 2',
    'rele 3',
    'rele 4',
    'rele 5',
    'rele 6'
  ];

  // Comandos de exemplo (você pode mudar esses valores)
  final List<List<int>> commands = [
    [0x12, 0x34],
    [0x56, 0x78],
    [0x9A, 0xBC],
    [0xDE, 0xF0],
    [0x12, 0x34],
    [0x56, 0x78],
  ];

  @override
  void initState() {
    super.initState();
    _initBleConnection();
  }

  /// 1) Conecta ao dispositivo e descobre as características
  Future<void> _initBleConnection() async {
    try {
      // Garante que estamos conectados antes de descobrir os serviços
      await widget.device.connect(autoConnect: false);
      print("Dispositivo conectado!");

      // Descobre serviços e características
      final services = await widget.device.discoverServices();
      for (final service in services) {
        // Verifica se este é o serviço que queremos
        if (service.uuid.toString().toUpperCase() ==
            serviceUuid.toUpperCase()) {
          for (final characteristic in service.characteristics) {
            // Verifica se é a característica que queremos
            if (characteristic.uuid.toString().toUpperCase() ==
                characteristicUuid.toUpperCase()) {
              setState(() {
                targetCharacteristic = characteristic;
              });
              print("Encontrou a característica: ${characteristic.uuid}");
              break;
            }
          }
        }
      }

      if (targetCharacteristic == null) {
        print("Não encontrou a característica que estávamos procurando!");
      }
    } catch (e) {
      print("Erro ao conectar e descobrir serviços/características: $e");
    }
  }

  @override
  void dispose() {
    // Quando sair da tela, desconecta o dispositivo para liberar recursos
    widget.device.disconnect();
    super.dispose();
  }

  /// 2) Envia o comando selecionado via BLE
  Future<void> _sendCommand(int index) async {
    // Verifica se temos a característica alvo
    if (targetCharacteristic == null) {
      print("Característica BLE não encontrada ou não inicializada.");
      return;
    }

    try {
      await targetCharacteristic!.write(
        commands[index],
        withoutResponse: false, // ou true se o seu ESP32 usar Write Without Response
      );
      print("Comando enviado: ${commands[index]}");
    } catch (e) {
      print("Erro ao enviar comando BLE: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            widget.device.disconnect();
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_disabled),
            onPressed: () {
              widget.device.disconnect();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: GridView.builder(
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              _sendCommand(index);
            },
            child: Card(
              margin: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  items[index],
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
