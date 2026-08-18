import 'dart:convert';

import 'package:crowdin_sdk/src/crowdin_storage.dart';
import 'package:crowdin_sdk/src/exceptions/crowdin_exceptions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CrowdinStorage', () {
    late CrowdinStorage crowdinStorage;
    late SharedPreferences sharedPrefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sharedPrefs = await SharedPreferences.getInstance();
      crowdinStorage = CrowdinStorage();
      await crowdinStorage.init();
    });

    tearDown(() async {
      await sharedPrefs.clear();
    });

    test('set and get translation timestamp', () async {
      const int timestamp = 123456;
      await crowdinStorage.setTranslationTimeStamp(timestamp);
      final int? retrievedTimestamp = crowdinStorage.getTranslationTimestamp();
      expect(retrievedTimestamp, equals(timestamp));
    });

    test('use fallback value for null translation timestamp', () async {
      await crowdinStorage.setTranslationTimeStamp(null);

      expect(crowdinStorage.getTranslationTimestamp(), equals(1));
    });

    test('replace an existing translation timestamp', () async {
      await crowdinStorage.setTranslationTimeStamp(123456);
      await crowdinStorage.setTranslationTimeStamp(654321);

      expect(crowdinStorage.getTranslationTimestamp(), equals(654321));
    });

    test('set and get distribution', () async {
      const String distributionJson =
          '{"@@locale": "en_US", "hello_world": "Hello, world!"}';
      final Map<String, dynamic> expectedDistribution =
          jsonDecode(distributionJson);

      await crowdinStorage.setDistribution(distributionJson);

      final Map<String, dynamic>? retrievedDistribution =
          crowdinStorage.getTranslation(const Locale('en', 'US'));

      expect(retrievedDistribution, equals(expectedDistribution));
    });

    test('replace an existing distribution', () async {
      const String initialDistribution =
          '{"@@locale": "en_US", "hello_world": "Hello, world!"}';
      const String replacementDistribution =
          '{"@@locale": "es_ES", "hello_world": "Hola, mundo!"}';

      await crowdinStorage.setDistribution(initialDistribution);
      await crowdinStorage.setDistribution(replacementDistribution);

      expect(
        crowdinStorage.getTranslation(const Locale('en', 'US')),
        isNull,
      );
      expect(
        crowdinStorage.getTranslation(const Locale('es', 'ES')),
        equals(jsonDecode(replacementDistribution)),
      );
    });

    test('get exception in case of empty distribution ', () async {
      await crowdinStorage.setDistribution('');

      expect(
        () => crowdinStorage.getTranslation(const Locale('en', 'US')),
        throwsA(const TypeMatcher<CrowdinException>()),
      );
    });

    test('get exception in case of malformed distribution', () async {
      await crowdinStorage.setDistribution('{not-json}');

      expect(
        () => crowdinStorage.getTranslation(const Locale('en', 'US')),
        throwsA(const TypeMatcher<CrowdinException>()),
      );
    });

    test('get null if timestamp is missed', () async {
      final int? retrievedTimestamp = crowdinStorage.getTranslationTimestamp();

      expect(retrievedTimestamp, isNull);
    });

    test('get null if distribution is missed', () async {
      final Map<String, dynamic>? retrievedDistribution =
          crowdinStorage.getTranslation(const Locale('en', 'US'));

      expect(retrievedDistribution, isNull);
    });

    test('get null if distribution locale mismatched', () async {
      const String distributionJson =
          '{"@@locale": "en_US", "hello_world": "Hello, world!"}';
      await crowdinStorage.setDistribution(distributionJson);

      final Map<String, dynamic>? retrievedDistribution =
          crowdinStorage.getTranslation(const Locale('es', 'ES'));

      expect(retrievedDistribution, isNull);
    });

    test('set and get permanent pause state', () {
      crowdinStorage.setIsPausedPermanently(true);
      expect(crowdinStorage.getIsPausedPermanently(), isTrue);

      crowdinStorage.setIsPausedPermanently(false);
      expect(crowdinStorage.getIsPausedPermanently(), isFalse);
    });

    test('get null if permanent pause state is missed', () {
      expect(crowdinStorage.getIsPausedPermanently(), isNull);
    });

    test('set and get error map', () {
      const Map<String, int> errorMap = {
        'network': 2,
        'distribution': 1,
      };

      crowdinStorage.setErrorMap(errorMap);

      expect(crowdinStorage.getErrorMap(), equals(errorMap));
    });

    test('get null if error map is missed', () {
      expect(crowdinStorage.getErrorMap(), isNull);
    });

    test('get null if error map is malformed', () async {
      await sharedPrefs.setString('errorMap', '{not-json}');

      expect(crowdinStorage.getErrorMap(), isNull);
    });
  });

  group('CrowdinStorage before initialization', () {
    late CrowdinStorage crowdinStorage;

    setUp(() {
      crowdinStorage = CrowdinStorage();
    });

    test('wrap timestamp storage errors', () async {
      expect(
        () => crowdinStorage.setTranslationTimeStamp(123456),
        throwsA(const TypeMatcher<CrowdinException>()),
      );
    });

    test('wrap timestamp read errors', () {
      expect(
        crowdinStorage.getTranslationTimestamp,
        throwsA(const TypeMatcher<CrowdinException>()),
      );
    });

    test('wrap distribution storage errors', () async {
      expect(
        () => crowdinStorage.setDistribution('{}'),
        throwsA(const TypeMatcher<CrowdinException>()),
      );
    });

    test('wrap distribution read errors', () {
      expect(
        () => crowdinStorage.getTranslation(const Locale('en', 'US')),
        throwsA(const TypeMatcher<CrowdinException>()),
      );
    });

    test('wrap permanent pause storage errors', () {
      expect(
        () => crowdinStorage.setIsPausedPermanently(true),
        throwsA(const TypeMatcher<CrowdinException>()),
      );
    });

    test('wrap permanent pause read errors', () {
      expect(
        crowdinStorage.getIsPausedPermanently,
        throwsA(const TypeMatcher<CrowdinException>()),
      );
    });

    test('return null when error map cannot be read', () {
      expect(crowdinStorage.getErrorMap(), isNull);
    });
  });
}
