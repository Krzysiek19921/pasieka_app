class HiveModel {
  final String name;

  final String weightEntity;
  final String delta8hEntity;
  final String delta24hEntity;

  final String? tempEntity;
  final String? humidityEntity;
  final String? pressureEntity;

  final double weight;
  final double delta8h;
  final double delta24h;

  final double temp;
  final double humidity;
  final double pressure;

  HiveModel({
    required this.name,

    required this.weightEntity,
    required this.delta8hEntity,
    required this.delta24hEntity,

    this.tempEntity,
    this.humidityEntity,
    this.pressureEntity,

    required this.weight,
    required this.delta8h,
    required this.delta24h,

    this.temp = 0,
    this.humidity = 0,
    this.pressure = 0,
  });
}