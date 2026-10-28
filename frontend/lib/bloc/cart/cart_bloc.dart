import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/api_client.dart';
import '../../models/cart_model.dart';
import '../../repositories/cart_repository.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository cartRepository;

  CartBloc({required this.cartRepository}) : super(const CartState()) {
    // Sequential, so rapid taps cannot interleave.
    on<CartEvent>(
      _onEvent,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
  }

  Future<void> _onEvent(CartEvent event, Emitter<CartState> emit) async {
    if (event is CartLoadRequested) return _load(emit);
    if (event is CartItemAdded) {
      return _mutate(
        emit,
        event.productId,
        () => cartRepository.addItem(event.productId, quantity: event.quantity),
        'Added to cart',
      );
    }
    if (event is CartQuantityChanged) {
      return _mutate(
        emit,
        event.productId,
        () => cartRepository.updateQuantity(event.productId, event.quantity),
        null,
      );
    }
    if (event is CartItemRemoved) {
      return _mutate(
        emit,
        event.productId,
        () => cartRepository.removeItem(event.productId),
        'Removed from cart',
      );
    }
    if (event is CartCleared) {
      emit(const CartState());
    }
  }

  Future<void> _load(Emitter<CartState> emit) async {
    emit(state.copyWith(status: CartStatus.loading));
    try {
      final cart = await cartRepository.getCart();
      emit(state.copyWith(status: CartStatus.ready, cart: cart));
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: CartStatus.error,
          message: e.isUnauthorized ? null : e.message,
          messageIsError: true,
          messageSeq: e.isUnauthorized ? null : state.messageSeq + 1,
        ),
      );
    }
  }

  Future<void> _mutate(
    Emitter<CartState> emit,
    String productId,
    Future<CartModel> Function() action,
    String? successMessage,
  ) async {
    emit(state.copyWith(busyProductId: productId));
    try {
      final cart = await action();
      emit(
        state.copyWith(
          status: CartStatus.ready,
          cart: cart,
          message: successMessage,
          messageSeq: successMessage == null ? null : state.messageSeq + 1,
        ),
      );
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        emit(state.copyWith());
        return;
      }
      emit(
        state.copyWith(
          message: e.message,
          messageIsError: true,
          messageSeq: state.messageSeq + 1,
        ),
      );
      if (e.statusCode == 404 || e.statusCode == 409) {
        try {
          final cart = await cartRepository.getCart();
          emit(state.copyWith(cart: cart));
        } on ApiException {
          // keep the old cart; the error message above is already shown
        }
      }
    }
  }
}
