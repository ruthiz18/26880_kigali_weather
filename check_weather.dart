import 'package:kigali_weather/weather.dart';

void main() async {
  print('Asking the weather server...');
  for (final city in cities) {
    final weather = await fetchWeather(city);
    print(
      '${city.name}: ${weather.temperature}°C, humidity ${weather.humidity}%, wind ${weather.wind} km/h, code ${weather.code}, at ${weather.clock}',
    );
  }
}
