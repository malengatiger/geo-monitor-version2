// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Data represents the last {count} days`
  String dashboardSubTitle(int count) {
    final NumberFormat countNumberFormat =
        NumberFormat.decimalPattern(Intl.getCurrentLocale());
    final String countString = countNumberFormat.format(count);

    return Intl.message(
      'Data represents the last $countString days',
      name: 'dashboardSubTitle',
      desc: '',
      args: [countString],
    );
  }

  /// `Activities in the last {count} hours`
  String activityTitle(int count) {
    final NumberFormat countNumberFormat =
        NumberFormat.decimalPattern(Intl.getCurrentLocale());
    final String countString = countNumberFormat.format(count);

    return Intl.message(
      'Activities in the last $countString hours',
      name: 'activityTitle',
      desc: '',
      args: [countString],
    );
  }

  /// `Organization Dashboard`
  String get organizationDashboard {
    return Intl.message(
      'Organization Dashboard',
      name: 'organizationDashboard',
      desc: '',
      args: [],
    );
  }

  /// `Project Dashboard`
  String get projectDashboard {
    return Intl.message(
      'Project Dashboard',
      name: 'projectDashboard',
      desc: '',
      args: [],
    );
  }

  /// `Project Locations Map`
  String get projectLocationsMap {
    return Intl.message(
      'Project Locations Map',
      name: 'projectLocationsMap',
      desc: '',
      args: [],
    );
  }

  /// `Refresh Project Dashboard Data`
  String get refreshProjectDashboardData {
    return Intl.message(
      'Refresh Project Dashboard Data',
      name: 'refreshProjectDashboardData',
      desc: '',
      args: [],
    );
  }

  /// `Photos, Videos and Audio Clips`
  String get photosVideosAudioClips {
    return Intl.message(
      'Photos, Videos and Audio Clips',
      name: 'photosVideosAudioClips',
      desc: '',
      args: [],
    );
  }

  /// `Photos`
  String get photos {
    return Intl.message(
      'Photos',
      name: 'photos',
      desc: '',
      args: [],
    );
  }

  /// `Videos`
  String get videos {
    return Intl.message(
      'Videos',
      name: 'videos',
      desc: '',
      args: [],
    );
  }

  /// `Audio Clips`
  String get audioClips {
    return Intl.message(
      'Audio Clips',
      name: 'audioClips',
      desc: '',
      args: [],
    );
  }

  /// `Add Project Locations`
  String get addProjectLocations {
    return Intl.message(
      'Add Project Locations',
      name: 'addProjectLocations',
      desc: '',
      args: [],
    );
  }

  /// `Add Project Areas`
  String get addProjectAreas {
    return Intl.message(
      'Add Project Areas',
      name: 'addProjectAreas',
      desc: '',
      args: [],
    );
  }

  /// `Edit Project`
  String get editProject {
    return Intl.message(
      'Edit Project',
      name: 'editProject',
      desc: '',
      args: [],
    );
  }

  /// `Directions to Project`
  String get directionsToProject {
    return Intl.message(
      'Directions to Project',
      name: 'directionsToProject',
      desc: '',
      args: [],
    );
  }

  /// `Add Project Location Here`
  String get addProjectLocationHere {
    return Intl.message(
      'Add Project Location Here',
      name: 'addProjectLocationHere',
      desc: '',
      args: [],
    );
  }

  /// `Organization Members`
  String get organizationMembers {
    return Intl.message(
      'Organization Members',
      name: 'organizationMembers',
      desc: '',
      args: [],
    );
  }

  /// `Organization Projects`
  String get organizationProjects {
    return Intl.message(
      'Organization Projects',
      name: 'organizationProjects',
      desc: '',
      args: [],
    );
  }

  /// `Register Organization`
  String get registerOrganization {
    return Intl.message(
      'Register Organization',
      name: 'registerOrganization',
      desc: '',
      args: [],
    );
  }

  /// `New Member`
  String get newMember {
    return Intl.message(
      'New Member',
      name: 'newMember',
      desc: '',
      args: [],
    );
  }

  /// `Edit Member`
  String get editMember {
    return Intl.message(
      'Edit Member',
      name: 'editMember',
      desc: '',
      args: [],
    );
  }

  /// `Administrators & Members`
  String get administratorsMembers {
    return Intl.message(
      'Administrators & Members',
      name: 'administratorsMembers',
      desc: '',
      args: [],
    );
  }

  /// `Tap for Color Scheme`
  String get tapForColorScheme {
    return Intl.message(
      'Tap for Color Scheme',
      name: 'tapForColorScheme',
      desc: '',
      args: [],
    );
  }

  /// `The Field Monitor members that are working with projects must follow the limits described below when they are making photos, videos and audio clips`
  String get fieldMonitorInstruction {
    return Intl.message(
      'The Field Monitor members that are working with projects must follow the limits described below when they are making photos, videos and audio clips',
      name: 'fieldMonitorInstruction',
      desc: '',
      args: [],
    );
  }

  /// `Maximum Monitoring Distance in metres`
  String get maximumMonitoringDistance {
    return Intl.message(
      'Maximum Monitoring Distance in metres',
      name: 'maximumMonitoringDistance',
      desc: '',
      args: [],
    );
  }

  /// `Maximum Video Length in seconds`
  String get maximumVideoLength {
    return Intl.message(
      'Maximum Video Length in seconds',
      name: 'maximumVideoLength',
      desc: '',
      args: [],
    );
  }

  /// `Maximum Audio Length in minutes`
  String get maximumAudioLength {
    return Intl.message(
      'Maximum Audio Length in minutes',
      name: 'maximumAudioLength',
      desc: '',
      args: [],
    );
  }

  /// `Activity Stream in hours`
  String get activityStreamHours {
    return Intl.message(
      'Activity Stream in hours',
      name: 'activityStreamHours',
      desc: '',
      args: [],
    );
  }

  /// `Number of days for Dashboard data`
  String get numberOfDaysForDashboardData {
    return Intl.message(
      'Number of days for Dashboard data',
      name: 'numberOfDaysForDashboardData',
      desc: '',
      args: [],
    );
  }

  /// `Select size of photos`
  String get selectSizePhotos {
    return Intl.message(
      'Select size of photos',
      name: 'selectSizePhotos',
      desc: '',
      args: [],
    );
  }

  /// `Select project only if these settings are for a single project, otherwise the settings are for the entire organization`
  String get selectProjectIfNecessary {
    return Intl.message(
      'Select project only if these settings are for a single project, otherwise the settings are for the entire organization',
      name: 'selectProjectIfNecessary',
      desc: '',
      args: [],
    );
  }

  /// `Project Name`
  String get projectName {
    return Intl.message(
      'Project Name',
      name: 'projectName',
      desc: '',
      args: [],
    );
  }

  /// `Description of the Project`
  String get descriptionOfProject {
    return Intl.message(
      'Description of the Project',
      name: 'descriptionOfProject',
      desc: '',
      args: [],
    );
  }

  /// `Submit Project`
  String get submitProject {
    return Intl.message(
      'Submit Project',
      name: 'submitProject',
      desc: '',
      args: [],
    );
  }

  /// `Request Member Location`
  String get requestMemberLocation {
    return Intl.message(
      'Request Member Location',
      name: 'requestMemberLocation',
      desc: '',
      args: [],
    );
  }

  /// `Projects`
  String get projects {
    return Intl.message(
      'Projects',
      name: 'projects',
      desc: '',
      args: [],
    );
  }

  /// `Members`
  String get members {
    return Intl.message(
      'Members',
      name: 'members',
      desc: '',
      args: [],
    );
  }

  /// `Locations`
  String get locations {
    return Intl.message(
      'Locations',
      name: 'locations',
      desc: '',
      args: [],
    );
  }

  /// `Schedules`
  String get schedules {
    return Intl.message(
      'Schedules',
      name: 'schedules',
      desc: '',
      args: [],
    );
  }

  /// `January`
  String get january {
    return Intl.message(
      'January',
      name: 'january',
      desc: '',
      args: [],
    );
  }

  /// `February`
  String get february {
    return Intl.message(
      'February',
      name: 'february',
      desc: '',
      args: [],
    );
  }

  /// `March`
  String get march {
    return Intl.message(
      'March',
      name: 'march',
      desc: '',
      args: [],
    );
  }

  /// `April`
  String get april {
    return Intl.message(
      'April',
      name: 'april',
      desc: '',
      args: [],
    );
  }

  /// `May`
  String get may {
    return Intl.message(
      'May',
      name: 'may',
      desc: '',
      args: [],
    );
  }

  /// `June`
  String get june {
    return Intl.message(
      'June',
      name: 'june',
      desc: '',
      args: [],
    );
  }

  /// `July`
  String get july {
    return Intl.message(
      'July',
      name: 'july',
      desc: '',
      args: [],
    );
  }

  /// `August`
  String get august {
    return Intl.message(
      'August',
      name: 'august',
      desc: '',
      args: [],
    );
  }

  /// `September`
  String get september {
    return Intl.message(
      'September',
      name: 'september',
      desc: '',
      args: [],
    );
  }

  /// `October`
  String get october {
    return Intl.message(
      'October',
      name: 'october',
      desc: '',
      args: [],
    );
  }

  /// `November`
  String get november {
    return Intl.message(
      'November',
      name: 'november',
      desc: '',
      args: [],
    );
  }

  /// `December`
  String get december {
    return Intl.message(
      'December',
      name: 'december',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
      desc: '',
      args: [],
    );
  }

  /// `Call Member`
  String get callMember {
    return Intl.message(
      'Call Member',
      name: 'callMember',
      desc: '',
      args: [],
    );
  }

  /// `Send Member Message`
  String get sendMemberMessage {
    return Intl.message(
      'Send Member Message',
      name: 'sendMemberMessage',
      desc: '',
      args: [],
    );
  }

  /// `Remove Member`
  String get removeMember {
    return Intl.message(
      'Remove Member',
      name: 'removeMember',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get name {
    return Intl.message(
      'Name',
      name: 'name',
      desc: '',
      args: [],
    );
  }

  /// `Email Address`
  String get emailAddress {
    return Intl.message(
      'Email Address',
      name: 'emailAddress',
      desc: '',
      args: [],
    );
  }

  /// `Male`
  String get male {
    return Intl.message(
      'Male',
      name: 'male',
      desc: '',
      args: [],
    );
  }

  /// `Female`
  String get female {
    return Intl.message(
      'Female',
      name: 'female',
      desc: '',
      args: [],
    );
  }

  /// `Cellphone`
  String get cellphone {
    return Intl.message(
      'Cellphone',
      name: 'cellphone',
      desc: '',
      args: [],
    );
  }

  /// `Field Monitor`
  String get fieldMonitor {
    return Intl.message(
      'Field Monitor',
      name: 'fieldMonitor',
      desc: '',
      args: [],
    );
  }

  /// `Administrator`
  String get administrator {
    return Intl.message(
      'Administrator',
      name: 'administrator',
      desc: '',
      args: [],
    );
  }

  /// `Executive`
  String get executive {
    return Intl.message(
      'Executive',
      name: 'executive',
      desc: '',
      args: [],
    );
  }

  /// `Submit Member`
  String get submitMember {
    return Intl.message(
      'Submit Member',
      name: 'submitMember',
      desc: '',
      args: [],
    );
  }

  /// `Profile Photo`
  String get profilePhoto {
    return Intl.message(
      'Profile Photo',
      name: 'profilePhoto',
      desc: '',
      args: [],
    );
  }

  /// `Please select Country`
  String get pleaseSelectCountry {
    return Intl.message(
      'Please select Country',
      name: 'pleaseSelectCountry',
      desc: '',
      args: [],
    );
  }

  /// `Internet Connection not available`
  String get internetConnectionNotAvailable {
    return Intl.message(
      'Internet Connection not available',
      name: 'internetConnectionNotAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Sign in failed`
  String get signInFailed {
    return Intl.message(
      'Sign in failed',
      name: 'signInFailed',
      desc: '',
      args: [],
    );
  }

  /// `Organization has been registered`
  String get organizationRegistered {
    return Intl.message(
      'Organization has been registered',
      name: 'organizationRegistered',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'af'),
      Locale.fromSubtags(languageCode: 'es'),
      Locale.fromSubtags(languageCode: 'fr'),
      Locale.fromSubtags(languageCode: 'ig'),
      Locale.fromSubtags(languageCode: 'pt'),
      Locale.fromSubtags(languageCode: 'st'),
      Locale.fromSubtags(languageCode: 'sw'),
      Locale.fromSubtags(languageCode: 'ts'),
      Locale.fromSubtags(languageCode: 'xh'),
      Locale.fromSubtags(languageCode: 'zu'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
