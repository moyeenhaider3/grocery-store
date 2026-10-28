import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/cart/cart_bloc.dart';
import '../../../bloc/cart/cart_event.dart';
import '../../../bloc/cart/cart_state.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/money.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/status_colors.dart';
import '../../../models/cart_model.dart';
import '../../../models/order_model.dart';
import '../../../repositories/order_repository.dart';
import '../../components/app_snack.dart';
import '../../components/confirm_dialog.dart';
import '../../components/empty_state.dart';
import '../../components/loading_skeleton.dart';
import '../../components/page_container.dart';
import '../../components/page_header.dart';
import '../../components/price_text.dart';
import '../../components/product_thumbnail.dart';
import '../../components/section_card.dart';
import '../../components/status_banner.dart';
import '../../components/step_indicator.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullName;
  final _phone = TextEditingController();
  final _addressLine = TextEditingController();
  final _city = TextEditingController();
  final _postalCode = TextEditingController();
  String _paymentMethod = 'COD';
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    _fullName = TextEditingController(
      text: context.read<AuthBloc>().state.user?.name ?? '',
    );
    // Fresh flags whenever the screen opens.
    context.read<CartBloc>().add(CartLoadRequested());
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _addressLine.dispose();
    _city.dispose();
    _postalCode.dispose();
    super.dispose();
  }

  String? _lengthBetween(String? v, int min, int max, String message) {
    final len = (v ?? '').trim().length;
    return len < min || len > max ? message : null;
  }

  String? _validatePhone(String? v) {
    final cleaned = (v ?? '').replaceAll(RegExp(r'[\s-]'), '');
    return RegExp(r'^\+?[0-9]{10,13}$').hasMatch(cleaned)
        ? null
        : 'Enter a valid phone number';
  }

  Future<void> _place() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_paymentMethod == 'MOCK_PAY') {
      final ok = await showConfirmDialog(
        context,
        title: 'Demo payment',
        message: 'This is a demo payment. No money is charged.',
        confirmLabel: 'Pay',
        cancelLabel: 'Cancel',
      );
      if (!ok || !mounted) return;
    }
    setState(() => _placing = true);
    try {
      final order = await sl<OrderRepository>().placeOrder(
        address: ShippingAddress(
          fullName: _fullName.text.trim(),
          phone: _phone.text.replaceAll(RegExp(r'[\s-]'), ''),
          addressLine: _addressLine.text.trim(),
          city: _city.text.trim(),
          postalCode: _postalCode.text.trim(),
        ),
        paymentMethod: _paymentMethod,
      );
      if (!mounted) return;
      // The server cart is now empty; reload so the badge drops to 0.
      context.read<CartBloc>().add(CartLoadRequested());
      context.go('/orders/${order.id}?placed=1');
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode != 401) showAppSnack(context, e.message, error: true);
      if (e.code == 'INSUFFICIENT_STOCK' ||
          e.code == 'ITEM_UNAVAILABLE' ||
          e.code == 'CART_EMPTY') {
        context.read<CartBloc>().add(CartLoadRequested());
      }
    } catch (_) {
      // Timeout or network error: the order may already exist, so do not offer a blind retry.
      if (mounted) {
        context.read<CartBloc>().add(CartLoadRequested());
        showAppSnack(
          context,
          'Could not confirm your order. Check My orders before trying again.',
          error: true,
        );
        context.go('/orders');
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  Widget _addressFields() {
    final fullName = TextFormField(
      controller: _fullName,
      decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline_rounded)),
      validator: (v) => _lengthBetween(v, 2, 80, 'Enter your full name'),
    );
    final phone = TextFormField(
      controller: _phone,
      keyboardType: TextInputType.phone,
      decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)),
      validator: _validatePhone,
    );
    final address = TextFormField(
      controller: _addressLine,
      decoration: const InputDecoration(labelText: 'Address line', prefixIcon: Icon(Icons.home_outlined)),
      validator: (v) => _lengthBetween(v, 5, 200, 'Enter your address'),
    );
    final city = TextFormField(
      controller: _city,
      decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city_outlined)),
      validator: (v) => _lengthBetween(v, 2, 60, 'Enter your city'),
    );
    final pin = TextFormField(
      controller: _postalCode,
      keyboardType: TextInputType.number,
      maxLength: 6,
      decoration: const InputDecoration(
        labelText: 'PIN code',
        counterText: '',
        prefixIcon: Icon(Icons.markunread_mailbox_outlined),
      ),
      validator: (v) => RegExp(r'^[1-9][0-9]{5}$').hasMatch((v ?? '').trim())
          ? null
          : 'Enter a valid 6-digit PIN code',
    );
    const gap = SizedBox(width: AppSpacing.md, height: AppSpacing.lg);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: fullName),
                  gap,
                  Expanded(child: phone),
                ],
              ),
              gap,
              address,
              gap,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: city),
                  gap,
                  Expanded(child: pin),
                ],
              ),
            ],
          );
        }
        return Column(
          children: [fullName, gap, phone, gap, address, gap, city, gap, pin],
        );
      },
    );
  }

  Widget _paymentCard(
    String value,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = _paymentMethod == value;
    return AnimatedContainer(
      duration: AppMotion.base,
      curve: AppMotion.ease,
      decoration: BoxDecoration(
        color: selected ? scheme.surfaceContainerLow : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: RadioListTile<String>(
          value: value,
          controlAffinity: ListTileControlAffinity.trailing,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          title: Text(title, style: theme.textTheme.titleSmall),
          subtitle: Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          secondary: AnimatedContainer(
            duration: AppMotion.base,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: selected ? scheme.primary : scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 22, color: selected ? scheme.onPrimary : scheme.onSurface),
          ),
        ),
      ),
    );
  }

  Widget _paymentOptions() {
    return RadioGroup<String>(
      groupValue: _paymentMethod,
      onChanged: (v) {
        if (v != null && !_placing) setState(() => _paymentMethod = v);
      },
      child: Column(
        children: [
          _paymentCard(
            'COD',
            Icons.payments_outlined,
            'Cash on Delivery',
            'Pay when the order arrives',
          ),
          const SizedBox(height: AppSpacing.md),
          _paymentCard(
            'MOCK_PAY',
            Icons.credit_card_rounded,
            'Pay now',
            'Demo payment, no money is charged',
          ),
        ],
      ),
    );
  }

  Widget _placeButton(CartModel cart) {
    final canPlace = !_placing && !cart.hasIssues;
    return FilledButton(
      style: FilledButton.styleFrom(minimumSize: const Size(64, AppSizes.buttonHeightLarge)),
      onPressed: canPlace ? _place : null,
      child: _placing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              _paymentMethod == 'MOCK_PAY'
                  ? 'Pay ${formatPaise(cart.subtotal)} and place order'
                  : 'Place order',
            ),
    );
  }

  Widget _summary(CartModel cart, {required bool showButton}) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Order summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in cart.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  ProductThumbnail(name: item.name, imageUrl: item.imageUrl, size: 44),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      '${item.name} × ${item.quantity}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  PriceText(item.lineTotal, size: PriceSize.sm),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text('Total', style: theme.textTheme.titleMedium),
              ),
              PriceText(cart.subtotal, size: PriceSize.lg),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Final total is confirmed by the server when you place the order.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (showButton) ...[
            const SizedBox(height: AppSpacing.lg),
            _placeButton(cart),
          ],
        ],
      ),
    );
  }

  Widget _body(BuildContext context, CartState state) {
    final cart = state.cart;
    if (cart.items.isEmpty) {
      if (state.status == CartStatus.initial ||
          state.status == CartStatus.loading) {
        return const PageContainer(child: ListSkeleton(rows: 3));
      }
      return PageContainer(
        child: EmptyState(
          icon: Icons.shopping_bag_outlined,
          title: 'Your cart is empty',
          action: FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Continue shopping'),
          ),
        ),
      );
    }
    final danger = StatusColors.of(context).danger;
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepIndicator(current: 1),
        SizedBox(height: context.isPhone ? AppSpacing.xl : AppSpacing.xxl),
        const PageHeader(title: 'Checkout', subtitle: 'Where should we deliver, and how would you like to pay?'),
        if (cart.hasIssues) ...[
          StatusBanner(
            tone: danger,
            icon: Icons.warning_amber_rounded,
            action: OutlinedButton(
              onPressed: () => context.go('/cart'),
              child: const Text('Back to cart'),
            ),
            child: const Text('Some items in your cart need attention.'),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
    final form = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(step: 1, title: 'Shipping address', child: _addressFields()),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(step: 2, title: 'Payment', child: _paymentOptions()),
        ],
      ),
    );

    if (context.isDesktop) {
      return PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: form),
                const SizedBox(width: AppSpacing.xxl),
                SizedBox(width: 400, child: _summary(cart, showButton: true)),
              ],
            ),
          ],
        ),
      );
    }
    if (!context.isPhone) {
      return PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            form,
            const SizedBox(height: AppSpacing.lg),
            _summary(cart, showButton: true),
          ],
        ),
      );
    }
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: PageContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                form,
                const SizedBox(height: AppSpacing.lg),
                _summary(cart, showButton: false),
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
            boxShadow: AppShadows.bar(theme.brightness),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      PriceText(cart.subtotal, size: PriceSize.lg),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: _placeButton(cart)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(builder: _body);
  }
}
