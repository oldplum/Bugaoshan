import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bugaoshan/utils/constants.dart';
import 'package:bugaoshan/utils/json_utils.dart';

/// 第二课堂纯数据 API（无状态）
///
/// 所有认证逻辑（login / token / logout）在 [CcylAuth] 中管理。
/// API 方法通过 [authHeaders] 参数接收已注入 token 的请求头。
class CcylService {
  static const _base = 'https://dekt.scu.edu.cn';
  static const apiBase = 'https://dekt.scu.edu.cn/ccyl-api';

  static final Map<String, String> baseHeaders = {
    'Accept': 'application/json, text/plain, */*',
    'Content-Type': 'application/json;charset=UTF-8',
    'Origin': _base,
    'Referer': _base,
    'User-Agent': kDefaultUserAgent,
  };

  /// 构造带 token 的请求头
  static Map<String, String> authHeaders(String token) {
    return {...baseHeaders, 'token': token};
  }

  // ═══════════════════════════════════════════════════════════════════
  //  登录（由 CcylAuth 调用）
  // ═══════════════════════════════════════════════════════════════════

  /// 用 OAuth code 登录，返回 (token, user)
  static Future<({String token, CcylUser user})> login(String oauthCode) async {
    final json = await _httpPost(
      'loginByUc',
      Uri.parse('$apiBase/app/auth/loginByUc'),
      baseHeaders,
      {'code': oauthCode},
    );

    if (json['code'] != 0) {
      final msg = json['msg']?.toString() ?? '登录失败';
      throw CcylException(msg);
    }

    final token = json['token']?.toString();
    if (token == null) {
      throw CcylException('Token 字段缺失');
    }

    final user = CcylUser.fromJson(json['user'] as Map<String, dynamic>);
    return (token: token, user: user);
  }

  // ═══════════════════════════════════════════════════════════════════
  //  数据 API（需要 token）
  // ═══════════════════════════════════════════════════════════════════

  static Future<List<CyclActivity>> searchActivities({
    required String token,
    int pageNum = 1,
    int pageSize = 10,
    String name = '',
    String level = '',
    String scoreType = '',
    String org = '',
    String order = '',
    String status = '',
    String quality = '',
  }) async {
    final json = await _httpPost(
      'list-activity-library',
      Uri.parse('$apiBase/app/activity/list-activity-library'),
      authHeaders(token),
      {
        'pn': pageNum,
        'time': DateTime.now().millisecondsSinceEpoch.toString(),
        'ps': pageSize,
        'name': name,
        'level': level,
        'scoreType': scoreType,
        'org': org,
        'order': order,
        'status': status,
        'quality': quality,
      },
    );
    if (json['code'] != 0) {
      throw CcylException(json['msg']?.toString() ?? '获取活动列表失败');
    }
    final list = json['list'] as List<dynamic>?;
    if (list == null) return [];
    return list
        .map((e) => CyclActivity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<CyclActivity>> getMyActivities({
    required String token,
    int pageNum = 1,
    int pageSize = 10,
  }) async {
    final json = await _httpPost(
      'list-mine',
      Uri.parse('$apiBase/app/activity/list-mine'),
      authHeaders(token),
      {
        'pn': pageNum,
        'time': DateTime.now().millisecondsSinceEpoch.toString(),
        'ps': pageSize,
      },
    );
    if (json['code'] != 0)
      throw CcylException(json['msg']?.toString() ?? '获取我参与的活动失败');
    final content = json['content'] as List<dynamic>?;
    if (content == null) return [];
    return content
        .map((e) => CyclActivity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<CyclActivity>> getOrderedActivities({
    required String token,
    int pageNum = 1,
    int pageSize = 10,
    String name = '',
  }) async {
    final json = await _httpPost(
      'list-ordered-activity-library',
      Uri.parse('$apiBase/app/activity/list-ordered-activity-library'),
      authHeaders(token),
      {
        'pn': pageNum,
        'time': DateTime.now().millisecondsSinceEpoch.toString(),
        'ps': pageSize,
        'name': name,
      },
    );
    if (json['code'] != 0)
      throw CcylException(json['msg']?.toString() ?? '获取预约的活动失败');
    final list = json['list'] as List<dynamic>?;
    if (list == null) return [];
    return list
        .map((e) => CyclActivity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<CyclOrg>> getAllOrgs({required String token}) async {
    final json = await _httpPost(
      'list-all',
      Uri.parse('$apiBase/app/org/list-all'),
      authHeaders(token),
      {},
    );
    if (json['code'] != 0)
      throw CcylException(json['msg']?.toString() ?? '获取组织列表失败');
    final list = json['list'] as List<dynamic>?;
    if (list == null) return [];
    return list
        .map((e) => CyclOrg.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<
    ({
      CyclActivityLib activityLib,
      List<CyclActivity> activities,
      bool subscribed,
    })
  >
  getActivityLibDetail({
    required String token,
    required String activityLibraryId,
  }) async {
    final json = await _httpGet(
      'get-lib-detail',
      Uri.parse('$apiBase/app/activity/get-lib-detail/$activityLibraryId'),
      authHeaders(token),
    );
    if (json['code'] != 0)
      throw CcylException(json['msg']?.toString() ?? '获取活动系列详情失败');
    final activityLibJson = json['activityLib'] as Map<String, dynamic>?;
    if (activityLibJson == null) throw const CcylException('活动系列数据缺失');
    return (
      activityLib: CyclActivityLib.fromJson(activityLibJson),
      activities:
          (json['activities'] as List<dynamic>?)
              ?.map((e) => CyclActivity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subscribed: json['subscribed'] == true,
    );
  }

  static Future<void> subscribeActivity({
    required String token,
    required String activityLibraryId,
  }) async {
    final json = await _httpPost(
      'subscribe-act',
      Uri.parse('$apiBase/app/activity/subscribe-act/$activityLibraryId'),
      authHeaders(token),
      {},
    );
    if (json['code'] != 0)
      throw CcylException(json['msg']?.toString() ?? '预约活动失败');
  }

  static Future<void> cancelSubscribe({
    required String token,
    required String activityLibraryId,
  }) async {
    final json = await _httpPost(
      'cancel-subscribe',
      Uri.parse('$apiBase/app/activity/cancel-subscribe/$activityLibraryId'),
      authHeaders(token),
      {},
    );
    if (json['code'] != 0)
      throw CcylException(json['msg']?.toString() ?? '取消预约失败');
  }

  static Future<List<CyclScoreType>> getActivityScoreTypes({
    required String token,
    required String activityLibraryId,
  }) async {
    final json = await _httpPost(
      'list-activity-score',
      Uri.parse('$apiBase/app/activity/list-activity-score/$activityLibraryId'),
      authHeaders(token),
      {},
    );
    if (json['code'] != 0)
      throw CcylException(json['msg']?.toString() ?? '获取能力类型失败');
    final list = json['list'] as List<dynamic>?;
    if (list == null) return [];
    return list
        .map((e) => CyclScoreType.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> signUpActivity({
    required String token,
    required String activityId,
    required String scoreType,
  }) async {
    final json = await _httpPost(
      'sign-up-act',
      Uri.parse('$apiBase/app/activity/sign-up-act'),
      authHeaders(token),
      {'activityId': activityId, 'scoreType': scoreType},
    );
    if (json['code'] != 0)
      throw CcylException(json['msg']?.toString() ?? '报名失败');
  }

  static Future<void> cancelSignUp({
    required String token,
    required String activityId,
    required String userId,
  }) async {
    final json = await _httpPost(
      'cancel',
      Uri.parse('$apiBase/app/activity/cancel'),
      authHeaders(token),
      {'activityId': activityId, 'userId': userId},
    );
    if (json['code'] != 0)
      throw CcylException(json['msg']?.toString() ?? '取消报名失败');
  }

  static Future<
    ({
      CyclActivity activity,
      CyclActivityLib? activityLib,
      bool isXtwRole,
      bool signUp,
    })
  >
  getActivityDetail({required String token, required String activityId}) async {
    final json = await _httpPost(
      'get-detail',
      Uri.parse('$apiBase/app/activity/get-detail'),
      authHeaders(token),
      {'activityId': activityId},
    );
    if (json['code'] != 0)
      throw CcylException(json['msg']?.toString() ?? '获取活动详情失败');
    final activityJson = json['activity'] as Map<String, dynamic>?;
    if (activityJson == null) throw const CcylException('活动数据缺失');
    return (
      activity: CyclActivity.fromJson(activityJson),
      activityLib: json['activityLib'] != null
          ? CyclActivityLib.fromJson(
              json['activityLib'] as Map<String, dynamic>,
            )
          : null,
      isXtwRole: json['isXtwRole'] == true,
      signUp: json['signUp'] == true,
    );
  }

  static Future<List<CyclCredit>> getCreditList({
    required String token,
    int pageNum = 1,
    int pageSize = 10,
  }) async {
    final json = await _httpPost(
      'list-credit',
      Uri.parse('$apiBase/app/credit/list'),
      authHeaders(token),
      {'pn': pageNum, 'ps': pageSize},
    );
    if (json['code'] != 0)
      throw CcylException(json['msg']?.toString() ?? '获取成绩单失败');
    final list = json['list'] as List<dynamic>?;
    if (list == null) return [];
    return list
        .map((e) => CyclCredit.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<String> exportCreditsToEmail({
    required String token,
    required List<String> creditIds,
    required String email,
  }) async {
    final json = await _httpPost(
      'export-pdf',
      Uri.parse('$apiBase/app/credit/exportPdfV2'),
      authHeaders(token),
      {'creditIds': creditIds.join(','), 'qqEmail': email},
    );
    if (json['code'] != 0)
      throw CcylException(json['msg']?.toString() ?? '导出失败');
    return json['msg']?.toString() ?? '成绩单已发送至邮箱';
  }

  static Future<Map<String, List<CyclDict>>> getDicts({
    required String token,
    required List<String> groupCodes,
  }) async {
    final results = <String, List<CyclDict>>{};
    for (final code in groupCodes) {
      try {
        final json = await _httpPost(
          'dict/$code',
          Uri.parse('$apiBase/app/dict/query-by-group-code'),
          authHeaders(token),
          {'groupCode': code},
        );
        if (json['code'] == 0) {
          final list = json['list'] as List<dynamic>?;
          if (list != null)
            results[code] = list
                .map((e) => CyclDict.fromJson(e as Map<String, dynamic>))
                .toList();
        }
      } on CcylException {
        // 忽略单个字典请求失败
      }
    }
    return results;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  HTTP 工具
  // ═══════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> _httpPost(
    String api,
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(kHttpTimeout);
      if (resp.statusCode != 200)
        throw CcylException('[$api] HTTP 错误: ${resp.statusCode}');
      return parseJson(resp.body, api, (msg) => CcylException(msg));
    } on CcylException {
      rethrow;
    } catch (e) {
      throw CcylException('[$api] 网络请求失败: $e');
    }
  }

  static Future<Map<String, dynamic>> _httpGet(
    String api,
    Uri uri,
    Map<String, String> headers,
  ) async {
    try {
      final resp = await http.get(uri, headers: headers).timeout(kHttpTimeout);
      if (resp.statusCode != 200)
        throw CcylException('[$api] HTTP 错误: ${resp.statusCode}');
      return parseJson(resp.body, api, (msg) => CcylException(msg));
    } on CcylException {
      rethrow;
    } catch (e) {
      throw CcylException('[$api] 网络请求失败: $e');
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  Model 类（不变）
// ═══════════════════════════════════════════════════════════════════════

class CyclActivity {
  final String? activityId;
  final String activityLibraryId;
  final String orgNo;
  final String name;
  final String activityName;
  final String level;
  final String star;
  final List<String> quality;
  final double classHour;
  final String? describe;
  final String poster;
  final String? startTime;
  final String? endTime;
  final String? enrollStartTime;
  final String? enrollEndTime;
  final int quota;
  final String activityTarget;
  final String? activityTargetName;
  final String isSignIn;
  final String isSignOut;
  final String? mobile;
  final String? activityAddress;
  final String? activityLon;
  final String? activityLat;
  final String status;
  final String? statusName;
  final String orgName;
  final String? levelName;
  final String? starName;
  final String? qualityName;
  final bool doing;
  final bool subscribed;

  CyclActivity({
    this.activityId,
    required this.activityLibraryId,
    required this.orgNo,
    required this.name,
    required this.activityName,
    required this.level,
    required this.star,
    required this.quality,
    required this.classHour,
    this.describe,
    required this.poster,
    this.startTime,
    this.endTime,
    this.enrollStartTime,
    this.enrollEndTime,
    required this.quota,
    required this.activityTarget,
    this.activityTargetName,
    required this.isSignIn,
    required this.isSignOut,
    this.mobile,
    this.activityAddress,
    this.activityLon,
    this.activityLat,
    required this.status,
    this.statusName,
    required this.orgName,
    this.levelName,
    this.starName,
    this.qualityName,
    required this.doing,
    required this.subscribed,
  });

  factory CyclActivity.fromJson(Map<String, dynamic> json) {
    return CyclActivity(
      activityId: json['activityId']?.toString(),
      activityLibraryId: json['activityLibraryId']?.toString() ?? '',
      orgNo: json['orgNo']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      activityName: json['activityName']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      star: json['star']?.toString() ?? '',
      quality:
          (json['quality'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      classHour: (json['classHour'] as num?)?.toDouble() ?? 0.0,
      describe: json['describe']?.toString(),
      poster: json['poster']?.toString() ?? '',
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
      enrollStartTime: json['enrollStartTime']?.toString(),
      enrollEndTime: json['enrollEndTime']?.toString(),
      quota: json['quota'] is int
          ? json['quota']
          : int.tryParse(json['quota']?.toString() ?? '0') ?? 0,
      activityTarget: json['activityTarget']?.toString() ?? '',
      activityTargetName: json['activityTargetName']?.toString(),
      isSignIn: json['isSignIn']?.toString() ?? '0',
      isSignOut: json['isSignOut']?.toString() ?? '0',
      mobile: json['mobile']?.toString(),
      activityAddress: json['activityAddress']?.toString(),
      activityLon: json['activityLon']?.toString(),
      activityLat: json['activityLat']?.toString(),
      status: json['status']?.toString() ?? '',
      statusName: json['statusName']?.toString(),
      orgName: json['orgName']?.toString() ?? '',
      levelName: json['levelName']?.toString(),
      starName: json['starName']?.toString(),
      qualityName: json['qualityName']?.toString(),
      doing: json['doing'] == true,
      subscribed: json['subscribed'] == true,
    );
  }
}

class CyclOrg {
  final String orgNo;
  final String orgName;
  final String? parentNo;
  CyclOrg({required this.orgNo, required this.orgName, this.parentNo});
  factory CyclOrg.fromJson(Map<String, dynamic> json) => CyclOrg(
    orgNo: json['orgNo']?.toString() ?? '',
    orgName: json['orgName']?.toString() ?? '',
    parentNo: json['parentNo']?.toString(),
  );
}

class CyclScoreType {
  final String? id;
  final String? groupId;
  final String name;
  final String value;
  final String? code;
  CyclScoreType({
    this.id,
    this.groupId,
    required this.name,
    required this.value,
    this.code,
  });
  factory CyclScoreType.fromJson(Map<String, dynamic> json) => CyclScoreType(
    id: json['id']?.toString(),
    groupId: json['groupId']?.toString(),
    name: json['name']?.toString() ?? '',
    value: json['value']?.toString() ?? '',
    code: json['code']?.toString(),
  );
}

class CyclDict {
  final String code;
  final String name;
  final String? groupCode;
  CyclDict({required this.code, required this.name, this.groupCode});
  factory CyclDict.fromJson(Map<String, dynamic> json) => CyclDict(
    code: json['code']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    groupCode: json['groupCode']?.toString(),
  );
}

class CcylUser {
  final String id;
  final String userName;
  final String realname;
  final String orgName;
  final String? mobile;
  final String? headImgUrl;
  final String? majorName;
  final String? classes;
  final String? grade;
  CcylUser({
    required this.id,
    required this.userName,
    required this.realname,
    required this.orgName,
    this.mobile,
    this.headImgUrl,
    this.majorName,
    this.classes,
    this.grade,
  });
  factory CcylUser.fromJson(Map<String, dynamic> json) => CcylUser(
    id: json['id']?.toString() ?? '',
    userName: json['userName']?.toString() ?? '',
    realname: json['realname']?.toString() ?? '',
    orgName: json['orgName']?.toString() ?? '',
    mobile: json['mobile']?.toString(),
    headImgUrl: json['headImgUrl']?.toString(),
    majorName: json['majorName']?.toString(),
    classes: json['classes']?.toString(),
    grade: json['grade']?.toString(),
  );
}

class CcylException implements Exception {
  final String message;
  const CcylException(this.message);
  @override
  String toString() => message;
}

class CyclCredit {
  final String creditId;
  final String? reportId;
  final String userId;
  final String userName;
  final String activityName;
  final String? activityType;
  final double classHour;
  final String scoreType;
  final String? classCredit;
  final String creditStatus;
  final String? comment;
  final String createTime;
  final String? updateTime;
  final String scoreTypeName;
  final String? activityLevel;
  final String? activityLevelName;
  final String? activityStar;
  final String creditStatusName;
  CyclCredit({
    required this.creditId,
    this.reportId,
    required this.userId,
    required this.userName,
    required this.activityName,
    this.activityType,
    required this.classHour,
    required this.scoreType,
    this.classCredit,
    required this.creditStatus,
    this.comment,
    required this.createTime,
    this.updateTime,
    required this.scoreTypeName,
    this.activityLevel,
    this.activityLevelName,
    this.activityStar,
    required this.creditStatusName,
  });
  factory CyclCredit.fromJson(Map<String, dynamic> json) => CyclCredit(
    creditId: json['creditId']?.toString() ?? '',
    reportId: json['reportId']?.toString(),
    userId: json['userId']?.toString() ?? '',
    userName: json['userName']?.toString() ?? '',
    activityName: json['activityName']?.toString() ?? '',
    activityType: json['activityType']?.toString(),
    classHour: (json['classHour'] as num?)?.toDouble() ?? 0.0,
    scoreType: json['scoreType']?.toString() ?? '',
    classCredit: json['classCredit']?.toString(),
    creditStatus: json['creditStatus']?.toString() ?? '',
    comment: json['comment']?.toString(),
    createTime: json['createTime']?.toString() ?? '',
    updateTime: json['updateTime']?.toString(),
    scoreTypeName: json['scoreTypeName']?.toString() ?? '',
    activityLevel: json['activityLevel']?.toString(),
    activityLevelName: json['activityLevelName']?.toString(),
    activityStar: json['activityStar']?.toString(),
    creditStatusName: json['creditStatusName']?.toString() ?? '',
  );
}

class CyclActivityLib {
  final String activityLibraryId;
  final String orgNo;
  final String name;
  final String level;
  final String star;
  final String? activityType;
  final List<String> quality;
  final double classHour;
  final String? classCredit;
  final String? avgRank;
  final String? isPrize;
  final int prizeClassHour;
  final String? describe;
  final String scoringMode;
  final String creator;
  final String createTime;
  final String? updater;
  final String? updateTime;
  final bool isDelete;
  final String liablePer;
  final String liablePerPhone;
  final String liableTer;
  final String liableTerPhone;
  final double instructorHour;
  final String orgName;
  final String? levelName;
  final String? starName;
  final String? activityTypeName;
  final String? doing;
  final String? subscribed;
  final String? scoreTypeNames;
  final String? qualityName;
  CyclActivityLib({
    required this.activityLibraryId,
    required this.orgNo,
    required this.name,
    required this.level,
    required this.star,
    this.activityType,
    required this.quality,
    required this.classHour,
    this.classCredit,
    this.avgRank,
    this.isPrize,
    required this.prizeClassHour,
    this.describe,
    required this.scoringMode,
    required this.creator,
    required this.createTime,
    this.updater,
    this.updateTime,
    required this.isDelete,
    required this.liablePer,
    required this.liablePerPhone,
    required this.liableTer,
    required this.liableTerPhone,
    required this.instructorHour,
    required this.orgName,
    this.levelName,
    this.starName,
    this.activityTypeName,
    this.doing,
    this.subscribed,
    this.scoreTypeNames,
    this.qualityName,
  });
  factory CyclActivityLib.fromJson(Map<String, dynamic> json) =>
      CyclActivityLib(
        activityLibraryId: json['activityLibraryId']?.toString() ?? '',
        orgNo: json['orgNo']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        level: json['level']?.toString() ?? '',
        star: json['star']?.toString() ?? '',
        activityType: json['activityType']?.toString(),
        quality:
            (json['quality'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        classHour: (json['classHour'] as num?)?.toDouble() ?? 0.0,
        classCredit: json['classCredit']?.toString(),
        avgRank: json['avgRank']?.toString(),
        isPrize: json['isPrize']?.toString(),
        prizeClassHour: json['prizeClassHour'] is int
            ? json['prizeClassHour']
            : int.tryParse(json['prizeClassHour']?.toString() ?? '0') ?? 0,
        describe: json['describe']?.toString(),
        scoringMode: json['scoringMode']?.toString() ?? '',
        creator: json['creator']?.toString() ?? '',
        createTime: json['createTime']?.toString() ?? '',
        updater: json['updater']?.toString(),
        updateTime: json['updateTime']?.toString(),
        isDelete: json['isDelete'] == true,
        liablePer: json['liablePer']?.toString() ?? '',
        liablePerPhone: json['liablePerPhone']?.toString() ?? '',
        liableTer: json['liableTer']?.toString() ?? '',
        liableTerPhone: json['liableTerPhone']?.toString() ?? '',
        instructorHour: (json['instructorHour'] as num?)?.toDouble() ?? 0.0,
        orgName: json['orgName']?.toString() ?? '',
        levelName: json['levelName']?.toString(),
        starName: json['starName']?.toString(),
        activityTypeName: json['activityTypeName']?.toString(),
        doing: json['doing']?.toString(),
        subscribed: json['subscribed']?.toString(),
        scoreTypeNames: json['scoreTypeNames']?.toString(),
        qualityName: json['qualityName']?.toString(),
      );
}
