# -*- coding: utf-8 -*-
"""
Created on Thu Apr  2 18:09:44 2020

@author: nfischoff
"""
# -*- coding: utf-8 -*-

# Data will be obtained at night for current day 

import requests
from pandas.io.json import json_normalize 
import sqlalchemy
import urllib
from pandas import DataFrame
from datetime import datetime, date, timedelta

import sys
import logging

logging.basicConfig(filename='exampleasdf.log',level=logging.DEBUG)

try:
    params = urllib.parse.quote_plus("DRIVER={SQL Server};SERVER=;DATABASE=;UID=;PWD=")
    
    engine = sqlalchemy.create_engine("mssql+pyodbc:///?odbc_connect=%s" % params)
    
    payload =  {
        'grant_type': 'password',
        'username': '',
        'password': '',
        'scope': 'AdminApi AgentApi AuthenticationApi PatronApi RealTimeApi'
    }
    
    r = requests.post('https://api.incontact.com/InContactAuthorizationServer/Token', data = payload, headers = {'Authorization': 'basic '})
    
    content = r.json()
    token = content['access_token']

    td = str(date.today())
    tdstr = datetime.strptime(td, "%Y-%m-%d")
    tmr = tdstr + timedelta(days=1)
    tmr_fmt = datetime.strftime(tmr, "%Y-%m-%d")
    
    agent_skills = requests.get('https://api-c19.incontact.com/inContactAPI/services/v17.0/agents/skill-data?startDate=' + td + '&endDate=' + tmr_fmt, headers = {'Authorization' : 'bearer ' + token})
    agent_skills_json = agent_skills.json()
    agent_skills_df  = json_normalize(agent_skills_json ['agentSkillData']['agents'])
    agent_skills_df1 = DataFrame([dict(y, agent=i) for i, x in agent_skills_df.values.tolist() for y in x])
    agent_skills_df1 ['callsDate'] = td
    agent_skills_df1.to_sql("calls_agent_skills", engine, if_exists="append", index=False)

    agents = requests.get('https://api-c19.incontact.com/inContactAPI/services/v17.0/agents', headers = {'Authorization' : 'bearer ' + token})
    agents_json = agents.json()
    agents_df  = json_normalize(agents_json['agents'])
    
    agents_df.drop(agents_df.columns[[1,3,5,6,10]],axis=1,inplace=True) 
    agents_df.drop(agents_df.iloc[:,6:95],inplace=True,axis=1)
    
    agents_df1 = agents_df[['agentId', 'firstName', 'lastName', 'teamId','teamName']]
    agents_df.to_sql("calls_agents", engine, if_exists="append", index=False)

except:
       body = str(sys.exc_info()[1])
       logging.debug(body)


