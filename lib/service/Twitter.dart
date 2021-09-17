
import 'package:http/http.dart';
import 'package:illinois/model/Twitter.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Network.dart';
import 'package:illinois/utils/Utils.dart';

class Twitter /* with Service implements NotificationsListener */ {

  static const String _tweetFieldsUrlParam = "tweet.fields=attachments,author_id,context_annotations,conversation_id,created_at,entities,geo,id,in_reply_to_user_id,lang,public_metrics,possibly_sensitive,referenced_tweets,reply_settings,source,text,withheld";
  static const String _userFieldsUrlParam = "user.fields=created_at,description,entities,id,location,name,pinned_tweet_id,profile_image_url,protected,public_metrics,url,username,verified,withheld";
  static const String _mediaFieldsUrlParam = "media.fields=duration_ms,height,media_key,preview_image_url,type,url,width,public_metrics,non_public_metrics,organic_metrics,promoted_metrics,alt_text";
  static const String _expansionsUrlParam = "expansions=attachments.poll_ids,attachments.media_keys,author_id,entities.mentions.username,geo.place_id,in_reply_to_user_id,referenced_tweets.id,referenced_tweets.id.author_id";
  static const String _excludeUrlParam = "exclude=retweets,replies";
/*
  static const String notifyChanged  = "edu.illinois.rokwire.twitter.changed";
  static const String _cacheFileName = "twitter.json";

  TweetsPage    _tweets;
  File          _cacheFile;
  DateTime      _pausedDateTime;
*/
  // Singletone instance

  static final Twitter _service = Twitter._internal();
  Twitter._internal();

  factory Twitter() {
    return _service;
  }

  // Service
/*
  @override
  void createService() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    _cacheFile = await _getCacheFile();
    _tweets = await _loadContentFromCache();
    _updateContentFromNet();
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Config()]);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      //TMP: _convertFile('student.guide.import.json', 'Illinois_Student_Guide_Final.json');
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _updateContentFromNet();
        }
      }
    }
  }

  // Implementation

  TweetsPage get tweets => _tweets;

  Future<File> _getCacheFile() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String cacheFilePath = join(appDocDir.path, _cacheFileName);
    return File(cacheFilePath);
  }

  Future<String> _loadContentStringFromCache() async {
    return (await _cacheFile?.exists() == true) ? await _cacheFile.readAsString() : null;
  }

  Future<void> _saveContentStringToCache(String value) async {
    try {
      if (value != null) {
        await _cacheFile?.writeAsString(value, flush: true);
      }
      else {
        await _cacheFile?.delete();
      }
    }
    catch(e) { print(e?.toString()); }
  }

  Future<TweetsPage> _loadContentFromCache() async {
    return TweetsPage.fromJson(AppJson.decodeMap(await _loadContentStringFromCache()));
  }

  Future<String> _loadContentStringFromNet({bool force}) async {
    if ((Config().contentUrl != null) && (Config().twitterUserId != null)) {
      String url = "${Config().contentUrl}/twitter/users/${Config().twitterUserId}/tweets?$_tweetFieldsUrlParam&$_userFieldsUrlParam&$_mediaFieldsUrlParam&$_expansionsUrlParam&$_excludeUrlParam&max_results=${count ?? Config().twitterTweetsCount}";
      Map<String, String> headers = (noCache == true) ? {
        "Cache-Control" : "no-cache"
      } : null;
      Response response = await Network().get(url, auth: NetworkAuth.App, headers: headers);
      return ((response != null) && (response.statusCode == 200)) ? response.body : null;
    }
    return null;
  }

  Future<String> _loadContentStringFromTwitter() async {
    if ((Config().twitterUrl != null) && (Config().twitterUserId != null)) {
      String url = "${Config().twitterUrl}/users/${Config().twitterUserId}/tweets?$_tweetFieldsUrlParam&$_userFieldsUrlParam&$_mediaFieldsUrlParam&$_expansionsUrlParam&$_excludeUrlParam&max_results=${Config().twitterTweetsCount * 2}";
      Map<String, String> headers = {
        HttpHeaders.authorizationHeader : "${Config().twitterTokenType} ${Config().twitterToken}"
      };
      Response response = await Network().get(url, headers: headers);
      return ((response != null) && (response.statusCode == 200)) ? response.body : null;
    }
    return null;
  }

  Future<void> _updateContentFromNet() async {
    try {
      String contentJsonString = await _loadContentStringFromNet();
      TweetsPage tweets = TweetsPage.fromJson(AppJson.decodeMap(contentJsonString));
      if ((tweets != null) && (tweets != _tweets)) {
        _tweets = tweets;
        await _saveContentStringToCache(contentJsonString);
        NotificationService().notify(notifyChanged);
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> refresh() async {
    await _updateContentFromNet();
  }
*/

  Future<TweetsPage> loadTweetsPage({int count, DateTime startTimeUtc, DateTime endTimeUtc, String token, bool noCache}) async {
    if ((Config().contentUrl != null) && (Config().twitterUserId != null)) {
      String url = "${Config().contentUrl}/twitter/users/${Config().twitterUserId}/tweets?$_tweetFieldsUrlParam&$_userFieldsUrlParam&$_mediaFieldsUrlParam&$_expansionsUrlParam&$_excludeUrlParam";
      if (token != null) {
        url += "&pagination_token=$token";
      }
      if (startTimeUtc != null) {
        url += "&start_time=${AppDateTime().utcDateTimeToString(startTimeUtc, format: "yyyy-MM-ddTHH:mm:ss")}";
      }
      if (endTimeUtc != null) {
        url += "&end_time=${AppDateTime().utcDateTimeToString(endTimeUtc, format: "yyyy-MM-ddTHH:mm:ss")}";
      }
      url += "&max_results=${count ?? Config().twitterTweetsCount}";

      Map<String, String> headers = (noCache == true) ? {
        "Cache-Control" : "no-cache"
      } : null;
      
      Response response = await Network().get(url, auth: NetworkAuth.App, headers: headers);
      String responseString = ((response != null) && (response.statusCode == 200)) ? response.body : null;
      print("Twitter Page Load: ${response.statusCode}\n${response.body}");
      return TweetsPage.fromJson(AppJson.decodeMap(responseString));
    }
    return null;
  }
}