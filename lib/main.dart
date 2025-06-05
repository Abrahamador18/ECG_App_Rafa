import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ECG Viewer',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.greenAccent,
        ),
      ),
      home: const ECGScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ECGScreen extends StatefulWidget {
  const ECGScreen({super.key});
  @override
  State<ECGScreen> createState() => _ECGScreenState();
}

class _ECGScreenState extends State<ECGScreen> {
  List<double> ecgData = [];
  List<FlSpot> displayedData = [];
  Timer? ecgTimer;
  Timer? timeTimer;
  int currentIndex = 0;
  int elapsedSeconds = 0;
  bool isRunning = false;

  @override
  void initState() {
    super.initState();
    loadEcgData();
  }

  Future<void> loadEcgData() async {
    final raw = await rootBundle.loadString('assets/rec_1_ecg_data.csv');
    final lines = raw.split('\n');
    final data = <double>[];

    for (int i = 1; i < lines.length; i++) {
      final cols = lines[i].split(',');
      if (cols.length >= 2) {
        final value = double.tryParse(cols[1].trim());
        if (value != null) {
          data.add(value);
        }
      }
    }

    setState(() {
      ecgData = data;
    });
  }

  void startEcg() {
    ecgTimer?.cancel();
    timeTimer?.cancel();
    setState(() {
      isRunning = true;
      elapsedSeconds = 0;
    });

    timeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        elapsedSeconds++;
      });
    });

    ecgTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (currentIndex + 200 < ecgData.length) {
        setState(() {
          displayedData = List.generate(
            200,
            (i) => FlSpot(i.toDouble(), ecgData[currentIndex + i]),
          );
          currentIndex += 2;
        });
      } else {
        stopEcg();
      }
    });
  }

  void stopEcg() {
    ecgTimer?.cancel();
    timeTimer?.cancel();
    setState(() {
      isRunning = false;
      currentIndex = 0;
      elapsedSeconds = 0;
      displayedData = [];
    });
  }

  @override
  void dispose() {
    ecgTimer?.cancel();
    timeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visualización de ECG'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: displayedData.isEmpty
                ? const Center(
                    child: Text(
                      'Presiona "Start" para comenzar',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: LineChart(
                      LineChartData(
                        minY: displayedData.map((e) => e.y).reduce(min),
                        maxY: displayedData.map((e) => e.y).reduce(max),
                        lineBarsData: [
                          LineChartBarData(
                            spots: displayedData,
                            isCurved: false,
                            color: Colors.redAccent,
                            barWidth: 2,
                          ),
                        ],
                        titlesData: FlTitlesData(show: false),
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tiempo: $elapsedSeconds s',
            style: const TextStyle(color: Colors.greenAccent, fontSize: 16),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: isRunning ? stopEcg : startEcg,
            icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
            label: Text(isRunning ? 'Stop' : 'Start'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}