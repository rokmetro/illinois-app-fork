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


import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/utils/utils.dart';

typedef void MapWidgetCreatedCallback(MapController controller);

class MapWidget extends StatefulWidget {
  final MapWidgetCreatedCallback? onMapCreated;
  final dynamic creationParams;

  const MapWidget({Key? key, this.onMapCreated, this.creationParams}) : super(key: key);

  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: 'mapview',
        onPlatformViewCreated: onPlatformViewCreated,
        creationParamsCodec: const StandardMessageCodec(),
        creationParams: widget.creationParams,
      );
    } else if(defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'mapview',
        onPlatformViewCreated: onPlatformViewCreated,
        creationParamsCodec: const StandardMessageCodec(),
        creationParams: widget.creationParams,
      );
    }
    return Text('$defaultTargetPlatform is not yet supported by this plugin');
  }

  Future<void> onPlatformViewCreated(id) async {
    if (widget.onMapCreated == null) {
      return;
    }
    widget.onMapCreated!(MapController.init(id));
  }
}

class MapController {
  static const int DefaultMapThresholdDistance = 200;

  static const String LocationThresoldDistanceParam = 'LocationThresoldDistance';
  static const String HideBuildingLabelsParams = 'HideBuildingLabels';
  static const String HideBusStopPOIsParams = 'HideBusStopPOIs';
  static const String ShowMarkerPopupsParams = 'ShowMarkerPopus';
  static const String UpdateOnlyParams = 'UpdateOnly';

  late MethodChannel _channel;
  int? _mapId;


  MapController.init(int id) {
    _mapId = id;
    _channel = MethodChannel('mapview_$id');
  }

  int? get mapId { return _mapId; }

  Future<void> placePOIs(List<Explore>? explores, { Map<String, dynamic>? options }) async {
    List<dynamic> jsonData = [];
    if (CollectionUtils.isNotEmpty(explores)) {
      for (Explore explore in explores!) {
        jsonData.add(explore.toJson());
      }
    }

    Map<String, dynamic> optionsParam = <String, dynamic>{
      LocationThresoldDistanceParam: Storage().debugMapThresholdDistance // ?? DefaultMapThresholdDistance
    };
    if (options != null) {
      optionsParam.addAll(options);
    }

    return _channel.invokeMethod('placePOIs', { "explores": jsonData, "options": optionsParam});
  }

  Future<void>enable(bool enable) async {
    return _channel.invokeMethod('enable', enable);
  }

  Future<void>fixZOrder() async {
    return _channel.invokeMethod('fixZOrder');
  }

  Future<void>enableMyLocation(bool enable) async {
    return _channel.invokeMethod('enableMyLocation', enable);
  }

  Future<void> viewPOI(Map<String, dynamic>? target) async {
    return _channel.invokeMethod('viewPOI', {'target': target});
  }

  Future<void> markPOI(Explore? explore) async {
    return _channel.invokeMethod('markPOI', {'explore': explore?.toJson()});
  }
}
