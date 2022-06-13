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

import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/ui/explore/ExploreDiningDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreEventDetailPanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/laundry/LaundryRoomDetailPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/SmallRoundedButton.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/model/RecentItem.dart';
import 'package:illinois/ext/RecentItem.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/RecentItems.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/athletics/AthleticsNewsArticlePanel.dart';
import 'package:illinois/ui/events/CompositeEventsDetailPanel.dart';
import 'package:illinois/ui/guide/GuideDetailPanel.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

// HomeRecentItemsWidget

class HomeRecentItemsWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeRecentItemsWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: Localization().getStringEx('panel.home.label.recently_viewed', 'Recently Viewed'),
    );

  @override
  _HomeRecentItemsWidgetState createState() => _HomeRecentItemsWidgetState();
}

class _HomeRecentItemsWidgetState extends State<HomeRecentItemsWidget> implements NotificationsListener {

  Iterable<RecentItem>? _recentItems;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, RecentItems.notifyChanged);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          if (mounted) {
            setState(() {
              _recentItems = RecentItems().recentItems;
            });
          }
        }
      });
    }

    _recentItems = RecentItems().recentItems;
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == RecentItems.notifyChanged) {
      if (mounted) {
        SchedulerBinding.instance?.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _recentItems = RecentItems().recentItems;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    
    return Visibility(visible: CollectionUtils.isNotEmpty(_recentItems), child:
      HomeSlantWidget(favoriteId: widget.favoriteId,
          title: Localization().getStringEx('panel.home.label.recently_viewed', 'Recently Viewed'),
          titleIcon: Image.asset('images/campus-tools.png', excludeFromSemantics: true,),
          child: Column(children: _buildListItems(),)
      ),
    );

  }

  List<Widget> _buildListItems() {
    List<Widget> widgets =  [];
    if (_recentItems?.isNotEmpty ?? false) {
      
      final int limit = 3;
      int itemsCount = _recentItems!.length;
      int visibleCount = (_showAll ? itemsCount : min(limit, itemsCount));

      for (RecentItem item in _recentItems!) {
        if (0 < visibleCount) {
          if (0 < widgets.length) {
            widgets.add(Container(height: 4));
          }
          widgets.add(HomeRecentItemCard(recentItem: item));
          visibleCount--;
        }
        else {
          break;
        }
      }

      if (limit < itemsCount) {
        widgets.add(Padding(padding: EdgeInsets.only(top: 16), child:
          SmallRoundedButton(
            label: _showAll ? Localization().getStringEx('widget.home_recent_items.button.less.title', 'Show Less') : Localization().getStringEx('widget.home_recent_items.button.all.title', 'Show All'),
            hint: _showAll ? Localization().getStringEx('widget.home_recent_items.button.less.hint', 'Tap to show less') : Localization().getStringEx('widget.home_recent_items.button.all.hint', 'Tap to show all'),
            onTap: _onViewAllTapped,),
        ));
      }
      
      widgets.add(Container(height: 16,));
    }

    return widgets;
  }

  void _onViewAllTapped() {
    setState(() {
      _showAll = !_showAll;
    });
  }
}

// HomeRecentItemsPanel

class HomeRecentItemsPanel extends StatefulWidget {
  HomeRecentItemsPanel();

  @override
  _HomeRecentItemsPanelState createState() => _HomeRecentItemsPanelState();
}

class _HomeRecentItemsPanelState extends State<HomeRecentItemsPanel> implements NotificationsListener {

  Iterable<RecentItem>? _recentItems;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, RecentItems.notifyChanged);
    _recentItems = RecentItems().recentItems;
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == RecentItems.notifyChanged) {
      if (mounted) {
        setState(() {
          _recentItems = RecentItems().recentItems;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.home.label.recently_viewed', 'Recently Viewed'),),
      body: RefreshIndicator(onRefresh: _onPullToRefresh, child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Expanded(child:
            SingleChildScrollView(child:
              Padding(padding: EdgeInsets.all(16), child:
                Column(children: _buildListItems(),)
              )
            ,),
          ),
        ],)),
      backgroundColor: Styles().colors!.background,
    );
  }

  List<Widget> _buildListItems() {
    List<Widget> widgets =  [];
    if (_recentItems != null) {
      for (RecentItem item in _recentItems!) {
        if (0 < widgets.length) {
          widgets.add(Container(height: 8));
        }
        widgets.add(HomeRecentItemCard(recentItem: item));
      }
    }
    return widgets;
  }

  Future<void> _onPullToRefresh() async {
    if (mounted) {
      setState(() {
        _recentItems = RecentItems().recentItems;
      });
    }
  }

}

// HomeRecentItemCard

class HomeRecentItemCard extends StatefulWidget {

  final RecentItem recentItem;
  final bool showDate;

  HomeRecentItemCard({required this.recentItem, this.showDate = false});

  @override
  _HomeRecentItemCardState createState() => _HomeRecentItemCardState();
}

class _HomeRecentItemCardState extends State<HomeRecentItemCard> implements NotificationsListener {

  @override
  void initState() {
    NotificationService().subscribe(this, Auth2UserPrefs.notifyFavoritesChanged);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      if (mounted){
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isFavorite = Auth2().isFavorite(widget.recentItem.favorite);

    String? favLabel = isFavorite ?
      Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites') :
      Localization().getStringEx('widget.card.button.favorite.on.title','Add To Favorites');

    String? favHint = isFavorite ?
      Localization().getStringEx('widget.card.button.favorite.off.hint', '') :
      Localization().getStringEx('widget.card.button.favorite.on.hint','');

    String favIcon = isFavorite ? 'images/icon-star-selected.png' : 'images/icon-star.png';

    return Padding(padding: EdgeInsets.only(bottom: 8), child:
      Container(decoration: BoxDecoration(boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]), clipBehavior: Clip.none, child:
        ClipRRect(borderRadius: BorderRadius.all(Radius.circular(6)), child:
          Stack(children: [
            GestureDetector(behavior: HitTestBehavior.translucent, onTap: _onTapItem, child:
              Container(color: Colors.white, padding: EdgeInsets.all(16), child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    Expanded(child:
                      Padding(padding: EdgeInsets.only(right: 24), child:
                        Text(widget.recentItem.title ?? '', style: TextStyle(fontSize: 18, fontFamily: Styles().fontFamilies!.extraBold, color: Styles().colors!.fillColorPrimary,),)
                      ),
                    ),
                  ]),
                  Padding(padding: EdgeInsets.only(top: 10), child:
                    Column(children: _buildDetails()),
                  )
                ])
              )
            ),
            _topBorder(),
            Visibility(visible: Auth2().canFavorite, child:
              Align(alignment: Alignment.topRight, child:
                GestureDetector(onTap: _onTapFavorite, child:
                  Semantics(excludeSemantics: true, label: favLabel, hint: favHint, child:
                    Container(padding: EdgeInsets.all(16), child: 
                      Image.asset(favIcon)
              ),),),),
            ),

          ],),
      ),
    ),);
  }

  List<Widget> _buildDetails() {
    List<Widget> details =  [];
    if(StringUtils.isNotEmpty(widget.recentItem.time)) {
      Widget? dateDetail = widget.showDate ? _dateDetail() : null;
      if (dateDetail != null) {
        details.add(dateDetail);
      }
      Widget? timeDetail = _timeDetail();
      if (timeDetail != null) {
        if (details.isNotEmpty) {
          details.add(Container(height: 8,));
        }
        details.add(timeDetail);
      }
    }
    Widget? descriptionDetail = ((widget.recentItem.type == RecentItemType.guide) && StringUtils.isNotEmpty(widget.recentItem.descripton)) ? _descriptionDetail() : null;
    if (descriptionDetail != null) {
      if (details.isNotEmpty) {
        details.add(Container(height: 8,));
      }
      details.add(descriptionDetail);
    }
    return details;
  }

  //Not used any more
  Widget? _dateDetail(){
    String? displayTime = widget.recentItem.time;
    if ((displayTime != null) && displayTime.isNotEmpty) {
      String displayDate = Localization().getStringEx('widget.home_recent_item_card.label.date', 'Date');
      return Semantics(label: displayDate, excludeSemantics: true, child:
        Row(children: <Widget>[
          Image.asset('images/icon-calendar.png'),
          Padding(padding: EdgeInsets.only(right: 5),),
          Text(displayDate, style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 12, color: Styles().colors!.textBackground)),
        ],),
      );
    } else {
      return null;
    }
  }

  Widget? _timeDetail() {
    String? displayTime = widget.recentItem.time;
    if ((displayTime != null) && displayTime.isNotEmpty) {
      return Semantics(label: displayTime, excludeSemantics: true, child:
        Row(children: <Widget>[
            Image.asset('images/icon-calendar.png'),
            Padding(padding: EdgeInsets.only(right: 5),),
            Text(displayTime, style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 12, color: Styles().colors!.textBackground)),
        ],),
      );
    } else {
      return null;
    }
  }

  Widget _descriptionDetail() {
    return Semantics(label: widget.recentItem.descripton ?? '', excludeSemantics: true, child:
      Text(widget.recentItem.descripton ?? '', style: TextStyle(fontFamily: Styles().fontFamilies!.medium, fontSize: 14, color: Styles().colors!.textBackground)),
    );
  }

  Widget _topBorder() {
    return Container(height: 7, color: widget.recentItem.headerColor ?? Styles().colors?.fillColorPrimary);
  }

  void _onTapFavorite() {
    Analytics().logSelect(target: "Favorite: ${widget.recentItem.title}");
    Auth2().prefs?.toggleFavorite(widget.recentItem.favorite);
  }

  void _onTapItem() {
    Analytics().logSelect(target: "HomeRecentItemCard clicked: ${widget.recentItem.title}");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => _getDetailPanel(widget.recentItem)));
  }

  static Widget _getDetailPanel(RecentItem item) {
    dynamic sourceItem = item.source;

    if (sourceItem is Event) {
      return sourceItem.isComposite ? CompositeEventsDetailPanel(parentEvent: sourceItem) : ExploreEventDetailPanel(event: sourceItem,);
    }
    else if (sourceItem is Dining) {
      return ExploreDiningDetailPanel(dining: sourceItem,);
    }
    else if (sourceItem is Game) {
      return AthleticsGameDetailPanel(game: sourceItem,);
    }
    else if (sourceItem is News) {
      return AthleticsNewsArticlePanel(article: sourceItem,);
    }
    else if (sourceItem is LaundryRoom) {
      return LaundryRoomDetailPanel(room: sourceItem,);
    }
    else if ((item.type == RecentItemType.guide) && (sourceItem is Map)) {
      return GuideDetailPanel(guideEntryId: Guide().entryId(JsonUtils.mapValue(sourceItem)));
    }
    return Container();
  }

}

