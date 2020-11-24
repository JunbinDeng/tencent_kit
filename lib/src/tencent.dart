import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tencent_kit/src/model/api/tencent_user_info_resp.dart';
import 'package:tencent_kit/src/model/sdk/tencent_login_resp.dart';
import 'package:tencent_kit/src/model/sdk/tencent_share_resp.dart';
import 'package:tencent_kit/src/model/unionid/tencent_unionid_resp.dart';
import 'package:tencent_kit/src/tencent_constant.dart';

///
class Tencent {
  ///
  Tencent() {
    _channel.setMethodCallHandler(_handleMethod);
  }

  static const String _METHOD_REGISTERAPP = 'registerApp';
  static const String _METHOD_ISQQINSTALLED = 'isQQInstalled';
  static const String _METHOD_ISTIMINSTALLED = 'isTIMInstalled';
  static const String _METHOD_LOGIN = 'login';
  static const String _METHOD_LOGOUT = 'logout';
  static const String _METHOD_SHAREMOOD = 'shareMood';
  static const String _METHOD_SHARETEXT = 'shareText';
  static const String _METHOD_SHAREIMAGE = 'shareImage';
  static const String _METHOD_SHAREMUSIC = 'shareMusic';
  static const String _METHOD_SHAREWEBPAGE = 'shareWebpage';
  static const String _METHOD_SHAREMINIAPP = 'shareMiniApp';

  static const String _METHOD_ONLOGINRESP = 'onLoginResp';
  static const String _METHOD_ONSHARERESP = 'onShareResp';

  static const String _ARGUMENT_KEY_APPID = 'appId';
  static const String _ARGUMENT_KEY_UNIVERSALLINK = 'universalLink';
  static const String _ARGUMENT_KEY_SCOPE = 'scope';
  static const String _ARGUMENT_KEY_SCENE = 'scene';
  static const String _ARGUMENT_KEY_TITLE = 'title';
  static const String _ARGUMENT_KEY_SUMMARY = 'summary';
  static const String _ARGUMENT_KEY_IMAGEURI = 'imageUri';
  static const String _ARGUMENT_KEY_IMAGEURIS = 'imageUris';
  static const String _ARGUMENT_KEY_VIDEOURI = 'videoUri';
  static const String _ARGUMENT_KEY_MUSICURL = 'musicUrl';
  static const String _ARGUMENT_KEY_TARGETURL = 'targetUrl';
  static const String _ARGUMENT_KEY_APPNAME = 'appName';
  static const String _ARGUMENT_KEY_EXTINT = 'extInt';
  static const String _ARGUMENT_KEY_MINIAPPID = "miniAppId";
  static const String _ARGUMENT_KEY_MINIAPPURL = "miniAppUrl";

  static const String _SCHEME_FILE = 'file';

  final MethodChannel _channel =
      const MethodChannel('v7lin.github.io/tencent_kit');

  final StreamController<TencentLoginResp> _loginRespStreamController =
      StreamController<TencentLoginResp>.broadcast();

  final StreamController<TencentShareResp> _shareRespStreamController =
      StreamController<TencentShareResp>.broadcast();

  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case _METHOD_ONLOGINRESP:
        _loginRespStreamController.add(
            TencentLoginResp.fromJson(call.arguments as Map<dynamic, dynamic>));
        break;
      case _METHOD_ONSHARERESP:
        _shareRespStreamController.add(
            TencentShareResp.fromJson(call.arguments as Map<dynamic, dynamic>));
        break;
    }
  }

  /// 向 Open_SDK 注册
  Future<void> registerApp({
    @required String appId,
    String universalLink,
  }) {
    assert(appId?.isNotEmpty ?? false);
    return _channel.invokeMethod<void>(
      _METHOD_REGISTERAPP,
      <String, dynamic>{
        _ARGUMENT_KEY_APPID: appId,
        if (universalLink?.isNotEmpty ?? false)
          _ARGUMENT_KEY_UNIVERSALLINK: universalLink,
      },
    );
  }

  /// 登录
  Stream<TencentLoginResp> loginResp() {
    return _loginRespStreamController.stream;
  }

  /// 分享
  Stream<TencentShareResp> shareResp() {
    return _shareRespStreamController.stream;
  }

  /// 检查QQ是否已安装
  Future<bool> isQQInstalled() {
    return _channel.invokeMethod<bool>(_METHOD_ISQQINSTALLED);
  }

  /// 检查QQ是否已安装
  Future<bool> isTIMInstalled() {
    return _channel.invokeMethod<bool>(_METHOD_ISTIMINSTALLED);
  }

  /// 登录
  Future<void> login({
    @required List<String> scope,
  }) {
    assert(scope?.isNotEmpty ?? false);
    return _channel.invokeMethod<void>(
      _METHOD_LOGIN,
      <String, dynamic>{
        _ARGUMENT_KEY_SCOPE: scope.join(','),
      },
    );
  }

  /// 登出
  Future<void> logout() {
    return _channel.invokeMethod<void>(_METHOD_LOGOUT);
  }

  /// 用户信息
  /// https://wiki.connect.qq.com/get_user_info
  Future<TencentUserInfoResp> getUserInfo({
    @required String appId,
    @required String openid,
    @required String accessToken,
  }) {
    assert(appId?.isNotEmpty ?? false);
    assert(openid?.isNotEmpty ?? false);
    assert(accessToken?.isNotEmpty ?? false);
    return HttpClient()
        .getUrl(Uri.parse(
            'https://graph.qq.com/user/get_user_info?access_token=$accessToken&oauth_consumer_key=$appId&openid=$openid'))
        .then((HttpClientRequest request) {
      return request.close();
    }).then((HttpClientResponse response) async {
      if (response.statusCode == HttpStatus.ok) {
        ContentType contentType = response.headers.contentType;
        Encoding encoding = Encoding.getByName(contentType?.charset) ?? utf8;
        String content = await encoding.decodeStream(response);
        return TencentUserInfoResp.fromJson(
            json.decode(content) as Map<dynamic, dynamic>);
      }
      throw HttpException(
          'HttpResponse statusCode: ${response.statusCode}, reasonPhrase: ${response.reasonPhrase}.');
    });
  }

  /// UnionID
  /// https://wiki.connect.qq.com/unionid%E4%BB%8B%E7%BB%8D
  Future<TencentUnionidResp> getUnionId({
    @required String accessToken,
    String unionid = '1',
  }) {
    assert(accessToken?.isNotEmpty ?? false);
    return HttpClient()
        .getUrl(Uri.parse(
            'https://graph.qq.com/oauth2.0/me?access_token=$accessToken&unionid=$unionid'))
        .then((HttpClientRequest request) {
      return request.close();
    }).then((HttpClientResponse response) async {
      if (response.statusCode == HttpStatus.ok) {
        ContentType contentType = response.headers.contentType;
        Encoding encoding = Encoding.getByName(contentType?.charset) ?? utf8;
        String callback = await encoding.decodeStream(response);
        // 腾讯有毒 callback( $json );
        RegExp exp = RegExp(r'callback\( (.*) \)\;');
        Match match = exp.firstMatch(callback);
        if (match.groupCount == 1) {
          String content = match.group(1);
          return TencentUnionidResp.fromJson(
              json.decode(content) as Map<dynamic, dynamic>);
        }
      }
      throw HttpException(
          'HttpResponse statusCode: ${response.statusCode}, reasonPhrase: ${response.reasonPhrase}.');
    });
  }

  /// 分享 - 说说
  Future<void> shareMood({
    @required int scene,
    String summary,
    List<Uri> imageUris,
    Uri videoUri,
  }) {
    assert(scene == TencentScene.SCENE_QZONE);
    assert((summary?.isNotEmpty ?? false) ||
        (imageUris?.isNotEmpty ?? false) ||
        (videoUri != null && videoUri.isScheme(_SCHEME_FILE)) ||
        ((imageUris?.isNotEmpty ?? false) &&
            imageUris.every((Uri element) =>
                element != null && element.isScheme(_SCHEME_FILE))));
    return _channel.invokeMethod<void>(
      _METHOD_SHAREMOOD,
      <String, dynamic>{
        _ARGUMENT_KEY_SCENE: scene,
        if (summary?.isNotEmpty ?? false) _ARGUMENT_KEY_SUMMARY: summary,
        if (imageUris?.isNotEmpty ?? false)
          _ARGUMENT_KEY_IMAGEURIS:
              imageUris.map((Uri imageUri) => imageUri.toString()).toList(),
        if (videoUri != null) _ARGUMENT_KEY_VIDEOURI: videoUri.toString(),
      },
    );
  }

  /// 分享 - 文本（Android调用的是系统API，故而不会有回调）
  Future<void> shareText({
    @required int scene,
    @required String summary,
  }) {
    assert(scene == TencentScene.SCENE_QQ);
    assert(summary?.isNotEmpty ?? false);
    return _channel.invokeMethod<void>(
      _METHOD_SHARETEXT,
      <String, dynamic>{
        _ARGUMENT_KEY_SCENE: scene,
        _ARGUMENT_KEY_SUMMARY: summary,
      },
    );
  }

  /// 分享 - 图片
  Future<void> shareImage({
    @required int scene,
    @required Uri imageUri,
    String appName,
    int extInt = TencentQZoneFlag.DEFAULT,
  }) {
    assert(scene == TencentScene.SCENE_QQ);
    assert(imageUri != null && imageUri.isScheme(_SCHEME_FILE));
    return _channel.invokeMethod<void>(
      _METHOD_SHAREIMAGE,
      <String, dynamic>{
        _ARGUMENT_KEY_SCENE: scene,
        _ARGUMENT_KEY_IMAGEURI: imageUri.toString(),
        if (appName?.isNotEmpty ?? false) _ARGUMENT_KEY_APPNAME: appName,
        _ARGUMENT_KEY_EXTINT: extInt,
      },
    );
  }

  /// 分享 - 音乐
  Future<void> shareMusic({
    @required int scene,
    @required String title,
    String summary,
    Uri imageUri,
    @required String musicUrl,
    @required String targetUrl,
    String appName,
    int extInt = TencentQZoneFlag.DEFAULT,
  }) {
    assert(scene == TencentScene.SCENE_QQ);
    assert(title?.isNotEmpty ?? false);
    assert(musicUrl?.isNotEmpty ?? false);
    assert(targetUrl?.isNotEmpty ?? false);
    return _channel.invokeMethod<void>(
      _METHOD_SHAREMUSIC,
      <String, dynamic>{
        _ARGUMENT_KEY_SCENE: scene,
        _ARGUMENT_KEY_TITLE: title,
        if (summary?.isNotEmpty ?? false) _ARGUMENT_KEY_SUMMARY: summary,
        if (imageUri != null) _ARGUMENT_KEY_IMAGEURI: imageUri.toString(),
        _ARGUMENT_KEY_MUSICURL: musicUrl,
        _ARGUMENT_KEY_TARGETURL: targetUrl,
        if (appName?.isNotEmpty ?? false) _ARGUMENT_KEY_APPNAME: appName,
        _ARGUMENT_KEY_EXTINT: extInt,
      },
    );
  }

  /// 分享 - 网页
  Future<void> shareWebpage({
    @required int scene,
    @required String title,
    String summary,
    Uri imageUri,
    @required String targetUrl,
    String appName,
    int extInt = TencentQZoneFlag.DEFAULT,
  }) {
    assert(title?.isNotEmpty ?? false);
    assert(targetUrl?.isNotEmpty ?? false);
    return _channel.invokeMethod<void>(
      _METHOD_SHAREWEBPAGE,
      <String, dynamic>{
        _ARGUMENT_KEY_SCENE: scene,
        _ARGUMENT_KEY_TITLE: title,
        if (summary?.isNotEmpty ?? false) _ARGUMENT_KEY_SUMMARY: summary,
        if (imageUri != null) _ARGUMENT_KEY_IMAGEURI: imageUri.toString(),
        _ARGUMENT_KEY_TARGETURL: targetUrl,
        if (appName?.isNotEmpty ?? false) _ARGUMENT_KEY_APPNAME: appName,
        _ARGUMENT_KEY_EXTINT: extInt,
      },
    );
  }



  // 参数	是否必传	类型	参数说明
  // QQShare.SHARE_TO_QQ_KEY_TYPE	必填	Int	分享的类型。分享小程序填QQShare.SHARE_TO_QQ_MINI_PROGRAM
  // QQShare.SHARE_TO_QQ_TITLE	必填	String	分享的标题, 最长30个字符。如果不填，默认使用小程序名称作为标题
  // QQShare.SHARE_TO_QQ_SUMMARY	必填	String	分享的消息摘要，最长40个字符。若不填，默认使用小程序后台注册的描述作为摘要
  // QQShare.SHARE_TO_QQ_TARGET_URL	必填	String	兼容低版本的网页链接
  // QQShare.SHARE_TO_QQ_IMAGE_URL	必填	String	分享预览封面图的url，或者是本地图的路径
  // QQShare.SHARE_TO_QQ_MINI_PROGRAM_APPID	必填	String	分享的小程序appid，小程序与当前应用必须为同一个主体
  // QQShare.SHARE_TO_QQ_MINI_PROGRAM_TYPE	可选	String	3表示正式版，1表示体验版
  // QQShare.SHARE_TO_QQ_MINI_PROGRAM_PATH	必填	String	分享的小程序页面路径，如不需要指定，请填主页路径
  //
  //
  /// 分享 - 小程序
  Future<void> shareMiniApp({
    @required int scene,
    @required String title,
    String summary,
    Uri imageUri,
    @required String targetUrl,
    @required String miniAppId,
    String miniAppUrl
  }) {
    assert(title?.isNotEmpty ?? false);
    assert(targetUrl?.isNotEmpty ?? false);
    return _channel.invokeMethod<void>(
      _METHOD_SHAREMINIAPP,
      <String, dynamic>{
        _ARGUMENT_KEY_SCENE: scene,
        _ARGUMENT_KEY_TITLE: title,
        if (summary?.isNotEmpty ?? false) _ARGUMENT_KEY_SUMMARY: summary,
        if (imageUri != null) _ARGUMENT_KEY_IMAGEURI: imageUri.toString(),
        _ARGUMENT_KEY_TARGETURL: targetUrl,
        _ARGUMENT_KEY_MINIAPPID: miniAppId,
        _ARGUMENT_KEY_MINIAPPURL: miniAppUrl,
      },
    );
  }
}
