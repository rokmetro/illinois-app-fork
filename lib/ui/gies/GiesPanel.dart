import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Gies.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/widgets/TrianglePainter.dart';
import 'package:rokwire_plugin/service/deep_link.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../WebPanel.dart';

class GiesPanel extends StatefulWidget{

  @override
  State<StatefulWidget> createState() => _GiesPanelState();

}

class _GiesPanelState extends State<GiesPanel> implements NotificationsListener{

  @override
  void initState() {
    NotificationService().subscribe(this, [Gies.notifyPageChanged]);
    super.initState();

  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(Localization().getStringEx('widget.gies.title', 'iDegrees New Student Checklist')!,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: Styles().fontFamilies!.extraBold,
            letterSpacing: 1.0),
        ),
      ),
      body: SingleChildScrollView(child:
      Column(children: <Widget>[
        _buildTitle(),
        _buildSlant(),
        _buildContent(),
      ]),
      ));
  }

  Widget _buildTitle() {
    String? progress = JsonUtils.intValue(_currentPage["progress"])?.toString();
    return Container(color: Styles().colors!.fillColorPrimary, child:
      Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 10), child:
        Column(children: [
          Visibility( visible:  progress!=null,
            child:Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(child:
              Text(JsonUtils.stringValue(_currentPage["step_title"]) ?? "", textAlign: TextAlign.center, style: TextStyle(color: Styles().colors!.fillColorSecondary, fontFamily: Styles().fontFamilies!.bold, fontSize: 20,),),),
          ],)),
          Container(height: 8,),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(child:
              Text(_currentPage["title"]??"", textAlign: TextAlign.center, style: TextStyle(color: Styles().colors!.white, fontFamily: Styles().fontFamilies!.extraBold, fontSize: 32,),),),
          ],),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
            Expanded(child: Container()),
            Padding(padding: EdgeInsets.only(top: 3), child:
            _buildProgress(),
            ),
            Expanded(child:
              Align(alignment: Alignment.centerRight, child:
                InkWell(onTap: () => _onTapNotes(), child:
                  Padding(padding: EdgeInsets.only(top: 14, bottom: 4), child:
                    Text(Localization().getStringEx('widget.gies.button.notes', 'Notes')!, style: TextStyle(color: Styles().colors!.white, fontFamily: Styles().fontFamilies!.bold, fontSize: 16, decoration: TextDecoration.underline, ),), // Styles().colors.fillColorSecondary
                  ),
                ),
              ),
            ),
          ],),
        ],),
    ),);
  }

  Widget _buildProgress() {

    List<Widget> progressWidgets = <Widget>[];
    if (Gies().progressSteps != null) {
      int? currentPageProgress = _currentPageProgress;

      for (int progressStep in Gies().progressSteps!) {

        Color textColor;
        String? textFamily;
        bool progressStepCompleted = Gies().isProgressStepCompleted(progressStep);
        bool currentStep = (currentPageProgress != null) && (progressStep == currentPageProgress);

        if (progressStepCompleted) {
          textColor = Colors.greenAccent;
          textFamily = Styles().fontFamilies!.medium;
        } else {
          textColor = Colors.white;
          textFamily = Styles().fontFamilies!.regular;
        }
        if (currentStep) {
          textColor = Styles().colors!.fillColorPrimary!;
          textFamily = Styles().fontFamilies!.extraBold;
        }

        progressWidgets.add(
            Semantics(label: "Page ${progressStep.toString()}", button: true, hint: progressStepCompleted? "Completed" :((progressStep == currentPageProgress)? "Current page":"Not Completed"), child:
            InkWell(onTap: () => _onTapProgress(progressStep), child:
            Padding(padding: EdgeInsets.symmetric(horizontal: 3, vertical: 3), child:
//              Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: borderColor, width: borderWidth),), child:
//              Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.rectangle, border: Border(bottom: BorderSide(color: borderColor, width: borderWidth)),), child:
            Container(width: 28, height: 28, child:
//                Align(alignment: Alignment.center, child:
//                  Text(progressStep.toString(), style: TextStyle(color: textColor, fontFamily: textFamily, fontSize: 16,), semanticsLabel: "",),),),),),));
/*                  Column(mainAxisSize: MainAxisSize.min, children:<Widget>[
                      Text(progressStep.toString(), style: TextStyle(color: textColor, fontFamily: textFamily, fontSize: 16,), semanticsLabel: '',),
                      Padding(padding: EdgeInsets.only(bottom: 3 - borderWidth), child:
                        Container(width: 12, height: borderWidth, color: borderColor,)
                      ),
                    ]),*/
            Stack(children:<Widget>[
              Visibility(
                visible: currentStep,
                child:  Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
              ),
              Container(child:
                Align(alignment: Alignment.center, child:
                  Text(progressStep.toString(), style: TextStyle(color: textColor, fontFamily: textFamily, fontSize: 16, decoration: TextDecoration.underline), semanticsLabel: '',),
              )
              ),
            ]),
//                ),
            ),
            ),
            ),
            )
        );
      }
    }

    return progressWidgets.isNotEmpty ? Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: progressWidgets) : Container();
  }

  Widget _buildSlant() {
    return Column(children: <Widget>[
      Container(color:  Styles().colors!.fillColorPrimary, height: 10,),
      Container(color: Styles().colors!.fillColorPrimary, child:
      CustomPaint(painter: TrianglePainter(painterColor: Styles().colors!.white, left : true), child:
      Container(height: 45,),
      )),
    ],);
  }

  Widget _buildContent() {
    return Container(color: Colors.white, padding: EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 0), child:
      _GiesPageWidget(page: _currentPage, onTapLink: _onTapLink, onTapButton: _onTapButton, onTapBack: (1 < Gies().navigationPages!.length) ? _onTapBack : null,onTapNotes: _onTapNotes, showTitle: false,),
    );
  }

  void _onTapNotes() {
    _showPopup(_pagePopup(_currentPage) ?? 'notes', _currentPage["id"]);
  }

  void _onTapLink(String? url) {
    if (StringUtils.isNotEmpty(url)) {

      Uri? uri = Uri.tryParse(url!);
      Uri? giesUri = Uri.tryParse(giesUrl);
      if ((giesUri != null) &&
          (giesUri.scheme == uri!.scheme) &&
          (giesUri.authority == uri.authority) &&
          (giesUri.path == uri.path))
      {
        String? pageId = JsonUtils.stringValue(uri.queryParameters['page_id']);
        Gies().pushPage(Gies().getPage(id: pageId));
      }
      else if (UrlUtils.launchInternal(url)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      } else {
        launch(url);
      }
    }
  }

  void _onTapButton(Map<String, dynamic> button, String pageId) {
    _processButtonPopup(button, pageId).then((_) {
      _processButtonPage(button, callerPageId: pageId);
    });
  }

  void _onTapBack() {
    Gies().popPage();
  }

  void _onTapProgress(int progress) {
    int? currentPageProgress = _currentPageProgress;
    if (currentPageProgress != progress) {
      Gies().pushPage(Gies().getPage(progress: progress));
    }
  }

  Future<void> _processButtonPopup(Map<String, dynamic> button, String panelId) async {
    String? popupId = JsonUtils.stringValue(button['popup']);
    if (popupId != null) {
      await _showPopup(popupId, panelId);
    }
  }

  Future<void> _showPopup(String popupId, String pageId) async {
    return showDialog(context: context, builder: (BuildContext context) {
      if (popupId == 'notes') {
        return GiesNotesWidget(notes: JsonUtils.decodeList(Storage().giesNotes) ?? []);
      }
      else if (popupId == 'current-notes') {
        List<dynamic> notes = JsonUtils.decodeList(Storage().giesNotes) ?? [];
        // Map<String, dynamic>? currentPage =  Gies().getPage(id: pageId);
        // String? nodeTitle;
        // if(currentPage!=null) {
        //   bool isInnerStep = JsonUtils.stringValue(currentPage["tab_index"]) != null;
        //
        //   if (isInnerStep) {
        //     nodeTitle = JsonUtils.stringValue(currentPage["title"]);
        //   } else {
        //     nodeTitle =
        //     "${JsonUtils.intValue(currentPage!['progress'])}${JsonUtils.stringValue(currentPage['tab_index']) ?? ""} "
        //         "${JsonUtils.stringValue(currentPage['title'])}";
        //   }
        // }
        String? focusNodeId =  Gies().setCurrentNotes(notes, pageId,);
        return GiesNotesWidget(notes: notes, focusNoteId: focusNodeId,);
      }
      else {
        return Container();
      }
    });
  }

  void _processButtonPage(Map<String, dynamic> button, {String? callerPageId}) {
    String? pageId = callerPageId ?? Gies().currentPageId;
    if (Gies().pageButtonCompletes(button)) {
      if ((pageId != null) && pageId.isNotEmpty && !Gies().completedPages!.contains(pageId)) {
        setState(() {
          Gies().completedPages!.add(pageId);
        });
        Storage().giesCompletedPages = Gies().completedPages;
      }
    }

    String? pushPageId = JsonUtils.stringValue(button['page']);
    if ((pushPageId != null) && pushPageId.isNotEmpty) {
      int? currentPageProgress = Gies().getPageProgress(_currentPage);

      Map<String, dynamic>? pushPage = Gies().getPage(id: pushPageId);
      int? pushPageProgress = Gies().getPageProgress(pushPage);

      if ((currentPageProgress != null) && (pushPageProgress != null) && (currentPageProgress < pushPageProgress)) {
        while (Gies().isProgressStepCompleted(pushPageProgress)) {
          int nextPushPageProgress = pushPageProgress! + 1;
          Map<String, dynamic>? nextPushPage = Gies().getPage(progress: nextPushPageProgress);
          String? nextPushPageId = (nextPushPage != null) ? JsonUtils.stringValue(nextPushPage['id']) : null;
          if ((nextPushPageId != null) && nextPushPageId.isNotEmpty) {
            pushPage = nextPushPage;
            pushPageId = nextPushPageId;
            pushPageProgress = nextPushPageProgress;
          }
          else {
            break;
          }
        }
      }

      Gies().pushPage(pushPage);
    }
  }

  String? _pagePopup(Map? page) {
    List<dynamic>? buttons = (page != null) ? JsonUtils.listValue(page['buttons']) : null;
    if (buttons != null) {
      String? popup;
      for (dynamic button in buttons) {
        if ((button is Map) && ((popup = _pageButtonPopup(button)) != null)) {
          return popup;
        }
      }
    }
    return null;
  }

  String? _pageButtonPopup(Map button) {
    return JsonUtils.stringValue(button['popup']);
  }

  @override
  void onNotification(String name, param) {
    if(name == Gies.notifyPageChanged){
      setState(() {});
    }
  }


  int? get _currentPageProgress {
    return Gies().getPageProgress(_currentPage);
  }

  Map<String, dynamic> get _currentPage {
    return Gies().getPage(id: Gies().currentPageId) ?? {};
  }

  String get giesUrl => '${DeepLink().appUrl}/gies';

}

class _GiesPageWidget extends StatelessWidget {
  final Map<String, dynamic>? page;
  final void Function(String?)? onTapLink;
  final void Function(Map<String, dynamic> button, String panelId)? onTapButton;
  final void Function()? onTapBack;
  final void Function()? onTapNotes;

  final bool showTitle;

  _GiesPageWidget({this.page, this.onTapLink, this.onTapButton, this.onTapBack, this.showTitle = true, this.onTapNotes});

  @override
  Widget build(BuildContext context) {
    List<Widget> contentList = <Widget>[];

    String? titleHtml = (page != null) && showTitle? "${JsonUtils.stringValue(page!["step_title"])}: ${JsonUtils.stringValue(page!['title'])}" : null;
    if (StringUtils.isNotEmpty(titleHtml)) {
      contentList.add(

          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            (onTapBack != null) ?
            Semantics(
              label: Localization().getStringEx('headerbar.back.title', 'Back'),
              hint: Localization().getStringEx('headerbar.back.hint', ''),
              button: true,
              child: InkWell(
                onTap: onTapBack,
                child: Container(height: 36, width: 36, child:
                Image.asset('images/chevron-left-gray.png')
                ),
              ),
            ) :
            Padding(padding: EdgeInsets.only(left: 16), child: Container()),

            Expanded(child:
            Padding(padding: EdgeInsets.only(top: 4, bottom: 4, right: 16), child:
            Html(data: titleHtml,
              onLinkTap: (url, context, attributes, element) => onTapLink!(url),
              style: {
                "body": Style(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.bold, fontSize: FontSize(24), padding: EdgeInsets.zero, margin: EdgeInsets.zero),
                "a": Style(color: Styles().colors!.fillColorSecondaryVariant),
              },),
            ),
            ),

          ],));
    }

    String? textHtml = (page != null) ? JsonUtils.stringValue(page!['text']) : null;
    if (StringUtils.isNotEmpty(textHtml)) {
      contentList.add(
        Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
        Html(data: textHtml,
          onLinkTap: (url, context, attributes, element) => onTapLink!(url),
          style: {
            "body": Style(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero),
            "a": Style(color: Styles().colors!.fillColorSecondaryVariant),
          },),
        ),);
    }

    List<dynamic>? content = (page != null) ? JsonUtils.listValue(page!['content']) : null;
    if (content != null) {
      for (dynamic contentEntry in content) {
        if (contentEntry is Map) {
          List<Widget> contentEntryWidgets = <Widget>[];

          String? headingHtml = JsonUtils.stringValue(contentEntry['heading']);
          if (StringUtils.isNotEmpty(headingHtml)) {
            contentEntryWidgets.add(
              Padding(padding: EdgeInsets.only(top: 4, bottom: 4), child:
              Html(data: headingHtml,
                onLinkTap: (url, context, attributes, element) => onTapLink!(url),
                style: {
                  "body": Style(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero),
                  "a": Style(color: Styles().colors!.fillColorSecondaryVariant),
                },
              ),),
            );
          }

          List<dynamic>? bullets = JsonUtils.listValue(contentEntry['bullets']);
          if (bullets != null) {
            String bulletText = '\u2022';
            Color? bulletColor = Styles().colors!.textBackground;
            List<Widget> bulletWidgets = <Widget>[];
            for (dynamic bulletEntry in bullets) {
              if ((bulletEntry is String) && bulletEntry.isNotEmpty) {
                bulletWidgets.add(
                  Padding(padding: EdgeInsets.only(top: 4, bottom: 2), child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(padding: EdgeInsets.only(left: 16, right: 8), child:
                    Text(bulletText, style: TextStyle(color: bulletColor, fontSize: 20),),),
                    Expanded(child:
                    Html(data: bulletEntry,
                      onLinkTap: (url, context, attributes, element) => onTapLink!(url),
                      style: {
                        "body": Style(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero),
                        "a": Style(color: Styles().colors!.fillColorSecondaryVariant),
                      },
                    ),),
                  ],)
                  ),
                );
              }
            }
            if (0 < bulletWidgets.length) {
              contentEntryWidgets.add(Column(children: bulletWidgets,));
            }
          }

          List<dynamic>? numbers = JsonUtils.listValue(contentEntry['numbers']);
          if (numbers != null) {
            Color? numberColor = Styles().colors!.textBackground;
            List<Widget> numberWidgets = <Widget>[];
            for (int numberIndex = 0; numberIndex < numbers.length; numberIndex++) {
              dynamic numberEntry = numbers[numberIndex];
              if ((numberEntry is String) && numberEntry.isNotEmpty) {
                numberWidgets.add(
                  Padding(padding: EdgeInsets.only(top: 4, bottom: 2), child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(padding: EdgeInsets.only(left: 16, right: 8), child:
                    Text('${numberIndex + 1}.', style: TextStyle(color: numberColor, fontSize: 20),),),
                    Expanded(child:
                    Html(data: numberEntry,
                      onLinkTap: (url, context, attributes, element) => onTapLink!(url),
                      style: {
                        "body": Style(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero),
                        "a": Style(color: Styles().colors!.fillColorSecondaryVariant),
                      },
                    ),),
                  ],)
                  ),
                );
              }
            }
            if (0 < numberWidgets.length) {
              contentEntryWidgets.add(Column(children: numberWidgets,));
            }
          }

          if (0 < contentEntryWidgets.length) {
            contentList.add(
              Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
              Column(children: contentEntryWidgets)
              ),);
          }
        }
      }
    }
    List<dynamic>? steps = (page != null) ? JsonUtils.listValue(page!['steps']) : null;
    if (steps != null ) {
      contentList.add(_StepsHorizontalListWidget(tabs: steps,
          pageProgress: JsonUtils.intValue(page!["progress"]) ?? 0,
          title:"${JsonUtils.stringValue(page!["step_title"])}: ${page!["title"]}",
          onTapLink: onTapLink,
          onTapButton: onTapButton,
          onTapBack: (1 < Gies().navigationPages!.length) ? onTapBack : null,
          onTapNotes: onTapNotes,
      ),
      );
    }

    List<dynamic>? buttons = (page != null) ? JsonUtils.listValue(page!['buttons']) : null;
    if (buttons != null) {
      List<Widget> buttonWidgets = <Widget>[];
      for (dynamic button in buttons) {
        if (button is Map) {
          String? title = JsonUtils.stringValue(button['title']);
          buttonWidgets.add(
            Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              RoundedButton(label: title,
                  backgroundColor: Styles().colors!.white,
                  textColor: Styles().colors!.fillColorPrimary,
                  fontFamily: Styles().fontFamilies!.bold,
                  fontSize: 16,
                  padding: EdgeInsets.symmetric(horizontal: 16, ),
                  borderColor: Styles().colors!.fillColorSecondary,
                  borderWidth: 2,
                  height: 42,
                  onTap:() {
                    try { onTapButton!(button.cast<String, dynamic>(), JsonUtils.stringValue(page?["id"])!); }
                    catch (e) { print(e.toString()); }
                  }
              )
            ]),
          );
        }
      }
      if (0 < buttonWidgets.length) {
        contentList.add(
          Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
          Wrap(runSpacing: 8, spacing: 16, children: buttonWidgets,)
          ),);
      }
    }

    return Padding(padding: EdgeInsets.only(), child:
    Container(
      color: Styles().colors!.white,
      clipBehavior: Clip.none,
      child: Padding(padding: EdgeInsets.only(top: 0, bottom: 16), child:
      Row(children: [ Expanded(child: Column(children: contentList))],)
      ),
    ),);
  }
}

class GiesNotesWidget extends StatefulWidget {
  final List<dynamic>? notes;
  final String? focusNoteId;

  GiesNotesWidget({this.notes, this.focusNoteId});
  _GiesNotesWidgetState createState() => _GiesNotesWidgetState();
}

class _GiesNotesWidgetState extends State<GiesNotesWidget> {

  Map<String, TextEditingController> _textEditingControllers = Map<String, TextEditingController>();
  FocusNode _focusNode = FocusNode();
  GlobalKey _focusKey = GlobalKey();

  @override
  void initState() {
    _focusNode = FocusNode();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      if (_focusKey.currentContext != null) {
        Scrollable.ensureVisible(_focusKey.currentContext!, duration: Duration(milliseconds: 300)).then((_) {
          _focusNode.requestFocus();
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textEditingControllers.forEach((key, value) {
      value.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    List<Widget> noteWidgets = <Widget>[];
    if ((widget.notes != null) && widget.notes!.isNotEmpty) {
      //Text(Localization().getStringEx('widget.gies.notes.label.add', 'Add to Notes:'), textAlign: TextAlign.center, style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 16, color: Styles().colors.fillColorPrimary),),
      for (dynamic note in widget.notes!) {
        if (note is Map) {
          String? noteId = JsonUtils.stringValue(note['id']);
          String title = JsonUtils.stringValue(note['title'])!;
          String? text = JsonUtils.stringValue(note['text']);

          TextEditingController? controller = _textEditingControllers[noteId];
          if ((controller == null) && (noteId != null)) {
            _textEditingControllers[noteId] = controller = TextEditingController(text: text ?? '');
          }

          noteWidgets.add(
              Padding(padding: EdgeInsets.only(bottom: 8), child:
              Column(key: (noteId == widget.focusNoteId) ? _focusKey : null, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 16, color: Styles().colors!.fillColorPrimary),),
                Container(height: 4,),
                TextField(
                  autocorrect: false,
                  focusNode: (noteId == widget.focusNoteId) ? _focusNode : null,
                  controller: controller,
                  maxLines: null,
                  decoration: InputDecoration(border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.0)), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.regular),
                ),
              ])
              )
          );
        }
      }
    }

    return ClipRRect(borderRadius: BorderRadius.all(Radius.circular(8)), child:
    Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),), child:
    Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Row(children: <Widget>[
        Expanded(child:
        Container(decoration: BoxDecoration(color: Styles().colors!.fillColorPrimary, borderRadius: BorderRadius.vertical(top: Radius.circular(8)),), child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child:
        Row(children: [
          Expanded(child:
          Text(Localization().getStringEx('widget.gies.notes.title', 'Things to Remember')!, style: TextStyle(fontSize: 20, color: Colors.white),),
          ),
          Semantics(
              label: Localization().getStringEx("dialog.close.title","Close"), button: true,
              child: InkWell(onTap:() {
                Analytics.instance.logAlert(text: "Things to Remember", selection: "Close");
                Navigator.of(context).pop();
              }, child:
              Container(height: 30, width: 30, decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(15)), border: Border.all(color: Styles().colors!.white!, width: 2),), child:
              Center(child:
              Text('\u00D7', style: TextStyle(fontSize: 24, color: Colors.white, ),semanticsLabel: "", ),
              ),
              ),
              )),
        ],),),
        ),
        ),
      ],
      ),
      Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child:
      Column(children: [
        Container(height: 240, child: noteWidgets.isNotEmpty
            ? SingleChildScrollView(child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: noteWidgets,),
        )
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Expanded(child: Container(),),
          Row(children: [
            Expanded(child:
            Text('No saved notes yet.', textAlign: TextAlign.center, style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 16, color: Styles().colors!.fillColorPrimary),),
            ),
          ]),
          Expanded(child: Container(),),
        ],),
        ),
        Container(height: 16,),
        Visibility(visible: (widget.notes != null) && widget.notes!.isNotEmpty, child:
        RoundedButton(
          label: Localization().getStringEx('widget.gies.notes.button.save', 'Save'),
          backgroundColor: Colors.transparent,
          textColor: Styles().colors!.fillColorPrimary,
          borderColor: Styles().colors!.fillColorSecondary,
          padding: EdgeInsets.symmetric(horizontal: 16, ),
          borderWidth: 2, height: 42,
          onTap: () => _onSave(),
        ),
        ),
      ]),
      )
    ],
    )
    ),
    );
  }

  void _onSave() {
    Analytics.instance.logAlert(text: "Things to Remember", selection: "Save");

    if (widget.notes != null) {
      for (dynamic note in widget.notes!) {
        if (note is Map) {
          String? noteId = JsonUtils.stringValue(note['id']);
          note['text'] = _textEditingControllers[noteId]?.text;
        }
      }
    }

    Storage().giesNotes = JsonUtils.encode(widget.notes);
    Navigator.of(context).pop();
  }

}

class _StepsHorizontalListWidget extends StatefulWidget{
  final List<dynamic>? tabs;
  final String? title;
  final int pageProgress;

  final void Function(String?)? onTapLink;
  final void Function(Map<String, dynamic> button, String panelId)? onTapButton;
  final void Function()? onTapBack;
  final void Function()? onTapNotes;

  const _StepsHorizontalListWidget({Key? key, this.tabs, this.title, this.onTapLink, this.onTapButton, this.onTapBack, this.pageProgress = 0, this.onTapNotes}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _StepsHorizontalListState();
}

class _StepsHorizontalListState extends State<_StepsHorizontalListWidget>{
  PageController? _pageController;
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildTabBar(),
          Stack(
            children: [
              _buildSlant(),
              _buildViewPager()
            ],
          ),
      ],)
    );
  }

  Widget _buildHeader(){
    return Container(
      padding: EdgeInsets.only(right: 16, left: 16, top: 16,),
      color: Styles().colors!.fillColorPrimary,
      child: Text(widget.title?? "", style: TextStyle(color: Styles().colors!.white, fontFamily: Styles().fontFamilies!.bold, fontSize: 24),),
    );
  }

  Widget _buildTabBar(){
    List<Widget> tabs = [];
    if(widget.tabs?.isNotEmpty ?? false){
      for(int i=0; i<widget.tabs!.length; i++){
        tabs.add(_buildTab(index: i, tabData: widget.tabs![i] ));
      }
    }

    tabs.add(
          GestureDetector(onTap: _onTapNotes,
            child: Padding(padding: EdgeInsets.only(top: 0, bottom: 0), child:
              Text(Localization().getStringEx('widget.gies.button.notes', 'Notes')!, style: TextStyle(color: Styles().colors!.white, fontFamily: Styles().fontFamilies!.bold, fontSize: 16, decoration: TextDecoration.underline, ),), // Styles().colors.fillColorSecondary
            ),
          ),
      );
    return Container(
      padding: EdgeInsets.only(right: 16, left: 16,),
      color: Styles().colors!.fillColorPrimary,
      child: Row(
        children: tabs,
      )
    );
  }

  Widget _buildTab({required int index, dynamic tabData}){
    String? tabKey = JsonUtils.stringValue(tabData["key"]);
    String? pageId = JsonUtils.stringValue(tabData["page_id"]);
    bool isCompleted = Gies().completedPages!.contains(pageId);
    bool isCurrentTab = _currentPage == index;
    Color textColor = Colors.white;
    String? textFamily = Styles().fontFamilies!.regular;
    if(isCompleted){
        textColor = Colors.greenAccent;
    }

    if(isCurrentTab){
      textFamily = Styles().fontFamilies!.extraBold;
    }
    return Container(
      child: GestureDetector(
        onTap: (){_onTapTabButton(index);},
        child: Container(
          padding: EdgeInsets.only(right: 16, top: 8, bottom: 8),
          child: Text("${widget.pageProgress}${tabKey??""}", style: TextStyle(color: textColor, fontFamily: textFamily, fontSize: 16, decoration: TextDecoration.underline),),
        )
      )
    );
  }

  Widget _buildViewPager(){
    List<Widget> pages = <Widget>[];
    if(widget.tabs?.isNotEmpty ?? false) {
      for (Map<String, dynamic>? page in widget.tabs!) {
        if (page != null) {
          pages.add( _buildCard(page));
        }
      }
    }

    double screenWidth = MediaQuery.of(context).size.width * 2/3;
    double pageHeight = MediaQuery.of(context).size.height * 4/7;
    double pageViewport = (screenWidth - 40) / screenWidth;

    if (_pageController == null) {
      _pageController = PageController(viewportFraction: pageViewport, keepPage: true);
    }

    return
      Padding(padding: EdgeInsets.only(top: 10, bottom: 20), child:
        Container(height: pageHeight, child:
          PageView(
            controller: _pageController,
            children: pages,
            onPageChanged: _onPageChanged,
          )
        )
      );
  }

  Widget _buildCard(Map<String, dynamic>? tab){
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child:Container(
          decoration: BoxDecoration(
              color: Styles().colors!.white,
              boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
              borderRadius: BorderRadius.all(Radius.circular(4)) // BorderRadius.all(Radius.circular(4))
          ),
          child: SingleChildScrollView(
            child:_GiesPageWidget( page: Gies().getPage(id: tab!["page_id"]),
              onTapBack: widget.onTapBack,
              onTapButton: (button, id){
                _onTapButton(button, id);
              },
              onTapLink: widget.onTapLink,))));
  }

  Widget _buildSlant() {
    return Column(children: <Widget>[
      Container(color:  Styles().colors!.fillColorPrimary, height: 40,),
      Container(color: Styles().colors!.fillColorPrimary, child:
      CustomPaint(painter: TrianglePainter(painterColor: Styles().colors!.white, left : true), child:
      Container(height: 55,),
      )),
    ],);
  }

  void _onTapButton(Map<String, dynamic> button, String panelId,){
    String? swipeToId = JsonUtils.stringValue(button["swipe_page"]); //This is _StepsHorizontalListWidget action the rest are global Page actions
    if(swipeToId!=null)
      _swipeToPage(swipeToId);
    
    if(widget.onTapButton!=null) {
      widget.onTapButton!(button, panelId);
    }
  }

  void _onTapTabButton(int index){
    _swipeToIndex(index);
  }

  void _onTapNotes(){
    if(widget.onTapNotes!=null)
      widget.onTapNotes!();
  }

  void _swipeToPage(String pageId){
    if(StringUtils.isNotEmpty(pageId)){
      int pageIndex = _getPageIndexById(pageId);
      _swipeToIndex(pageIndex);
    }
  }

  void _swipeToIndex(int pageIndex){
      if(pageIndex>=0)
        _pageController?.animateToPage(pageIndex, duration: Duration(milliseconds: 500), curve: Curves.linear);
  }

  int _getPageIndexById(String pageId){
    if((widget.tabs?.isNotEmpty ?? false)  && StringUtils.isNotEmpty(pageId)){
      return widget.tabs!.indexWhere((tab) => JsonUtils.stringValue(tab["page_id"]) == pageId);
    }
    return -1;
  }

  void _onPageChanged(int index){
    setState(() {
      _currentPage = index;
    });
  }
}