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

import 'dart:collection';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:illinois/service/Storage.dart';

import 'package:illinois/model/RecentItem.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class RecentItems with Service implements NotificationsListener {
  
  static const String notifyChanged  = "edu.illinois.rokwire.recentitems.changed";

  static final RecentItems _logic = new RecentItems._internal();
  factory RecentItems() {
    return _logic;
  }
  RecentItems._internal();

  Queue<RecentItem> _recentItems = Queue<RecentItem>();

  Queue<RecentItem> get recentItems{
    return _recentItems;
  }

  @override
  void createService() {
    NotificationService().subscribe(this, Auth2.notifyUserDeleted);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    _loadRecentItems();
    await super.initService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Storage()]);
  }

  void addRecentItem(RecentItem? item) {

    if ((item == null) || (recentItems.contains(item) == true)) {
      return;
    }
    recentItems.addFirst(item);
    if (recentItems.length > 3) {
      recentItems.removeLast();
    }
    _saveRecentItems();
    _notifyRecentItemsChanged();

  }

  void _loadRecentItems() {
    List<dynamic>? jsonListData = Storage().recentItems;
    if (jsonListData != null) {
      List<RecentItem> recentItemsList = [];
      for (dynamic jsonData in jsonListData) {
        ListUtils.add(recentItemsList, RecentItem.fromJson(JsonUtils.mapValue(jsonData) ));
      }
      _recentItems = Queue.from(recentItemsList);
      _notifyRecentItemsChanged();
    }
  }

  void _saveRecentItems() {
    Storage().recentItems = recentItems.toList();
  }

  void _notifyRecentItemsChanged(){
    NotificationService().notify(notifyChanged, null);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2.notifyUserDeleted) {
      _loadRecentItems();
    }
  }
}
