import 'dart:math';

import '../../core/config/date_guess_config.dart';
import 'date_guess_validator.dart';

/// Picks a random real calendar date within [DateGuessConfig]'s year range,
/// formatted as the 8-digit DDMMYYYY string the rest of the date-guess mode
/// works with (same shape as a Round.solutionWord).
class DateGuessService {
  final DateGuessValidator _validator;
  final int minYear;
  final int maxYear;

  DateGuessService({DateGuessValidator validator = const DateGuessValidator(), this.minYear = DateGuessConfig.minYear, int? maxYear})
    : _validator = validator,
      maxYear = maxYear ?? DateGuessConfig.maxYear;

  String randomSolution({Random? random}) {
    final rng = random ?? Random();
    final year = minYear + rng.nextInt(maxYear - minYear + 1);
    final month = 1 + rng.nextInt(12);
    final day = 1 + rng.nextInt(_validator.daysInMonth(month, year));
    return '${_pad2(day)}${_pad2(month)}${year.toString().padLeft(4, '0')}';
  }

  String _pad2(int n) => n.toString().padLeft(2, '0');
}
