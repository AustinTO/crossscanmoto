import 'dart:async';

import 'uds_client.dart';
import 'uds_response.dart';

enum RecoveredActuatorAction { none, start, run, on, off, end }

class RecoveredActuatorCommand {
  const RecoveredActuatorCommand({
    required this.rowId,
    required this.positionId,
    required this.action,
    required this.actionLabel,
    required this.request,
    required this.responsePrefix,
    required this.durationSeconds,
    required this.raw,
  });

  /// The first numeric table column. The native parser reads it but discards it.
  final int rowId;

  /// ACTUATORCMD column 1; joined to ACTUATORPOS column 0.
  final int positionId;
  final RecoveredActuatorAction action;
  final String actionLabel;
  final List<int> request;

  /// Preserved exactly from ACTUATORCMD. The recovered parser decodes this
  /// field but does not retain or compare it during its actuator request path.
  final List<int> responsePrefix;
  final int durationSeconds;
  final String raw;

  /// Whether the table prefix equals the positive service byte followed by
  /// the same request bytes. Some rows intentionally do not satisfy this.
  bool get responsePrefixEchoesRequest {
    if (request.isEmpty ||
        responsePrefix.isEmpty ||
        responsePrefix.first != request.first + 0x40 ||
        responsePrefix.length > request.length) {
      return false;
    }
    for (var index = 1; index < responsePrefix.length; index++) {
      if (responsePrefix[index] != request[index]) return false;
    }
    return true;
  }
}

class RecoveredActuatorPosition {
  const RecoveredActuatorPosition({
    required this.id,
    required this.actuatorId,
    required this.titleTextId,
    required this.title,
    required this.instructionTextId,
    required this.instruction,
    required this.ignoredColumn4,
    required this.completionInstructionTextId,
    required this.completionTextId,
    required this.completion,
    required this.commands,
    required this.unsupportedReason,
  });

  /// ACTUATORPOS columns 0 and 1 are the position key and actuator parent key.
  final int id;
  final int actuatorId;

  /// Text IDs/values are resolved using the recovered native `q` accessor.
  final int titleTextId;
  final String title;
  final int instructionTextId;
  final String instruction;

  /// ACTUATORPOS column 4 is parsed as an integer but its role is unknown.
  final int ignoredColumn4;
  final int completionInstructionTextId;
  final int completionTextId;
  final String completion;
  final List<RecoveredActuatorCommand> commands;
  final String? unsupportedReason;

  bool get isSupported => unsupportedReason == null;
  RecoveredActuatorCommand? command(RecoveredActuatorAction action) {
    for (final command in commands) {
      if (command.action == action) return command;
    }
    return null;
  }

  RecoveredActuatorCommand? get start => command(RecoveredActuatorAction.start);
  RecoveredActuatorCommand? get on => command(RecoveredActuatorAction.on);
  RecoveredActuatorCommand? get run => command(RecoveredActuatorAction.run);
  RecoveredActuatorCommand? get off => command(RecoveredActuatorAction.off);
  RecoveredActuatorCommand? get end => command(RecoveredActuatorAction.end);

  RecoveredActuatorCommand? get activation => on ?? run;
}

class RecoveredActuatorDefinition {
  const RecoveredActuatorDefinition({
    required this.id,
    required this.nameTextId,
    required this.name,
    required this.positions,
  });

  final int id;
  final int nameTextId;
  final String name;
  final List<RecoveredActuatorPosition> positions;
}

// Generated from assets/research/recovered-native/runtime-tables by
// tool/native/build_actuator_catalog.py. Do not hand-edit the generated block.
// BEGIN GENERATED ACTUATOR CATALOG
const recoveredActuatorsByEcu = <String, List<RecoveredActuatorDefinition>>{
  "cuMRBMSMP1": <RecoveredActuatorDefinition>[
    RecoveredActuatorDefinition(
      id: 365, nameTextId: 106070,
      name: "Fuel injector",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 380, actuatorId: 365,
          titleTextId: 106051, title: "Fuel injector 1",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 0, completion: "Unknown native text #0",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 767, positionId: 380,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 80, 3, 0, 100, 0, 1, 192], responsePrefix: <int>[111, 100, 80, 3],
              durationSeconds: 10, raw: "767;380;On;2F,64,50,03,00,64,00,01,C0;6F,64,50,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 768, positionId: 380,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 80, 0, 255], responsePrefix: <int>[111, 100, 80, 0],
              durationSeconds: 0, raw: "768;380;Off;2F,64,50,00,FF;6F,64,50,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
        RecoveredActuatorPosition(
          id: 397, actuatorId: 365,
          titleTextId: 106054, title: "Fuel injector 2",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 0, completion: "Unknown native text #0",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 801, positionId: 397,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 80, 3, 0, 100, 0, 2, 192], responsePrefix: <int>[111, 100, 80, 3],
              durationSeconds: 10, raw: "801;397;On;2F,64,50,03,00,64,00,02,C0;6F,64,50,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 802, positionId: 397,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 80, 0, 255], responsePrefix: <int>[111, 100, 80, 0],
              durationSeconds: 0, raw: "802;397;Off;2F,64,50,00,FF;6F,64,50,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 367, nameTextId: 111421,
      name: "Tank vent valve",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 382, actuatorId: 367,
          titleTextId: 111421, title: "Tank vent valve",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 0, completion: "Unknown native text #0",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 771, positionId: 382,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 82, 3, 0, 100, 70, 192], responsePrefix: <int>[111, 100, 82, 3],
              durationSeconds: 10, raw: "771;382;On;2F,64,52,03,00,64,46,C0;6F,64,52,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 772, positionId: 382,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 82, 0, 255], responsePrefix: <int>[111, 100, 82, 0],
              durationSeconds: 0, raw: "772;382;Off;2F,64,52,00,FF;6F,64,52,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 368, nameTextId: 106059,
      name: "Electric fuel pump",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 383, actuatorId: 368,
          titleTextId: 106059, title: "Electric fuel pump",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 0, completion: "Unknown native text #0",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 773, positionId: 383,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 83, 0, 100, 50, 192], responsePrefix: <int>[111, 100, 83, 3],
              durationSeconds: 10, raw: "773;383;On;2F,64,53,00,64,32,C0;6F,64,53,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 774, positionId: 383,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 83, 0, 255], responsePrefix: <int>[111, 100, 83, 0],
              durationSeconds: 0, raw: "774;383;Off;2F,64,53,00,FF;6F,64,53,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 369, nameTextId: 106061,
      name: "Fan",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 384, actuatorId: 369,
          titleTextId: 106061, title: "Fan",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 0, completion: "Unknown native text #0",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 775, positionId: 384,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 84, 3, 0, 100], responsePrefix: <int>[111, 100, 84, 3],
              durationSeconds: 10, raw: "775;384;On;2F,64,54,03,00,64;6F,64,54,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 776, positionId: 384,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 84, 0], responsePrefix: <int>[111, 100, 84, 0],
              durationSeconds: 0, raw: "776;384;Off;2F,64,54,00;6F,64,54,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 370, nameTextId: 106068,
      name: "Oxygen sensor heating",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 385, actuatorId: 370,
          titleTextId: 106062, title: "Oxygen sensor heating of cylinder bank 1",
          instructionTextId: 106064, instruction: "Activation for 60 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106064, completionTextId: 0, completion: "Unknown native text #0",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 777, positionId: 385,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 85, 3, 0, 2, 88, 0, 224], responsePrefix: <int>[111, 100, 85, 3],
              durationSeconds: 60, raw: "777;385;On;2F,64,55,03,00,02,58,00,E0;6F,64,55,03;60",
            ),
            RecoveredActuatorCommand(
              rowId: 778, positionId: 385,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 85, 0, 255], responsePrefix: <int>[111, 100, 85, 0],
              durationSeconds: 0, raw: "778;385;Off;2F,64,55,00,FF;6F,64,55,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
        RecoveredActuatorPosition(
          id: 398, actuatorId: 370,
          titleTextId: 106063, title: "Oxygen sensor heating of cylinder bank 2",
          instructionTextId: 106064, instruction: "Activation for 60 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106064, completionTextId: 0, completion: "Unknown native text #0",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 803, positionId: 398,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 85, 3, 1, 2, 88, 0, 224], responsePrefix: <int>[111, 100, 85, 3],
              durationSeconds: 60, raw: "803;398;On;2F,64,55,03,01,02,58,00,E0;6F,64,55,03;60",
            ),
            RecoveredActuatorCommand(
              rowId: 804, positionId: 398,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 85, 0, 255], responsePrefix: <int>[111, 100, 85, 0],
              durationSeconds: 0, raw: "804;398;Off;2F,64,55,00,FF;6F,64,55,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 371, nameTextId: 106069,
      name: "Coolant temperature warning light",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 386, actuatorId: 371,
          titleTextId: 106069, title: "Coolant temperature warning light",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 106052, completionInstructionTextId: 106052, completionTextId: 0, completion: "Unknown native text #0",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 779, positionId: 386,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 86, 3, 0, 100], responsePrefix: <int>[111, 100, 86, 3],
              durationSeconds: 10, raw: "779;386;On;2F,64,56,03,00,64;6F,64,56,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 780, positionId: 386,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 86, 0], responsePrefix: <int>[111, 100, 86, 0],
              durationSeconds: 0, raw: "780;386;Off;2F,64,56,00;6F,64,56,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 372, nameTextId: 106066,
      name: "Engine warning light",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 387, actuatorId: 372,
          titleTextId: 106066, title: "Engine warning light",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 0, completion: "Unknown native text #0",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 781, positionId: 387,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 87, 3, 0, 100], responsePrefix: <int>[111, 100, 87, 3],
              durationSeconds: 10, raw: "781;387;On;2F,64,57,03,00,64;6F,64,57,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 782, positionId: 387,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 87, 0], responsePrefix: <int>[111, 100, 87, 0],
              durationSeconds: 0, raw: "782;387;Off;2F,64,57,00;6F,64,57,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 373, nameTextId: 111419,
      name: "Exhaust flap servomotor",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 388, actuatorId: 373,
          titleTextId: 111419, title: "Exhaust flap servomotor",
          instructionTextId: 111420, instruction: "Activation for 3 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 111420, completionTextId: 0, completion: "Unknown native text #0",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 783, positionId: 388,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 88, 3, 0, 30, 70, 192], responsePrefix: <int>[111, 100, 88, 3],
              durationSeconds: 3, raw: "783;388;On;2F,64,58,03,00,1E,46,C0;6F,64,58,03;3",
            ),
            RecoveredActuatorCommand(
              rowId: 784, positionId: 388,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 88, 0, 255], responsePrefix: <int>[111, 100, 88, 0],
              durationSeconds: 0, raw: "784;388;Off;2F,64,58,00,FF;6F,64,58,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 377, nameTextId: 106067,
      name: "Throttle valve servomotor",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 392, actuatorId: 377,
          titleTextId: 106067, title: "Throttle valve servomotor",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 0, completion: "Unknown native text #0",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 791, positionId: 392,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 92, 3, 0, 100, 0, 0, 16, 0, 0, 141, 185, 240], responsePrefix: <int>[111, 100, 92, 3],
              durationSeconds: 10, raw: "791;392;On;2F,64,5C,03,00,64,00,00,10,00,00,8D,B9,F0;6F,64,5C,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 792, positionId: 392,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 92, 0, 255], responsePrefix: <int>[111, 100, 92, 0],
              durationSeconds: 0, raw: "792;392;Off;2F,64,5C,00,FF;6F,64,5C,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
  ],
  "cuX_ABS": <RecoveredActuatorDefinition>[
    RecoveredActuatorDefinition(
      id: 52, nameTextId: 106922,
      name: "Pump motor",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 58, actuatorId: 52,
          titleTextId: 106922, title: "Pump motor",
          instructionTextId: 106917, instruction: "Activation for approx. 5 s",
          ignoredColumn4: 0, completionInstructionTextId: 106917, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 115, positionId: 58,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 224, 218, 3, 1], responsePrefix: <int>[111, 224, 218, 3, 1],
              durationSeconds: 5, raw: "115;58;On;2F,E0,DA,03,01;6F,E0,DA,03,01;5",
            ),
            RecoveredActuatorCommand(
              rowId: 116, positionId: 58,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 224, 218, 0], responsePrefix: <int>[],
              durationSeconds: 0, raw: "116;58;Off;2F,E0,DA,00;;0",
            ),
            RecoveredActuatorCommand(
              rowId: 119, positionId: 58,
              action: RecoveredActuatorAction.start, actionLabel: "Start",
              request: <int>[16, 3], responsePrefix: <int>[80, 3],
              durationSeconds: 0, raw: "119;58;Start;10,03;50,03;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 53, nameTextId: 106923,
      name: "ABS valves",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 59, actuatorId: 53,
          titleTextId: 106925, title: "All valves",
          instructionTextId: 106917, instruction: "Activation for approx. 5 s",
          ignoredColumn4: 0, completionInstructionTextId: 106917, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 117, positionId: 59,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 224, 219, 3, 1, 1, 1, 1, 1, 1, 252], responsePrefix: <int>[],
              durationSeconds: 5, raw: "117;59;On;2F,E0,DB,03,01,01,01,01,01,01,FC;;5",
            ),
            RecoveredActuatorCommand(
              rowId: 118, positionId: 59,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 224, 219, 0], responsePrefix: <int>[],
              durationSeconds: 0, raw: "118;59;Off;2F,E0,DB,00;;0",
            ),
            RecoveredActuatorCommand(
              rowId: 120, positionId: 59,
              action: RecoveredActuatorAction.start, actionLabel: "Start",
              request: <int>[16, 3], responsePrefix: <int>[80, 3],
              durationSeconds: 0, raw: "120;59;Start;10,03;50,03;0",
            ),
          ],
          unsupportedReason: null,
        ),
        RecoveredActuatorPosition(
          id: 60, actuatorId: 53,
          titleTextId: 106924, title: "Intake valve front",
          instructionTextId: 106917, instruction: "Activation for approx. 5 s",
          ignoredColumn4: 0, completionInstructionTextId: 106917, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 121, positionId: 60,
              action: RecoveredActuatorAction.start, actionLabel: "Start",
              request: <int>[16, 3], responsePrefix: <int>[80, 3],
              durationSeconds: 0, raw: "121;60;Start;10,03;50,03;0",
            ),
            RecoveredActuatorCommand(
              rowId: 127, positionId: 60,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 224, 219, 3, 1, 0, 0, 0, 0, 0, 252], responsePrefix: <int>[],
              durationSeconds: 5, raw: "127;60;On;2F,E0,DB,03,01,00,00,00,00,00,FC;;5",
            ),
            RecoveredActuatorCommand(
              rowId: 133, positionId: 60,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 224, 219, 0], responsePrefix: <int>[],
              durationSeconds: 0, raw: "133;60;Off;2F,E0,DB,00;;0",
            ),
          ],
          unsupportedReason: null,
        ),
        RecoveredActuatorPosition(
          id: 61, actuatorId: 53,
          titleTextId: 106926, title: "Intake valve rear",
          instructionTextId: 106917, instruction: "Activation for approx. 5 s",
          ignoredColumn4: 0, completionInstructionTextId: 106917, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 122, positionId: 61,
              action: RecoveredActuatorAction.start, actionLabel: "Start",
              request: <int>[16, 3], responsePrefix: <int>[80, 3],
              durationSeconds: 0, raw: "122;61;Start;10,03;50,03;0",
            ),
            RecoveredActuatorCommand(
              rowId: 128, positionId: 61,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 224, 219, 3, 0, 1, 0, 0, 0, 0, 252], responsePrefix: <int>[],
              durationSeconds: 5, raw: "128;61;On;2F,E0,DB,03,00,01,00,00,00,00,FC;;5",
            ),
            RecoveredActuatorCommand(
              rowId: 134, positionId: 61,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 224, 219, 0], responsePrefix: <int>[],
              durationSeconds: 0, raw: "134;61;Off;2F,E0,DB,00;;0",
            ),
          ],
          unsupportedReason: null,
        ),
        RecoveredActuatorPosition(
          id: 62, actuatorId: 53,
          titleTextId: 106927, title: "Exhaust valve front",
          instructionTextId: 106917, instruction: "Activation for approx. 5 s",
          ignoredColumn4: 0, completionInstructionTextId: 106917, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 123, positionId: 62,
              action: RecoveredActuatorAction.start, actionLabel: "Start",
              request: <int>[16, 3], responsePrefix: <int>[80, 3],
              durationSeconds: 0, raw: "123;62;Start;10,03;50,03;0",
            ),
            RecoveredActuatorCommand(
              rowId: 129, positionId: 62,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 224, 219, 3, 0, 0, 1, 0, 0, 0, 252], responsePrefix: <int>[],
              durationSeconds: 5, raw: "129;62;On;2F,E0,DB,03,00,00,01,00,00,00,FC;;5",
            ),
            RecoveredActuatorCommand(
              rowId: 135, positionId: 62,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 224, 219, 0], responsePrefix: <int>[],
              durationSeconds: 0, raw: "135;62;Off;2F,E0,DB,00;;0",
            ),
          ],
          unsupportedReason: null,
        ),
        RecoveredActuatorPosition(
          id: 63, actuatorId: 53,
          titleTextId: 106928, title: "Exhaust valve rear",
          instructionTextId: 106917, instruction: "Activation for approx. 5 s",
          ignoredColumn4: 0, completionInstructionTextId: 106917, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 124, positionId: 63,
              action: RecoveredActuatorAction.start, actionLabel: "Start",
              request: <int>[16, 3], responsePrefix: <int>[80, 3],
              durationSeconds: 0, raw: "124;63;Start;10,03;50,03;0",
            ),
            RecoveredActuatorCommand(
              rowId: 130, positionId: 63,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 224, 219, 3, 0, 0, 0, 1, 0, 0, 252], responsePrefix: <int>[],
              durationSeconds: 5, raw: "130;63;On;2F,E0,DB,03,00,00,00,01,00,00,FC;;5",
            ),
            RecoveredActuatorCommand(
              rowId: 136, positionId: 63,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 224, 219, 0], responsePrefix: <int>[],
              durationSeconds: 0, raw: "136;63;Off;2F,E0,DB,00;;0",
            ),
          ],
          unsupportedReason: null,
        ),
        RecoveredActuatorPosition(
          id: 64, actuatorId: 53,
          titleTextId: 106929, title: "Pre-charge valve rear",
          instructionTextId: 106917, instruction: "Activation for approx. 5 s",
          ignoredColumn4: 0, completionInstructionTextId: 106917, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 125, positionId: 64,
              action: RecoveredActuatorAction.start, actionLabel: "Start",
              request: <int>[16, 3], responsePrefix: <int>[80, 3],
              durationSeconds: 0, raw: "125;64;Start;10,03;50,03;0",
            ),
            RecoveredActuatorCommand(
              rowId: 131, positionId: 64,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 224, 219, 3, 0, 0, 0, 0, 1, 0, 252], responsePrefix: <int>[],
              durationSeconds: 5, raw: "131;64;On;2F,E0,DB,03,00,00,00,00,01,00,FC;;5",
            ),
            RecoveredActuatorCommand(
              rowId: 137, positionId: 64,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 224, 219, 0], responsePrefix: <int>[],
              durationSeconds: 0, raw: "137;64;Off;2F,E0,DB,00;;0",
            ),
          ],
          unsupportedReason: null,
        ),
        RecoveredActuatorPosition(
          id: 65, actuatorId: 53,
          titleTextId: 106930, title: "Separator valve rear",
          instructionTextId: 106917, instruction: "Activation for approx. 5 s",
          ignoredColumn4: 0, completionInstructionTextId: 106917, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 126, positionId: 65,
              action: RecoveredActuatorAction.start, actionLabel: "Start",
              request: <int>[16, 3], responsePrefix: <int>[80, 3],
              durationSeconds: 0, raw: "126;65;Start;10,03;50,03;0",
            ),
            RecoveredActuatorCommand(
              rowId: 132, positionId: 65,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 224, 219, 3, 0, 0, 0, 0, 0, 1, 252], responsePrefix: <int>[],
              durationSeconds: 5, raw: "132;65;On;2F,E0,DB,03,00,00,00,00,00,01,FC;;5",
            ),
            RecoveredActuatorCommand(
              rowId: 138, positionId: 65,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 224, 219, 0], responsePrefix: <int>[],
              durationSeconds: 0, raw: "138;65;Off;2F,E0,DB,00;;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
  ],
  "cuX_BMSE2B": <RecoveredActuatorDefinition>[
    RecoveredActuatorDefinition(
      id: 337, nameTextId: 106059,
      name: "Electric fuel pump",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 351, actuatorId: 337,
          titleTextId: 106059, title: "Electric fuel pump",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 709, positionId: 351,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 102, 240, 3, 0, 100], responsePrefix: <int>[],
              durationSeconds: 10, raw: "709;351;On;2F,66,F0,03,00,64;;10",
            ),
            RecoveredActuatorCommand(
              rowId: 710, positionId: 351,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 102, 240, 0], responsePrefix: <int>[],
              durationSeconds: 0, raw: "710;351;Off;2F,66,F0,00;;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 339, nameTextId: 106061,
      name: "Fan",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 353, actuatorId: 339,
          titleTextId: 106061, title: "Fan",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 713, positionId: 353,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 102, 242, 3, 0, 100], responsePrefix: <int>[],
              durationSeconds: 10, raw: "713;353;On;2F,66,F2,03,00,64;;10",
            ),
            RecoveredActuatorCommand(
              rowId: 714, positionId: 353,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 102, 242, 0], responsePrefix: <int>[],
              durationSeconds: 0, raw: "714;353;Off;2F,66,F2,00;;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 340, nameTextId: 106070,
      name: "Fuel injector",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 354, actuatorId: 340,
          titleTextId: 106070, title: "Fuel injector",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 715, positionId: 354,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 102, 243, 3, 0, 100, 0, 1, 192], responsePrefix: <int>[],
              durationSeconds: 10, raw: "715;354;On;2F,66,F3,03,00,64,00,01,C0;;10",
            ),
            RecoveredActuatorCommand(
              rowId: 716, positionId: 354,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 102, 243, 0], responsePrefix: <int>[],
              durationSeconds: 0, raw: "716;354;Off;2F,66,F3,00;;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 342, nameTextId: 106060,
      name: "Secondary-air valve",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 356, actuatorId: 342,
          titleTextId: 106060, title: "Secondary-air valve",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 719, positionId: 356,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 102, 245, 3, 0, 100, 50, 192], responsePrefix: <int>[],
              durationSeconds: 10, raw: "719;356;On;2F,66,F5,03,00,64,32,C0;;10",
            ),
            RecoveredActuatorCommand(
              rowId: 720, positionId: 356,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 102, 245, 0], responsePrefix: <int>[],
              durationSeconds: 0, raw: "720;356;Off;2F,66,F5,00;;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 344, nameTextId: 111477,
      name: "Idle actuator",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 358, actuatorId: 344,
          titleTextId: 111477, title: "Idle actuator",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 723, positionId: 358,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 102, 247, 3, 0, 100, 0, 0, 3, 232, 0, 1, 134, 160, 240], responsePrefix: <int>[],
              durationSeconds: 10, raw: "723;358;On;2F,66,F7,03,00,64,00,00,03,E8,00,01,86,A0,F0;;10",
            ),
            RecoveredActuatorCommand(
              rowId: 724, positionId: 358,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 102, 247, 0], responsePrefix: <int>[],
              durationSeconds: 0, raw: "724;358;Off;2F,66,F7,00;;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 345, nameTextId: 106066,
      name: "Engine warning light",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 359, actuatorId: 345,
          titleTextId: 106066, title: "Engine warning light",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 725, positionId: 359,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 102, 248, 3, 0, 100], responsePrefix: <int>[],
              durationSeconds: 10, raw: "725;359;On;2F,66,F8,03,00,64;;10",
            ),
            RecoveredActuatorCommand(
              rowId: 726, positionId: 359,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 102, 248, 0], responsePrefix: <int>[],
              durationSeconds: 0, raw: "726;359;Off;2F,66,F8,00;;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 346, nameTextId: 106069,
      name: "Coolant temperature warning light",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 360, actuatorId: 346,
          titleTextId: 106069, title: "Coolant temperature warning light",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 106052, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 727, positionId: 360,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 102, 249, 3, 0, 100], responsePrefix: <int>[],
              durationSeconds: 10, raw: "727;360;On;2F,66,F9,03,00,64;;10",
            ),
            RecoveredActuatorCommand(
              rowId: 728, positionId: 360,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 102, 249, 0], responsePrefix: <int>[],
              durationSeconds: 0, raw: "728;360;Off;2F,66,F9,00;;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
  ],
  "cuX_BMSMP1": <RecoveredActuatorDefinition>[
    RecoveredActuatorDefinition(
      id: 313, nameTextId: 106070,
      name: "Fuel injector",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 325, actuatorId: 313,
          titleTextId: 106051, title: "Fuel injector 1",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 657, positionId: 325,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 80, 3, 0, 100, 0, 1, 192], responsePrefix: <int>[111, 100, 80, 3],
              durationSeconds: 10, raw: "657;325;On;2F,64,50,03,00,64,00,01,C0;6F,64,50,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 658, positionId: 325,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 80, 0, 255], responsePrefix: <int>[111, 100, 80, 0],
              durationSeconds: 0, raw: "658;325;Off;2F,64,50,00,FF;6F,64,50,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
        RecoveredActuatorPosition(
          id: 349, actuatorId: 313,
          titleTextId: 106054, title: "Fuel injector 2",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 705, positionId: 349,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 80, 3, 0, 100, 0, 2, 192], responsePrefix: <int>[111, 100, 80, 3],
              durationSeconds: 10, raw: "705;349;On;2F,64,50,03,00,64,00,02,C0;6F,64,50,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 706, positionId: 349,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 80, 0, 255], responsePrefix: <int>[111, 100, 80, 0],
              durationSeconds: 0, raw: "706;349;Off;2F,64,50,00,FF;6F,64,50,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 315, nameTextId: 111421,
      name: "Tank vent valve",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 327, actuatorId: 315,
          titleTextId: 111421, title: "Tank vent valve",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 661, positionId: 327,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 82, 3, 0, 100, 70, 192], responsePrefix: <int>[111, 100, 82, 3],
              durationSeconds: 10, raw: "661;327;On;2F,64,52,03,00,64,46,C0;6F,64,52,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 662, positionId: 327,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 82, 0, 255], responsePrefix: <int>[111, 100, 82, 0],
              durationSeconds: 0, raw: "662;327;Off;2F,64,52,00,FF;6F,64,52,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 316, nameTextId: 106059,
      name: "Electric fuel pump",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 328, actuatorId: 316,
          titleTextId: 106059, title: "Electric fuel pump",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 663, positionId: 328,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 83, 0, 100, 50, 192], responsePrefix: <int>[111, 100, 83, 3],
              durationSeconds: 10, raw: "663;328;On;2F,64,53,00,64,32,C0;6F,64,53,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 664, positionId: 328,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 83, 0, 255], responsePrefix: <int>[111, 100, 83, 0],
              durationSeconds: 0, raw: "664;328;Off;2F,64,53,00,FF;6F,64,53,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 317, nameTextId: 106061,
      name: "Fan",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 329, actuatorId: 317,
          titleTextId: 106061, title: "Fan",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 665, positionId: 329,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 84, 3, 0, 100], responsePrefix: <int>[111, 100, 84, 3],
              durationSeconds: 10, raw: "665;329;On;2F,64,54,03,00,64;6F,64,54,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 666, positionId: 329,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 84, 0], responsePrefix: <int>[111, 100, 84, 0],
              durationSeconds: 0, raw: "666;329;Off;2F,64,54,00;6F,64,54,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 318, nameTextId: 106068,
      name: "Oxygen sensor heating",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 330, actuatorId: 318,
          titleTextId: 106062, title: "Oxygen sensor heating of cylinder bank 1",
          instructionTextId: 106064, instruction: "Activation for 60 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106064, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 667, positionId: 330,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 85, 3, 0, 2, 88, 0, 224], responsePrefix: <int>[111, 100, 85, 3],
              durationSeconds: 60, raw: "667;330;On;2F,64,55,03,00,02,58,00,E0;6F,64,55,03;60",
            ),
            RecoveredActuatorCommand(
              rowId: 668, positionId: 330,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 85, 0, 255], responsePrefix: <int>[111, 100, 85, 0],
              durationSeconds: 0, raw: "668;330;Off;2F,64,55,00,FF;6F,64,55,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
        RecoveredActuatorPosition(
          id: 350, actuatorId: 318,
          titleTextId: 106063, title: "Oxygen sensor heating of cylinder bank 2",
          instructionTextId: 106064, instruction: "Activation for 60 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106064, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 707, positionId: 350,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 85, 3, 1, 2, 88, 0, 224], responsePrefix: <int>[111, 100, 85, 3],
              durationSeconds: 60, raw: "707;350;On;2F,64,55,03,01,02,58,00,E0;6F,64,55,03;60",
            ),
            RecoveredActuatorCommand(
              rowId: 708, positionId: 350,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 85, 0, 255], responsePrefix: <int>[111, 100, 85, 0],
              durationSeconds: 0, raw: "708;350;Off;2F,64,55,00,FF;6F,64,55,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 319, nameTextId: 106069,
      name: "Coolant temperature warning light",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 331, actuatorId: 319,
          titleTextId: 106069, title: "Coolant temperature warning light",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 669, positionId: 331,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 86, 3, 0, 100], responsePrefix: <int>[111, 100, 86, 3],
              durationSeconds: 10, raw: "669;331;On;2F,64,56,03,00,64;6F,64,56,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 670, positionId: 331,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 86, 0], responsePrefix: <int>[111, 100, 86, 0],
              durationSeconds: 0, raw: "670;331;Off;2F,64,56,00;6F,64,56,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 320, nameTextId: 106066,
      name: "Engine warning light",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 332, actuatorId: 320,
          titleTextId: 106066, title: "Engine warning light",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 671, positionId: 332,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 87, 3, 0, 100], responsePrefix: <int>[111, 100, 87, 3],
              durationSeconds: 10, raw: "671;332;On;2F,64,57,03,00,64;6F,64,57,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 672, positionId: 332,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 87, 0], responsePrefix: <int>[111, 100, 87, 0],
              durationSeconds: 0, raw: "672;332;Off;2F,64,57,00;6F,64,57,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 321, nameTextId: 111419,
      name: "Exhaust flap servomotor",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 333, actuatorId: 321,
          titleTextId: 111419, title: "Exhaust flap servomotor",
          instructionTextId: 111420, instruction: "Activation for 3 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 111420, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 673, positionId: 333,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 88, 3, 0, 30, 70, 192], responsePrefix: <int>[111, 100, 88, 3],
              durationSeconds: 0, raw: "673;333;On;2F,64,58,03,00,1E,46,C0;6F,64,58,03;0",
            ),
            RecoveredActuatorCommand(
              rowId: 674, positionId: 333,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 88, 0, 255], responsePrefix: <int>[111, 100, 88, 0],
              durationSeconds: 0, raw: "674;333;Off;2F,64,58,00,FF;6F,64,58,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 325, nameTextId: 106067,
      name: "Throttle valve servomotor",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 337, actuatorId: 325,
          titleTextId: 106067, title: "Throttle valve servomotor",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 681, positionId: 337,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 92, 3, 0, 100, 0, 0, 16, 0, 0, 141, 185, 240], responsePrefix: <int>[111, 100, 92, 3],
              durationSeconds: 10, raw: "681;337;On;2F,64,5C,03,00,64,00,00,10,00,00,8D,B9,F0;6F,64,5C,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 682, positionId: 337,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 92, 0, 255], responsePrefix: <int>[111, 100, 92, 0],
              durationSeconds: 0, raw: "682;337;Off;2F,64,5C,00,FF;6F,64,5C,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
  ],
  "cuX_BMSO1": <RecoveredActuatorDefinition>[
    RecoveredActuatorDefinition(
      id: 347, nameTextId: 106070,
      name: "Fuel injector",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 361, actuatorId: 347,
          titleTextId: 106051, title: "Fuel injector 1",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 729, positionId: 361,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 80, 3, 0, 100, 0, 1, 192], responsePrefix: <int>[111, 100, 80, 3],
              durationSeconds: 10, raw: "729;361;On;2F,64,50,03,00,64,00,01,C0;6F,64,50,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 730, positionId: 361,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 80, 0], responsePrefix: <int>[111, 100, 80, 0],
              durationSeconds: 0, raw: "730;361;Off;2F,64,50,00;6F,64,50,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
        RecoveredActuatorPosition(
          id: 379, actuatorId: 347,
          titleTextId: 106054, title: "Fuel injector 2",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 765, positionId: 379,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 80, 3, 0, 100, 0, 2, 192], responsePrefix: <int>[111, 100, 80, 3],
              durationSeconds: 10, raw: "765;379;On;2F,64,50,03,00,64,00,02,C0;6F,64,50,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 766, positionId: 379,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 80, 0], responsePrefix: <int>[111, 100, 80, 0],
              durationSeconds: 0, raw: "766;379;Off;2F,64,50,00;6F,64,50,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 349, nameTextId: 111421,
      name: "Tank vent valve",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 363, actuatorId: 349,
          titleTextId: 111421, title: "Tank vent valve",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 733, positionId: 363,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 82, 3, 0, 100, 30, 192], responsePrefix: <int>[111, 100, 82, 3],
              durationSeconds: 10, raw: "733;363;On;2F,64,52,03,00,64,1E,C0;6F,64,52,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 734, positionId: 363,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 82, 0], responsePrefix: <int>[111, 100, 82, 0],
              durationSeconds: 0, raw: "734;363;Off;2F,64,52,00;6F,64,52,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 350, nameTextId: 106059,
      name: "Electric fuel pump",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 364, actuatorId: 350,
          titleTextId: 106059, title: "Electric fuel pump",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 735, positionId: 364,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 83, 3, 0, 100, 50, 192], responsePrefix: <int>[111, 100, 83, 3],
              durationSeconds: 10, raw: "735;364;On;2F,64,53,03,00,64,32,C0;6F,64,53,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 736, positionId: 364,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 83, 0], responsePrefix: <int>[111, 100, 83, 0],
              durationSeconds: 0, raw: "736;364;Off;2F,64,53,00;6F,64,53,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 351, nameTextId: 106061,
      name: "Fan",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 365, actuatorId: 351,
          titleTextId: 106061, title: "Fan",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 737, positionId: 365,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 84, 3, 0, 100], responsePrefix: <int>[111, 100, 84, 3],
              durationSeconds: 10, raw: "737;365;On;2F,64,54,03,00,64;6F,64,54,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 738, positionId: 365,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 84, 0], responsePrefix: <int>[111, 100, 84, 0],
              durationSeconds: 0, raw: "738;365;Off;2F,64,54,00;6F,64,54,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 353, nameTextId: 106069,
      name: "Coolant temperature warning light",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 367, actuatorId: 353,
          titleTextId: 106065, title: "Coolant temperature warning light (engine start)",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 741, positionId: 367,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 86, 3, 0, 100], responsePrefix: <int>[111, 100, 86, 3],
              durationSeconds: 10, raw: "741;367;On;2F,64,56,03,00,64;6F,64,56,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 742, positionId: 367,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 86, 0], responsePrefix: <int>[111, 100, 86, 0],
              durationSeconds: 0, raw: "742;367;Off;2F,64,56,00;6F,64,56,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 354, nameTextId: 106066,
      name: "Engine warning light",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 368, actuatorId: 354,
          titleTextId: 106066, title: "Engine warning light",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 743, positionId: 368,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 87, 3, 0, 100], responsePrefix: <int>[111, 100, 87, 3],
              durationSeconds: 10, raw: "743;368;On;2F,64,57,03,00,64;6F,64,57,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 744, positionId: 368,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 87, 0], responsePrefix: <int>[111, 100, 87, 0],
              durationSeconds: 0, raw: "744;368;Off;2F,64,57,00;6F,64,57,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 355, nameTextId: 111419,
      name: "Exhaust flap servomotor",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 369, actuatorId: 355,
          titleTextId: 111419, title: "Exhaust flap servomotor",
          instructionTextId: 111420, instruction: "Activation for 3 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 111420, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 745, positionId: 369,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 88, 3, 1, 0, 30, 70, 224], responsePrefix: <int>[111, 100, 88, 3],
              durationSeconds: 3, raw: "745;369;On;2F,64,58,03,01,00,1E,46,E0;6F,64,58,03;3",
            ),
            RecoveredActuatorCommand(
              rowId: 746, positionId: 369,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 88, 0], responsePrefix: <int>[111, 100, 88, 0],
              durationSeconds: 0, raw: "746;369;Off;2F,64,58,00;6F,64,58,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 358, nameTextId: 106067,
      name: "Throttle valve servomotor",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 372, actuatorId: 358,
          titleTextId: 106067, title: "Throttle valve servomotor",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 751, positionId: 372,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 92, 3, 0, 100, 0, 0, 16, 0, 0, 6, 141, 185, 240], responsePrefix: <int>[111, 100, 92, 3],
              durationSeconds: 10, raw: "751;372;On;2F,64,5C,03,00,64,00,00,10,00,00,06,8D,B9,F0;6F,64,5C,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 752, positionId: 372,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 92, 0], responsePrefix: <int>[111, 100, 92, 0],
              durationSeconds: 0, raw: "752;372;Off;2F,64,5C,00;6F,64,5C,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 363, nameTextId: 112550,
      name: "Switching cam adjuster",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 377, actuatorId: 363,
          titleTextId: 112551, title: "Switching cam adjuster 1 and 2 (start engine)",
          instructionTextId: 112552, instruction: "Activation for 20 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 112552, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 761, positionId: 377,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 100, 87, 3, 0, 100], responsePrefix: <int>[111, 100, 87, 3],
              durationSeconds: 20, raw: "761;377;On;2F,64,57,03,00,64;6F,64,57,03;20",
            ),
            RecoveredActuatorCommand(
              rowId: 762, positionId: 377,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 100, 87, 0], responsePrefix: <int>[111, 100, 87, 0],
              durationSeconds: 0, raw: "762;377;Off;2F,64,57,00;6F,64,57,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
  ],
  "cuX_BMSX": <RecoveredActuatorDefinition>[
    RecoveredActuatorDefinition(
      id: 1, nameTextId: 106070,
      name: "Fuel injector",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 1, actuatorId: 1,
          titleTextId: 106051, title: "Fuel injector 1",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 1, positionId: 1,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 98, 80, 3, 0, 100, 0, 1, 192], responsePrefix: <int>[111, 98, 80, 3],
              durationSeconds: 10, raw: "1;1;On;2F,62,50,03,00,64,00,01,C0;6F,62,50,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 2, positionId: 1,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 98, 80, 0, 255], responsePrefix: <int>[111, 98, 92, 0],
              durationSeconds: 0, raw: "2;1;Off;2F,62,50,00,FF;6F,62,5C,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
        RecoveredActuatorPosition(
          id: 16, actuatorId: 1,
          titleTextId: 106054, title: "Fuel injector 2",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 31, positionId: 16,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 98, 80, 3, 0, 100, 0, 2, 192], responsePrefix: <int>[111, 98, 80, 3],
              durationSeconds: 10, raw: "31;16;On;2F,62,50,03,00,64,00,02,C0;6F,62,50,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 32, positionId: 16,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 98, 80, 0, 255], responsePrefix: <int>[111, 98, 92, 0],
              durationSeconds: 0, raw: "32;16;Off;2F,62,50,00,FF;6F,62,5C,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
        RecoveredActuatorPosition(
          id: 17, actuatorId: 1,
          titleTextId: 106055, title: "Fuel injector 3",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 33, positionId: 17,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 98, 80, 3, 0, 100, 0, 4, 192], responsePrefix: <int>[111, 98, 80, 3],
              durationSeconds: 10, raw: "33;17;On;2F,62,50,03,00,64,00,04,C0;6F,62,50,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 34, positionId: 17,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 98, 80, 0, 255], responsePrefix: <int>[111, 98, 92, 0],
              durationSeconds: 0, raw: "34;17;Off;2F,62,50,00,FF;6F,62,5C,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
        RecoveredActuatorPosition(
          id: 18, actuatorId: 1,
          titleTextId: 106056, title: "Fuel injector 4",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 35, positionId: 18,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 98, 80, 3, 0, 100, 0, 8, 192], responsePrefix: <int>[111, 98, 80, 3],
              durationSeconds: 10, raw: "35;18;On;2F,62,50,03,00,64,00,08,C0;6F,62,50,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 36, positionId: 18,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 98, 80, 0, 255], responsePrefix: <int>[111, 98, 92, 0],
              durationSeconds: 0, raw: "36;18;Off;2F,62,50,00,FF;6F,62,5C,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
        RecoveredActuatorPosition(
          id: 19, actuatorId: 1,
          titleTextId: 106057, title: "Fuel injector 5",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 37, positionId: 19,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 98, 80, 3, 0, 100, 0, 16, 192], responsePrefix: <int>[111, 98, 80, 3],
              durationSeconds: 10, raw: "37;19;On;2F,62,50,03,00,64,00,10,C0;6F,62,50,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 38, positionId: 19,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 98, 80, 0, 255], responsePrefix: <int>[111, 98, 92, 0],
              durationSeconds: 0, raw: "38;19;Off;2F,62,50,00,FF;6F,62,5C,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
        RecoveredActuatorPosition(
          id: 20, actuatorId: 1,
          titleTextId: 106058, title: "Fuel injector 6",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 39, positionId: 20,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 98, 80, 3, 0, 100, 0, 32, 192], responsePrefix: <int>[111, 98, 80, 3],
              durationSeconds: 10, raw: "39;20;On;2F,62,50,03,00,64,00,20,C0;6F,62,50,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 40, positionId: 20,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 98, 80, 0, 255], responsePrefix: <int>[111, 98, 92, 0],
              durationSeconds: 0, raw: "40;20;Off;2F,62,50,00,FF;6F,62,5C,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 2, nameTextId: 106060,
      name: "Secondary-air valve",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 2, actuatorId: 2,
          titleTextId: 106060, title: "Secondary-air valve",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 3, positionId: 2,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 98, 81, 3, 0, 100], responsePrefix: <int>[111, 98, 92, 3],
              durationSeconds: 10, raw: "3;2;On;2F,62,51,03,00,64;6F,62,5C,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 4, positionId: 2,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 98, 81, 0], responsePrefix: <int>[111, 98, 92, 0],
              durationSeconds: 0, raw: "4;2;Off;2F,62,51,00;6F,62,5C,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 4, nameTextId: 106059,
      name: "Electric fuel pump",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 4, actuatorId: 4,
          titleTextId: 106059, title: "Electric fuel pump",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 7, positionId: 4,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 98, 83, 3, 0, 100, 80, 192], responsePrefix: <int>[111, 98, 92, 3],
              durationSeconds: 10, raw: "7;4;On;2F,62,53,03,00,64,50,C0;6F,62,5C,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 8, positionId: 4,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 98, 83, 0, 255], responsePrefix: <int>[111, 98, 92, 0],
              durationSeconds: 0, raw: "8;4;Off;2F,62,53,00,FF;6F,62,5C,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 5, nameTextId: 106061,
      name: "Fan",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 5, actuatorId: 5,
          titleTextId: 106061, title: "Fan",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 9, positionId: 5,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 98, 84, 3, 0, 100], responsePrefix: <int>[111, 98, 92, 3],
              durationSeconds: 10, raw: "9;5;On;2F,62,54,03,00,64;6F,62,5C,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 10, positionId: 5,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 98, 84, 0], responsePrefix: <int>[111, 98, 92, 0],
              durationSeconds: 0, raw: "10;5;Off;2F,62,54,00;6F,62,5C,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 6, nameTextId: 106068,
      name: "Oxygen sensor heating",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 6, actuatorId: 6,
          titleTextId: 106062, title: "Oxygen sensor heating of cylinder bank 1",
          instructionTextId: 106064, instruction: "Activation for 60 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106064, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 11, positionId: 6,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 98, 85, 3, 0, 2, 88, 0, 224], responsePrefix: <int>[111, 98, 92, 3],
              durationSeconds: 60, raw: "11;6;On;2F,62,55,03,00,02,58,00,E0;6F,62,5C,03;60",
            ),
            RecoveredActuatorCommand(
              rowId: 12, positionId: 6,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 98, 85, 0], responsePrefix: <int>[111, 98, 92, 0],
              durationSeconds: 0, raw: "12;6;Off;2F,62,55,00;6F,62,5C,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
        RecoveredActuatorPosition(
          id: 21, actuatorId: 6,
          titleTextId: 106063, title: "Oxygen sensor heating of cylinder bank 2",
          instructionTextId: 106064, instruction: "Activation for 60 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106064, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 41, positionId: 21,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 98, 85, 3, 1, 2, 88, 0, 224], responsePrefix: <int>[111, 98, 92, 3],
              durationSeconds: 60, raw: "41;21;On;2F,62,55,03,01,02,58,00,E0;6F,62,5C,03;60",
            ),
            RecoveredActuatorCommand(
              rowId: 42, positionId: 21,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 98, 85, 0], responsePrefix: <int>[111, 98, 92, 0],
              durationSeconds: 0, raw: "42;21;Off;2F,62,55,00;6F,62,5C,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 7, nameTextId: 106069,
      name: "Coolant temperature warning light",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 7, actuatorId: 7,
          titleTextId: 106065, title: "Coolant temperature warning light (engine start)",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 13, positionId: 7,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 98, 86, 3, 0, 0, 100], responsePrefix: <int>[111, 98, 92, 3],
              durationSeconds: 10, raw: "13;7;On;2F,62,56,03,00,00,64;6F,62,5C,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 14, positionId: 7,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 98, 86, 0], responsePrefix: <int>[111, 98, 92, 0],
              durationSeconds: 0, raw: "14;7;Off;2F,62,56,00;6F,62,5C,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 8, nameTextId: 106066,
      name: "Engine warning light",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 8, actuatorId: 8,
          titleTextId: 106066, title: "Engine warning light",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 15, positionId: 8,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 98, 87, 3, 0, 100], responsePrefix: <int>[111, 98, 87, 3],
              durationSeconds: 10, raw: "15;8;On;2F,62,57,03,00,64;6F,62,57,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 16, positionId: 8,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 98, 87, 0], responsePrefix: <int>[111, 98, 87, 0],
              durationSeconds: 0, raw: "16;8;Off;2F,62,57,00;6F,62,57,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
    RecoveredActuatorDefinition(
      id: 13, nameTextId: 106067,
      name: "Throttle valve servomotor",
      positions: <RecoveredActuatorPosition>[
        RecoveredActuatorPosition(
          id: 13, actuatorId: 13,
          titleTextId: 106067, title: "Throttle valve servomotor",
          instructionTextId: 106052, instruction: "Activation for 10 seconds",
          ignoredColumn4: 0, completionInstructionTextId: 106052, completionTextId: 106053, completion: "Activation finished",
          commands: <RecoveredActuatorCommand>[
            RecoveredActuatorCommand(
              rowId: 25, positionId: 13,
              action: RecoveredActuatorAction.on, actionLabel: "On",
              request: <int>[47, 98, 92, 3, 0, 100, 0, 0, 16, 0, 0, 6, 141, 185, 240], responsePrefix: <int>[111, 98, 92, 3],
              durationSeconds: 10, raw: "25;13;On;2F,62,5C,03,00,64,00,00,10,00,00,06,8D,B9,F0;6F,62,5C,03;10",
            ),
            RecoveredActuatorCommand(
              rowId: 26, positionId: 13,
              action: RecoveredActuatorAction.off, actionLabel: "Off",
              request: <int>[47, 98, 92, 0], responsePrefix: <int>[111, 98, 92, 0],
              durationSeconds: 0, raw: "26;13;Off;2F,62,5C,00;6F,62,5C,00;0",
            ),
          ],
          unsupportedReason: null,
        ),
      ],
    ),
  ],
};
// END GENERATED ACTUATOR CATALOG

class RecoveredActuatorExecutionException implements Exception {
  const RecoveredActuatorExecutionException({
    this.operationError,
    this.cleanupErrors = const [],
  });

  final Object? operationError;
  final List<Object> cleanupErrors;

  @override
  String toString() {
    final operation = operationError is RecoveredActuatorCancelledException
        ? operationError.toString()
        : 'Actuator operation failed: ${operationError ?? 'cleanup failed'}';
    return '$operation; cleanup errors: ${cleanupErrors.join(', ')}';
  }
}

class RecoveredActuatorCancelledException implements Exception {
  const RecoveredActuatorCancelledException();

  @override
  String toString() => 'Actuator test cancelled.';
}

/// Executes verified bi-directional actuator test sequences.
/// Every execution is bounded to the command's observed duration (maximum 60 s)
/// and issues Off in cleanup after the start/activation sequence was attempted.
class RecoveredActuatorExecutor {
  RecoveredActuatorExecutor({
    this.requestTimeout = const Duration(seconds: 3),
    this.maximumDuration = const Duration(seconds: 60),
    Future<void> Function(Duration)? wait,
  }) : _wait = wait ?? _defaultWait;

  static const int maximumObservedDurationSeconds = 60;
  static final _runQueue = _SerialActuatorRunQueue();
  final Duration requestTimeout;
  final Duration maximumDuration;
  final Future<void> Function(Duration) _wait;

  static Future<void> _defaultWait(Duration duration) =>
      Future<void>.delayed(duration);

  Future<void> run({
    required UdsRequestLink link,
    required RecoveredActuatorPosition position,
    Future<void>? cancellation,
  }) {
    final signal = cancellation == null
        ? null
        : _ActuatorCancellationSignal(cancellation);
    return _runQueue.run(
      () => _runUnlocked(
        link: link,
        position: position,
        cancellation: signal,
      ),
    );
  }

  Future<void> _runUnlocked({
    required UdsRequestLink link,
    required RecoveredActuatorPosition position,
    required _ActuatorCancellationSignal? cancellation,
  }) async {
    if (!position.isSupported) {
      throw StateError(position.unsupportedReason ?? 'Actuator is unsupported');
    }
    final activation = position.activation;
    final stop = position.off;
    if (activation == null || stop == null) {
      throw StateError('Actuator requires an activation and an Off command');
    }
    if (activation.durationSeconds < 0 ||
        activation.durationSeconds > maximumObservedDurationSeconds ||
        Duration(seconds: activation.durationSeconds) > maximumDuration) {
      throw RangeError.range(
        activation.durationSeconds,
        0,
        maximumDuration.inSeconds,
        'durationSeconds',
      );
    }

    Object? operationError;
    final cleanupErrors = <Object>[];
    var cleanupRequired = false;
    try {
      await cancellation?.throwIfCancelled();
      final start = position.start;
      if (start != null) {
        // A timed-out start request may still have reached the ECU.
        cleanupRequired = true;
        await _send(link, start);
        await cancellation?.throwIfCancelled();
      }
      await cancellation?.throwIfCancelled();
      // A timed-out activation request may still have reached the ECU.
      cleanupRequired = true;
      await _send(link, activation);
      await cancellation?.throwIfCancelled();
      await _waitOrCancel(
        Duration(seconds: activation.durationSeconds),
        cancellation,
      );
      // The wait and cancellation can resolve in the same microtask turn.
      // Preserve cancellation even if the ordinary wait wins Future.any.
      await cancellation?.throwIfCancelled();
    } catch (error) {
      operationError = error;
    }

    if (cleanupRequired) {
      try {
        await _send(link, stop);
      } catch (error) {
        cleanupErrors.add(error);
      }

      final end = position.end;
      if (end != null) {
        try {
          await _send(link, end);
        } catch (error) {
          cleanupErrors.add(error);
        }
      }
    }

    if (operationError != null || cleanupErrors.isNotEmpty) {
      if (operationError is RecoveredActuatorCancelledException &&
          cleanupErrors.isEmpty) {
        throw operationError;
      }
      throw RecoveredActuatorExecutionException(
        operationError: operationError,
        cleanupErrors: List.unmodifiable(cleanupErrors),
      );
    }
  }

  Future<void> _waitOrCancel(
    Duration duration,
    _ActuatorCancellationSignal? cancellation,
  ) {
    if (cancellation == null) return _wait(duration);
    return Future.any<void>([
      _wait(duration),
      cancellation.whenCancelled.then<void>(
        (_) => throw const RecoveredActuatorCancelledException(),
      ),
    ]);
  }

  Future<void> _send(
    UdsRequestLink link,
    RecoveredActuatorCommand command,
  ) async {
    if (command.request.isEmpty) {
      throw FormatException('Actuator command ${command.rowId} has no request');
    }
    final response = await link.request(
      command.request,
      timeout: requestTimeout,
    );
    final decoded = UdsResponse.decode(
      response,
      requestService: command.request.first,
    );
    if (decoded is UdsNegativeResponse) {
      throw UdsNegativeResponseException(decoded);
    }
  }
}

class _ActuatorCancellationSignal {
  _ActuatorCancellationSignal(Future<void> source) {
    source.then<void>(
      (_) => _complete(),
      onError: (Object _, StackTrace __) => _complete(),
    );
  }

  final _completed = Completer<void>();

  bool get isCancelled => _completed.isCompleted;
  Future<void> get whenCancelled => _completed.future;

  Future<void> throwIfCancelled() async {
    if (!isCancelled) await Future<void>.value();
    if (isCancelled) throw const RecoveredActuatorCancelledException();
  }

  void _complete() {
    if (!_completed.isCompleted) _completed.complete();
  }
}

/// Serializes actuator sequences so separate panel instances cannot interleave
/// On/Off traffic on the one active motorcycle diagnostic bus.
class _SerialActuatorRunQueue {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() operation) {
    final previous = _tail;
    final release = Completer<void>();
    _tail = release.future;
    return _runAfter(previous, release, operation);
  }

  Future<T> _runAfter<T>(
    Future<void> previous,
    Completer<void> release,
    Future<T> Function() operation,
  ) async {
    await previous;
    try {
      return await operation();
    } finally {
      release.complete();
    }
  }
}
