/// Friendly naming and standard addressing for BMW Motorrad control units.
class BmwEcuHelper {
  const BmwEcuHelper._();

  /// Formats an internal control unit identifier into a clear, professional label.
  static String friendlyName(String key) {
    switch (key) {
      case 'cuMRBMSMP1':
      case 'cuX_BMSMP1':
        return 'Engine Electronics (BMS-MP1)';
      case 'cuMRBMSO1':
      case 'cuX_BMSO1':
        return 'Engine Electronics (BMS-O / ShiftCam)';
      case 'cuMRBMSX':
      case 'cuX_BMSX':
        return 'Engine Electronics (BMS-X Motorsport)';
      case 'cuX_BMSE2B':
      case 'cuX_BMSE2':
        return 'Engine Electronics (BMS-E2B)';
      case 'cuMRBMSK24':
        return 'Engine Electronics (BMS-K / K24)';
      case 'cuX_ABS':
        return 'ABS / Dynamic Traction Control (ABS Pro)';
      case 'cuX_ABS9M':
        return 'ABS / Brake Control (ABS 9M)';
      case 'cuX_ABSVI':
        return 'ABS / Integral ABS (I-ABS 2)';
      case 'cuX_KOMBI':
      case 'cuMRKOMBI':
      case 'cuMRKOMB':
        return 'Instrument Cluster (KOMBI / TFT)';
      case 'cuX_KOMB18':
      case 'cuX_KOMB17':
      case 'cuX_KOMB46':
      case 'cuMRKOMB18':
      case 'cuMRKOMB46':
      case 'cuMRKOMB24':
        final suffix = key.replaceFirst('cuX_', '').replaceFirst('cuMR', '');
        return 'Instrument Cluster ($suffix)';
      case 'cuX_SAF':
      case 'cuX_ESA':
        return 'Dynamic ESA / Suspension (SAF)';
      case 'cuX_RDC':
        return 'Tire Pressure Monitor (RDC / TPMS)';
      case 'cuX_BCO':
      case 'cuX_BCA':
      case 'cuX_BCL':
        return 'Body Controller / Central Electronics (ZFE / BDC)';
      case 'cuX_DWA':
      case 'cuX_DWA_9':
        return 'Anti-Theft Alarm (DWA)';
      case 'cuX_EWS4':
        return 'Electronic Immobilizer (EWS)';
      case 'cuX_AUDIO':
        return 'Audio & Sound System';
      default:
        final clean = key.startsWith('cuX_')
            ? key.substring(4)
            : (key.startsWith('cuMR') ? key.substring(4) : key);
        return 'Module $clean';
    }
  }

  /// Returns the standard diagnostic hex address for the given ECU key.
  static int standardAddress(String key) {
    if (key.contains('BMS') || key.contains('MRBMS') || key.contains('DME')) {
      return 0x12;
    }
    if (key.contains('ABS')) return 0x28;
    if (key.contains('KOMB')) return 0x60;
    if (key.contains('SAF') || key.contains('ESA')) return 0x58;
    if (key.contains('RDC')) return 0x39;
    if (key.contains('BCO') || key.contains('ZFE') || key.contains('BDC')) {
      return 0x00;
    }
    if (key.contains('DWA') || key.contains('EWS')) return 0x24;
    if (key.contains('AUDIO')) return 0x68;
    return 0x12;
  }
}
