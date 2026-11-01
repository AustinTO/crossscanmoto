import 'package:flutter/material.dart';

/// Supported BMW Motorrad actuator and component output tests.
enum ActuatorTestType {
  fuelPump,
  coolingFan,
  clusterSweep,
  exhaustFlap,
  absValve,
  esaStepper,
  lightsCheck,
}

/// Description and control parameters for an actuator test.
class ActuatorTestDefinition {
  const ActuatorTestDefinition({
    required this.type,
    required this.name,
    required this.ecuAcronym,
    required this.ecuAddress,
    required this.description,
    required this.warning,
    required this.durationSeconds,
    required this.icon,
  });

  final ActuatorTestType type;
  final String name;
  final String ecuAcronym;
  final int ecuAddress;
  final String description;
  final String warning;
  final int durationSeconds;
  final IconData icon;
}

/// Engine managing execution of BMW Motorrad actuator component tests.
class BmwActuatorManager {
  const BmwActuatorManager._();

  static const tests = <ActuatorTestDefinition>[
    ActuatorTestDefinition(
      type: ActuatorTestType.fuelPump,
      name: 'Fuel Pump Relay Test',
      ecuAcronym: 'DME',
      ecuAddress: 0x12,
      description:
          'Energizes the electronic fuel pump relay for 5 seconds to test fuel delivery line pressurization.',
      warning: 'Ensure fuel tank has fuel and fuel lines are connected securely.',
      durationSeconds: 5,
      icon: Icons.local_gas_station_outlined,
    ),
    ActuatorTestDefinition(
      type: ActuatorTestType.coolingFan,
      name: 'Engine Radiator Cooling Fan Test',
      ecuAcronym: 'DME',
      ecuAddress: 0x12,
      description:
          'Spins the radiator electric fan at 50% PWM speed, then ramps to 100% speed.',
      warning: 'Keep hands and loose cables clear of the cooling fan blades.',
      durationSeconds: 6,
      icon: Icons.toys_outlined,
    ),
    ActuatorTestDefinition(
      type: ActuatorTestType.clusterSweep,
      name: 'Instrument Cluster Gauge & TFT Test',
      ecuAcronym: 'KOMBI',
      ecuAddress: 0x60,
      description:
          'Performs a full dial needle sweep, activates all warning LEDs (ABS, MIL, Triangle, Oil) and tests LCD segments.',
      warning: 'Verify all warning lights illuminate clearly on the cockpit.',
      durationSeconds: 4,
      icon: Icons.speed,
    ),
    ActuatorTestDefinition(
      type: ActuatorTestType.exhaustFlap,
      name: 'Exhaust Flap Actuator Cycle',
      ecuAcronym: 'DME',
      ecuAddress: 0x12,
      description:
          'Commands the exhaust flap servomotor to fully open, fully close, and return to default idle position.',
      warning: 'Listen for mechanical binding, squeaking or cable friction.',
      durationSeconds: 6,
      icon: Icons.compare_arrows_outlined,
    ),
    ActuatorTestDefinition(
      type: ActuatorTestType.absValve,
      name: 'ABS Hydraulic Valve & Pump Pulsation',
      ecuAcronym: 'ABS',
      ecuAddress: 0x28,
      description:
          'Pulses front and rear ABS modulator solenoid valves and runs return pump briefly.',
      warning: 'Do not squeeze brake levers during active valve pulsation.',
      durationSeconds: 5,
      icon: Icons.alt_route_outlined,
    ),
    ActuatorTestDefinition(
      type: ActuatorTestType.esaStepper,
      name: 'Dynamic ESA Preload Travel Test',
      ecuAcronym: 'SAF',
      ecuAddress: 0x58,
      description:
          'Steps the hydraulic rear spring preload collar from minimum rider-only height to maximum 2-up luggage height.',
      warning: 'Bike must be placed on center stand before initiating preload test.',
      durationSeconds: 8,
      icon: Icons.unfold_more,
    ),
    ActuatorTestDefinition(
      type: ActuatorTestType.lightsCheck,
      name: 'Lighting, Turn Signal & Horn Test',
      ecuAcronym: 'ZFE',
      ecuAddress: 0x00,
      description:
          'Sequentially toggles left indicator, right indicator, high beam flasher, brake lamp and emits brief horn pulse.',
      warning: 'Horn will emit a brief acoustic signal.',
      durationSeconds: 6,
      icon: Icons.lightbulb_outline,
    ),
  ];
}
