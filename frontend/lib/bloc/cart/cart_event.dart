import 'package:equatable/equatable.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class CartLoadRequested extends CartEvent {}

class CartItemAdded extends CartEvent {
  final String productId;
  final int quantity;

  const CartItemAdded(this.productId, {this.quantity = 1});

  @override
  List<Object?> get props => [productId, quantity];
}

class CartQuantityChanged extends CartEvent {
  final String productId;
  final int quantity;

  const CartQuantityChanged(this.productId, this.quantity);

  @override
  List<Object?> get props => [productId, quantity];
}

class CartItemRemoved extends CartEvent {
  final String productId;

  const CartItemRemoved(this.productId);

  @override
  List<Object?> get props => [productId];
}

class CartCleared extends CartEvent {}
