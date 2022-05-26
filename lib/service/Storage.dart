/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:illinois/model/illinicash/IlliniCashBallance.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/storage.dart' as rokwire;
import 'package:rokwire_plugin/utils/utils.dart';

class Storage extends rokwire.Storage {

  static String get notifySettingChanged => rokwire.Storage.notifySettingChanged;

  // Singletone Factory

  @protected
  Storage.internal() : super.internal();

  factory Storage() => ((rokwire.Storage.instance is Storage) ? (rokwire.Storage.instance as Storage) : (rokwire.Storage.instance = Storage.internal()));


  // Overrides

  @override String get configEnvKey => 'config_environment';
  @override String get reportedUpgradeVersionsKey  => 'reported_upgrade_versions';

  // User: readonly, backward compatability only.

  static const String _userKey  = 'user';

  Map<String, dynamic>? get userProfile {
    return JsonUtils.decodeMap(getStringWithName(_userKey));
  }

  // Dining: readonly, backward compatability only.

  static const String excludedFoodIngredientsPrefsKey  = 'excluded_food_ingredients_prefs';

  Set<String>? get excludedFoodIngredientsPrefs {
    List<String>? list = getStringListWithName(excludedFoodIngredientsPrefsKey);
    return (list != null) ? Set.from(list) : null;
  }

  static const String includedFoodTypesPrefsKey  = 'included_food_types_prefs';

  Set<String>? get includedFoodTypesPrefs {
    List<String>? list = getStringListWithName(includedFoodTypesPrefsKey);
    return (list != null) ? Set.from(list) : null;
  }

  // Notifications

  bool? getNotifySetting(String name) {
    return getBoolWithName(name);
  }

  void setNotifySetting(String name, bool? value) {
    return setBoolWithName(name, value);
  }

  /////////////
  // Polls

  static const String selectedPollTypeKey  = 'selected_poll_type';

  int? get selectedPollType {
    return getIntWithName(selectedPollTypeKey);
  }

  set selectedPollType(int? value) {
    setIntWithName(selectedPollTypeKey, value);
  }

  ///////////////
  // On Boarding

  static const String onBoardingPassedKey  = 'on_boarding_passed';
  static const String onBoardingExploreChoiceKey  = 'on_boarding_explore_campus';
  static const String onBoardingPersonalizeChoiceKey  = 'on_boarding_personalize';
  static const String onBoardingImproveChoiceKey  = 'on_boarding_improve';

  bool? get onBoardingPassed {
    return getBoolWithName(onBoardingPassedKey, defaultValue: false);
  }

  set onBoardingPassed(bool? showOnBoarding) {
    setBoolWithName(onBoardingPassedKey, showOnBoarding);
  }

  set onBoardingExploreCampus(bool? exploreCampus) {
    setBoolWithName(onBoardingExploreChoiceKey, exploreCampus);
  }

  bool? get onBoardingExploreCampus {
    return getBoolWithName(onBoardingExploreChoiceKey, defaultValue: true);
  }

  set onBoardingPersonalizeChoice(bool? personalize) {
    setBoolWithName(onBoardingPersonalizeChoiceKey, personalize);
  }

  bool? get onBoardingPersonalizeChoice {
    return getBoolWithName(onBoardingPersonalizeChoiceKey, defaultValue: true);
  }

  set onBoardingImproveChoice(bool? personalize) {
    setBoolWithName(onBoardingImproveChoiceKey, personalize);
  }

  bool? get onBoardingImproveChoice {
    return getBoolWithName(onBoardingImproveChoiceKey, defaultValue: true);
  }

  ////////////////////////////
  // Privacy Update Version

  static const String privacyUpdateVersionKey  = 'privacy_update_version';

  String? get privacyUpdateVersion {
    return getStringWithName(privacyUpdateVersionKey);
  }

  set privacyUpdateVersion(String? value) {
    setStringWithName(privacyUpdateVersionKey, value);
  }

  ////////////////////////////
  // Last Run Version

  static const String lastRunVersionKey  = 'last_run_version';

  String? get lastRunVersion {
    return getStringWithName(lastRunVersionKey);
  }

  set lastRunVersion(String? value) {
    setStringWithName(lastRunVersionKey, value);
  }

  ////////////////
  // IlliniCash

  static const String illiniCashBallanceKey  = '_illinicash_ballance';

  IlliniCashBallance? get illiniCashBallance {
    return IlliniCashBallance.fromJson(JsonUtils.decodeMap(getEncryptedStringWithName(illiniCashBallanceKey)));
  }

  set illiniCashBallance(IlliniCashBallance? value) {
    setEncryptedStringWithName(illiniCashBallanceKey, value != null ? json.encode(value.toJson()) : null);
  }

  /////////////////////
  // Twitter

  static const String selectedTwitterAccountKey  = 'selected_twitter_account';
  String? get selectedTwitterAccount => getStringWithName(selectedTwitterAccountKey);
  set selectedTwitterAccount(String? value) => setStringWithName(selectedTwitterAccountKey, value);

  /////////////////////
  // Date offset

  static const String offsetDateKey  = 'settings_offset_date';

  set offsetDate(DateTime? value) {
    setStringWithName(offsetDateKey, AppDateTime().formatDateTime(value, ignoreTimeZone: true));
  }

  DateTime? get offsetDate {
    String? dateString = getStringWithName(offsetDateKey);
    return StringUtils.isNotEmpty(dateString) ? DateTimeUtils.dateTimeFromString(dateString) : null;
  }

  /////////////////
  // Language

  @override String get currentLanguageKey => 'current_language';

  //////////////////
  // Favorites

  static const String favoritesDialogWasVisibleKey  = 'favorites_dialog_was_visible';

  bool? get favoritesDialogWasVisible {
    return getBoolWithName(favoritesDialogWasVisibleKey, defaultValue: false);
  }

  set favoritesDialogWasVisible(bool? value) {
    setBoolWithName(favoritesDialogWasVisibleKey, value);
  }

  //////////////
  // Recent Items

  static const String recentItemsKey  = '_recent_items_json_string';
  
  List<dynamic>? get recentItems {
    final String? jsonString = getStringWithName(recentItemsKey);
    return JsonUtils.decode(jsonString);
  }

  set recentItems(List<dynamic>? recentItems) {
    setStringWithName(recentItemsKey, recentItems != null ? json.encode(recentItems) : null);
  }

  //////////////
  // Local Date/Time

  static const String useDeviceLocalTimeZoneKey  = 'use_device_local_time_zone';

  bool? get useDeviceLocalTimeZone {
    return getBoolWithName(useDeviceLocalTimeZoneKey, defaultValue: true);
  }

  set useDeviceLocalTimeZone(bool? value) {
    setBoolWithName(useDeviceLocalTimeZoneKey, value);
  }


  //////////////
  // Debug

  static const String debugMapThresholdDistanceKey  = 'debug_map_threshold_distance';

  int? get debugMapThresholdDistance {
    return getIntWithName(debugMapThresholdDistanceKey, defaultValue: 200);
  }

  set debugMapThresholdDistance(int? value) {
    setIntWithName(debugMapThresholdDistanceKey, value);
  }

  @override
  String get debugGeoFenceRegionRadiusKey  => 'debug_geo_fence_region_radius';

  static const String debugDisableLiveGameCheckKey  = 'debug_disable_live_game_check';

  bool? get debugDisableLiveGameCheck {
    return getBoolWithName(debugDisableLiveGameCheckKey, defaultValue: false);
  }

  set debugDisableLiveGameCheck(bool? value) {
    setBoolWithName(debugDisableLiveGameCheckKey, value);
  }

  static const String debugMapLocationProviderKey  = 'debug_map_location_provider';

  bool? get debugMapLocationProvider {
    return getBoolWithName(debugMapLocationProviderKey, defaultValue: false);
  }

  set debugMapLocationProvider(bool? value) {
    setBoolWithName(debugMapLocationProviderKey, value);
  }

  static const String debugMapHideLevelsKey  = 'debug_map_hide_levels';

  bool? get debugMapHideLevels {
    return getBoolWithName(debugMapHideLevelsKey, defaultValue: false);
  }

  set debugMapHideLevels(bool? value) {
    setBoolWithName(debugMapHideLevelsKey, value);
  }

  static const String debugLastInboxMessageKey  = 'debug_last_inbox_message';

  String? get debugLastInboxMessage {
    return getStringWithName(debugLastInboxMessageKey);
  }

  set debugLastInboxMessage(String? value) {
    setStringWithName(debugLastInboxMessageKey, value);
  }

  //////////////
  // Firebase

// static const String firebaseMessagingSubscriptionTopisKey  = 'firebase_subscription_topis';
// Replacing "firebase_subscription_topis" with "firebase_messaging_subscription_topis" key ensures that
// all subsciptions will be applied again through Notifications BB APIs
  @override String get inboxFirebaseMessagingSubscriptionTopicsKey => 'firebase_messaging_subscription_topis';

  @override String get inboxFirebaseMessagingTokenKey => 'inbox_firebase_messaging_token';
  @override String get inboxFirebaseMessagingUserIdKey => 'inbox_firebase_messaging_user_id';
  @override String get inboxUserInfoKey => 'inbox_user_info';

  //////////////
  // Polls

  
  @override String get activePollsKey  => 'active_polls';

  /////////////
  // Styles

  @override String get stylesContentModeKey => 'styles_content_mode';

  /////////////
  // Voter

  static const String _voterHiddenForPeriodKey = 'voter_hidden_for_period';

  bool? get voterHiddenForPeriod {
    return getBoolWithName(_voterHiddenForPeriodKey, defaultValue: false);
  }

  set voterHiddenForPeriod(bool? value) {
    setBoolWithName(_voterHiddenForPeriodKey, value);
  }

  /////////////
  // Http Proxy

  @override String get httpProxyEnabledKey => 'http_proxy_enabled';
  @override String get httpProxyHostKey => 'http_proxy_host';
  @override String get httpProxyPortKey => 'http_proxy_port';
  
  //////////////////
  // Guide

  static const String _guideContentSourceKey = 'guide_content_source';

  String? get guideContentSource {
    return getStringWithName(_guideContentSourceKey);
  }

  set guideContentSource(String? value) {
    setStringWithName(_guideContentSourceKey, value);
  }

  //////////////////
  // Auth2

  @override String get auth2AnonymousIdKey => 'auth2AnonymousId';
  @override String get auth2AnonymousTokenKey => 'auth2AnonymousToken';
  @override String get auth2AnonymousPrefsKey => 'auth2AnonymousPrefs';
  @override String get auth2AnonymousProfileKey => 'auth2AnonymousProfile';
  @override String get auth2TokenKey => 'auth2Token';
  @override String get auth2AccountKey => 'auth2Account';
  
  String get auth2UiucTokenKey => 'auth2UiucToken';
  Auth2Token? get auth2UiucToken => Auth2Token.fromJson(JsonUtils.decodeMap(getEncryptedStringWithName(auth2UiucTokenKey)));
  set auth2UiucToken(Auth2Token? value) => setEncryptedStringWithName(auth2UiucTokenKey, JsonUtils.encode(value?.toJson()));

  String get auth2CardTimeKey => 'auth2CardTime';
  int? get auth2CardTime => getIntWithName(auth2CardTimeKey);
  set auth2CardTime(int? value) => setIntWithName(auth2CardTimeKey, value);

  //////////////////
  // Calendar

  @override String get calendarEventsTableKey => 'calendar_events_table';
  @override String get calendarEnableSaveKey => 'calendar_enabled_to_save';
  @override String get calendarEnablePromptKey => 'calendar_enabled_to_prompt';

  //////////////////
  // GIES

  static const String _giesNavPagesKey  = 'gies_nav_pages';

  List<String>? get giesNavPages {
    return getStringListWithName(_giesNavPagesKey);
  }

  set giesNavPages(List<String>? value) {
    setStringListWithName(_giesNavPagesKey, value);
  }

  static const String _giesCompletedPagesKey  = 'gies_completed_pages';
  
  Set<String>? get giesCompletedPages {
    List<String>? pagesList = getStringListWithName(_giesCompletedPagesKey);
    return (pagesList != null) ? Set.from(pagesList) : null;
  }

  set giesCompletedPages(Set<String>? value) {
    List<String>? pagesList = (value != null) ? List.from(value) : null;
    setStringListWithName(_giesCompletedPagesKey, pagesList);
  }

  static const String _giesNotesKey = 'gies_notes';

  String? get giesNotes {
    return getStringWithName(_giesNotesKey);
  }

  set giesNotes(String? value) {
    setStringWithName(_giesNotesKey, value);
  }

  //Groups
  static const String _groupMemberSelectionTableKey = 'group_members_selection';

  set groupMembersSelection(Map<String, List<List<Member>>>? selection){
    setStringWithName(_groupMemberSelectionTableKey, JsonUtils.encode(selection));
  }

  Map<String, List<List<Member>>>? get groupMembersSelection{
    Map<String, List<List<Member>>> result = Map();
    Map<String, dynamic>? table = JsonUtils.decodeMap(getStringWithName(_groupMemberSelectionTableKey));
    // try { return table?.cast<String, List<List<Member>>>(); }
    // catch(e) { debugPrint(e.toString()); return null; }
    if(table != null){
      table.forEach((key, selections) {
        List<List<Member>> groupSelections = <List<Member>>[];
        if(selections is List && CollectionUtils.isNotEmpty(selections)){
          selections.forEach((selection) {
            List<Member>? groupSelection;
            if(CollectionUtils.isNotEmpty(selection)){
              groupSelection = Member.listFromJson(selection);
            }
            if(groupSelection != null) {
              groupSelections.add(groupSelection);
              result[key] = groupSelections;
            }
          });
        }
      });
    // if(table != null){
    //   table.forEach((key, value) {
    //     List<List<Member>> groupSelections = <List<Member>>[];
    //     List<dynamic>? selections = JsonUtils.decodeList(value);
    //     if(CollectionUtils.isNotEmpty(selections)){
    //       selections!.forEach((element) {
    //         List<Member>? groupSelection;
    //         List<dynamic>? selection = JsonUtils.decodeList(value);
    //         if(CollectionUtils.isNotEmpty(selection)){
    //           groupSelection = Member.listFromJson(selection);
    //         }
    //
    //         if(groupSelection != null) {
    //           groupSelections.add(groupSelection);
    //         }
    //       });
    //     }
    //   });
    }

    return result;
  }

  // On Campus

  String get onCampusRegionIdKey => 'edu.illinois.rokwire.on_campus.region_id';
  String? get onCampusRegionId => getStringWithName(onCampusRegionIdKey);
  set onCampusRegionId(String? value) => setStringWithName(onCampusRegionIdKey, value);

  String get onCampusRegionMonitorEnabledKey => 'edu.illinois.rokwire.on_campus.region_monitor.enabled';
  bool? get onCampusRegionMonitorEnabled => getBoolWithName(onCampusRegionMonitorEnabledKey);
  set onCampusRegionMonitorEnabled(bool? value) => setBoolWithName(onCampusRegionMonitorEnabledKey, value);

  String get onCampusRegionManualInsideKey => 'edu.illinois.rokwire.on_campus.region_manual.inside';
  bool? get onCampusRegionManualInside => getBoolWithName(onCampusRegionManualInsideKey);
  set onCampusRegionManualInside(bool? value) => setBoolWithName(onCampusRegionManualInsideKey, value);

}
