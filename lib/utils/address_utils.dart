String formatAddress(String? rawAddress, {String? city}) {
  if (rawAddress == null || rawAddress.trim().isEmpty) {
    return city ?? '';
  }

  String fullString = rawAddress;
  if (city != null && city.trim().isNotEmpty) {
    fullString = '$fullString, $city';
  }

  final parts = fullString.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
  final List<String> uniqueParts = [];
  final Set<String> seen = {};

  for (final part in parts) {
    final lower = part.toLowerCase();
    if (!seen.contains(lower)) {
      seen.add(lower);
      uniqueParts.add(part);
    }
  }

  return uniqueParts.join(', ');
}
