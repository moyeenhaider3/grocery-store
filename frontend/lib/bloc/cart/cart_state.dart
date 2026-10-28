import 'package:equatable/equatable.dart';

import '../../models/cart_model.dart';

enum CartStatus { initial, loading, ready, error }

class CartState extends Equatable {
  final CartStatus status;
  final CartModel cart;
  final String? busyProductId;
  final String? message;
  final bool messageIsError;
  final int messageSeq;

  const CartState({
    this.status = CartStatus.initial,
    this.cart = const CartModel.empty(),
    this.busyProductId,
    this.message,
    this.messageIsError = false,
    this.messageSeq = 0,
  });

  /// busyProductId and message are cleared unless explicitly passed.
  CartState copyWith({
    CartStatus? status,
    CartModel? cart,
    String? busyProductId,
    String? message,
    bool messageIsError = false,
    int? messageSeq,
  }) => CartState(
    status: status ?? this.status,
    cart: cart ?? this.cart,
    busyProductId: busyProductId,
    message: message,
    messageIsError: messageIsError,
    messageSeq: messageSeq ?? this.messageSeq,
  );

  @override
  List<Object?> get props => [
    status,
    cart,
    busyProductId,
    message,
    messageIsError,
    messageSeq,
  ];
}
