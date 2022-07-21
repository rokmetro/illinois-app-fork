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

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/CheckList.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/academics/AcademicsEventsContentWidget.dart';
import 'package:illinois/ui/canvas/CanvasCoursesContentWidget.dart';
import 'package:illinois/ui/gies/CheckListContentWidget.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class AcademicsHomePanel extends StatefulWidget {
  final AcademicsContent? content;

  AcademicsHomePanel({this.content});

  @override
  _AcademicsHomePanelState createState() => _AcademicsHomePanelState();
}

class _AcademicsHomePanelState extends State<AcademicsHomePanel>
    with AutomaticKeepAliveClientMixin<AcademicsHomePanel>
    implements NotificationsListener {

  static AcademicsContent? _lastSelectedContent;
  late AcademicsContent _selectedContent;
  List<AcademicsContent>? _contentValues;
  bool _contentValuesVisible = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [FlexUI.notifyChanged, Auth2.notifyLoginChanged]);
    _buildContentValues();
    _initSelectedContentItem();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // AutomaticKeepAliveClientMixin

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
        appBar: RootHeaderBar(title: Localization().getStringEx('panel.academics.header.title', 'Academics')),
        body: Column(children: <Widget>[
          Padding(padding: EdgeInsets.only(left: 16, top: 16, right: 16), child:
            RibbonButton(
              textColor: Styles().colors!.fillColorSecondary,
              backgroundColor: Styles().colors!.white,
              borderRadius: BorderRadius.all(Radius.circular(5)),
              border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
              rightIconAsset: (_contentValuesVisible ? 'images/icon-up.png' : 'images/icon-down-orange.png'),
              label: _getContentLabel(_selectedContent),
              onTap: _onTapRibbonButton
            ),
          ),
          Expanded(child:
            Stack(children: [
              Padding(padding: EdgeInsets.only(top: 16, left: 16, right: 16,), child:
                _contentWidget
              ),
              _buildContentValuesContainer()
            ]),
          )
        ]),
        backgroundColor: Styles().colors!.background
      );
  }

  Widget _buildContentValuesContainer() {
    return Visibility(
        visible: _contentValuesVisible,
        child: Positioned.fill(child: Stack(children: <Widget>[_buildContentDismissLayer(), _buildContentValuesWidget()])));
  }

  Widget _buildContentDismissLayer() {
    return Positioned.fill(
        child: BlockSemantics(
            child: GestureDetector(
                onTap: () {
                  Analytics().logSelect(target: 'Close Dropdown');
                  setState(() {
                    _contentValuesVisible = false;
                  });
                },
                child: Container(color: Styles().colors!.blackTransparent06))));
  }

  Widget _buildContentValuesWidget() {
    List<Widget> sectionList = <Widget>[];
    sectionList.add(Container(color: Styles().colors!.fillColorSecondary, height: 2));
    if (CollectionUtils.isNotEmpty(_contentValues)) {
      for (AcademicsContent section in _contentValues!) {
        if ((_selectedContent != section)) {
          sectionList.add(_buildContentItem(section));
        }
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SingleChildScrollView(child: Column(children: sectionList)));
  }

  Widget _buildContentItem(AcademicsContent contentItem) {
    return RibbonButton(
        backgroundColor: Styles().colors!.white,
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        rightIconAsset: null,
        rightIcon: _buildContentItemRightIcon(contentItem),
        label: _getContentLabel(contentItem),
        onTap: () => _onTapContentItem(contentItem));
  }

  Widget? _buildContentItemRightIcon(AcademicsContent contentItem) {
    return (contentItem == AcademicsContent.my_illini)
        ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Image.asset('images/icon-login-grey.png'),
            Padding(padding: EdgeInsets.only(left: 6), child: Image.asset('images/icon-external-link-grey.png'))
          ])
        : null;
  }

  void _buildContentValues() {
    List<String>? contentCodes = JsonUtils.listStringsValue(FlexUI()['academics']);
    List<AcademicsContent>? contentValues;
    if (contentCodes != null) {
      contentValues = [];
      for (String code in contentCodes) {
        AcademicsContent? value = _getContentValueFromCode(code);
        if (value != null) {
          contentValues.add(value);
        }
      }
    }

    _contentValues = contentValues;
    if (mounted) {
      setState(() {});
    }
  }

  void _initSelectedContentItem() {
    AcademicsContent? initialContent = widget.content ?? _lastSelectedContent;
    if (initialContent == null) {
      if (CollectionUtils.isNotEmpty(_contentValues)) {
        if (_contentValues!.contains(AcademicsContent.gies_checklist) && !_isCheckListCompleted(CheckList.giesOnboarding)) {
          initialContent = AcademicsContent.gies_checklist;
        } else if (_contentValues!.contains(AcademicsContent.courses)) {
          initialContent = AcademicsContent.courses;
        }
      }
    }
    _selectedContent = initialContent ?? AcademicsContent.events;
  }

  AcademicsContent? _getContentValueFromCode(String? code) {
    if (code == 'gies_checklist') {
      return AcademicsContent.gies_checklist;
    } else if (code == 'new_student_checklist') {
      return AcademicsContent.uiuc_checklist;
    } else if (code == 'canvas_courses') {
      return AcademicsContent.courses;
    } else if (code == 'academics_events') {
      return AcademicsContent.events;
    } else if (code == 'my_illini') {
      return AcademicsContent.my_illini;
    } else {
      return null;
    }
  }

  void _onTapContentItem(AcademicsContent contentItem) {
    Analytics().logSelect(target: '$contentItem');
    // Open My Illini in an external browser
    if (contentItem == AcademicsContent.my_illini) {
      _onMyIlliniSelected();
    } else {
      _selectedContent = _lastSelectedContent = contentItem;
    }
    _changeSettingsContentValuesVisibility();
  }

  void _onTapRibbonButton() {
    Analytics().logSelect(target: 'Toggle Dropdown');
    _changeSettingsContentValuesVisibility();
  }

  void _changeSettingsContentValuesVisibility() {
    _contentValuesVisible = !_contentValuesVisible;
    if (mounted) {
      setState(() {});
    }
  }

  void _onMyIlliniSelected() {
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context,
          Localization().getStringEx('panel.browse.label.offline.my_illini', 'My Illini not available while offline.'));
    } else if (StringUtils.isNotEmpty(Config().myIlliniUrl)) {
      // Please make this use an external browser
      // Ref: https://github.com/rokwire/illinois-app/issues/1110
      launch(Config().myIlliniUrl!);

      //
      // Until webview_flutter get fixed for the dropdowns we will continue using it as a webview plugin,
      // but we will open in an external browser all problematic pages.
      // The other plugin doesn't work with VoiceOver
      // Ref: https://github.com/rokwire/illinois-client/issues/284
      //      https://github.com/flutter/plugins/pull/2330
      //
      // if (Platform.isAndroid) {
      //   launch(Config().myIlliniUrl);
      // }
      // else {
      //   String myIlliniPanelTitle = Localization().getStringEx(
      //       'widget.home.campus_resources.header.my_illini.title', 'My Illini');
      //   Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: Config().myIlliniUrl, title: myIlliniPanelTitle,)));
      // }
    }
  }

  Widget get _contentWidget {
    return ((_selectedContent == AcademicsContent.gies_checklist) || (_selectedContent == AcademicsContent.uiuc_checklist)) ?
      _rawContentWidget :
      SingleChildScrollView(child:
        Padding(padding: EdgeInsets.only(bottom: 16), child:
          _rawContentWidget
        ),
      );
}

  Widget get _rawContentWidget {
    // There is no content for AcademicsContent.my_illini - it is a web url opened in an external browser
    switch (_selectedContent) {
      case AcademicsContent.events:
        return AcademicsEventsContentWidget();
      case AcademicsContent.gies_checklist:
        return CheckListContentWidget(contentKey: CheckList.giesOnboarding);
      case AcademicsContent.uiuc_checklist:
        return CheckListContentWidget(contentKey: CheckList.uiucOnboarding);
      case AcademicsContent.courses:
        return CanvasCoursesContentWidget();
      default:
        return Container();
    }
  }

  bool _isCheckListCompleted(String contentKey) {
    int stepsCount = CheckList(contentKey).progressSteps?.length ?? 0;
    int completedStepsCount = CheckList(contentKey).completedStepsCount;
    return (stepsCount == completedStepsCount);
  }

  // Utilities

  String _getContentLabel(AcademicsContent section) {
    switch (section) {
      case AcademicsContent.events:
        return Localization().getStringEx('panel.academics.section.events.label', 'Academic Events');
      case AcademicsContent.gies_checklist:
        return Localization().getStringEx('panel.academics.section.gies_checklist.label', 'iDegrees New Student Checklist');
      case AcademicsContent.uiuc_checklist:
        return Localization().getStringEx('panel.academics.section.uiuc_checklist.label', 'New Student Checklist');
      case AcademicsContent.courses:
        return Localization().getStringEx('panel.academics.section.courses.label', 'My Gies Canvas Courses');
      case AcademicsContent.my_illini:
        return Localization().getStringEx('panel.academics.section.my_illini.label', 'myIllini');
    }
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == FlexUI.notifyChanged) {
      _buildContentValues();
    } else if (name == Auth2.notifyLoginChanged) {
      _buildContentValues();
    }
  }
}

enum AcademicsContent { events, gies_checklist, uiuc_checklist, courses, my_illini }
