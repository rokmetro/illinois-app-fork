
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/guide/GuideListPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/utils/Utils.dart';

class GuideCategoriesPanel extends StatefulWidget {
  final String guide;

  GuideCategoriesPanel({Key key, this.guide}) : super(key: key);

  _GuideCategoriesPanelState createState() => _GuideCategoriesPanelState();
}

class _GuideCategoriesPanelState extends State<GuideCategoriesPanel> implements NotificationsListener {

  List<String> _categories;
  Map<String, List<GuideSection>> _categorySections;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      Guide.notifyChanged,
    ]);
    _buildCategories();
    Guide().refresh();
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Guide.notifyChanged) {
      setState(() {
        _buildCategories();
      });
    }
  }

  void _buildCategories() {
    
    List<dynamic> contentList = Guide().getContentList(guide: widget.guide);
    if (contentList != null) {

      LinkedHashMap<String, LinkedHashSet<GuideSection>> categoriesMap = LinkedHashMap<String, LinkedHashSet<GuideSection>>();
      
      for (dynamic contentEntry in contentList) {
        Map<String, dynamic> guideEntry = AppJson.mapValue(contentEntry);
        if (guideEntry != null) {
          String category = AppJson.stringValue(Guide().entryValue(guideEntry, 'category'));
          GuideSection section = GuideSection.fromGuideEntry(guideEntry);

          if (AppString.isStringNotEmpty(category) && (section != null)) {
            LinkedHashSet<GuideSection> categorySections = categoriesMap[category];
            if (categorySections == null) {
              categoriesMap[category] = categorySections = LinkedHashSet<GuideSection>();
            }
            if (!categorySections.contains(section)) {
              categorySections.add(section);
            }
          }
        }
      }

      _categories = List.from(categoriesMap.keys) ;
      _categories.sort();

      _categorySections = Map<String, List<GuideSection>>();
      categoriesMap.forEach((String category, LinkedHashSet<GuideSection> sectionsSet) {
        List<GuideSection> sections = List.from(sectionsSet);
        sections.sort((GuideSection section1, GuideSection section2) {
          return section1.compareTo(section2);
        });
        _categorySections[category] = sections;
      });
        
    }
    else {
      _categories = null;
      _categorySections = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(Localization().getStringEx('panel.guide_categories.label.heading', 'Campus Guide'), style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.extraBold),),
      ),
      body: Column(children: <Widget>[
          Expanded(child:
            _buildContent(),
          ),
          TabBarWidget(),
        ],),
      backgroundColor: Styles().colors.background,
    );
  }

  Widget _buildContent() {
    if ((_categories != null) && (0 < _categories.length)) {
      List<Widget> contentList = <Widget>[];
      for (String category in _categories) {
        contentList.add(_buildHeading(category));
        for (GuideSection section in _categorySections[category]) {
          contentList.add(_buildEntry(section, category: category));
        }
      }

      return SingleChildScrollView(child:
        SafeArea(child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children:
            contentList
          ),
        ),
      );
    }
    else {
      return Padding(padding: EdgeInsets.all(32), child:
        Center(child:
          Text(Localization().getStringEx('panel.guide_categories.label.content.empty', 'Empty guide content'), style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies.bold),)
        ,)
      );
    }

  }

  Widget _buildHeading(String category) {
    
    return GestureDetector(onTap: () => _onTapCategory(category), child:
      Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 32, bottom: 4), child:
      Semantics(hint: "Heading", child:
        Row(children: [
          Expanded(child:
            Text(category, style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 20, fontFamily: Styles().fontFamilies.bold),)
          ),
          ],),
        )
      ),
    );
  }

  Widget _buildEntry(GuideSection section, { String category }) {
    return GestureDetector(onTap: () => _onTapSection(section, category: category), child:
      Padding(padding: EdgeInsets.only(left:16, right: 16, top: 4), child:
        Container(color: Styles().colors.fillColorPrimary, child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
            Semantics(button: true, child:
              Row(children: [
                Expanded(child:
                  Text(section.name ?? '', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.bold),)
                ),
                Image.asset("images/chevron-right-white.png", excludeFromSemantics: true,)
            ],)),
          ),
        ),
      ),
    );
  }

  void _onTapCategory(String category) {
    Analytics.instance.logSelect(target: category);
    //Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideListPanel(category: category,)));
  }

  void _onTapSection(GuideSection section, {String category}) {
    Analytics.instance.logSelect(target: "$category / ${section.name}");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideListPanel(category: category, section: section,)));
  }
}