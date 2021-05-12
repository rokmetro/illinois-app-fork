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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/settings/debug/TestHtmlPreviewPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
//import 'package:html_editor/html_editor.dart';
import 'package:html_editor_enhanced/html_editor.dart';

class TestHtmlEditorPanel extends StatefulWidget {
  _TestHtmlEditorPanelState createState() => _TestHtmlEditorPanelState();
}

class _TestHtmlEditorPanelState extends State<TestHtmlEditorPanel> {

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
          Column(children: [
            Expanded(child:
              HtmlEditor(
                hint: "Your text here...",
                //value: "text content initial, if any",
                //key: keyEditor,
                height: 400,
            ),
            ),
            Padding(padding: EdgeInsets.only(top: 16), child:
              RoundedButton(label: "Preview", backgroundColor: Styles().colors.background, fontSize: 16.0, textColor: Styles().colors.fillColorPrimary, borderColor: Styles().colors.fillColorPrimary, onTap: _onTapPreview),
            ),
          ],),
        ),
      ),
    );
  }

  void _onTapPreview() {
    HtmlEditor.getText().then((String htmlContent) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => TestHtmlPreviewPanel(htmlContent)));
    }).
    catchError((e){ print(e?.toString()); });
  }

}


