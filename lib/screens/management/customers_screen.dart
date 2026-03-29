import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/customer.dart';
import '../../services/database_helper.dart';
import '../../widgets/premium_scaffold.dart';
import '../../widgets/premium_toast.dart';
import '../../l10n/app_localizations.dart';

import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class CustomersScreen extends StatefulWidget {
  final bool isSelectionMode;
  final void Function(Customer)? onSelect;

  const CustomersScreen({
    super.key,
    this.isSelectionMode = false,
    this.onSelect,
  });

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Customer> _customers = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const int _limit = 20;
  int _offset = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadCustomers(isRefresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _loadCustomers();
    }
  }

  Future<void> _loadCustomers({bool isRefresh = false, String? query}) async {
    if (isRefresh) {
      setState(() {
        _isLoading = true;
        _offset = 0;
        _hasMore = true;
        _customers = [];
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    final searchQuery = query ?? _searchController.text;

    final maps = searchQuery.isNotEmpty
        ? await DatabaseHelper()
            .searchCustomers(searchQuery, limit: _limit, offset: _offset)
        : await DatabaseHelper()
            .getAllCustomers(limit: _limit, offset: _offset);

    final newCustomers = maps.map((m) => Customer.fromMap(m)).toList();

    setState(() {
      if (isRefresh) {
        _customers = newCustomers;
      } else {
        _customers.addAll(newCustomers);
      }

      _offset += newCustomers.length;
      _hasMore = newCustomers.length == _limit;
      _isLoading = false;
      _isLoadingMore = false;
    });
  }

  Future<void> _showCustomerDialog({Customer? customer}) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: customer?.name ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final emailController = TextEditingController(text: customer?.email ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
          title: Text(
          customer == null ? l10n.addCustomer : l10n.editCustomer,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: _inputDecoration(l10n.nameLabel),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: phoneController,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration(l10n.phoneLabel),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: emailController,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(l10n.emailLabel),
                ),
              ],
            ),
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
              final data = {
                'name': nameController.text,
                'phone':
                    phoneController.text.isEmpty ? null : phoneController.text,
                'email':
                    emailController.text.isEmpty ? null : emailController.text,
                'points': customer?.points ?? 0,
                'created_at': customer?.createdAt ??
                    DateTime.now().millisecondsSinceEpoch,
              };
              if (customer == null) {
                await DatabaseHelper().addCustomer(data);
              } else {
                await DatabaseHelper().updateCustomer(customer.id!, data);
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
    );

    if (result == true) {
      _loadCustomers(isRefresh: true);
      if (mounted) {
        PremiumToast.show(context,
            customer == null ? l10n.customerAdded : l10n.customerUpdated);
      }
    }
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text(l10n.deleteCustomer,
            style: const TextStyle(color: Colors.white)),
        content: Text('${l10n.deleteCustomer} "${customer.name}"?',
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
      await DatabaseHelper().deleteCustomer(customer.id!);
      _loadCustomers(isRefresh: true);
      if (mounted) PremiumToast.show(context, l10n.customerDeleted);
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

  Future<void> _showPointsRuleDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final controller =
        TextEditingController(text: settings.pointsPerBaht.toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text(l10n.loyaltyPointsRule,
            style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.loyaltyPointsRulePrompt,
              style: const TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(l10n.bahtAmount),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel,
                style: const TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = int.tryParse(controller.text) ?? 100;
              await settings.setPointsPerBaht(val);
              if (context.mounted) Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      PremiumToast.show(context, l10n.pointsRuleUpdated);
    }
  }

  void _handleCustomerTap(Customer customer) {
    if (widget.isSelectionMode) {
      widget.onSelect?.call(customer);
      Navigator.pop(context);
    } else {
      // In normal mode, show edit dialog or do nothing?
      // Current implementation shows edit dialog on edit button click.
      // Maybe on tap we can show details or edit?
      // For now let's just show edit dialog for consistency or keep it enabled only on edit icon.
      // But user might expect tap to do something.
      // Let's make tap open edit dialog in normal mode.
      _showCustomerDialog(customer: customer);
    }
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
              widget.isSelectionMode
                  ? l10n.selectCustomer
                  : l10n.customersTitle,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 24.w),
            // Search
            Expanded(
              child: Container(
                height: 44.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: Colors.white, fontSize: 14.sp),
                  decoration: InputDecoration(
                    hintText: l10n.searchCustomerHint,
                    hintStyle:
                        TextStyle(color: Colors.white38, fontSize: 14.sp),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  onChanged: (value) =>
                      _loadCustomers(isRefresh: true, query: value),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            if (!widget.isSelectionMode)
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                tooltip: "Points Rule",
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                onPressed: _showPointsRuleDialog,
              ),
            if (!widget.isSelectionMode) SizedBox(width: 16.w),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: Text(l10n.addCustomer),
              onPressed: () => _showCustomerDialog(),
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
          : _customers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64.sp, color: Colors.white12),
                      SizedBox(height: 16.h),
                      Text(l10n.noCustomersFound,
                          style: TextStyle(
                              fontSize: 16.sp, color: Colors.white38)),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(24.w),
                  itemCount: _customers.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _customers.length) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }
                    final customer = _customers[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                            color: widget.isSelectionMode
                                ? Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: ListTile(
                        onTap: () => _handleCustomerTap(customer),
                        contentPadding: EdgeInsets.all(16.w),
                        leading: CircleAvatar(
                          radius: 25.r,
                          backgroundColor: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.2),
                          child: Text(
                            customer.name.isNotEmpty
                                ? customer.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20.sp,
                            ),
                          ),
                        ),
                        title: Text(
                          customer.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (customer.phone != null)
                              Text(customer.phone!,
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 12.sp)),
                            if (customer.email != null)
                              Text(customer.email!,
                                  style: TextStyle(
                                      color: Colors.white38, fontSize: 12.sp)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E096)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                '${customer.points} pts',
                                style: TextStyle(
                                  color: const Color(0xFF00E096),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                            if (!widget.isSelectionMode) ...[
                              SizedBox(width: 12.w),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blueAccent),
                                onPressed: () =>
                                    _showCustomerDialog(customer: customer),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () => _deleteCustomer(customer),
                              ),
                            ] else ...[
                              SizedBox(width: 12.w),
                              const Icon(Icons.chevron_right,
                                  color: Colors.white54),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
