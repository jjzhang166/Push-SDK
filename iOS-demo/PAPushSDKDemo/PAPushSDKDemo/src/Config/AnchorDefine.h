//
//  AnchorDefine.h
//  anchor
//
//  Created by wangweishun on 17/05/2017.
//  Copyright © 2017 PAJK. All rights reserved.
//

#ifndef AnchorDefine_h
#define AnchorDefine_h

//直播间类型
typedef NS_ENUM(NSInteger, HLSLiveType) {
    HLSLiveTypeHealth = 10,   //个人讲解直播（健康直播）
    HLSLiveTypeDoctor = 20,   //医生问答直播 (医生直播)
};

//筛选问题类型
typedef NS_ENUM(NSInteger, HLSQuestionType) {
    HLSQuestionTypeUnAnswer = 0,  //未回答问题
    HLSQuestionTypeAnswered,      //已回答的问题
    HLSQuestionTypeAll,           //全部问题
    
};

//问题操作类型
typedef NS_ENUM(NSInteger, HLSQuestionOperateType) {
    HLSQuestionOperateTypeAnswer = 0,   //回答
    HLSQuestionOperateTypeAnswering,    //解答中
    HLSQuestionOperateTypeAnswered,     //已回答
    HLSQuestionOperateTypeRetry,        //重新提交
};

//问题回答状态，回答状态 10:未答 20:已答 30:正在回答
typedef NS_ENUM(NSInteger, HLSQuestionReplyStatus) {
    HLSQuestionReplyStatusUnAnswer = 10,  //未回答
    HLSQuestionReplyStatusAnswering = 30,     //回答中
    HLSQuestionReplyStatusAnswered = 20,      //已回答
    
};


#endif /* AnchorDefine_h */
