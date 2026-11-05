import 'package:flutter/material.dart';
import 'package:photography_flutter_application/models/booking_list_model.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:photography_flutter_application/services/repos/bookingListRepo.dart';

enum LoadState { idle, loading, ready, error }

enum BookingFilter {
  needsAction('Needs action'),
  confirmed('Confirmed'),
  completed('Completed'),
  closed('Declined or cancelled'),
  all('All');

  const BookingFilter(this.label);
  final String label;

  bool test(BookingList b) => switch (this) {
    BookingFilter.needsAction => b.status == BookingStatus.pending,
    BookingFilter.confirmed => b.status == BookingStatus.confirmed,
    BookingFilter.completed => b.status == BookingStatus.completed,
    BookingFilter.closed =>
      b.status == BookingStatus.declined || b.status == BookingStatus.cancelled,
    BookingFilter.all => true,
  };
}

/// What the view shows after an action:a snackbar message and whether it worked.
class ActionResult {
  final bool ok;
  final String message;
  const ActionResult.ok(this.message) : ok = true;
  const ActionResult.fail(this.message) : ok = false;
}

class BookingsViewModel extends ChangeNotifier {
  BookingsViewModel({BookingRepository? repository})
    : _repo = repository ?? BookingRepository();

  final BookingRepository _repo;

  List<BookingList> _bookings = const [];
  LoadState _state = LoadState.idle;
  String? _error;
  BookingFilter _filter = BookingFilter.needsAction;
  String _query = '';
  final Set<String> _busy = {};

  RealtimeChannel? _channel;
  Timer? _debounce;
  bool _disposed = false;

  //Read-only state for the view

  LoadState get state => _state;
  String? get error => _error;
  BookingFilter get filter => _filter;
  String get query => _query;
  List<BookingList> get allBookings => List.unmodifiable(_bookings);
  bool isBusy(String id) => _busy.contains(id);

  int countFor(BookingFilter f) => _bookings.where(f.test).length;

  BookingList? bookingById(String id) {
    for (final b in _bookings) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// The list the screen draws: filtered, searched and sorted for the way
  /// each tab is used (oldest request first, soonest event first, newest history first).
  List<BookingList> get visible {
    final list = _bookings
        .where((b) => _filter.test(b) && b.matches(_query))
        .toList();
    switch (_filter) {
      case BookingFilter.needsAction:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;

      case BookingFilter.confirmed:
        list.sort(
          (a, b) => (a.firstStart ?? a.createdAt).compareTo(
            b.firstStart ?? b.createdAt,
          ),
        );
        break;

      default:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return list;
  }

  //loading and refreshing the list of bookings from the server.
  //The [silent] parameter allows the current list to remain on screen while
  //a refresh occurs in the background, preventing UI flicker and providing a smoother user experience.

  /// [silent] keeps the current list on screen while refreshing.
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _state = LoadState.loading;
      _error = null;
      notifyListeners();
    }
    try {
      _bookings = await _repo.fetchAll();
      _state = LoadState.ready;
      _error = null;
    } catch (e) {
      if (!silent || _bookings.isEmpty) {
        _state = LoadState.error;
        _error = _describe(e);
      }
    }
    notifyListeners();
  }

  /// This function listens for new requests and status changes
  void startListening() {
    if (_channel != null) return;
    _channel = _repo.listen(() {
      _debounce?.cancel();
      _debounce = Timer(
        const Duration(milliseconds: 600),
        () => load(silent: true),
      );
    });
  }

  //This filter and search is applied to the list of bookings before it is shown on screen.
  void setFilter(BookingFilter f) {
    if (f == _filter) return;
    _filter = f;
    notifyListeners();
  }

  void setQuery(String q) {
    if (q == _query) return;
    _query = q;
    notifyListeners();
  }

  //These are actions

  Future<ActionResult> confirm(BookingList b) {
    if (!b.canConfirm) {
      return Future.value(
        const ActionResult.fail('This booking can\'t be confirmed.'),
      );
    }
    return _transition(
      b,
      BookingStatus.confirmed,
      done: '${b.displayName}\'s booking is confirmed.',
    );
  }

  Future<ActionResult> decline(BookingList b, {String? reason}) {
    if (!b.canDecline) {
      return Future.value(
        const ActionResult.fail('This booking can\'t be declined.'),
      );
    }
    return _transition(
      b,
      BookingStatus.declined,
      reason: reason,
      done: 'Declined. The slots are open again.',
    );
  }

  Future<ActionResult> cancel(BookingList b, {String? reason}) {
    if (!b.canCancel) {
      return Future.value(
        const ActionResult.fail('This booking can\'t be cancelled.'),
      );
    }
    return _transition(
      b,
      BookingStatus.cancelled,
      reason: reason,
      done: 'Cancelled. The slots are open again.',
    );
  }

  Future<ActionResult> complete(BookingList b) {
    if (!b.canComplete) {
      return Future.value(
        const ActionResult.fail(
          'A booking can be completed once its event has started.',
        ),
      );
    }
    return _transition(
      b,
      BookingStatus.completed,
      done: 'Marked as completed.',
    );
  }

  Future<ActionResult> _transition(
    BookingList b,
    BookingStatus target, {
    String? reason,
    required String done,
  }) async {
    if (_busy.contains(b.id)) {
      return const ActionResult.fail('Still updating this booking.');
    }
    _busy.add(b.id);
    notifyListeners();

    final trimmed = reason?.trim();
    try {
      await _repo.setStatus(
        b.id,
        target,
        reason: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      );
      _replace(await _repo.fetchOne(b.id));
      return ActionResult.ok(done);
    } on PostgrestException catch (e) {
      // Someone else may have changed it, or the slot was lost. Show the truth.
      unawaited(load(silent: true));
      return ActionResult.fail(e.message);
    } catch (e) {
      return ActionResult.fail(_describe(e));
    } finally {
      _busy.remove(b.id);
      notifyListeners();
    }
  }

  void _replace(BookingList fresh) {
    _bookings = [for (final b in _bookings) b.id == fresh.id ? fresh : b];
  }

  String _describe(Object e) =>
      e is PostgrestException ? e.message : e.toString();

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    final ch = _channel;
    if (ch != null) unawaited(_repo.stopListening(ch));
    super.dispose();
  }
}
