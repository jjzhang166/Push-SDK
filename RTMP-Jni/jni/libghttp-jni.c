#include "libghttp-jni.h"
#include <stdio.h>
#include <string.h>
#include "../libghttp/jni/ghttp.h"
#include "cJSON.h"
#include <time.h>

int64_t getAbsTime()
{
	char szXML[2048];
	char *uri = "http://gpgame.dev.api.smartcourt.cn/QueryGameData/getTimeStamp";
	char timeCh[32];
	time_t timep;
	struct tm *p;
	time(&timep);
	p = localtime(&timep);
	memset(&timeCh, 0, sizeof(timeCh));
	sprintf(timeCh, "%d-%d-%d %d:%d:%d", (1900+p->tm_year), (1 + p->tm_mon), p->tm_mday, p->tm_hour, p->tm_min, p->tm_sec);
	ghttp_request *request = NULL;
	ghttp_status status;
	char *buf;
	int len;
	cJSON *root;
	cJSON *data;
	cJSON *dateInfo;
	cJSON *timeInterval;
	int iTimeInterval = 0;
	sprintf(szXML, "{\"appId\":\"123\", \"clientTime\":\"%s\"}", timeCh);
	printf("%s\n", szXML);          //test
	request = ghttp_request_new();
	ghttp_set_header(request, http_hdr_Content_Type, "application/x-www-form-urlencoded");
	ghttp_set_sync(request, ghttp_sync); //set sync
	
	while(true)
	{
		ghttp_clean(request);
		if (ghttp_set_uri(request, uri) == -1)
		{
				printf("ghttp_set_uri failuer\n");              //test
				sleep(1);
				continue;
		}
		if (ghttp_set_type(request, ghttp_type_post) == -1)             //post
		{
				printf("ghttp_set_type failuer\n");
				sleep(1);
				continue;
		}
		printf("step 1  \n");
		len = strlen(szXML);
		ghttp_set_body(request, szXML, len);    //
		printf("step 2  \n");
		status = ghttp_prepare(request);
		if (status == ghttp_error)
		{
			printf("ghttp_prepare status error   \n");
			sleep(1);
			continue;
		}
		status = ghttp_process(request);
		if (status == ghttp_error)
		{
			printf("ghttp_process status error   \n");
			sleep(1);
			continue;
		}
		printf("step 3  \n");
		int statusCode = ghttp_status_code(request);
		if(statusCode != 200)
		{
			sleep(1);
			continue;
		}
		buf = ghttp_get_body(request);  //test
		printf("step 4  \n");
		if(buf == NULL)
		{
			printf("error.........................\n");
			sleep(1);
			continue;
		}
		printf("%s \n", buf);
		int resLen = ghttp_get_body_len(request);
		char *jsonbuf = (char *)malloc(resLen + 1);
		memset(jsonbuf, 0, resLen + 1);
		strncpy(jsonbuf, buf, resLen);
		printf("step 6  \n");
		root = cJSON_Parse(jsonbuf);
		data = cJSON_GetObjectItem(root, "data");
		if(data == NULL)
		{
			free(jsonbuf);
			cJSON_Delete(root);
			sleep(1);
			continue;
		}
		printf("step 7  \n");
		dateInfo = cJSON_GetObjectItem(data, "dateInfo");
		timeInterval = cJSON_GetObjectItem(dateInfo, "timeInterval");
		printf("step 8  \n");
		if(timeInterval == NULL)
		{
			free(jsonbuf);
			cJSON_Delete(root);
			sleep(1);
			continue;
		}
		printf("step 9  \n");
		iTimeInterval = timeInterval->valueint;
		printf("iTimeInterval = %d\n", timeInterval->valueint);
		free(jsonbuf);
		printf("step 10  \n");
		if(iTimeInterval != 0)
		{
			printf("step 11  \n");
			break;
		}
	}
	return iTimeInterval;
}
