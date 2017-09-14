//
//  EnvironConfig.h
//  PAPersonalDoctor
//
//  Created by Perry on 15/1/21.
//  Copyright (c) 2015年 Ping An Health Insurance Company of China, Ltd. All rights reserved.
//

#ifndef PAAnchor_EnvironConfig_h
#define PAAnchor_EnvironConfig_h

//#define PA_ENVIRON_DEVELOP                //开发环境
//#define PA_ENVIRON_INTEGRATIONTEST          //集成测试环境
#define PA_ENVIRON_TEST                   //测试环境
//#define PA_ENVIRON_INHOUSE                //预发环境
//#define PA_ENVIRON_APPSTORE               //线上环境

//------------- 开发环境 ----------------
#ifdef PA_ENVIRON_DEVELOP

#define PAAPI_BaseUrl @"http://api.dev.pajkdc.com/m.api"
#define PAAPI_TFSUploadUrl @"http://filegw.dev.pajkdc.com/upload?tfsGroupId=0"
#define PAAPI_TFSUrl @"http://static.dev.pajkdc.com/v1/tfs/"

#define PAAPI_IM_IMAGE_TFS_ADDRESS @"http://immessage.jc.dev.pajkdc.com"
#define PAAPI_IM_VOICE_TFS_ADDRESS @"http://immessage.jc.dev.pajkdc.com"
#define PAAPI_IM_XMPP_DOMAIN @"im.jc.dev.pajkdc.com"
#define PAAPI_IM_XMPP_DOMAIN_MUC @"muc.im.jc.dev.pajkdc.com"
#define PAAPI_IM_XMPP_HOST_NAME @"im.jc.dev.pajkdc.com"
#define PAAPI_IM_XMPP_HOST_PORT 25222
#define PAAPI_IM_XMPP_UPLOAD_FILE_URL @"http://immessage.jc.dev.pajkdc.com/tfs.do"
//直播聊天相关
#define PAAPI_LIVE_XMPP_DOMAIN @"liveim.dev.pajkdc.com"
#define PAAPI_LIVE_XMPP_DOMAIN_MUC @"muc.liveim.dev.pajkdc.com"
#define PAAPI_LIVE_XMPP_HOST_NAME @"liveim.dev.pajkdc.com"
#define PAAPI_LIVE_XMPP_HOST_PORT 5222

#define PAAPI_ClickUrl @"http://dwtracking.jk.cn/a.gif"
//直播打点
#define PAAPI_LiveClickUrl @"http://srv.dev.pajk.cn/log-collector/log/put"
#define PAAPI_LiveBatchUploadUrl @" http://srv.dev.pajk.cn/log-collector/log/batch/put"

#define PHL_ANCHOR_PROTOCOL_URL @"http://gc.test.pajkdc.com/health_protocol/home.html"

// talking data
#define PA_AppKeyForTalkingData     @"286B729A99F00B6DBE2A07131720F925"
#define PA_ChanelName               @"AppStore"
#define PA_AppKeyForKJTalkingData   @"7CD2CB744F9CC31FA9737E2E74B3A3C7"

//------------- 集成测试环境 -------------
#elif defined PA_ENVIRON_INTEGRATIONTEST

#define PAAPI_BaseUrl @"http://api.dev.pajkdc.com/m.api"
#define PAAPI_TFSUploadUrl @"http://filegw.dev.pajkdc.com/upload?tfsGroupId=0"
#define PAAPI_TFSUrl @"http://static.dev.pajkdc.com/v1/tfs/"

#define PAAPI_IM_IMAGE_TFS_ADDRESS @"http://immessage.jc.dev.pajkdc.com"
#define PAAPI_IM_VOICE_TFS_ADDRESS @"http://immessage.jc.dev.pajkdc.com"
#define PAAPI_IM_XMPP_DOMAIN @"im.jc.dev.pajkdc.com"
#define PAAPI_IM_XMPP_DOMAIN_MUC @"muc.im.jc.dev.pajkdc.com"
#define PAAPI_IM_XMPP_HOST_NAME @"im.jc.dev.pajkdc.com"
#define PAAPI_IM_XMPP_HOST_PORT 25222
#define PAAPI_IM_XMPP_UPLOAD_FILE_URL @"http://immessage.jc.dev.pajkdc.com/tfs.do"
//直播聊天相关
#define PAAPI_LIVE_XMPP_DOMAIN @"liveim.dev.pajkdc.com"
#define PAAPI_LIVE_XMPP_DOMAIN_MUC @"muc.liveim.dev.pajkdc.com"
#define PAAPI_LIVE_XMPP_HOST_NAME @"liveim.dev.pajkdc.com"
#define PAAPI_LIVE_XMPP_HOST_PORT 5222

#define PHL_ANCHOR_PROTOCOL_URL @"http://gc.test.pajkdc.com/health_protocol/home.html"

#define PAAPI_ClickUrl @"http://dwtracking.jk.cn/a.gif"
//直播打点
#define PAAPI_LiveClickUrl @"http://srv.dev.pajk.cn/log-collector/log/put"
#define PAAPI_LiveBatchUploadUrl @" http://srv.dev.pajk.cn/log-collector/log/batch/put"

// talking data
#define PA_AppKeyForTalkingData     @"286B729A99F00B6DBE2A07131720F925"
#define PA_ChanelName               @"AppStore"
#define PA_AppKeyForKJTalkingData   @"7CD2CB744F9CC31FA9737E2E74B3A3C7"

//---------------- 测试环境 ----------------
#elif defined PA_ENVIRON_TEST

#define PAAPI_BaseUrl @"http://api.test.pajkdc.com/m.api"
#define PAAPI_TFSUploadUrl @"http://filegw.test.pajkdc.com/upload?tfsGroupId=0"
#define PAAPI_TFSUrl @"http://static.test.pajkdc.com/v1/tfs/"

#define PAAPI_IM_IMAGE_TFS_ADDRESS @"http://message.test.pajkdc.com"
#define PAAPI_IM_VOICE_TFS_ADDRESS @"http://message.test.pajkdc.com"
#define PAAPI_IM_XMPP_DOMAIN @"im.test.pajkdc.com"
#define PAAPI_IM_XMPP_DOMAIN_MUC @"muc.im.test.pajkdc.com"
#define PAAPI_IM_XMPP_HOST_NAME @"im.test.pajkdc.com"
#define PAAPI_IM_XMPP_HOST_PORT 5222
#define PAAPI_IM_XMPP_UPLOAD_FILE_URL @"http://message.test.pajkdc.com/tfs.do"

//直播聊天相关
#define PAAPI_LIVE_XMPP_DOMAIN @"liveim.test.pajkdc.com"
#define PAAPI_LIVE_XMPP_DOMAIN_MUC @"muc.liveim.test.pajkdc.com"
#define PAAPI_LIVE_XMPP_HOST_NAME @"liveim.test.pajkdc.com"
#define PAAPI_LIVE_XMPP_HOST_PORT 5222

#define PHL_ANCHOR_PROTOCOL_URL @"http://gc.test.pajkdc.com/health_protocol/home.html"
//直播打点
#define PAAPI_LiveClickUrl @"http://srv.test.pajk.cn/log-collector/log/put"
#define PAAPI_LiveBatchUploadUrl @"http://srv.test.pajk.cn/log-collector/log/batch/put"

#define PAAPI_ClickUrl @"http://dwtracking.test.jk.cn/a.gif"

// talking data
#define PA_AppKeyForTalkingData     @"286B729A99F00B6DBE2A07131720F925"
#define PA_ChanelName               @"AppStore"
#define PA_AppKeyForKJTalkingData   @"7CD2CB744F9CC31FA9737E2E74B3A3C7"

//---------------- 预发环境 ----------------
#elif defined PA_ENVIRON_INHOUSE

#define PAAPI_BaseUrl @"http://api.pre.jk.cn/m.api"
#define PAAPI_TFSUploadUrl @"http://filegw.pre.jk.cn/upload?tfsGroupId=0"
#define PAAPI_TFSUrl @"http://static.jk.cn/"

#define PAAPI_IM_IMAGE_TFS_ADDRESS @"http://message.im.pre.jk.cn/"
#define PAAPI_IM_VOICE_TFS_ADDRESS @"http://message.im.pre.jk.cn/"
#define PAAPI_IM_XMPP_DOMAIN @"im.pre.jk.cn"
#define PAAPI_IM_XMPP_DOMAIN_MUC @"muc.im.pre.jk.cn"
#define PAAPI_IM_XMPP_HOST_NAME @"im.pre.jk.cn"
#define PAAPI_IM_XMPP_HOST_PORT 5222
#define PAAPI_IM_XMPP_UPLOAD_FILE_URL @"http://message.im.pre.jk.cn/tfs.do"
//直播聊天相关
#define PAAPI_LIVE_XMPP_DOMAIN @"liveim.pre.jk.cn"
#define PAAPI_LIVE_XMPP_DOMAIN_MUC @"muc.liveim.pre.jk.cn"
#define PAAPI_LIVE_XMPP_HOST_NAME @"liveim.pre.jk.cn"
#define PAAPI_LIVE_XMPP_HOST_PORT 5222

#define PHL_ANCHOR_PROTOCOL_URL @"http://gc.jk.cn/health_protocol/home.html"

#define PAAPI_ClickUrl @"http://dwtracking.jk.cn/a.gif"
//直播打点
#define PAAPI_LiveClickUrl @"http://srv.pre.pajk.cn/log-collector/log/put"
#define PAAPI_LiveBatchUploadUrl @"http://srv.pre.pajk.cn/log-collector/log/batch/put"

// talking data
#define PA_AppKeyForTalkingData     @"1F25FA19E26277A8461BA3638DFBFAA1"
#define PA_ChanelName               @"AppStore"
#define PA_AppKeyForKJTalkingData   @"31EAC935C09989C4813D5254D10C4E77"

//---------------- 线上环境 ----------------
#elif defined PA_ENVIRON_APPSTORE

#define PAAPI_BaseUrl @"http://api.jk.cn/m.api"
#define PAAPI_TFSUploadUrl @"http://filegw.jk.cn/upload?tfsGroupId=0"
#define PAAPI_TFSUrl @"http://static.jk.cn/"

#define PAAPI_IM_IMAGE_TFS_ADDRESS @"http://message.im.jk.cn/"
#define PAAPI_IM_VOICE_TFS_ADDRESS @"http://message.im.jk.cn/"
#define PAAPI_IM_XMPP_DOMAIN @"im.jk.cn"
#define PAAPI_IM_XMPP_DOMAIN_MUC @"muc.im.jk.cn"
#define PAAPI_IM_XMPP_HOST_NAME @"im.jk.cn"
#define PAAPI_IM_XMPP_HOST_PORT 5222
#define PAAPI_IM_XMPP_UPLOAD_FILE_URL @"http://message.im.jk.cn/tfs.do"
//直播聊天相关
#define PAAPI_LIVE_XMPP_DOMAIN @"liveim.jk.cn"
#define PAAPI_LIVE_XMPP_DOMAIN_MUC @"muc.liveim.jk.cn"
#define PAAPI_LIVE_XMPP_HOST_NAME @"liveim.jk.cn"
#define PAAPI_LIVE_XMPP_HOST_PORT 5222

#define PHL_ANCHOR_PROTOCOL_URL @"http://gc.jk.cn/health_protocol/home.html"

#define PAAPI_ClickUrl @"http://dwtracking.jk.cn/a.gif"
//直播打点
#define PAAPI_LiveClickUrl @"http://srv.jk.cn/log-collector/log/put"
#define PAAPI_LiveBatchUploadUrl @"http://srv.jk.cn/log-collector/log/batch/put"

// talking data
#define PA_AppKeyForTalkingData     @"1F25FA19E26277A8461BA3638DFBFAA1"
#define PA_ChanelName               @"AppStore"
#define PA_AppKeyForKJTalkingData   @"31EAC935C09989C4813D5254D10C4E77"


#endif


#define GeneTestNative 0

// PAPay
#define kPAPayMerchantAppId     @"A000000000000202"
#define kPAPayPluginId          @"B0000003"
#define kPAPayHeaderStyleId     @"ps_000"


typedef NS_ENUM(NSInteger, EnvType) {
    EnvDevelop = 0,
    EnvIntegrationTest,
    EnvTest,
    EnvInhouse,
    EnvAppStore,
};


typedef NS_ENUM(NSUInteger, TFSResourceType) {
    TFSResourceTypeImage,       //图片
    TFSResourceTypeThumnail,    //缩略图
    TFSResourceTypeVoice,       //语音
    TFSResourceTypeFile,        //文件
};


// 根据tfs key获取图片路径
NSURL *resourceUrlWithTfsKey(NSString *tfskey);
NSURL *resourceUrlWithTfsKeyAndSize(NSString *tfskey, CGSize size);
NSString *resourcePathWithTfsKey(NSString *tfskey);

// 获取私有云的资源路径
NSURL *privateResourceUrlWithTfsKey(NSString *tfskey, TFSResourceType resourceType);
NSString *privateResourcePathWithTfsKey(NSString *tfskey, TFSResourceType resourceType);

// 获取私有云的缩略图路径
NSURL *privateThumnailUrlWithTfsKey(NSString *tfskey, NSString *sizeSting);   //sizeString: 形如@"_200x200"
NSString *privateThumnailPathWithTfsKey(NSString *tfskey, NSString *sizeSting);

#endif
