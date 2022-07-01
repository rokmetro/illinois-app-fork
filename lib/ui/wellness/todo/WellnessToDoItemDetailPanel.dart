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
import 'package:illinois/model/wellness/ToDo.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/Wellness.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class WellnessToDoItemDetailPanel extends StatefulWidget {
  final ToDoItem? item;
  WellnessToDoItemDetailPanel({this.item});

  @override
  State<WellnessToDoItemDetailPanel> createState() => _WellnessToDoItemDetailPanelState();
}

class _WellnessToDoItemDetailPanelState extends State<WellnessToDoItemDetailPanel> {
  static final String _workDayFormat = 'yyyy-MM-dd';

  ToDoItem? _item;
  ToDoCategory? _category;
  List<ToDoCategory>? _categories;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  List<DateTime>? _workDays;
  ToDoItemLocation? _location;
  bool _optionalFieldsVisible = false;
  bool _categoriesDropDownVisible = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    if (_item != null) {
      _populateItemFields();
    }
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.wellness.home.header.title', 'Wellness')),
      body:
          SingleChildScrollView(child: Padding(padding: EdgeInsets.all(16), child: (_loading ? _buildLoadingContent() : _buildContent()))),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildAddItemHeader(),
      _buildItemName(),
      _buildOptionalFieldsHeader(),
      Visibility(
          visible: _optionalFieldsVisible,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildCurrentCategoryContainer(),
            Stack(children: [
              Column(children: [
                _buildDueDateContainer(),
                _buildDueTimeContainer(),
                _buildWorkDaysContainer(),
                _buildLocationContainer(),
                _buildDescriptionContainer()
              ]),
              _buildCategoryDropDown()
            ])
          ])),
      _buildSaveButton()
    ]);
  }

  Widget _buildLoadingContent() {
    return Center(
        child: Column(children: <Widget>[
      Container(height: MediaQuery.of(context).size.height / 5),
      CircularProgressIndicator(),
      Container(height: MediaQuery.of(context).size.height / 5 * 3)
    ]));
  }

  Widget _buildAddItemHeader() {
    return Padding(
        padding: EdgeInsets.only(top: 16),
        child: Text(Localization().getStringEx('panel.wellness.todo.item.add.label', 'Add an Item'),
            style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.bold)));
  }

  Widget _buildItemName() {
    return Padding(
        padding: EdgeInsets.only(top: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: _buildFieldLabel(label: Localization().getStringEx('panel.wellness.todo.item.name.field.label', 'ITEM NAME'))),
          _buildInputField(controller: _nameController)
        ]));
  }

  Widget _buildOptionalFieldsHeader() {
    return GestureDetector(
        onTap: _onTapOptionalFields,
        child: Container(
            color: Colors.transparent,
            child: Padding(
                padding: EdgeInsets.only(top: 22),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(height: 1, color: Styles().colors!.mediumGray2),
                  Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        Text(Localization().getStringEx('panel.wellness.todo.item.optional_fields.label', 'Optional Fields'),
                            style:
                                TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 14, fontFamily: Styles().fontFamilies!.bold)),
                        Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Image.asset(_optionalFieldsVisible ? 'images/icon-up.png' : 'images/icon-down.png',
                                color: Styles().colors!.fillColorPrimary))
                      ]))
                ]))));
  }

  Widget _buildCurrentCategoryContainer() {
    return Padding(
        padding: EdgeInsets.only(top: 11),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: _buildFieldLabel(label: Localization().getStringEx('panel.wellness.todo.item.category.field.label', 'CATEGORY'))),
          GestureDetector(
              onTap: _onTapCurrentCategory,
              child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  decoration:
                      BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.mediumGray!, width: 1)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Text(
                        StringUtils.ensureNotEmpty(_category?.name,
                            defaultValue: Localization().getStringEx('panel.wellness.todo.item.category.none.label', 'None')),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies!.regular, color: Styles().colors!.textSurface)),
                    Expanded(child: Container()),
                    Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Image.asset(_categoriesDropDownVisible ? 'images/icon-up.png' : 'images/icon-down-orange.png'))
                  ])))
        ]));
  }

  Widget _buildCategoryDropDown() {
    List<Widget> widgetList = <Widget>[];
    if (CollectionUtils.isNotEmpty(_categories)) {
      widgetList.add(Container(color: Styles().colors!.fillColorSecondary, height: 2));
      widgetList.add(_buildCategoryItem(null));
      for (ToDoCategory category in _categories!) {
        widgetList.add(_buildCategoryItem(category));
      }
    }
    return Visibility(
        visible: _categoriesDropDownVisible, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgetList));
  }

  Widget _buildCategoryItem(ToDoCategory? category) {
    bool isSelected = (category == _category);
    BorderSide borderSide = BorderSide(color: Styles().colors!.fillColorPrimary!, width: 1);
    return GestureDetector(
        onTap: () => _onTapCategory(category),
        child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, border: Border(left: borderSide, right: borderSide, bottom: borderSide)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(StringUtils.ensureNotEmpty(category?.name, defaultValue: Localization().getStringEx('panel.wellness.todo.item.category.none.label', 'None')),
                  style: TextStyle(fontSize: 16, color: Styles().colors!.textSurfaceAccent, fontFamily: Styles().fontFamilies!.regular)),
              Image.asset(isSelected ? 'images/icon-favorite-selected.png' : 'images/icon-favorite-deselected.png')
            ])));
  }

  Widget _buildDueDateContainer() {
    return Padding(
        padding: EdgeInsets.only(top: 17),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: _buildFieldLabel(label: Localization().getStringEx('panel.wellness.todo.item.due_date.field.label', 'DUE DATE'))),
          GestureDetector(
              onTap: _onTapDueDate,
              child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  decoration:
                      BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.mediumGray!, width: 1)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Text(StringUtils.ensureNotEmpty(_formattedDueDate),
                        style: TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies!.regular, color: Styles().colors!.textSurface)),
                    Expanded(child: Container()),
                    Image.asset('images/icon-calendar-grey.png')
                  ])))
        ]));
  }

  Widget _buildDueTimeContainer() {
    return Padding(
        padding: EdgeInsets.only(top: 17),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: _buildFieldLabel(label: Localization().getStringEx('panel.wellness.todo.item.due_time.field.label', 'TIME DUE'))),
          GestureDetector(
              onTap: _onTapDueTime,
              child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  decoration:
                      BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.mediumGray!, width: 1)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Text(StringUtils.ensureNotEmpty(_formattedDueTime),
                        style: TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies!.regular, color: Styles().colors!.textSurface)),
                    Expanded(child: Container())
                  ])))
        ]));
  }

  Widget _buildWorkDaysContainer() {
    return Padding(
        padding: EdgeInsets.only(top: 17),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: _buildFieldLabel(label: Localization().getStringEx('panel.wellness.todo.item.work_days.field.label', 'DAYS TO WORK ON ITEM'))),
          GestureDetector(
              onTap: _onTapWorkDays,
              child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: (CollectionUtils.isEmpty(_workDays) ? 24 : 12)),
                  decoration:
                      BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.mediumGray!, width: 1)),
                  child: Row(children: [
                    Expanded(
                        child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: _buildWorkDaysWidgetList())))
                  ])))
        ]));
  }

  List<Widget> _buildWorkDaysWidgetList() {
    List<Widget> widgetList = <Widget>[];
    if (_workDays != null) {
      for (DateTime date in _workDays!) {
        widgetList.add(Padding(padding: EdgeInsets.only(left: 5), child: _buildWorkDayWidget(date: date)));
      }
    }
    return widgetList;
  }

  Widget _buildWorkDayWidget({required DateTime date}) {
    return Padding(
        padding: EdgeInsets.only(left: 5),
        child: Container(
            decoration: BoxDecoration(color: Styles().colors!.lightGray),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Text(StringUtils.ensureNotEmpty(AppDateTime().formatDateTime(date, format: 'EEEE, MM/dd', ignoreTimeZone: true)),
                      style: TextStyle(fontSize: 11, color: Colors.black, fontFamily: Styles().fontFamilies!.regular))),
              GestureDetector(
                  onTap: () => _onTapRemoveWorkDay(date),
                  child: Container(
                      color: Styles().colors!.lightGray,
                      child: Padding(
                          padding: EdgeInsets.only(left: 25, top: 7, right: 10, bottom: 7),
                          child: Image.asset('images/icon-x-orange-small.png', color: Colors.black))))
            ])));
  }

  Widget _buildLocationContainer() {
    return Padding(
        padding: EdgeInsets.only(top: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: _buildFieldLabel(label: Localization().getStringEx('panel.wellness.todo.item.location.field.label', 'LOCATION'))),
          GestureDetector(
              onTap: _onTapLocation,
              child: Row(children: [
                Expanded(
                    child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                        decoration:
                            BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.mediumGray!, width: 1)),
                        child: Text(StringUtils.ensureNotEmpty(_formattedLocation),
                            style:
                                TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies!.regular, color: Styles().colors!.textSurface))))
              ]))
        ]));
  }

  Widget _buildDescriptionContainer() {
    return Padding(
        padding: EdgeInsets.only(top: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: EdgeInsets.only(bottom: 5),
              child:
                  _buildFieldLabel(label: Localization().getStringEx('panel.wellness.todo.item.description.field.label', 'DESCRIPTION'))),
          _buildInputField(controller: _descriptionController)
        ]));
  }

  Widget _buildFieldLabel({required String label}) {
    return Text(label, style: TextStyle(color: Styles().colors!.textSurfaceAccent, fontSize: 12, fontFamily: Styles().fontFamilies!.bold));
  }

  Widget _buildInputField({required TextEditingController controller}) {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: Styles().colors!.white, border: Border.all(color: Styles().colors!.mediumGray!, width: 1)),
        child: TextField(
            controller: controller,
            decoration: InputDecoration(border: InputBorder.none),
            style: TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies!.regular, color: Styles().colors!.textSurface)));
  }

  Widget _buildSaveButton() {
    bool hasItemForEdit = (_item != null);
    return Center(
        child: Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
              Flexible(flex: (hasItemForEdit ? 1 : 0), child: Visibility(visible: hasItemForEdit, child: RoundedButton(
                label: Localization().getStringEx('panel.wellness.todo.item.delete.button', 'Delete'),
                borderColor: Styles().colors!.fillColorPrimary,
                contentWeight: (hasItemForEdit ? 1 : 0),
                padding: EdgeInsets.symmetric(horizontal: 46, vertical: 8),
                onTap: _onTapDelete))),
              Visibility(visible: hasItemForEdit, child: Container(width: 15)),
              Flexible(flex: (hasItemForEdit ? 1 : 0), child: RoundedButton(
                label: Localization().getStringEx('panel.wellness.todo.item.save.button', 'Save'),
                contentWeight: (hasItemForEdit ? 1 : 0),
                padding: EdgeInsets.symmetric(horizontal: 46, vertical: 8),
                onTap: _onTapSave))
            ])));
  }

  void _onTapOptionalFields() {
    _hideKeyboard();
    _optionalFieldsVisible = !_optionalFieldsVisible;
    if (_optionalFieldsVisible == false) {
      _categoriesDropDownVisible = false;
    }
    _updateState();
  }

  void _onTapCurrentCategory() {
    _hideKeyboard();
    _categoriesDropDownVisible = !_categoriesDropDownVisible;
    _updateState();
  }

  void _onTapCategory(ToDoCategory? category) {
    _hideKeyboard();
    if (_category != category) {
      _category = category;
    }
    _categoriesDropDownVisible = !_categoriesDropDownVisible;
    _updateState();
  }

  void _onTapDueDate() async {
    _hideKeyboard();
    DateTime? resultDate = await _pickDate(initialDate: _dueDate);
    if (resultDate != null) {
      _dueDate = resultDate;
      _updateState();
    }
  }

  void _onTapDueTime() async {
    if (_dueDate == null) {
      return;
    }
    _hideKeyboard();
    TimeOfDay initialTime = _dueTime ?? TimeOfDay.now();
    TimeOfDay? resultTime = await showTimePicker(context: context, initialTime: initialTime);
    if (resultTime != null) {
      _dueTime = resultTime;
      _updateState();
    }
  }

  void _onTapWorkDays() async {
    DateTime? resultDate = await _pickDate(initialDate: _workDays?.last);
    if ((resultDate != null) && !(_workDays?.contains(resultDate) ?? false)) {
      if (_workDays == null) {
        _workDays = <DateTime>[];
      }
      _workDays!.add(resultDate);
      _workDays!.sort();
      _updateState();
    }
  }

  void _onTapRemoveWorkDay(DateTime date) {
    if (_workDays?.contains(date) ?? false) {
      _workDays!.remove(date);
      _updateState();
    }
  }

  void _onTapLocation() async {
    _setLoading(true);
    String? location = await NativeCommunicator().launchSelectLocation();
    if (location != null) {
      Map<String, dynamic>? locationSelectionResult = JsonUtils.decodeMap(location);
      if (locationSelectionResult != null && locationSelectionResult.isNotEmpty) {
        Map<String, dynamic>? locationData = locationSelectionResult["location"];
        if (locationData != null) {
          double? lat = JsonUtils.doubleValue(locationData['latitude']);
          double? long = JsonUtils.doubleValue(locationData['longitude']);
          _location = ToDoItemLocation(latitude: lat, longitude: long);
        }
      }
    }
    _setLoading(false);
  }

  Future<DateTime?> _pickDate({DateTime? initialDate}) async {
    if (initialDate == null) {
      initialDate = DateTime.now();
    }
    final int oneYearInDays = 365;
    DateTime firstDate = DateTime.fromMillisecondsSinceEpoch(initialDate.subtract(Duration(days: oneYearInDays)).millisecondsSinceEpoch);
    DateTime lastDate = DateTime.fromMillisecondsSinceEpoch(initialDate.add(Duration(days: oneYearInDays)).millisecondsSinceEpoch);
    DateTime? resultDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        builder: (BuildContext context, Widget? child) {
          return Theme(data: ThemeData.light(), child: child!);
        });
    return resultDate;
  }

  void _onTapDelete() {
    if (_item == null) {
      AppAlert.showDialogResult(
          context, Localization().getStringEx('panel.wellness.todo.item.delete.no_item.msg', 'There is no selected item to delete.'));
      return;
    }

    AppAlert.showConfirmationDialog(
        buildContext: context,
        message: Localization()
            .getStringEx('panel.wellness.todo.item.delete.confirmation.msg', 'Are sure that you want to delete this To-Do item?'),
        positiveCallback: () => _deleteToDoItem());
  }

  void _deleteToDoItem() {
    _setLoading(true);
    Wellness().deleteToDoItem(_item!.id!).then((success) {
      late String msg;
      if (success) {
        msg = Localization().getStringEx('panel.wellness.todo.item.delete.succeeded.msg', 'To-Do item deleted successfully.');
      } else {
        msg = Localization().getStringEx('panel.wellness.todo.item.delete.failed.msg', 'Failed to delete To-Do item.');
      }
      AppAlert.showDialogResult(context, msg).then((_) {
        if (success) {
          Navigator.of(context).pop();
        }
      });
      _setLoading(false);
    });
  }

  void _onTapSave() {
    _hideKeyboard();
    String name = _nameController.text;
    if (StringUtils.isEmpty(name)) {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.wellness.todo.item.empty.name.msg', 'Please, fill name.'));
      return;
    }
    _setLoading(true);
    bool hasDueTime = false;
    if (_dueDate != null) {
      if (_dueTime != null) {
        hasDueTime = true;
        _dueDate = DateTime(_dueDate!.year, _dueDate!.month, _dueDate!.day, _dueTime!.hour, _dueTime!.minute);
      }
    }
    String? description = StringUtils.isNotEmpty(_descriptionController.text) ? _descriptionController.text : null;
    ToDoItem itemToSave = ToDoItem(
        id: _item?.id,
        name: name,
        category: _category,
        dueDateTimeUtc: _dueDate?.toUtc(),
        hasDueTime: hasDueTime,
        location: _location,
        isCompleted: _item?.isCompleted ?? false,
        description: description,
        workDays: _formattedWorkDays,
        reminderDateTimeUtc: _reminderDateTimeUtc);
    if (_item?.id != null) {
      Wellness().updateToDoItem(itemToSave).then((success) {
        _onSaveCompleted(success);
      });
    } else {
      Wellness().createToDoItem(itemToSave).then((success) {
        _onSaveCompleted(success);
      });
    }
  }

  void _onSaveCompleted(bool success) {
    late String msg;
      if (success) {
        msg = Localization().getStringEx('panel.wellness.todo.item.save.succeeded.msg', 'To-Do item saved successfully.');
      } else {
        msg = Localization().getStringEx('panel.wellness.todo.item.save.failed.msg', 'Failed to save To-Do item.');
      }
      AppAlert.showDialogResult(context, msg).then((_) {
        if (success) {
          Navigator.of(context).pop();
        }
      });
      _setLoading(false);
  }

  void _loadCategories() {
    _setLoading(true);
    Wellness().loadToDoCategories().then((categories) {
      _categories = categories;
      _setLoading(false);
    });
  }

  void _populateItemFields() {
    _category = _item?.category;
    _nameController.text = StringUtils.ensureNotEmpty(_item?.name);
    _descriptionController.text = StringUtils.ensureNotEmpty(_item?.description);
    _dueDate = _item?.dueDateTime;
    if ((_dueDate != null) && (_item?.hasDueTime ?? false) == true) {
      _dueTime = TimeOfDay(hour: _dueDate!.hour, minute: _dueDate!.minute);
    }
    if (CollectionUtils.isNotEmpty(_item?.workDays)) {
      _workDays = <DateTime>[];
      for (String dateString in _item!.workDays!) {
        DateTime? workDate = DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(dateString), format: _workDayFormat, isUtc: false);
        if (workDate != null) {
          _workDays!.add(workDate);
        }
      }
    }
    _location = _item?.location;
  }

  void _setLoading(bool loading) {
    _loading = loading;
    _updateState();
  }

  void _hideKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  String? get _formattedDueDate {
    return AppDateTime().formatDateTime(_dueDate, format: 'MM/dd/yy', ignoreTimeZone: true);
  }

  String? get _formattedDueTime {
    if ((_dueDate == null) || (_dueTime == null)) {
      return null;
    }
    DateTime time = DateTime(_dueDate!.year, _dueDate!.month, _dueDate!.day, _dueTime!.hour, _dueTime!.minute);
    return AppDateTime().formatDateTime(time, format: 'h:mm a', ignoreTimeZone: true);
  }

  String? get _formattedLocation {
    if (_location != null) {
      return '${_location?.latitude}, ${_location?.longitude}';
    } else {
      return null;
    }
  }

  List<String>? get _formattedWorkDays {
    if (CollectionUtils.isEmpty(_workDays)) {
      return null;
    }
    List<String> stringList = <String>[];
    for (DateTime day in _workDays!) {
      String? formattedWorkDay = AppDateTime().formatDateTime(day, format: _workDayFormat, ignoreTimeZone: true);
      if (StringUtils.isNotEmpty(formattedWorkDay)) {
        stringList.add(formattedWorkDay!);
      }
    }
    return stringList;
  }

  DateTime? get _reminderDateTimeUtc {
    if (_dueDate == null) {
      return null;
    }
    ToDoCategoryReminderType? reminderType = _category?.reminderType;
    if((reminderType == null) || (reminderType == ToDoCategoryReminderType.none)) {
      return null;
    }
    // Do not set reminder date if there is no due date or the reminder type is none.
    int dayDiff = (reminderType == ToDoCategoryReminderType.night_before) ? -1 : 0;
    int hour = (reminderType == ToDoCategoryReminderType.night_before) ? 17 : 9; // predefined day hours
    DateTime reminderDateTime = DateTime(_dueDate!.year, _dueDate!.month, (_dueDate!.day + dayDiff), hour);
    return reminderDateTime.toUtc();
  }
}