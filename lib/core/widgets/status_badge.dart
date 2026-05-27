import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum StatusType {
  hospitalized,
  inConsultation,
  discharged,
  emergency,
  waiting,
}

class StatusBadge extends StatelessWidget {
  final StatusType status;
  final double fontSize;

  const StatusBadge({
    Key? key,
    required this.status,
    this.fontSize = 12,
  }) : super(key: key);

  Map<StatusType, Map<String, Color>> get _statusStyles => {
    StatusType.hospitalized: {
      'bg': AppColors.primaryLight,
      'text': AppColors.primary,
    },
    StatusType.inConsultation: {
      'bg': AppColors.successBg,
      'text': AppColors.success,
    },
    StatusType.discharged: {
      'bg': AppColors.neutralBg,
      'text': AppColors.neutral,
    },
    StatusType.emergency: {
      'bg': AppColors.dangerBg,
      'text': AppColors.danger,
    },
    StatusType.waiting: {
      'bg': AppColors.warningBg,
      'text': AppColors.warning,
    },
  };

  Map<StatusType, String> get _statusLabels => {
    StatusType.hospitalized: 'Hospitalizado',
    StatusType.inConsultation: 'En consulta',
    StatusType.discharged: 'Alta médica',
    StatusType.emergency: 'Urgencias',
    StatusType.waiting: 'En espera',
  };

  @override
  Widget build(BuildContext context) {
    final styles = _statusStyles[status]!;
    final label = _statusLabels[status]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: styles['bg'],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: styles['text'],
        ),
      ),
    );
  }
}
