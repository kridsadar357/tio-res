import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/buffet_tier.dart';
import '../../services/database_helper.dart';
import '../../widgets/premium_scaffold.dart';
import '../../widgets/premium_toast.dart';
import '../../utils/currency_helper.dart';
import '../../l10n/app_localizations.dart';

class BuffetTierScreen extends StatefulWidget {
  const BuffetTierScreen({super.key});

  @override
  State<BuffetTierScreen> createState() => _BuffetTierScreenState();
}

class _BuffetTierScreenState extends State<BuffetTierScreen> {
  List<BuffetTier> _tiers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTiers();
  }

  Future<void> _loadTiers() async {
    setState(() => _isLoading = true);
    final maps = await DatabaseHelper().getAllBuffetTiers();
    setState(() {
      _tiers = maps.map((m) => BuffetTier.fromMap(m)).toList();
      _isLoading = false;
    });
  }

  Future<void> _showTierDialog({BuffetTier? tier}) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: tier?.name ?? '');
    final priceController = TextEditingController(
      text: tier?.price.toStringAsFixed(2) ?? '',
    );
    final descController = TextEditingController(text: tier?.description ?? '');
    bool isActive = tier?.isActive ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF252836),
          title: Text(
            tier == null ? l10n.addBuffetTier : l10n.editBuffetTier,
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(l10n.nameLabel),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(l10n.price,
                      prefix: '${CurrencyHelper.symbol(context)} '),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(l10n.descriptionOptional),
                  maxLines: 2,
                ),
                SizedBox(height: 16.h),
                SwitchListTile(
                  title: Text(l10n.activeStatus,
                      style: const TextStyle(color: Colors.white)),
                  value: isActive,
                  activeThumbColor: Theme.of(context).primaryColor,
                  onChanged: (val) => setDialogState(() => isActive = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel,
                  style: const TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  PremiumToast.show(context, l10n.nameRequired, isError: true);
                  return;
                }
                final price = double.tryParse(priceController.text) ?? 0;
                final data = {
                  'name': nameController.text,
                  'price': price,
                  'description':
                      descController.text.isEmpty ? null : descController.text,
                  'is_active': isActive ? 1 : 0,
                };
                if (tier == null) {
                  await DatabaseHelper().addBuffetTier(data);
                } else {
                  await DatabaseHelper().updateBuffetTier(tier.id!, data);
                }
                if (context.mounted) Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      _loadTiers();
      if (mounted) {
        PremiumToast.show(
            context, tier == null ? l10n.tierAdded : l10n.tierUpdated);
      }
    }
  }

  Future<void> _deleteTier(BuffetTier tier) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252836),
        title:
            Text(l10n.deleteTier, style: const TextStyle(color: Colors.white)),
        content: Text(
          '${l10n.deleteTier} "${tier.name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel,
                style: const TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete,
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseHelper().deleteBuffetTier(tier.id!);
      _loadTiers();
      if (mounted) PremiumToast.show(context, l10n.tierDeleted);
    }
  }

  InputDecoration _inputDecoration(String label, {String? prefix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixText: prefix,
      prefixStyle: const TextStyle(color: Colors.white),
      filled: true,
      fillColor: const Color(0xFF1A1F2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PremiumScaffold(
      header: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Text(
              l10n.buffetTiersTitle,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(l10n.addBuffetTier),
              onPressed: () => _showTierDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tiers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_offer_outlined,
                          size: 64.sp, color: Colors.white12),
                      SizedBox(height: 16.h),
                      Text(l10n.noBuffetTiers,
                          style: TextStyle(
                              fontSize: 16.sp, color: Colors.white38)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(24.w),
                  itemCount: _tiers.length,
                  itemBuilder: (context, index) {
                    final tier = _tiers[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16.w),
                        leading: Container(
                          width: 50.w,
                          height: 50.w,
                          decoration: BoxDecoration(
                            color: tier.isActive
                                ? Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.2)
                                : Colors.grey.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.local_offer,
                              color: tier.isActive
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                              size: 24.sp,
                            ),
                          ),
                        ),
                        title: Text(
                          tier.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp,
                            color:
                                tier.isActive ? Colors.white : Colors.white38,
                            decoration: tier.isActive
                                ? null
                                : TextDecoration.lineThrough,
                          ),
                        ),
                        subtitle: tier.description != null
                            ? Text(tier.description!,
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 12.sp))
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              CurrencyHelper.format(context, tier.price),
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Colors.blueAccent),
                              onPressed: () => _showTierDialog(tier: tier),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.redAccent),
                              onPressed: () => _deleteTier(tier),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
