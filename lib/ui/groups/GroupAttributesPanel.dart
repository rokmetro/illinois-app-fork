import 'dart:collection';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/ContentAttributes.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:sprintf/sprintf.dart';


class GroupAttributesPanel extends StatefulWidget {
  final bool filtersMode;
  final ContentAttributes contentAttributes;
  final Map<String, dynamic>? selection;

  GroupAttributesPanel({Key? key, required this.contentAttributes, this.selection, this.filtersMode = false }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GroupAttributesPanelState();
}

class _GroupAttributesPanelState extends State<GroupAttributesPanel> {

  final Map<String, GlobalKey> dropdownKeys = <String, GlobalKey>{};
  Map<String, LinkedHashSet<String>> _selection = <String, LinkedHashSet<String>>{};

  @override
  void initState() {
    if (widget.selection != null) {
      _selection = ContentAttributes.selectionFromAttributesSelection(widget.selection) ?? Map<String, LinkedHashSet<String>>();
    }
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String headerTitle = widget.filtersMode ?
      Localization().getStringEx('panel.group.attributes.filters.header.title', 'Group Filters') : 
      Localization().getStringEx('panel.group.attributes.attributes.header.title', 'Group Attributes');
    return Scaffold(
      appBar: HeaderBar(title: headerTitle),
      backgroundColor: Styles().colors?.background,
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    List<ContentAttributesCategory>? categories = widget.contentAttributes.categories;
    return ((categories != null) && categories.isNotEmpty) ? Column(children: <Widget>[
      Expanded(child:
        Container(padding: EdgeInsets.only(left: 16, right: 24, top: 8), child:
          SingleChildScrollView(child:
            _buildCategoriesContent(),
          ),
        ),
      ),
      // Container(height: 1, color: Styles().colors?.surfaceAccent),
      _buildCommands(),
    ]) : Container();
  }

  Widget _buildCategoriesContent() {
    List<ContentAttributesCategory>? categories = widget.contentAttributes.categories;
    List<Widget> conentList = <Widget>[];
    if ((categories != null) && categories.isNotEmpty) {
      for (ContentAttributesCategory category in categories) {
        conentList.add(_buildAttributesDropDown(category));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: conentList,); 
  }

  Widget _buildAttributesDropDown(ContentAttributesCategory category) {
    List<ContentAttribute>? attributes = category.attributesFromSelection(_selection);
    if ((attributes != null) && (0 < attributes.length) && !widget.filtersMode && category.isSingleSelection /* && !category.requiresSelection*/) {
      attributes.insert(0, _ContentNullAttribute());
    }

    LinkedHashSet<String>? categoryLabels = _selection[category.title];
    ContentAttribute? selectedAttribute = ((categoryLabels != null) && categoryLabels.isNotEmpty) ?
      ((1 < categoryLabels.length) ? _ContentMultipleAttributes(categoryLabels) : category.findAttribute(label: categoryLabels.first)) : null;
    
    return Visibility(visible: attributes?.isNotEmpty ?? false, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        GroupSectionTitle(
          title: widget.contentAttributes.stringValue(category.title)?.toUpperCase(),
          description: widget.contentAttributes.stringValue(category.description),
          requiredMark: !widget.filtersMode && (0 < (category.minRequiredCount ?? 0)),
        ),
        GroupDropDownButton<ContentAttribute>(
          key: dropdownKeys[category.title ?? ''] ??= GlobalKey(),
          emptySelectionText: widget.contentAttributes.stringValue(category.emptyLabel),
          buttonHint: widget.contentAttributes.stringValue(category.hint),
          items: attributes,
          initialSelectedValue: selectedAttribute,
          multipleSelection: (!widget.filtersMode && category.isMultipleSelection) || widget.filtersMode,
          enabled: attributes?.isNotEmpty ?? false,
          itemHeight: null,
          constructTitle: (ContentAttribute attribute) => _constructAttributeTitle(category, attribute),
          isItemSelected: (ContentAttribute attribute) => _isAttributeSelected(category, attribute),
          isItemEnabled: (ContentAttribute attribute) => (attribute is! _ContentNullAttribute),
          onItemSelected: (ContentAttribute attribute) => _onAttributeSelected(category, attribute),
          onValueChanged: (ContentAttribute attribute) => _onAttributeChanged(category, attribute),
        ),
      ]),
    );
  }

  String? _constructAttributeTitle(ContentAttributesCategory category, ContentAttribute attribute) {
    if (attribute is _ContentMultipleAttributes) {
      return attribute.toString(contentAttributes: widget.contentAttributes);
    }
    else if (attribute is _ContentNullAttribute) {
      return attribute.toString(contentAttributes: widget.contentAttributes, category: category);
    }
    else {
      return widget.contentAttributes.stringValue(attribute.label);
    }
  }

  bool _isAttributeSelected(ContentAttributesCategory category, ContentAttribute attribute) {
    LinkedHashSet<String>? categoryLabels = _selection[category.title];
    if (attribute is _ContentMultipleAttributes) {
      return categoryLabels?.containsAll(attribute.labels) ?? false;
    }
    else if (attribute is _ContentNullAttribute) {
      return false;
    }
    else {
      return categoryLabels?.contains(attribute.label) ?? false;
    }
  }

  void _onAttributeSelected(ContentAttributesCategory category, ContentAttribute attribute) {
  }

  void _onAttributeChanged(ContentAttributesCategory category, ContentAttribute attribute) {
    String? categoryTitle = category.title;
    if (categoryTitle != null) {
      LinkedHashSet<String> categoryLabels = (_selection[categoryTitle] ??= LinkedHashSet<String>());
      setStateIfMounted(() {

        if (attribute is _ContentMultipleAttributes) {
          if (categoryLabels.containsAll(attribute.labels)) {
            categoryLabels.removeAll(attribute.labels);
          }
          else {
            categoryLabels.addAll(attribute.labels);
          }
        }
        else if (attribute is _ContentNullAttribute) {
          categoryLabels.clear();
        }
        else {
          String? attributeLabel = attribute.label;
          if (attributeLabel != null) {
            if (categoryLabels.contains(attributeLabel)) {
              categoryLabels.remove(attributeLabel);
            }
            else {
              categoryLabels.add(attributeLabel);
            }
          }
        }

        if (!widget.filtersMode && (category.maxRequiredCount != null)) {
          while (category.maxRequiredCount! < categoryLabels.length) {
            categoryLabels.remove(categoryLabels.first);
          }
        }

        widget.contentAttributes.validateSelection(_selection);
      });
    }

    if ((!widget.filtersMode && category.isMultipleSelection) || widget.filtersMode) {
      // Ugly workaround: show again dropdown popup if category supports multiple select.
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        final RenderObject? renderBox = dropdownKeys[category.title]?.currentContext?.findRenderObject();
        if (renderBox is RenderBox) {
          Offset globalOffset = renderBox.localToGlobal(Offset(renderBox.size.width / 2, renderBox.size.height / 2));
          GestureBinding.instance.handlePointerEvent(PointerDownEvent(position: globalOffset,));
          //Future.delayed(Duration(milliseconds: 100)).then((_) =>);
          GestureBinding.instance.handlePointerEvent(PointerUpEvent(position: globalOffset,));
        }
      });
    }
  }

  bool get _isSelectionNotEmpty {
    for (LinkedHashSet<String> attributeLabels in _selection.values) {
      if (attributeLabels.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  Widget _buildCommands() {
    List<Widget> buttons = <Widget>[];

    if (widget.filtersMode) {
      bool canClear = _isSelectionNotEmpty;
      buttons.addAll(<Widget>[
        Expanded(child: RoundedButton(
          label: Localization().getStringEx('panel.group.attributes.button.clear.title', 'Clear'),
          textColor: canClear ? Styles().colors?.fillColorPrimary : Styles().colors?.surfaceAccent,
          borderColor: canClear ? Styles().colors?.fillColorSecondary : Styles().colors?.surfaceAccent ,
          backgroundColor: Styles().colors?.white,
          enabled: canClear,
          onTap: _onTapClear
        )
      )]);
    }

    bool canApply = (widget.filtersMode && _isSelectionNotEmpty) || (!widget.filtersMode && (widget.contentAttributes.unsatisfiedCategoryFromSelection(_selection) == null));
    String applyTitle = widget.filtersMode ? 
      Localization().getStringEx('panel.group.attributes.button.filter.title', 'Filter') :
      Localization().getStringEx('panel.group.attributes.button.apply.title', 'Apply Attributes');
    buttons.add(Expanded(child:
      RoundedButton(
        label: applyTitle,
        textColor: canApply ? Styles().colors?.fillColorPrimary : Styles().colors?.surfaceAccent,
        borderColor: canApply ? Styles().colors?.fillColorSecondary : Styles().colors?.surfaceAccent ,
        backgroundColor: Styles().colors?.white,
        enabled: canApply,
        onTap: _onTapApply
      )
    ));
    return SafeArea(child:
      Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
        Row(children: buttons,)
      )
    );
  }

  void _onTapApply() {
    Analytics().logSelect(target: 'Apply');
    Navigator.of(context).pop(ContentAttributes.selectionToAttributesSelection(_selection) ?? <String, dynamic>{});
  }

  void _onTapClear() {
    Analytics().logSelect(target: 'Clear');
    Navigator.of(context).pop(<String, dynamic>{});
  }
}

class _ContentMultipleAttributes extends ContentAttribute {
  final LinkedHashSet<String> labels;
  _ContentMultipleAttributes(this.labels);

  String toString({ContentAttributes? contentAttributes}) {
    String title = '';
    for (String attributeLabel in labels) {
      String attributeName = contentAttributes?.stringValue(attributeLabel) ?? attributeLabel;
      if (attributeName.isNotEmpty) {
        if (title.isNotEmpty) {
          title += ', ';
        }
        title += attributeName;
      }
    }
    return title;
  }
}

class _ContentNullAttribute extends ContentAttribute {
  String toString({ContentAttributes? contentAttributes, ContentAttributesCategory? category}) {
    String? categoryTitle = category?.title;
    if ((categoryTitle != null) && categoryTitle.isNotEmpty) {
      return sprintf(Localization().getStringEx('panel.group.attributes.label.no_selection.title.format', 'No %s'), [
        contentAttributes?.stringValue(categoryTitle) ?? categoryTitle
      ]);
    }
    else {
      return Localization().getStringEx('panel.group.attributes.label.no_selection.title', 'None');
    }
  }
}

