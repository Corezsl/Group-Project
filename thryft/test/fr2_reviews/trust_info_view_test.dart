import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:thryft/providers/notification_provider.dart';
import 'package:thryft/providers/search_provider.dart';
import 'package:thryft/providers/cart_provider.dart';
import 'package:thryft/screens/user_profile_screen.dart';
import '../helpers/mock_supabase.dart';

// Instead of talking to the real internet or waiting for a real database, 
// these 'Fake' classes just pretend to run the database queries so the app doesn't crash. 
// They safely intercept the chain of commands and immediately hand over the ready-made data we give them.

// This intercepts the `.eq()` command for single items (like a user profile)
// and gets ready to hand over our completely hard-coded Map.
class FakeFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final Map<String, dynamic>? data;
  FakeFilterBuilder(this.data);
  @override
  FakeFilterBuilder eq(String column, Object value) => this;
  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() =>
      FakeTransformBuilder(data);
}

// This is the end of the line for single-item queries. 
// It actually hands the mock data back to the app as if it just downloaded it.
class FakeTransformBuilder extends Fake
    implements PostgrestTransformBuilder<Map<String, dynamic>?> {
  final Map<String, dynamic>? data;
  FakeTransformBuilder(this.data);
  @override
  Future<U> then<U>(
    FutureOr<U> Function(Map<String, dynamic>?) onValue, {
    Function? onError,
  }) =>
      Future<Map<String, dynamic>?>.value(data).then(onValue, onError: onError);
}

// This pretends to handle commands like `.eq()`, `.filter()`, and `.order()` 
// for lists (like a list of products or ratings) just to keep the program running happily.
class FakeListFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>> data;
  FakeListFilterBuilder(this.data);
  @override
  FakeListFilterBuilder eq(String column, Object value) => this;
  @override
  FakeListFilterBuilder filter(String column, String operator, Object? value) =>
      this;
  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) => FakeListTransformBuilder(data);
  @override
  Future<U> then<U>(
    FutureOr<U> Function(List<Map<String, dynamic>>) onValue, {
    Function? onError,
  }) => Future<List<Map<String, dynamic>>>.value(
    data,
  ).then(onValue, onError: onError);
}

// This is the end of the line for list queries. 
// It hands our hard-coded lists of data back to the app as if they just downloaded.
class FakeListTransformBuilder extends Fake
    implements PostgrestTransformBuilder<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>> data;
  FakeListTransformBuilder(this.data);
  @override
  Future<U> then<U>(
    FutureOr<U> Function(List<Map<String, dynamic>>) onValue, {
    Function? onError,
  }) => Future<List<Map<String, dynamic>>>.value(
    data,
  ).then(onValue, onError: onError);
}