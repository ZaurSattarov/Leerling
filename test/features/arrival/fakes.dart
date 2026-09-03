import 'dart:async';

import 'package:leerling_app/core/services/arrival_repository.dart';
import 'package:leerling_app/models/arrival_location.dart';
import 'package:leerling_app/models/arrival_session.dart';
import 'package:leerling_app/models/arrival_settings_info.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Test-fake voor ArrivalRepository -- laat tests de "servertoestand"
/// scripten (welke sessie/locatie een verse SELECT teruggeeft) en Realtime-
/// events handmatig triggeren, zonder een echte Supabase-verbinding.
class FakeArrivalRepository implements ArrivalRepository {
  /// lessonId -> sessie die een verse fetchSessionForLesson teruggeeft.
  final Map<String, ArrivalSession?> sessionsByLesson = {};

  /// sessionId -> locatie die een verse fetchLocation teruggeeft.
  final Map<String, ArrivalLocation?> locationsBySession = {};

  /// lessonId -> settings die een verse fetchArrivalSettings teruggeeft.
  final Map<String, ArrivalSettingsInfo> settingsByLesson = {};

  Object? sessionFetchError;
  Object? locationFetchError;
  Object? settingsFetchError;

  int fetchSessionCalls = 0;
  int fetchLocationCalls = 0;
  int fetchSettingsCalls = 0;
  final List<String> subscribedSessionLessonIds = [];
  final List<String> subscribedLocationSessionIds = [];
  final List<String> removedChannelNames = [];

  final Map<String, void Function()> _sessionCallbacks = {};
  final Map<String, void Function()> _locationCallbacks = {};

  void stuurSessionEvent(String lessonId) => _sessionCallbacks[lessonId]?.call();
  void stuurLocationEvent(String sessionId) =>
      _locationCallbacks[sessionId]?.call();

  @override
  Future<ArrivalSession?> fetchSessionForLesson(String lessonId) async {
    fetchSessionCalls++;
    if (sessionFetchError != null) throw sessionFetchError!;
    return sessionsByLesson[lessonId];
  }

  @override
  Future<ArrivalLocation?> fetchLocation(String sessionId) async {
    fetchLocationCalls++;
    if (locationFetchError != null) throw locationFetchError!;
    return locationsBySession[sessionId];
  }

  @override
  Future<ArrivalSettingsInfo> fetchArrivalSettings(String lessonId) async {
    fetchSettingsCalls++;
    if (settingsFetchError != null) throw settingsFetchError!;
    return settingsByLesson[lessonId] ?? ArrivalSettingsInfo.nietBeschikbaar;
  }

  @override
  RealtimeChannel subscribeSession(
    String lessonId,
    void Function() onChange,
  ) {
    subscribedSessionLessonIds.add(lessonId);
    _sessionCallbacks[lessonId] = onChange;
    return _FakeRealtimeChannel('session_$lessonId');
  }

  @override
  RealtimeChannel subscribeLocation(
    String sessionId,
    void Function() onChange,
  ) {
    subscribedLocationSessionIds.add(sessionId);
    _locationCallbacks[sessionId] = onChange;
    return _FakeRealtimeChannel('location_$sessionId');
  }

  @override
  Future<void> removeChannel(RealtimeChannel channel) async {
    removedChannelNames.add((channel as _FakeRealtimeChannel).naam);
  }
}

/// Minimale stand-in -- de echte RealtimeChannel-constructor vereist een
/// live SupabaseClient/socket, dus in tests wordt uitsluitend tegen de
/// [ArrivalRepository]-interface geprogrammeerd, nooit tegen een concreet
/// kanaalobject.
class _FakeRealtimeChannel implements RealtimeChannel {
  _FakeRealtimeChannel(this.naam);
  final String naam;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
