class HiveModel {
  final String name;
  final String weightEntity;
  final String delta8hEntity;
  final String delta24hEntity;

  final double weight;
  final double delta8h;
  final double delta24h;

  HiveModel({
    required this.name,
    required this.weightEntity,
    required this.delta8hEntity,
    required this.delta24hEntity,
    required this.weight,
    required this.delta8h,
    required this.delta24h,
  });
}