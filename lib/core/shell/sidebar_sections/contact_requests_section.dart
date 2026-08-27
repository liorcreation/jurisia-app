import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/contact_professional/domain/entities/contact_request.dart';
import '../../../features/contact_professional/domain/entities/professional_category.dart';
import '../../../features/contact_professional/presentation/controllers/contact_professional_controller.dart';
import '../../../theme/app_theme.dart';
import '../app_shell.dart';
import 'sidebar_section_scaffold.dart';

/// Section contextuelle « Mes demandes » — les demandes de mise en relation
/// envoyées, avec leur statut de prise en charge.
class ContactRequestsSection extends StatelessWidget {
  const ContactRequestsSection({super.key});

  static const int _maxItems = 6;

  Color _statusColor(ContactRequestStatus status) {
    switch (status) {
      case ContactRequestStatus.pending:
        return AppColors.warning;
      case ContactRequestStatus.contacted:
        return AppColors.info;
      case ContactRequestStatus.closed:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final requests = context.watch<ContactProfessionalController>().requests;

    return SidebarSection(
      title: 'Mes demandes',
      children: [
        if (requests.isEmpty)
          const SidebarSectionEmpty('Vos demandes de mise en relation apparaîtront ici.')
        else
          for (final request in requests.take(_maxItems))
            SidebarSectionTile(
              icon: Icons.assignment_ind_outlined,
              title: request.category.label,
              subtitle: request.status.label,
              trailing: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _statusColor(request.status),
                ),
              ),
              onTap: () => AppShellScope.of(context).selectModule(4),
            ),
      ],
    );
  }
}
