import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class MainScreen extends StatefulWidget {
  final BluetoothDevice device;

  const MainScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  BluetoothCharacteristic? targetCharacteristic;

  static const String characteristicUuid =
      "87654321-4321-4321-4321-0987654321ba";

  static const String serviceUuid =
      "12345678-1234-1234-1234-1234567890ab";

  final List<String> items = [
    'rele 1',
    'rele 2',
    'rele 3',
    'rele 4',
    'rele 5',
    'rele 6',
  ];

  List<bool> relayStates = [false, false, false, false, false, false];

  final List<List<int>> commands = [
    [0x1],
    [0x2],
    [0x3],
    [0x4],
    [0x5],
    [0x6],
  ];

  bool _servicesDiscovered = false;

  // StreamSubscription para cancelar quando sair da tela
  StreamSubscription<List<int>>? _notifySubscription;

  @override
  void initState() {
    super.initState();
    _initBleConnection();
  }

  Future<void> _initBleConnection() async {
    try {
      final state = await widget.device.state.first;
      if (state != BluetoothDeviceState.connected) {
        await widget.device.connect(autoConnect: false);
        print("Dispositivo conectado!");
      } else {
        print("Dispositivo já estava conectado!");
      }

      if (!_servicesDiscovered) {
        _servicesDiscovered = true;
        await _discoverServices();
      }
    } catch (e) {
      print("Erro ao conectar e descobrir serviços/características: $e");
    }
  }

  Future<void> _discoverServices() async {
    final services = await widget.device.discoverServices();
    for (final service in services) {
      if (service.uuid.toString().toUpperCase() == serviceUuid.toUpperCase()) {
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toUpperCase() ==
              characteristicUuid.toUpperCase()) {
            setState(() {
              targetCharacteristic = characteristic;
            });
            print("Encontrou a característica: ${characteristic.uuid}");

            if (characteristic.properties.notify) {
              await characteristic.setNotifyValue(true);

              // Cancela se já houver assinatura anterior (boa prática)
              await _notifySubscription?.cancel();

              // Armazena a nova assinatura
              _notifySubscription = characteristic.value.listen((value) {
                // Se quiser, cheque se 'mounted' == true antes de setState()
                if (!mounted) return;

                final receivedString = String.fromCharCodes(value);
                print("Recebeu notificação: $receivedString");
                _updateRelayStates(receivedString);
              });
            }

            if (characteristic.properties.read) {
              final initialValue = await characteristic.read();
              final initialString = String.fromCharCodes(initialValue);
              print("Valor inicial: $initialString");
              _updateRelayStates(initialString);
            }

            break;
          }
        }
      }
    }

    if (targetCharacteristic == null) {
      print("Não encontrou a característica que estávamos procurando!");
    }
  }

  void _updateRelayStates(String binaryStates) {
    // Se o widget já estiver desmontado, não faz nada
    if (!mounted) return;

    if (binaryStates.length < 6) return; // Evita erro se a string for menor

    List<bool> newStates = List.generate(6, (index) {
      return binaryStates[index] == '1';
    });

    setState(() {
      relayStates = newStates;
    });
  }

  @override
  void dispose() {
    // Cancela a assinatura de notificação
    _notifySubscription?.cancel();

    // Se quiser desligar o dispositivo ao sair, faça aqui
    try {
      widget.device.disconnect();
    } catch (e) {
      print("Erro ao desconectar (dispose): $e");
    }
    
    super.dispose();
  }

  Future<void> _sendCommand(int index) async {
    if (targetCharacteristic == null) {
      print("Característica BLE não encontrada ou não inicializada.");
      return;
    }

    try {
      await targetCharacteristic!.write(
        commands[index],
        withoutResponse: false,
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
            // Só sai da tela; o disconnect ocorre no dispose()
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_disabled),
            onPressed: () {
              // Também só sai da tela
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
          final isOn = relayStates[index];
          return GestureDetector(
            onTap: () {
              _sendCommand(index);
            },
            child: Card(
              color: isOn ? Colors.lightGreen : Colors.redAccent,
              margin: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  "${items[index]}\n${isOn ? 'Ligado' : 'Desligado'}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
