﻿/**
 * Tencent is pleased to support the open source community by making Tars available.
 *
 * Copyright (C) 2016THL A29 Limited, a Tencent company. All rights reserved.
 *
 * Licensed under the BSD 3-Clause License (the "License"); you may not use this file except 
 * in compliance with the License. You may obtain a copy of the License at
 *
 * https://opensource.org/licenses/BSD-3-Clause
 *
 * Unless required by applicable law or agreed to in writing, software distributed 
 * under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR 
 * CONDITIONS OF ANY KIND, either express or implied. See the License for the 
 * specific language governing permissions and limitations under the License.
 */

#include <iostream>
#include "util/tc_http.h"
#include "util/tc_option.h"
#include "util/tc_common.h"
#include "util/tc_clientsocket.h"
#include "util/tc_thread_pool.h"
#include "tup/Tars.h"
#include "tup/tup.h"
#include "util/tc_timeprovider.h"
#include "servant/Application.h"
using namespace std;
using namespace tars;
using namespace tup;


Communicator* _comm;

//static string httpObj = "TestApp.HttpServer.httpObj@tcp -h 127.0.0.1 -p 8081";
static string httpObj = "TestApp.HttpServer.httpObj@tcp -h 134.175.105.92 -p 8081";

struct Param
{
	int count;
	string call;
	int thread;

	ServantPrx servantPrx;
};

Param param;
std::atomic<int> callback_count(0);


void httpCall(int excut_num)
{
    int64_t _iTime = TC_TimeProvider::getInstance()->getNowMs();

  //  string sServer1("http://134.175.105.92:8081/");
    string sServer1("http://127.0.0.1:8081/");

    TC_HttpRequest stHttpReq;
    stHttpReq.setCacheControl("no-cache");
//    stHttpReq.setGetRequest(sServer1);

    TC_TCPClient client ;
 //   client.init("127.0.0.1", 8081, 3000);
    client.init("127.0.0.1", 8082, 3000);

    int iRet = 0;

    for (int i = 0; i<excut_num; i++)
    {
        TC_HttpResponse stHttpRsp;

        stHttpReq.setPostRequest(sServer1, TC_Common::tostr(i), true);
        iRet = stHttpReq.doRequest(stHttpRsp, 3000);
    //    iRet = stHttpReq.doRequest(client,stHttpRsp);
        
        if (iRet != 0)
        {
            cout <<"pthread id: " << TC_Thread::CURRENT_THREADID() << ", iRet:" << iRet <<endl;
        }
        
        ++callback_count;
    }
    cout <<  "httpCall, succ:" << param.count << "/" << excut_num << ", " << TC_TimeProvider::getInstance()->getNowMs() - _iTime <<"(ms)"<<endl;
}

struct TestHttpCallback : public HttpCallback
{
    TestHttpCallback(int64_t t, int i, int c) : start(t), cur(i), count(c)
    {

    }

    virtual int onHttpResponse(const std::map<std::string, std::string>& requestHeaders ,
                               const std::map<std::string, std::string>& responseHeaders ,
                               const std::vector<char>& rspBody)
    {
	    callback_count++;

        if(cur == count-1)
        {
            int64_t cost = TC_Common::now2us() - start;
            cout << "onHttpResponse count:" << count << ", " << cost << " us, avg:" << 1.*cost/count << "us" << endl;
        }

        return 0;
    }
    virtual int onHttpResponseException(const std::map<std::string, std::string>& requestHeaders,
                                        int expCode)
    {
        cout << "onHttpResponseException expCode:" << expCode  << endl;

	    callback_count++;

        return 0;
    }

    int64_t start;
    int     cur;
    int     count;
};

void syncRpc(int c)
{
	int64_t t = TC_Common::now2us();

    std::map<std::string, std::string> header;

    std::map<std::string, std::string> rheader;
    //发起远程调用
    for (int i = 0; i < c; ++i)
    {
        string rbody;

        try
        {
	        param.servantPrx->http_call("GET", "/", header, "helloworld", rheader, rbody);
        }
        catch(exception& e)
        {
            cout << "exception:" << e.what() << endl;
        }
        ++callback_count;
    }

    int64_t cost = TC_Common::now2us() - t;
    cout << "syncCall total:" << cost << "us, avg:" << 1.*cost/c << "us" << endl;
}

int main(int argc, char *argv[])
{
    try
    {
        if (argc < 4)
        {
	        cout << "Usage:" << argv[0] << "--count=1000 --call=[basehttp|synchttp] --thread=1" << endl;

	        return 0;
        }

	    TC_Option option;
        option.decode(argc, argv);

		param.count = TC_Common::strto<int>(option.getValue("count"));
	    if(param.count <= 0) param.count = 1000;
	    param.call = option.getValue("call");
	    if(param.call.empty()) param.call = "sync";
	    param.thread = TC_Common::strto<int>(option.getValue("thread"));
	    if(param.thread <= 0) param.thread = 1;
/*
        _comm = new Communicator();

//         TarsRollLogger::getInstance()->logger()->setLogLevel(6);

        _comm->setProperty("sendqueuelimit", "1000000");
        _comm->setProperty("asyncqueuecap", "1000000");

	    param.servantPrx = _comm->stringToProxy<ServantPrx>(httpObj);

	    param.servantPrx->tars_connect_timeout(5000);
        param.servantPrx->tars_async_timeout(60*1000);

        ProxyProtocol proto;
        proto.requestFunc = ProxyProtocol::http1Request;
        proto.responseFunc = ProxyProtocol::http1Response;
        param.servantPrx->tars_set_protocol(proto);
        */
        int64_t start = TC_Common::now2us();

        std::function<void(int)> func;

        if (param.call == "basehttp")
        {
            func = httpCall;
        }
        else if (param.call == "synchttp")
        {
            func = syncRpc;
        }
        // else if(param.call == "asynchttp")
        // {
        // 	func = asyncRpc;
        // }
        else
        {
        	cout << "no func, exits" << endl;
        	exit(0);
        }

	    vector<std::thread*> vt;
        for(int i = 0 ; i< param.thread; i++)
        {
            vt.push_back(new std::thread(func, param.count));
        }

        std::thread print([&]{while(callback_count != param.count * param.thread) {
	        cout << "Http:" << param.call << ": ----------finish count:" << callback_count << endl;
	        std::this_thread::sleep_for(std::chrono::seconds(1));
        };});

        for(size_t i = 0 ; i< vt.size(); i++)
        {
            vt[i]->join();
            delete vt[i];
        }

        cout << "(pid:" << std::this_thread::get_id() << ")"
             << "(count:" << param.count << ")"
             << "(use ms:" << (TC_Common::now2us() - start)/1000 << ")"
             << endl;

	    while(callback_count != param.count * param.thread) {
		    std::this_thread::sleep_for(std::chrono::seconds(1));
	    }
	    print.join();
	    cout << "----------finish count:" << callback_count << endl;
    }
    catch(exception &ex)
    {
        cout << ex.what() << endl;
    }
    cout << "main return." << endl;

    return 0;
}