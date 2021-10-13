
import 'package:device_calendar/device_calendar.dart';
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/ExploreService.dart';

import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/model/Event.dart' as ExploreEvent;

class DeviceCalendar with Service implements NotificationsListener{

  static const String notifyPromptPopupMessage            = "edu.illinois.rokwire.device_calendar.messaging.message.popup";
  static const String notifyCalendarSelectionPopupMessage = "edu.illinois.rokwire.device_calendar.messaging.calendar_selection.popup";
  static const String notifyPlaceEventMessage             = "edu.illinois.rokwire.device_calendar.messaging.place.event";
  static const String showConsoleMessage                  = "edu.illinois.rokwire.debug_console.messaging.message";

  Calendar _defaultCalendar;
  List<Calendar> _deviceCalendars;
  Calendar _selectedCalendar;
  Map<String, String> _calendarEventIdTable;
  DeviceCalendarPlugin _deviceCalendarPlugin;

  static final DeviceCalendar _instance = DeviceCalendar._internal();

  factory DeviceCalendar(){
    return _instance;
  }

  DeviceCalendar._internal();

  @override
  void createService() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoriteChanged,
      DeviceCalendar.notifyPlaceEventMessage
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  Future<bool> _addEvent(DeviceCalendarEvent event) async{
    //User prefs
    if(!canAddToCalendar){
      _debugMessage("Disabled");
      return false;
    }

    if(_deviceCalendarPlugin == null){
      bool initResult = await _initDeviceCalendarPlugin();
      if(!initResult ?? true){
        _debugMessage("Unable to init plugin");
      }
    }
    
    if(canShowPrompt){
      _promptPermissionDialog(event);
      return true;
    }

    return _placeCalendarEvent(event);
  }

  Future<bool> _placeCalendarEvent(DeviceCalendarEvent event,) async{
    if(event == null)
      return false;

    //PLUGIN
    if(_deviceCalendarPlugin == null){
      bool initResult = await _initDeviceCalendarPlugin();
      if(!initResult ?? true){
        _debugMessage("Unable to init plugin");
      }
    }
    
    _debugMessage("Add to calendar- id:${calendar?.id}, name:${calendar?.name}, accountName:${calendar?.accountName}, accountType:${calendar?.accountType}, isReadOnly:${calendar?.isReadOnly}, isDefault:${calendar?.isDefault},");
    //PERMISSIONS
    bool hasPermissions = await _requestPermissions();

    _debugMessage("Has permissions: $hasPermissions");
    //PLACE
    if(hasPermissions && calendar!=null) {
      final createEventResult = await _deviceCalendarPlugin.createOrUpdateEvent(event.toCalendarEvent(calendar?.id));
      if(createEventResult?.data!=null){
        _storeEventId(event.internalEventId, createEventResult?.data);
      }

      _debugMessage("result.data: ${createEventResult.data}, result.errorMessages: ${createEventResult.errorMessages}");

      if(!createEventResult.isSuccess) {
        AppToast.show(createEventResult?.data ?? createEventResult?.errorMessages ?? "Unable to save Event to calendar");
        print(createEventResult?.errorMessages);
        return false;
      }
    }
    
    return true;
  }

  Future<bool> deleteEvent(DeviceCalendarEvent event) async{
    if(event == null)
      return false;

    if(_deviceCalendarPlugin == null){
      bool initResult = await _initDeviceCalendarPlugin();
      if(!initResult ?? true){
        _debugMessage("Unable to init plugin");
      }
    }

    String eventId = event?.internalEventId != null && _calendarEventIdTable!= null ? _calendarEventIdTable[event?.internalEventId] : null;
    _debugMessage("Try delete eventId: ${event.internalEventId} stored with calendarId: $eventId from calendarId ${calendar.id}");
    if(AppString.isStringEmpty(eventId)){
      return false;
    }

    final deleteEventResult = await _deviceCalendarPlugin.deleteEvent(calendar?.id, eventId);
    _debugMessage("delete result.data: ${deleteEventResult.data}, result.error: ${deleteEventResult.errorMessages}");
    if(deleteEventResult.isSuccess){
      _eraseEventId(event?.internalEventId);
    }
    return deleteEventResult?.isSuccess;
  }

  Future<bool> _initDeviceCalendarPlugin() async{
    _deviceCalendarPlugin = new DeviceCalendarPlugin();
    dynamic storedTable = Storage().calendarEventsTable ?? Map();
    _calendarEventIdTable = storedTable!=null ? Map<String, String>.from(storedTable): Map();
    return await _loadCalendars();
  }

  Future<bool> _loadCalendars() async {
    bool hasPermissions = await _requestPermissions();
    if(!hasPermissions) {
      return false;
    }
    final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
    List<Calendar> calendars = calendarsResult.data;
    _deviceCalendars = calendars!=null && calendars.isNotEmpty? calendars.where((Calendar calendar) => calendar.isReadOnly == false)?.toList() : null;
    if(AppCollection.isCollectionNotEmpty(_deviceCalendars)) {
      Calendar defaultCalendar = _deviceCalendars.firstWhere((element) => element.isDefault);
      if (defaultCalendar!= null){
        _defaultCalendar = defaultCalendar;
        return true;
      }
    }

    return false;
  }

  Future<List<Calendar>> refreshCalendars() async {
    await _loadCalendars();
    return _deviceCalendars;
  }

  Future<bool> _requestPermissions() async {
    var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
    if (permissionsGranted.isSuccess && !permissionsGranted.data) {
      permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
      if (!permissionsGranted.isSuccess || !permissionsGranted.data) {
        AppToast.show("Unable to save event to calendar. Permissions not granted");
        return false;
      }
    }

    return true;
  }

  void _storeEventId(String exploreId, String calendarEventId){
    _calendarEventIdTable[exploreId] = calendarEventId;
    Storage().calendarEventsTable = _calendarEventIdTable;
  }
  
  void _eraseEventId(String id){
    _calendarEventIdTable.removeWhere((key, value) => key == id);
  }

  void _debugMessage(String msg){
    NotificationService().notify(DeviceCalendar.showConsoleMessage, msg);
  }

  void _processEvents(dynamic event){
    DeviceCalendarEvent deviceCalendarEvent = DeviceCalendarEvent.from(event);
    if(deviceCalendarEvent==null)
      return;

    if (Auth2().isFavorite(event)) {
      _addEvent(deviceCalendarEvent);
    }
    else {
      deleteEvent(deviceCalendarEvent);
    }
  }

  void _promptPermissionDialog(DeviceCalendarEvent event) {
    NotificationService().notify(DeviceCalendar.notifyCalendarSelectionPopupMessage, {"event": event});
  }

  @override
  void onNotification(String name, param) {
    if(name == Auth2UserPrefs.notifyFavoriteChanged){
      _processEvents(param);
    } else if(name == DeviceCalendar.notifyPlaceEventMessage){
      if(param!=null && param is Map){
        DeviceCalendarEvent event = param["event"];
        Calendar calendarSelection = param["calendar"];
        if(calendarSelection!=null){
          _selectedCalendar = calendarSelection;
        }
        _placeCalendarEvent(event);
      }
    }
  }
  
  bool get canAddToCalendar{
    return Storage().calendarEnabledToSave ?? false;
  }
  
  bool get canShowPrompt{
    return Storage().calendarCanPrompt ?? false;
  }
  
  Calendar get calendar{
    return _selectedCalendar ?? _defaultCalendar;
  }

  set calendar(Calendar calendar){
    _selectedCalendar = calendar;
  }
}

class DeviceCalendarEvent {
  String internalEventId;
  String title;
  String deepLinkUrl;
  DateTime startDate;
  DateTime endDate;

  DeviceCalendarEvent({this.internalEventId, this.title, this.deepLinkUrl, this.startDate, this.endDate});

  factory DeviceCalendarEvent.from(dynamic data){
    if(data==null)
      return null;

    if(data is ExploreEvent.Event){
      return DeviceCalendarEvent.fromEvent(data);
    }
    else if (data is Game){
      return DeviceCalendarEvent.fromGame(data);
    }

    return null;
  }

  factory DeviceCalendarEvent.fromEvent(ExploreEvent.Event event){
    if(event==null)
      return null;

    return DeviceCalendarEvent(title: event.title, internalEventId: event.id, startDate: event.startDateLocal, endDate: event.endDateLocal,
        deepLinkUrl: "${ExploreService.EVENT_URI}?event_id=${event.id}");
  }

  factory DeviceCalendarEvent.fromGame(Game game){
    if(game==null)
      return null;

    return DeviceCalendarEvent(title: game.title, internalEventId: game.id, startDate: game.dateTimeUniLocal,
        endDate:  AppDateTime().getUniLocalTimeFromUtcTime(game.endDateTimeUtc),
        deepLinkUrl: "${ExploreService.EVENT_URI}?game_id=${game.id}");
  }

  Event toCalendarEvent(String calendarId){
    Event calendarEvent = Event(calendarId);
    calendarEvent.title = title ?? "";
    if (startDate != null) {
      calendarEvent.start = startDate;
    }
    if (endDate != null) {
      calendarEvent.end = endDate;
    } else {
      calendarEvent.end = DateTime(
        startDate.year, startDate.month,
        startDate.day, 23, 59,);
    }

    calendarEvent.description = _constructRedirectLinkUrl(deepLinkUrl);

    return calendarEvent;
  }

  static String _constructRedirectLinkUrl(String url){

    Uri assetsUri = Uri.parse(Config().assetsUrl);
    String redirectUrl = assetsUri!= null ? "${assetsUri.scheme}://${assetsUri.host}/html/redirect.html" : null;

    return AppString.isStringNotEmpty(redirectUrl) ? "$redirectUrl?target=$url" : url;
  }

}