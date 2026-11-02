import 'recovered_dtc_descriptions.dart';

/// BMW Motorrad diagnostic trouble code interpretation.
class BmwDtcRecord {
  const BmwDtcRecord({
    required this.code,
    required this.standardCode,
    required this.title,
    required this.ecuAcronym,
    required this.description,
    required this.possibleCauses,
    required this.recommendedAction,
  });

  final int code; // 24-bit integer code
  final String standardCode; // e.g. P0118, 5DF0, 3A1448
  final String title;
  final String ecuAcronym;
  final String description;
  final String possibleCauses;
  final String recommendedAction;

  String get hexCode =>
      '0x${code.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// Parsed UDS DTC status byte according to ISO 14229-1.
class UdsDtcStatusFlags {
  const UdsDtcStatusFlags(this.status);

  final int status;

  bool get testFailed => (status & 0x01) != 0;
  bool get testFailedThisCycle => (status & 0x02) != 0;
  bool get pendingDtc => (status & 0x04) != 0;
  bool get confirmedDtc => (status & 0x08) != 0;
  bool get testNotCompletedSinceLastClear => (status & 0x10) != 0;
  bool get testFailedSinceLastClear => (status & 0x20) != 0;
  bool get testNotCompletedThisCycle => (status & 0x40) != 0;
  bool get warningIndicatorRequested => (status & 0x80) != 0;

  String get summary {
    final flags = <String>[];
    if (confirmedDtc) flags.add('Confirmed');
    if (pendingDtc) flags.add('Pending');
    if (testFailed) flags.add('Test Failed');
    if (warningIndicatorRequested) flags.add('Warning Lamp (MIL)');
    if (flags.isEmpty) {
      if (testFailedSinceLastClear) flags.add('Previously Failed');
      else flags.add('Status 0x${status.toRadixString(16).padLeft(2, '0').toUpperCase()}');
    }
    return flags.join(' • ');
  }
}

/// BMW Motorrad 24-bit factory diagnostic trouble code database.
class BmwDtcDatabase {
  const BmwDtcDatabase._();
  static BmwDtcRecord lookup(
    int code, {
    String defaultEcu = 'Unknown',
    String? ecuKey,
    Iterable<String>? candidateKeys,
  }) {
    String? text;
    if (ecuKey != null) {
      text = RecoveredDtcDescriptions.byEcu[ecuKey]?[code];
    }
    if (text == null && candidateKeys != null) {
      for (final key in candidateKeys) {
        text = RecoveredDtcDescriptions.byEcu[key]?[code];
        if (text != null) break;
      }
    }
    text ??= RecoveredDtcDescriptions.unambiguous[code];
    final hex = '0x${code.toRadixString(16).padLeft(6, '0').toUpperCase()}';
    return BmwDtcRecord(
      code: code,
      standardCode: hex,
      title: text ?? 'Unresolved ECU fault $hex',
      ecuAcronym: defaultEcu,
      description: text ??
          'An ECU-specific description is not available for this code and controller selection.',
      possibleCauses: 'Not supplied by the diagnostic definition.',
      recommendedAction:
          'Use the repair procedure for the identified motorcycle and control unit.',
    );
  }
}
