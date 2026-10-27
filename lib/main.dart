import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'weather.dart';

void main() {
  runApp(const WeatherApp());
}

IconData iconFor(int code) {
  if (code == 0) return Icons.wb_sunny;
  if (code <= 3) return Icons.cloud;
  if (code == 45 || code == 48) return Icons.foggy;
  if (code >= 95) return Icons.thunderstorm;
  if (code >= 51) return Icons.water_drop;
  return Icons.help_outline;
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: const WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  City city = cities.first;
  Weather? weather;
  bool loading = true;
  bool offline = false;
  String? error;

  @override
  void initState() {
    super.initState();
    start();
  }

  Future<void> start() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('city');
      final match = cities.where((c) => c.name == saved);
      if (match.isNotEmpty) city = match.first;
    } catch (_) {
    }
    await load();
  }

  Future<void> load() async {
    final requested = city;
    try {
      final result = await fetchWeather(requested);
      if (!mounted || requested != city) return;
      setState(() {
        weather = result;
        loading = false;
        offline = false;
        error = null;
      });
      await _save(requested, result);
    } catch (e) {
      if (!mounted || requested != city) return;
      final saved = await _loadSaved(requested);
      if (!mounted || requested != city) return;
      setState(() {
        loading = false;
        weather = saved;
        offline = saved != null;
        error = saved == null
            ? 'Could not load the weather. Check your internet connection.'
            : null;
      });
    }
  }

  Future<void> _save(City c, Weather w) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('weather_${c.name}', jsonEncode(w.toJson()));
    } catch (_) {}
  }

  Future<Weather?> _loadSaved(City c) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final text = prefs.getString('weather_${c.name}');
      if (text == null) return null;
      return Weather.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> choose(City c) async {
    if (c == city && !loading) return;
    setState(() {
      city = c;
      weather = null;
      loading = true;
      offline = false;
      error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('city', c.name);
    } catch (_) {}
    await load();
  }

  void retry() {
    setState(() {
      loading = true;
      error = null;
    });
    load();
  }

  Widget _chips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (final c in cities)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(c.name),
                selected: c == city,
                onSelected: (_) => choose(c),
              ),
            ),
        ],
      ),
    );
  }

  Widget _banner() {
    return Container(
      width: double.infinity,
      color: Colors.amber.shade200,
      padding: const EdgeInsets.all(12),
      child: Text(
        'Offline: showing the weather saved at ${weather!.clock}',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.black87),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (error != null || weather == null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48),
              const SizedBox(height: 12),
              Text(
                error ?? 'Could not load the weather.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: retry, child: const Text('Retry')),
            ],
          ),
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (offline) ...[_banner(), const SizedBox(height: 12)],
            WeatherCard(weather: weather!),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('${city.name} Weather')),
      body: Column(
        children: [
          _chips(),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key, required this.weather});

  final Weather weather;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(iconFor(weather.code), size: 80, color: scheme.primary),
            const SizedBox(height: 8),
            Text(
              '${weather.temperature.round()}°C',
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
            ),
            Text(
              describe(weather.code),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Humidity ${weather.humidity}%'),
                Text('Wind ${weather.wind} km/h'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Updated at ${weather.clock}',
              style: TextStyle(color: scheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
