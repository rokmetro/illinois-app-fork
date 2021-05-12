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
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:url_launcher/url_launcher.dart';

class TestHtmlPreviewPanel extends StatefulWidget {
  final String htmlContent;
  TestHtmlPreviewPanel(this.htmlContent);
  _TestHtmlPreviewPanelState createState() => _TestHtmlPreviewPanelState();
}

class _TestHtmlPreviewPanelState extends State<TestHtmlPreviewPanel> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Style htmlStyle = Style(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.bold, fontSize: FontSize(16));
    return Scaffold(
      backgroundColor: Styles().colors.surface,
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(
          "Test Html Editor",
          style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.extraBold),
        ),
      ),
      body: Padding(padding: EdgeInsets.all(16), child:
        SafeArea(child:
          SingleChildScrollView(child: 
            Html(data: widget.htmlContent, style: { 'body': htmlStyle }, onLinkTap: (url) => launch(url)),
          ),
        ),
      ),
    );
  }

}


