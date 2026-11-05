import 'package:hammasir_driver/core/widgets/status_chip.dart';
import 'package:hammasir_driver/data/models/driver.dart';
import 'package:hammasir_driver/l10n/l10n.dart';

/// متن و رنگ وضعیت‌ها؛ تنها جایی که ترجمه‌ی وضعیت‌ها نوشته شده است.
class StatusLabel {
  const StatusLabel(this.text, this.tone);

  final String text;
  final Tone tone;

  static StatusLabel trip(String status) {
    switch (status) {
      case TripStatus.boarding:
        return StatusLabel(L10n.t('trip.boarding'), Tone.warning);
      case TripStatus.inProgress:
        return StatusLabel(L10n.t('trip.in_progress'), Tone.success);
      case TripStatus.completed:
        return StatusLabel(L10n.t('trip.completed'), Tone.neutral);
      case TripStatus.cancelled:
        return StatusLabel(L10n.t('trip.cancelled'), Tone.danger);
      default:
        return StatusLabel(L10n.t('trip.scheduled'), Tone.brand);
    }
  }
}
