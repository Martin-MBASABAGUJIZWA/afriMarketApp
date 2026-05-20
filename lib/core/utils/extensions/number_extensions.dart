extension DoubleExtensions on double {
  String toFormattedPrice({String currency = 'RWF'}) {
    return '${toStringAsFixed(0)} $currency';
  }

  String toCompactPrice({String currency = 'RWF'}) {
    if (this >= 1000000) {
      return '${(this / 1000000).toStringAsFixed(1)}M $currency';
    } else if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)}K $currency';
    }
    return toFormattedPrice(currency: currency);
  }

  String toPercentage({int decimals = 1}) {
    return '${toStringAsFixed(decimals)}%';
  }
}

extension IntExtensions on int {
  String toFormattedPrice({String currency = 'RWF'}) {
    return '$this $currency';
  }

  String toCompact() {
    if (this >= 1000000) {
      return '${(this / 1000000).toStringAsFixed(1)}M';
    } else if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)}K';
    }
    return toString();
  }
}
