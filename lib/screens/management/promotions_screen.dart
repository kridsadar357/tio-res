import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/promotion.dart';
import '../../services/database_helper.dart';
import '../../widgets/premium_scaffold.dart';
import '../../widgets/premium_toast.dart';
import '../../utils/currency_helper.dart';
import '../../l10n/app_localizations.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  List<Promotion> _promotions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    setState(() => _isLoading = true);
    final maps = await DatabaseHelper().getAllPromotions();
    setState(() {
      _promotions = maps.map((m) => Promotion.fromMap(m)).toList();
      _isLoading = false;
    });
  }

  Future<void> _showPromotionDialog({Promotion? promotion}) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: promotion?.name ?? '');
    final valueController = TextEditingController(
      text: promotion?.discountValue.toString() ?? '',
    );
    String discountType = promotion?.discountType ?? 'PERCENT';
    bool isActive = promotion?.isActive ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF252836),
          title: Text(
            promotion == null ? l10n.addPromotion : l10n.editPromotion,
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: valueController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(l10n.discountValue),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1F2C),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: DropdownButton<String>(
                        value: discountType,
                        dropdownColor: const Color(0xFF252836),
                        style: const TextStyle(color: Colors.white),
                        underline: const SizedBox(),
                        items: [
                          const DropdownMenuItem(
                              value: 'PERCENT', child: Text('%')),
                          DropdownMenuItem(
                              value: 'FIXED',
                              child: Text(CurrencyHelper.symbol(context))),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => discountType = val);
                          }
                        },
                      ),
                    ),
                  ],
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
                final value = double.tryParse(valueController.text) ?? 0;
                final data = {
                  'name': nameController.text,
                  'discount_type': discountType,
                  'discount_value': value,
                  'is_active': isActive ? 1 : 0,
                };
                if (promotion == null) {
                  await DatabaseHelper().addPromotion(data);
                } else {
                  await DatabaseHelper().updatePromotion(promotion.id!, data);
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
      _loadPromotions();
      if (mounted) {
        PremiumToast.show(context,
            promotion == null ? l10n.promotionAdded : l10n.promotionUpdated);
      }
    }
  }

  Future<void> _deletePromotion(Promotion promotion) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252836),
        title: Text(l10n.deletePromotion,
            style: const TextStyle(color: Colors.white)),
        content: Text('${l10n.delete} "${promotion.name}"?',
            style: const TextStyle(color: Colors.white70)),
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
      await DatabaseHelper().deletePromotion(promotion.id!);
      _loadPromotions();
      if (mounted) PremiumToast.show(context, l10n.promotionDeleted);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
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
              l10n.promotionsTitle,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(l10n.addPromotion),
              onPressed: () => _showPromotionDialog(),
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
          : _promotions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.discount_outlined,
                          size: 64.sp, color: Colors.white12),
                      SizedBox(height: 16.h),
                      Text(l10n.noPromotionsFound,
                          style: TextStyle(
                              fontSize: 16.sp, color: Colors.white38)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(24.w),
                  itemCount: _promotions.length,
                  itemBuilder: (context, index) {
                    final promo = _promotions[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: promo.isCurrentlyValid
                              ? const Color(0xFF00E096).withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16.w),
                        leading: Container(
                          width: 50.w,
                          height: 50.w,
                          decoration: BoxDecoration(
                            color: promo.isActive
                                ? const Color(0xFF00E096).withValues(alpha: 0.2)
                                : Colors.grey.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.discount,
                              color: promo.isActive
                                  ? const Color(0xFF00E096)
                                  : Colors.grey,
                              size: 24.sp,
                            ),
                          ),
                        ),
                        title: Text(
                          promo.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                            color:
                                promo.isActive ? Colors.white : Colors.white38,
                            decoration: promo.isActive
                                ? null
                                : TextDecoration.lineThrough,
                          ),
                        ),
                        subtitle: Text(
                          promo.isCurrentlyValid
                              ? l10n.activeStatus
                              : l10n.inactiveStatus,
                          style: TextStyle(
                            color: promo.isCurrentlyValid
                                ? const Color(0xFF00E096)
                                : Colors.white38,
                            fontSize: 12.sp,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                promo.discountType == 'PERCENT'
                                    ? '${promo.discountValue.toStringAsFixed(0)}%'
                                    : CurrencyHelper.format(
                                        context, promo.discountValue),
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.sp,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Colors.blueAccent),
                              onPressed: () =>
                                  _showPromotionDialog(promotion: promo),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.redAccent),
                              onPressed: () => _deletePromotion(promo),
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
