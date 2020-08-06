# -*- coding: utf-8 -*-
"""
Created on Thu Aug  6 15:50:15 2020

@author: nfischoff
"""


from flask import Flask
import dash
#from datetime import datetime as dt
import dash_html_components as html
import dash_core_components as dcc
import pandas as pd
import plotly.graph_objs as go
#import plotly
#import plotly.express as px
import dash_bootstrap_components as dbc
from dash.dependencies import Input, Output
import json
import pyodbc
from datetime import datetime as dt
from datetime import timedelta as timedelta
import re
from  geopy.geocoders import Nominatim

server = Flask(__name__)


app = dash.Dash(__name__, 
				server=server, 
                external_stylesheets=[dbc.themes.BOOTSTRAP]
				
				)

mapboxToken = ('')

counties = json.load(open('counties.json'))


geolocator = Nominatim(user_agent="nfischoff@planned.org")

con = pyodbc.connect("DRIVER={SQL Server};SERVER=;DATABASE=;UID=;PWD=")
cur = con.cursor()

thCountyDaily = "exec TH_county_daily"
thCounty1Daily = pd.read_sql(thCountyDaily,con)
thCounty1Daily['fips'] = thCounty1Daily['fips'].apply(lambda x: '{0:0>5}'.format(x))
thCounty1Daily['County'] = thCounty1Daily['County'].str.upper() 

today = dt.today()
midnight = dt.combine(today, dt.min.time())
yesterday = midnight - timedelta(days=1)   

    
rfv_options = []
ct2 = thCounty1Daily.sort_values(by= "Visit_Count",ascending=False)
for rfv in ct2['RFV'].unique():
		rfv_options.append({'label':str(rfv),'value':rfv})
rfv_options.append({'label': 'All RFV', 'value': 'All RFV'})
        
thCityDaily = "exec TH_city_daily"        
thCity1Daily = pd.read_sql(thCityDaily ,con)

thCity1Daily ['stateforLatLong'] = thCity1Daily['state']
thCity1Daily = thCity1Daily.replace({'stateforLatLong': {'CA': 'California'}})

thCity1Daily ['cityState'] = thCity1Daily [['city', 'state']].agg(', '.join, axis=1)
thCity1Daily ['cityStateforLatLong'] = thCity1Daily [['city', 'stateforLatLong']].agg(', '.join, axis=1)

thCity1Daily = thCity1Daily.sort_values(by= "Visit_Count",ascending=False)

#noLatLong = thCity1Daily[thCity1Daily['Latitude'].isnull()]
#uniqueValues = noLatLong['cityStateforLatLong'].unique()
# =============================================================================
# 
# if uniqueValues.any():
#     lat_long = []
# 
#     for x in uniqueValues:             
#         loc = geolocator.geocode(x)
#         lat_long.append(
#             {
#                 'cityStateforLatLong': x, 
#                 'Latitude': loc.latitude, 
#                 'Longitude': loc.longitude
#                 }
#             )
#     
#     d = pd.DataFrame(lat_long)
#     
#     thCity1Daily = thCity1Daily.merge(d, on='cityStateforLatLong', how='left')
# 
# 
#     thCity1Daily['Latitude'] = thCity1Daily['Latitude_x'].fillna(thCity1Daily['Latitude_y'])
#     thCity1Daily['Longitude'] = thCity1Daily['Longitude_x'].fillna(thCity1Daily['Longitude_y'])
#     thCity1Daily = thCity1Daily.drop(['Latitude_x', 'Latitude_y', 'Longitude_x', 'Longitude_y','cityStateforLatLong'],axis=1)
#     
# 
# =============================================================================
city_options = []
thCity1Daily.sort_values(by="cityState")
for city in thCity1Daily['cityState'].unique():
		city_options.append({'label':str(city),'value':city})
city_options.append({'label': 'All Cities', 'value': 'All Cities'})

thDemoQ =  "exec TH_demographics"   
thDemo = pd.read_sql(thDemoQ,con)


app.layout = dbc.Container(html.Div([
                    dcc.Location(id='url'),
                    
                    dbc.Tabs(
                        [
                            dbc.Tab(label="County", tab_id="tab-1"), 
                            dbc.Tab(label="City", tab_id="tab-2"),   
                             dbc.Tab(label="Demographics", tab_id="tab-3"), 
                            ],
                        id="tabs", 
                        active_tab="tab-1",
                        
                        ),
                    html.Div(id='page-content')
        
    ]))


page_1_layout= html.Div([
                   
                   html.Div(dbc.Row([dbc.Col(html.H2('Telehealth Visits by County',style={'marginBottom':50,'marginTop': 50}))])),
                    
                      html.Div(dbc.Row([
                      dbc.Col(dcc.DatePickerRange(
                                    id='my-date-picker-range',
                                    min_date_allowed=dt(2020, 3, 28),
                                    max_date_allowed=midnight,
                                    initial_visible_month=dt(2020, 3, 28),
                                    start_date=dt(2020,3,28).date(),
                                    end_date=yesterday.date(),
                                   
                                )),
                    dbc.Col(dcc.Dropdown(id='county-ptType-picker',
 									options=[{'label':'New','value':'New'},{'label':'Est','value':'Est'},{'label':'All Patients','value':'All Patients'}],
 									value='All Patients'
 									)),
                   dbc.Col( dcc.Dropdown(id='county-rfv-picker',
 									options=rfv_options,
 									value='All RFV'
 									))
                          ])),
                    html.Div(
                            [ dbc.Row([dbc.Col(dcc.Graph(id='county-combined'))]), 
                                dbc.Row([dbc.Col(dcc.Graph(id='summary-number-table'))],style={'marginBottom': 0,'marginTop':0}),                      
                            dbc.Row([dbc.Col(dcc.Graph(id='summary-county-bar-ptType'))])   ,
                             dbc.Row([dbc.Col(dcc.Graph(id='summary-line-chart'))])   ,
                             dbc.Row([dbc.Col(dcc.Graph(id='summary-county-bar-rfv'))])   ,
                               dbc.Row([dbc.Col(dcc.Graph(id='summary-county-table'))])   ,
                           
                            ],style={'marginBottom':50})

])


page_2_layout =html.Div([
                        html.H2('Telehealth Visits by City',style={'marginBottom':50,'marginTop': 50}),
                       
                        html.Div(dbc.Row([
                              dbc.Col(dcc.DatePickerRange(
                                    id='city-my-date-picker-range',
                                    min_date_allowed=dt(2020, 3, 28),
                                    max_date_allowed=midnight,
                                    initial_visible_month=dt(2020, 3, 28),
                                    start_date=dt(2020,3,28).date(),
                                    end_date=yesterday.date(),                                   
                                )),      
                            dbc.Col(dcc.Dropdown(id='ptType-picker',
									options=[{'label':'New','value':'New'},{'label':'Est','value':'Est'},{'label':'All Patients','value':'All Patients'}],
									value='All Patients'
									)),
                            dbc.Col(dcc.Dropdown(id='vt-picker',
									options=rfv_options,
 									value='All RFV'
									)),
                            dbc.Col(dcc.Dropdown(id='city-picker',
									options=city_options,
 									value='All Cities'
									)),                        
                        ])),
                        
                        html.Div(
                            [ dbc.Row([dbc.Col(dcc.Graph(id='cityMap'),style={'marginBottom': 0,'marginTop':0})],style={'marginBottom': 0,'marginTop':0}), 
                                dbc.Row([dbc.Col(dcc.Graph(id='summary-city-bar-ptType'))],style={'marginBottom': 0,'marginTop':0}),                     
                                dbc.Row([dbc.Col(dcc.Graph(id='summary-city-line-ptType'))],style={'marginBottom': 0,'marginTop':0}),          
                                dbc.Row([dbc.Col(dcc.Graph(id='summary-city-line-rfv'))],style={'marginBottom': 0,'marginTop':0}),               
                                dbc.Row([dbc.Col(dcc.Graph(id='summary-city-table'))],style={'marginBottom': 0,'marginTop':0}),                      
                              
                                                
                            ],style={'marginBottom':50})
                            

])

page_3_layout =html.Div([
                        html.H2('Telehealth Patient Demographics by Visit',style={'marginBottom':50,'marginTop': 50}),
                       
                        html.Div(dbc.Row([
                              dbc.Col(dcc.DatePickerRange(
                                    id='demo-my-date-picker-range',
                                    min_date_allowed=dt(2020, 3, 28),
                                    max_date_allowed=midnight,
                                    initial_visible_month=dt(2020, 3, 28),
                                    start_date=dt(2020,3,28).date(),
                                    end_date=yesterday.date(),                                   
                                )),                          
                            dbc.Col(dcc.Dropdown(id='demo-city-picker',
									options=city_options,
 									value='All Cities'
									)),                        
                            dbc.Col(dcc.Dropdown(id='demo-ptType-picker',
 									options=[{'label':'New','value':'New'},{'label':'Est','value':'Est'},{'label':'All Patients','value':'All Patients'}],
 									value='All Patients'
 									)),
                        ])),
                        
                        html.Div(
                            [ dbc.Row([dbc.Col(dcc.Graph(id='demo-age-bar'),style={'marginBottom': 0,'marginTop':0})],style={'marginBottom': 0,'marginTop':0}), 
                             dbc.Row([dbc.Col(dcc.Graph(id='demo-race-bar'),style={'marginBottom': 0,'marginTop':0})],style={'marginBottom': 0,'marginTop':0}), 
                            ],style={'marginBottom':50})
                            

])


@app.callback(Output("page-content","children"),[Input("tabs","active_tab")])
def switch_tab(at): 
    if at=='tab-1':
            return page_1_layout        
    elif at == "tab-2":
        return page_2_layout
    elif at == "tab-3":
        return page_3_layout
    return html.P("this shouldnt be displayed")


@app.callback(Output('summary-city-table','figure'),
				[Input('ptType-picker','value'),
                Input('vt-picker','value'),
                Input('city-my-date-picker-range', 'start_date'),
                 Input('city-my-date-picker-range', 'end_date'),
                 Input('city-picker', 'value')
                ])
def city_table_figure (selected_ptType,selected_rfv,start_date,end_date, selected_city):
    if (selected_ptType == 'All Patients') & (selected_rfv == 'All RFV') & (selected_city == 'All Cities') : 
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) ]  
    elif(selected_ptType=='All Patients') & (selected_rfv != 'All RFV') & (selected_city == 'All Cities'):
        city_filtered_df = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                    (thCity1Daily['RFV'] == selected_rfv) ]
    elif(selected_ptType!='All Patients') & (selected_rfv == 'All RFV') & (selected_city == 'All Cities'):
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                    (thCity1Daily['New or Est Pt'] == selected_ptType)] 
    elif(selected_ptType!='All Patients') & (selected_rfv != 'All RFV') & (selected_city == 'All Cities'):
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                   (thCity1Daily['RFV'] == selected_rfv) &
                                    (thCity1Daily['New or Est Pt'] == selected_ptType)] 
    elif(selected_ptType=='All Patients') & (selected_rfv == 'All RFV') & (selected_city != 'All Cities'):
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                    (thCity1Daily['cityState'] == selected_city)] 
    elif(selected_ptType!='All Patients') & (selected_rfv == 'All RFV') & (selected_city != 'All Cities'):
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                    (thCity1Daily['New or Est Pt'] == selected_ptType) &
                                    (thCity1Daily['cityState'] == selected_city)] 
    elif(selected_ptType=='All Patients') & (selected_rfv != 'All RFV') & (selected_city != 'All Cities'):
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                    (thCity1Daily['RFV'] == selected_rfv) &
                                    (thCity1Daily['cityState'] == selected_city)] 
    else: 
         city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) & 
                                   (thCity1Daily['New or Est Pt'] == selected_ptType) &
                                    (thCity1Daily['RFV'] == selected_rfv) &
                                    (thCity1Daily['cityState'] == selected_city)] 
   
    
    total_city = city_filtered_df.groupby(['County', 'city', 'state']).sum()['Visit_Count'].reset_index()
    
    total_city = total_city.sort_values(by='Visit_Count', ascending=False)
    
    traces = [go.Table(
                   header=dict(values=['County','City','State','Visits']),
                       cells=dict(values=[total_city['County'],total_city['city'],total_city['state'], total_city['Visit_Count']]))]
				
    start_date = dt.strptime(re.split('T| ', start_date)[0], '%Y-%m-%d')
    start_date_string = start_date.strftime('%m/%d/%y')
    
    end_date = dt.strptime(re.split('T| ', end_date)[0], '%Y-%m-%d')
    end_date_string = end_date.strftime('%m/%d/%y')
    
    cityTableLayout = go.Layout(height=700,title=start_date_string + '-' + end_date_string + ' - ' + selected_ptType + ' - ' + selected_rfv )
    
    return {'data': traces,'layout':cityTableLayout}



@app.callback(Output('cityMap','figure'),
                [
				Input('ptType-picker','value'),
                Input('vt-picker','value'),
                Input('city-my-date-picker-range', 'start_date'),
                 Input('city-my-date-picker-range', 'end_date'),
                 Input('city-picker', 'value')
                ])
def update_figure(selected_ptType,selected_rfv,start_date,end_date,selected_city):
    
    if (selected_ptType == 'All Patients') & (selected_rfv == 'All RFV') & (selected_city == 'All Cities') : 
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) ]  
    elif(selected_ptType=='All Patients') & (selected_rfv != 'All RFV') & (selected_city == 'All Cities'):
        city_filtered_df = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                    (thCity1Daily['RFV'] == selected_rfv) ]
    elif(selected_ptType!='All Patients') & (selected_rfv == 'All RFV') & (selected_city == 'All Cities'):
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                    (thCity1Daily['New or Est Pt'] == selected_ptType)] 
    elif(selected_ptType!='All Patients') & (selected_rfv != 'All RFV') & (selected_city == 'All Cities'):
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                   (thCity1Daily['RFV'] == selected_rfv) &
                                    (thCity1Daily['New or Est Pt'] == selected_ptType)] 
    elif(selected_ptType=='All Patients') & (selected_rfv == 'All RFV') & (selected_city != 'All Cities'):
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                    (thCity1Daily['cityState'] == selected_city)] 
    elif(selected_ptType!='All Patients') & (selected_rfv == 'All RFV') & (selected_city != 'All Cities'):
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                    (thCity1Daily['New or Est Pt'] == selected_ptType) &
                                    (thCity1Daily['cityState'] == selected_city)] 
    elif(selected_ptType=='All Patients') & (selected_rfv != 'All RFV') & (selected_city != 'All Cities'):
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                    (thCity1Daily['RFV'] == selected_rfv) &
                                    (thCity1Daily['cityState'] == selected_city)] 
    else: 
         city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) & 
                                   (thCity1Daily['New or Est Pt'] == selected_ptType) &
                                    (thCity1Daily['RFV'] == selected_rfv) &
                                    (thCity1Daily['cityState'] == selected_city)] 
   
    if not city_filtered_df.empty:
        total_city = city_filtered_df.groupby(['city', 'state', 'Latitude','Longitude']).sum()['Visit_Count'].reset_index()
        
        maxVisits = total_city['Visit_Count'].max()
        minVisits = total_city['Visit_Count'].min()
        
        traces = [go.Scattermapbox(
    					lat=total_city['Latitude'],
    					lon=total_city['Longitude'],
    					mode='markers',
    					marker=go.scattermapbox.Marker(
    						size=18, 
                            cmax=maxVisits, 
                            cmin=minVisits, 
                            opacity=0.8,
                            color=total_city['Visit_Count'],
                            colorscale='Viridis',
                            colorbar=dict(
                                    title="Visits"
                                    )                        
    					),
    					hovertext=total_city['city'] + ', ' + total_city['Visit_Count'].astype(str),
    					hoverinfo='text',
    
    					)]
    
        start_date = dt.strptime(re.split('T| ', start_date)[0], '%Y-%m-%d')
        start_date_string = start_date.strftime('%m/%d/%y')
        
        end_date = dt.strptime(re.split('T| ', end_date)[0], '%Y-%m-%d')
        end_date_string = end_date.strftime('%m/%d/%y')
        
        cityMapLayout = go.Layout(title=start_date_string + '-' + end_date_string + ' - ' + selected_ptType + ' - ' + selected_rfv, mapbox=dict(accesstoken=mapboxToken,
    																				center = dict(lat=32.7157,lon=-117.1611),
    																				zoom=7 ),height=600) 
        
        
        return  {'data':traces,
    				'layout': cityMapLayout}
    else:
       return {
                    "layout": {
                        "xaxis": {
                            "visible": False
                        },
                        "yaxis": {
                            "visible": False
                        },
                        "annotations": [
                            {
                                "text": "No matching data found",
                                "xref": "paper",
                                "yref": "paper",
                                "showarrow": False,
                                "font": {
                                    "size": 28
                                }
                            }
                        ]
                    }
                }

@app.callback(Output('summary-city-bar-ptType','figure'),
				  [
				Input('ptType-picker','value'),
                Input('vt-picker','value'),
                Input('city-my-date-picker-range', 'start_date'),
                 Input('city-my-date-picker-range', 'end_date'),
                 Input('city-picker', 'value')
                ])
def update_city_bar_daily(selected_ptType,selected_rfv,start_date,end_date,selected_city):
		
    if (selected_ptType == 'All Patients') & (selected_rfv == 'All RFV') & (selected_city == 'All Cities') : 
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) ]  
    elif(selected_ptType=='All Patients') & (selected_rfv != 'All RFV') & (selected_city == 'All Cities'):
        city_filtered_df = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                    (thCity1Daily['RFV'] == selected_rfv) ]
    elif(selected_ptType!='All Patients') & (selected_rfv == 'All RFV') & (selected_city == 'All Cities'):
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                    (thCity1Daily['New or Est Pt'] == selected_ptType)] 
    elif(selected_ptType!='All Patients') & (selected_rfv != 'All RFV') & (selected_city == 'All Cities'):
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                   (thCity1Daily['RFV'] == selected_rfv) &
                                    (thCity1Daily['New or Est Pt'] == selected_ptType)] 
    elif(selected_ptType=='All Patients') & (selected_rfv == 'All RFV') & (selected_city != 'All Cities'):
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                    (thCity1Daily['cityState'] == selected_city)] 
    elif(selected_ptType!='All Patients') & (selected_rfv == 'All RFV') & (selected_city != 'All Cities'):
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                    (thCity1Daily['New or Est Pt'] == selected_ptType) &
                                    (thCity1Daily['cityState'] == selected_city)] 
    elif(selected_ptType=='All Patients') & (selected_rfv != 'All RFV') & (selected_city != 'All Cities'):
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                    (thCity1Daily['RFV'] == selected_rfv) &
                                    (thCity1Daily['cityState'] == selected_city)] 
    else: 
         city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) & 
                                   (thCity1Daily['New or Est Pt'] == selected_ptType) &
                                    (thCity1Daily['RFV'] == selected_rfv) &
                                    (thCity1Daily['cityState'] == selected_city)] 
   
    
    if not city_filtered_df.empty:
        total_visits = city_filtered_df.groupby(['cityState','New or Est Pt']).sum()['Visit_Count'].reset_index()
        
        cfb = total_visits.sort_values(by='Visit_Count', ascending=False)
            
        cfb1 = cfb.nlargest(10, 'Visit_Count')
        
        cityList = cfb1['cityState'].unique()
        cfb2 = cfb[cfb.cityState.isin(cityList)]
        
        cfb_est = cfb2[cfb2['New or Est Pt']=='Est']      
        cfb_new = cfb2[cfb2['New or Est Pt']=='New']    
                
        traces = [
				    	  
            				  go.Bar(
                                        x=cfb_est['cityState'],
                                        y= cfb_est['Visit_Count'],        
                                        marker_color='#2D2926',  
                                        textposition='auto', 
                                        name='Established', 
                                        opacity=0.7
                                        ),
                              go.Bar(
                                        x=cfb_new['cityState'],
                                        y= cfb_new['Visit_Count'],        
                                        marker_color='#E94B3C',                                    
                                        textposition='auto', 
                                        name='New', 
                                        opacity=0.7
                                        )
                        ]
        start_date = dt.strptime(re.split('T| ', start_date)[0], '%Y-%m-%d')
        start_date_string = start_date.strftime('%m/%d/%y')
        
        end_date = dt.strptime(re.split('T| ', end_date)[0], '%Y-%m-%d')
        end_date_string = end_date.strftime('%m/%d/%y')
        
        if selected_city == "All Cities": 
            countyBarLayout = go.Layout(title='Top Cities: ' + start_date_string + '-' + end_date_string + ' - ' + selected_ptType + ' - ' + selected_rfv)
        else: 
            countyBarLayout = go.Layout(title= selected_city + '-' +  start_date_string + '-' + end_date_string + ' - ' + selected_ptType + ' - ' + selected_rfv)
            
            
        return  {'data':traces, 
                 'layout': countyBarLayout}
    else: 
        return {
                    "layout": {
                        "xaxis": {
                            "visible": False
                        },
                        "yaxis": {
                            "visible": False
                        },
                        "annotations": [
                            {
                                "text": "No matching data found",
                                "xref": "paper",
                                "yref": "paper",
                                "showarrow": False,
                                "font": {
                                    "size": 28
                                }
                            }
                        ]
                    }
                }


@app.callback(Output('summary-city-line-ptType','figure'),
				  [
				Input('ptType-picker','value'),
                Input('vt-picker','value'),
                Input('city-my-date-picker-range', 'start_date'),
                 Input('city-my-date-picker-range', 'end_date'),
                 Input('city-picker', 'value')
                ])
def update_city_line_daily(selected_ptType,selected_rfv,start_date,end_date,selected_city):
		
    if (selected_ptType == 'All Patients') & (selected_rfv == 'All RFV') & (selected_city == 'All Cities') : 
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) ]  
    elif(selected_ptType=='All Patients') & (selected_rfv != 'All RFV') & (selected_city == 'All Cities'):
        city_filtered_df = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                    (thCity1Daily['RFV'] == selected_rfv) ]
    elif(selected_ptType!='All Patients') & (selected_rfv == 'All RFV') & (selected_city == 'All Cities'):
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                    (thCity1Daily['New or Est Pt'] == selected_ptType)] 
    elif(selected_ptType!='All Patients') & (selected_rfv != 'All RFV') & (selected_city == 'All Cities'):
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                   (thCity1Daily['RFV'] == selected_rfv) &
                                    (thCity1Daily['New or Est Pt'] == selected_ptType)] 
    elif(selected_ptType=='All Patients') & (selected_rfv == 'All RFV') & (selected_city != 'All Cities'):
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                    (thCity1Daily['cityState'] == selected_city)] 
    elif(selected_ptType!='All Patients') & (selected_rfv == 'All RFV') & (selected_city != 'All Cities'):
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                    (thCity1Daily['New or Est Pt'] == selected_ptType) &
                                    (thCity1Daily['cityState'] == selected_city)] 
    elif(selected_ptType=='All Patients') & (selected_rfv != 'All RFV') & (selected_city != 'All Cities'):
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                    (thCity1Daily['RFV'] == selected_rfv) &
                                    (thCity1Daily['cityState'] == selected_city)] 
    else: 
         city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) & 
                                   (thCity1Daily['New or Est Pt'] == selected_ptType) &
                                    (thCity1Daily['RFV'] == selected_rfv) &
                                    (thCity1Daily['cityState'] == selected_city)] 
   
         
    if not city_filtered_df.empty:     
        total_visits = city_filtered_df.groupby(['DOS', 'New or Est Pt']).sum()['Visit_Count'].reset_index()
       
        cfb1_new = total_visits[total_visits['New or Est Pt']=='New']
        
        cfb1_est = total_visits[total_visits['New or Est Pt']=='Est']
      
        traces = [
				    	  
            				  go.Scatter(
                                        x=cfb1_est['DOS'],
                                        y= cfb1_est['Visit_Count'],        
                                        marker_color='#2D2926', 
                                        name='Established', 
                                        opacity=0.7
                                        ),
                              go.Scatter(
                                        x=cfb1_new['DOS'],
                                        y= cfb1_new['Visit_Count'],        
                                        marker_color='#E94B3C', 
                                        name='New', 
                                        opacity=0.7
                                        )
                        ]
        
    
            
        return  {'data':traces}   
    else: 
        return {
                    "layout": {
                        "xaxis": {
                            "visible": False
                        },
                        "yaxis": {
                            "visible": False
                        },
                        "annotations": [
                            {
                                "text": "No matching data found",
                                "xref": "paper",
                                "yref": "paper",
                                "showarrow": False,
                                "font": {
                                    "size": 28
                                }
                            }
                        ]
                    }
                }

@app.callback(Output('summary-city-line-rfv','figure'),
				  [
				Input('ptType-picker','value'),
                Input('vt-picker','value'),
                Input('city-my-date-picker-range', 'start_date'),
                 Input('city-my-date-picker-range', 'end_date'),
                 Input('city-picker', 'value')
                ])
def update_city_rfv_line_daily(selected_ptType,selected_rfv,start_date,end_date,selected_city):
		
    if (selected_ptType == 'All Patients') & (selected_rfv == 'All RFV') & (selected_city == 'All Cities') : 
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) ]  
    elif(selected_ptType=='All Patients') & (selected_rfv != 'All RFV') & (selected_city == 'All Cities'):
        city_filtered_df = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                    (thCity1Daily['RFV'] == selected_rfv) ]
    elif(selected_ptType!='All Patients') & (selected_rfv == 'All RFV') & (selected_city == 'All Cities'):
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                    (thCity1Daily['New or Est Pt'] == selected_ptType)] 
    elif(selected_ptType!='All Patients') & (selected_rfv != 'All RFV') & (selected_city == 'All Cities'):
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                   (thCity1Daily['RFV'] == selected_rfv) &
                                    (thCity1Daily['New or Est Pt'] == selected_ptType)] 
    elif(selected_ptType=='All Patients') & (selected_rfv == 'All RFV') & (selected_city != 'All Cities'):
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                    (thCity1Daily['cityState'] == selected_city)] 
    elif(selected_ptType!='All Patients') & (selected_rfv == 'All RFV') & (selected_city != 'All Cities'):
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                    (thCity1Daily['New or Est Pt'] == selected_ptType) &
                                    (thCity1Daily['cityState'] == selected_city)] 
    elif(selected_ptType=='All Patients') & (selected_rfv != 'All RFV') & (selected_city != 'All Cities'):
        city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) &
                                    (thCity1Daily['RFV'] == selected_rfv) &
                                    (thCity1Daily['cityState'] == selected_city)] 
    else: 
         city_filtered_df  = thCity1Daily[(thCity1Daily['DOS'] >= start_date) & 
                                   (thCity1Daily['DOS'] <= end_date) & 
                                   (thCity1Daily['New or Est Pt'] == selected_ptType) &
                                    (thCity1Daily['RFV'] == selected_rfv) &
                                    (thCity1Daily['cityState'] == selected_city)] 
   
         
    if not city_filtered_df.empty: 
         
        total_visits = city_filtered_df.groupby(['RFV','New or Est Pt']).sum()['Visit_Count'].reset_index()
        
        cfb = total_visits.sort_values(by='Visit_Count', ascending=False)
            
        cfb1 = cfb.nlargest(10, 'Visit_Count')
        
        rfvList = cfb1['RFV'].unique()
        cfb2 = cfb[cfb.RFV.isin(rfvList)]
        
        cfb_est = cfb2[cfb2['New or Est Pt']=='Est']      
        cfb_new = cfb2[cfb2['New or Est Pt']=='New']    
            
        traces = [
				    	  
            				  go.Bar(
                                        x=cfb_est['RFV'],
                                        y= cfb_est['Visit_Count'],        
                                        marker_color='#2D2926', 
                                        textposition='auto', 
                                        name='Established', 
                                        opacity=0.7
                                        ),
                              go.Bar(
                                        x=cfb_new['RFV'],
                                        y= cfb_new['Visit_Count'],        
                                        marker_color='#E94B3C',                                    
                                        textposition='auto', 
                                        name='New', 
                                        opacity=0.7
                                        )
                        ]
        
        start_date = dt.strptime(re.split('T| ', start_date)[0], '%Y-%m-%d')
        start_date_string = start_date.strftime('%m/%d/%y')
        
        end_date = dt.strptime(re.split('T| ', end_date)[0], '%Y-%m-%d')
        end_date_string = end_date.strftime('%m/%d/%y')
        
        if selected_rfv == 'All RFV':     
            cityBarRFVLayout = go.Layout(title='Top 10 RFV: ' + start_date_string + '-' + end_date_string )   
        else: 
            cityBarRFVLayout = go.Layout(title= start_date_string + '-' + end_date_string + ' - ' + selected_rfv)   
            
        return  {'data':traces, 
                 'layout': cityBarRFVLayout}
    else: 
        return {
                    "layout": {
                        "xaxis": {
                            "visible": False
                        },
                        "yaxis": {
                            "visible": False
                        },
                        "annotations": [
                            {
                                "text": "No matching data found",
                                "xref": "paper",
                                "yref": "paper",
                                "showarrow": False,
                                "font": {
                                    "size": 28
                                }
                            }
                        ]
                    }
                }

@app.callback(Output('county-combined','figure'),
				[Input('county-ptType-picker','value'),
     			Input('my-date-picker-range', 'start_date'),
                 Input('my-date-picker-range', 'end_date'),
                 Input('county-rfv-picker','value')
     ])
def update_county_figure(selected_ptType,start_date,end_date,selected_rfv):

    if (selected_ptType == 'All Patients') & (selected_rfv == 'All RFV'): 
        county_filtered_df = thCounty1Daily[(thCounty1Daily['DOS'] >= start_date) & 
                                   (thCounty1Daily['DOS'] <= end_date) ]  
    elif(selected_ptType=='All Patients') & (selected_rfv != 'All RFV'):
        county_filtered_df = thCounty1Daily[(thCounty1Daily['DOS'] >= start_date) & 
                                   (thCounty1Daily['DOS'] <= end_date) &
                                    (thCounty1Daily['RFV'] == selected_rfv) ]
    elif(selected_ptType!='All Patients') & (selected_rfv == 'All RFV'):
        county_filtered_df = thCounty1Daily[(thCounty1Daily['DOS'] >= start_date) & 
                                   (thCounty1Daily['DOS'] <= end_date) &
                                    (thCounty1Daily['New or Est Pt'] == selected_ptType)] 
    else: 
         county_filtered_df = thCounty1Daily[(thCounty1Daily['DOS'] >= start_date) & 
                                   (thCounty1Daily['DOS'] <= end_date) & 
                                   (thCounty1Daily['New or Est Pt'] == selected_ptType) &
                                    (thCounty1Daily['RFV'] == selected_rfv) ]
                  
    total_visits = county_filtered_df.groupby(['fips','County']).sum()['Visit_Count'].reset_index()
                              
    maxVisits = total_visits['Visit_Count'].max()
    minVisits = total_visits['Visit_Count'].min()
    
    traces = [ go.Choroplethmapbox(geojson=counties, locations=total_visits['fips'], z=total_visits['Visit_Count'],
					colorscale="Viridis", zmin=minVisits,zmax=maxVisits,marker_opacity=0.5,marker_line_width=0, text=total_visits['County']
					)
				]
    
    start_date = dt.strptime(re.split('T| ', start_date)[0], '%Y-%m-%d')
    start_date_string = start_date.strftime('%m/%d/%y')
    
    end_date = dt.strptime(re.split('T| ', end_date)[0], '%Y-%m-%d')
    end_date_string = end_date.strftime('%m/%d/%y')
    
    countyMapLayout =go.Layout(mapbox_style='carto-positron',
										mapbox_zoom=5, mapbox_center={"lat": 35.3733, "lon":-119.0187},
										#margin={"r":0,"t":0,"l":0,"b":0},
										height=800,title=start_date_string + '-' + end_date_string + ' - ' + selected_ptType + ' - ' + selected_rfv)
    return  {'data':traces,
				'layout': countyMapLayout}
    



@app.callback(Output('summary-county-table','figure'),
				[Input('county-ptType-picker','value'),
     			Input('my-date-picker-range', 'start_date'),
                 Input('my-date-picker-range', 'end_date'),
                 Input('county-rfv-picker','value')
     ])
def update_county_table(selected_ptType,start_date, end_date,selected_rfv):
		
       
    if (selected_ptType == 'All Patients') & (selected_rfv == 'All RFV'): 
        county_filtered_df = thCounty1Daily[(thCounty1Daily['DOS'] >= start_date) & 
                                   (thCounty1Daily['DOS'] <= end_date) ]  
    elif(selected_ptType=='All Patients') & (selected_rfv != 'All RFV'):
        county_filtered_df = thCounty1Daily[(thCounty1Daily['DOS'] >= start_date) & 
                                   (thCounty1Daily['DOS'] <= end_date) &
                                    (thCounty1Daily['RFV'] == selected_rfv) ]
    elif(selected_ptType!='All Patients') & (selected_rfv == 'All RFV'):
        county_filtered_df = thCounty1Daily[(thCounty1Daily['DOS'] >= start_date) & 
                                   (thCounty1Daily['DOS'] <= end_date) &
                                    (thCounty1Daily['New or Est Pt'] == selected_ptType)] 
    else: 
         county_filtered_df = thCounty1Daily[(thCounty1Daily['DOS'] >= start_date) & 
                                   (thCounty1Daily['DOS'] <= end_date) & 
                                   (thCounty1Daily['New or Est Pt'] == selected_ptType) &
                                    (thCounty1Daily['RFV'] == selected_rfv) ]

    total_visits = county_filtered_df.groupby(['fips','County']).sum()['Visit_Count'].reset_index()
   
    
    cfb1 = total_visits.sort_values(by='Visit_Count', ascending=False)
    
    start_date = dt.strptime(re.split('T| ', start_date)[0], '%Y-%m-%d')
    start_date_string = start_date.strftime('%m/%d/%y')
    
    end_date = dt.strptime(re.split('T| ', end_date)[0], '%Y-%m-%d')
    end_date_string = end_date.strftime('%m/%d/%y')
                
    traces = [go.Table(
                   header=dict(values=['County','Visits']),
                       cells=dict(values=[cfb1['County'],cfb1['Visit_Count']]))
				]
    countyTableLayout = go.Layout(height=750, title=start_date_string + '-' + end_date_string + ' - ' + selected_ptType + ' - ' + selected_rfv)

    return  {'data': traces,
                 'layout':countyTableLayout}

@app.callback(Output('summary-number-table','figure'),
				[Input('county-ptType-picker','value'),
                 Input('my-date-picker-range', 'start_date'),
                 Input('my-date-picker-range', 'end_date'),
                 Input('county-rfv-picker','value')
     ])
def update_county_number(selected_ptType,start_date,end_date,selected_rfv):
		
       
    if (selected_ptType == 'All Patients') & (selected_rfv == 'All RFV'): 
        county_filtered_df = thCounty1Daily[(thCounty1Daily['DOS'] >= start_date) & 
                                   (thCounty1Daily['DOS'] <= end_date) ]  
    elif(selected_ptType=='All Patients') & (selected_rfv != 'All RFV'):
        county_filtered_df = thCounty1Daily[(thCounty1Daily['DOS'] >= start_date) & 
                                   (thCounty1Daily['DOS'] <= end_date) &
                                    (thCounty1Daily['RFV'] == selected_rfv) ]
    elif(selected_ptType!='All Patients') & (selected_rfv == 'All RFV'):
        county_filtered_df = thCounty1Daily[(thCounty1Daily['DOS'] >= start_date) & 
                                   (thCounty1Daily['DOS'] <= end_date) &
                                    (thCounty1Daily['New or Est Pt'] == selected_ptType)] 
    else: 
         county_filtered_df = thCounty1Daily[(thCounty1Daily['DOS'] >= start_date) & 
                                   (thCounty1Daily['DOS'] <= end_date) & 
                                   (thCounty1Daily['New or Est Pt'] == selected_ptType) &
                                    (thCounty1Daily['RFV'] == selected_rfv) ]
    
    totalVisits = county_filtered_df ['Visit_Count'].sum()
    traces = [go.Indicator(value= totalVisits )]
        
    numLayout = go.Layout(    template = {'data' : {'indicator': [{
        'title': {'text': "Total Visits",
                  'font':{'color':'#532b23'}},
        }]}}, font={'color':'#532b23'},  height=200,margin={'b':0, 't':0,'r':0,'l':0})

    return  {'data': traces,
                 'layout': numLayout}
    
@app.callback(Output('summary-county-bar-ptType','figure'),
				[Input('county-ptType-picker','value'),
                 Input('my-date-picker-range', 'start_date'),
                 Input('my-date-picker-range', 'end_date'),
                 Input('county-rfv-picker','value')
     ])
def update_county_bar_daily(selected_ptType,start_date,end_date,selected_rfv):
		
       
    if (selected_ptType == 'All Patients') & (selected_rfv == 'All RFV'): 
        county_filtered_df = thCounty1Daily[(thCounty1Daily['DOS'] >= start_date) & 
                                   (thCounty1Daily['DOS'] <= end_date) ]  
    elif(selected_ptType=='All Patients') & (selected_rfv != 'All RFV'):
        county_filtered_df = thCounty1Daily[(thCounty1Daily['DOS'] >= start_date) & 
                                   (thCounty1Daily['DOS'] <= end_date) &
                                    (thCounty1Daily['RFV'] == selected_rfv) ]
    elif(selected_ptType!='All Patients') & (selected_rfv == 'All RFV'):
        county_filtered_df = thCounty1Daily[(thCounty1Daily['DOS'] >= start_date) & 
                                   (thCounty1Daily['DOS'] <= end_date) &
                                    (thCounty1Daily['New or Est Pt'] == selected_ptType)] 
    else: 
         county_filtered_df = thCounty1Daily[(thCounty1Daily['DOS'] >= start_date) & 
                                   (thCounty1Daily['DOS'] <= end_date) & 
                                   (thCounty1Daily['New or Est Pt'] == selected_ptType) &
                                    (thCounty1Daily['RFV'] == selected_rfv) ]
    if not county_filtered_df.empty:    
        total_visits = county_filtered_df.groupby(['County','New or Est Pt']).sum()['Visit_Count'].reset_index()
        
        cfb = total_visits.sort_values(by='Visit_Count', ascending=False)
            
        #cfb1 = cfb.nlargest(5, 'Visit_Count')
        
        cfb1_new = cfb[cfb['New or Est Pt']=='New'].nlargest(5,'Visit_Count')
        
        cfb1_est = cfb[cfb['New or Est Pt']=='Est'].nlargest(5,'Visit_Count')
            
        traces = [
				    	  
            				  go.Bar(
                                        x=cfb1_est['County'],
                                        y= cfb1_est['Visit_Count'],        
                                        marker_color='#2D2926',  
                                        textposition='auto', 
                                        name='Established', 
                                        opacity=0.7
                                        ),
                              go.Bar(
                                        x=cfb1_new['County'],
                                        y= cfb1_new['Visit_Count'],        
                                        marker_color='#E94B3C',                                    
                                        textposition='auto', 
                                        name='New', 
                                        opacity=0.7
                                        )
                        ]
        start_date = dt.strptime(re.split('T| ', start_date)[0], '%Y-%m-%d')
        start_date_string = start_date.strftime('%m/%d/%y')
        
        end_date = dt.strptime(re.split('T| ', end_date)[0], '%Y-%m-%d')
        end_date_string = end_date.strftime('%m/%d/%y')
        
        countyBarLayout = go.Layout(title='Top 5 Counties: ' + start_date_string + '-' + end_date_string + ' - ' + selected_ptType + ' - ' + selected_rfv)
            
        return  {'data':traces, 
                 'layout': countyBarLayout}
    else: 
        return {
                    "layout": {
                        "xaxis": {
                            "visible": False
                        },
                        "yaxis": {
                            "visible": False
                        },
                        "annotations": [
                            {
                                "text": "No matching data found",
                                "xref": "paper",
                                "yref": "paper",
                                "showarrow": False,
                                "font": {
                                    "size": 28
                                }
                            }
                        ]
                    }
                }
  
@app.callback(Output('summary-line-chart','figure'),
				[Input('county-ptType-picker','value'),
                 Input('my-date-picker-range', 'start_date'),
                 Input('my-date-picker-range', 'end_date'),
                 Input('county-rfv-picker','value')
     ])
def update_county_line_daily(selected_ptType,start_date,end_date,selected_rfv):
		
       
    if (selected_ptType == 'All Patients') & (selected_rfv == 'All RFV'): 
        county_filtered_df = thCounty1Daily[(thCounty1Daily['DOS'] >= start_date) & 
                                   (thCounty1Daily['DOS'] <= end_date) ]  
    elif(selected_ptType=='All Patients') & (selected_rfv != 'All RFV'):
        county_filtered_df = thCounty1Daily[(thCounty1Daily['DOS'] >= start_date) & 
                                   (thCounty1Daily['DOS'] <= end_date) &
                                    (thCounty1Daily['RFV'] == selected_rfv) ]
    elif(selected_ptType!='All Patients') & (selected_rfv == 'All RFV'):
        county_filtered_df = thCounty1Daily[(thCounty1Daily['DOS'] >= start_date) & 
                                   (thCounty1Daily['DOS'] <= end_date) &
                                    (thCounty1Daily['New or Est Pt'] == selected_ptType)] 
    else: 
         county_filtered_df = thCounty1Daily[(thCounty1Daily['DOS'] >= start_date) & 
                                   (thCounty1Daily['DOS'] <= end_date) & 
                                   (thCounty1Daily['New or Est Pt'] == selected_ptType) &
                                    (thCounty1Daily['RFV'] == selected_rfv) ]
         
    if not county_filtered_df.empty:      
        total_visits = county_filtered_df.groupby(['DOS', 'New or Est Pt']).sum()['Visit_Count'].reset_index()
       
        cfb1_new = total_visits[total_visits['New or Est Pt']=='New']
        
        cfb1_est = total_visits[total_visits['New or Est Pt']=='Est']
      
        traces = [
				    	  
            				  go.Scatter(
                                        x=cfb1_est['DOS'],
                                        y= cfb1_est['Visit_Count'],        
                                        marker_color='#2D2926', 
                                     #   text=cfb1_est['Visit_Count'],
                                       
                                        name='Established', 
                                        opacity=0.7
                                        ),
                              go.Scatter(
                                        x=cfb1_new['DOS'],
                                        y= cfb1_new['Visit_Count'],        
                                        marker_color='#E94B3C', 
                                      #  text=cfb1_new['Visit_Count'],
                                        
                                        name='New', 
                                        opacity=0.7
                                        )
                        ]
        
    
            
        return  {'data':traces}   
    else: 
        return {
                    "layout": {
                        "xaxis": {
                            "visible": False
                        },
                        "yaxis": {
                            "visible": False
                        },
                        "annotations": [
                            {
                                "text": "No matching data found",
                                "xref": "paper",
                                "yref": "paper",
                                "showarrow": False,
                                "font": {
                                    "size": 28
                                }
                            }
                        ]
                    }
                }
@app.callback(Output('summary-county-bar-rfv','figure'),
				[Input('county-ptType-picker','value'),
                 Input('my-date-picker-range', 'start_date'),
                 Input('my-date-picker-range', 'end_date'),
                 Input('county-rfv-picker','value')
     ])
def update_county_rfv_bar_daily(selected_ptType,start_date,end_date,selected_rfv):
       
    if (selected_ptType == 'All Patients') & (selected_rfv == 'All RFV'): 
        county_filtered_df = thCounty1Daily[(thCounty1Daily['DOS'] >= start_date) & 
                                   (thCounty1Daily['DOS'] <= end_date) ]  
    elif(selected_ptType=='All Patients') & (selected_rfv != 'All RFV'):
        county_filtered_df = thCounty1Daily[(thCounty1Daily['DOS'] >= start_date) & 
                                   (thCounty1Daily['DOS'] <= end_date) &
                                    (thCounty1Daily['RFV'] == selected_rfv) ]
    elif(selected_ptType!='All Patients') & (selected_rfv == 'All RFV'):
        county_filtered_df = thCounty1Daily[(thCounty1Daily['DOS'] >= start_date) & 
                                   (thCounty1Daily['DOS'] <= end_date) &
                                    (thCounty1Daily['New or Est Pt'] == selected_ptType)] 
    else: 
         county_filtered_df = thCounty1Daily[(thCounty1Daily['DOS'] >= start_date) & 
                                   (thCounty1Daily['DOS'] <= end_date) & 
                                   (thCounty1Daily['New or Est Pt'] == selected_ptType) &
                                    (thCounty1Daily['RFV'] == selected_rfv) ]
         
         
    if not county_filtered_df.empty:      
        total_visits = county_filtered_df.groupby(['RFV','New or Est Pt']).sum()['Visit_Count'].reset_index()
       
        
        cfb = total_visits.sort_values(by='Visit_Count', ascending=False)
            
        cfb1 = cfb.nlargest(10, 'Visit_Count')
        
        rfvList = cfb1['RFV'].unique()
        cfb2 = cfb[cfb.RFV.isin(rfvList)]
        
        cfb_est = cfb2[cfb2['New or Est Pt']=='Est']      
        cfb_new = cfb2[cfb2['New or Est Pt']=='New']    
       
        
        #cfb1_new = cfb[cfb['New or Est Pt']=='New'].nlargest(5,'Visit_Count')
        
        #cfb1_est = cfb[cfb['New or Est Pt']=='Est'].nlargest(5,'Visit_Count')
            
        traces = [
				    	  
            				  go.Bar(
                                        x=cfb_est['RFV'],
                                        y= cfb_est['Visit_Count'],        
                                        marker_color='#2D2926', 
                                        textposition='auto', 
                                        name='Established', 
                                        opacity=0.7
                                        ),
                              go.Bar(
                                        x=cfb_new['RFV'],
                                        y= cfb_new['Visit_Count'],        
                                        marker_color='#E94B3C',                                    
                                        textposition='auto', 
                                        name='New', 
                                        opacity=0.7
                                        )
                        ]
        
        start_date = dt.strptime(re.split('T| ', start_date)[0], '%Y-%m-%d')
        start_date_string = start_date.strftime('%m/%d/%y')
        
        end_date = dt.strptime(re.split('T| ', end_date)[0], '%Y-%m-%d')
        end_date_string = end_date.strftime('%m/%d/%y')
        
        if selected_rfv == 'All RFV':     
            countyBarRFVLayout = go.Layout(title='Top 5 RFV: ' + start_date_string + '-' + end_date_string )   
        else: 
            countyBarRFVLayout = go.Layout(title= start_date_string + '-' + end_date_string + ' - ' + selected_rfv)   
            
        return  {'data':traces, 
                 'layout': countyBarRFVLayout}
    else:
                 return {
                    "layout": {
                        "xaxis": {
                            "visible": False
                        },
                        "yaxis": {
                            "visible": False
                        },
                        "annotations": [
                            {
                                "text": "No matching data found",
                                "xref": "paper",
                                "yref": "paper",
                                "showarrow": False,
                                "font": {
                                    "size": 28
                                }
                            }
                        ]
                    }
                }

@app.callback(Output('demo-age-bar','figure'),
				  [
                Input('demo-my-date-picker-range', 'start_date'),
                 Input('demo-my-date-picker-range', 'end_date'),
                 Input('demo-city-picker', 'value'),
                 Input('demo-ptType-picker', 'value')
                ])
def update_demo_age(start_date,end_date,selected_city, selected_ptType):
		
    if (selected_city == 'All Cities') & (selected_ptType == 'All Patients') : 
        demo_filtered_df  = thDemo[(thDemo['DOS'] >= start_date) & 
                                   (thDemo['DOS'] <= end_date) ]  
    elif (selected_city == 'All Cities') & (selected_ptType != 'All Patients'): 
        demo_filtered_df  = thDemo[(thDemo['DOS'] >= start_date) & 
                                   (thDemo['DOS'] <= end_date) &
                                   (thDemo['new_est'] == selected_ptType)]  
    elif (selected_city != 'All Cities') & (selected_ptType == 'All Patients'): 
        demo_filtered_df  = thDemo[(thDemo['DOS'] >= start_date) & 
                                   (thDemo['DOS'] <= end_date) &
                                   (thDemo['cityState'] == selected_city) ]
    else: 
         demo_filtered_df  = thDemo[(thDemo['DOS'] >= start_date) & 
                                   (thDemo['DOS'] <= end_date) & 
                                    (thDemo['cityState'] == selected_city) & 
                                    (thDemo['new_est'] == selected_ptType)] 
   
    if not demo_filtered_df.empty:
        age_pt = demo_filtered_df.groupby(['age_group','new_est']).sum()['countPerson'].reset_index()
        age_pt =age_pt.sort_values(by='countPerson', ascending=False)
        
        age_est = age_pt[age_pt['new_est']=='Est']      
        age_new = age_pt[age_pt['new_est']=='New']      
                
        traces = [
				    	  
            				  go.Bar(
                                        x=age_est['age_group'],
                                        y= age_est['countPerson'],        
                                        marker_color='#2D2926',  
                                        textposition='auto', 
                                        name='Established',
                                        opacity=0.7
                                        ),
                              
                              go.Bar(
                                        x=age_new['age_group'],
                                        y= age_new['countPerson'],        
                                        marker_color='#E94B3C',  
                                        textposition='auto', 
                                        name='New',
                                        opacity=0.7
                                        ),
                          
                        ]
        start_date = dt.strptime(re.split('T| ', start_date)[0], '%Y-%m-%d')
        start_date_string = start_date.strftime('%m/%d/%y')
        
        end_date = dt.strptime(re.split('T| ', end_date)[0], '%Y-%m-%d')
        end_date_string = end_date.strftime('%m/%d/%y')
        
        demoLayout = go.Layout(title='Patients by Age Group ' + start_date_string + '-' + end_date_string + ' - ' + selected_city)   
           
            
        return  {'data':traces, 
                 'layout': demoLayout}   
    else: 
                 return {
                    "layout": {
                        "xaxis": {
                            "visible": False
                        },
                        "yaxis": {
                            "visible": False
                        },
                        "annotations": [
                            {
                                "text": "No matching data found",
                                "xref": "paper",
                                "yref": "paper",
                                "showarrow": False,
                                "font": {
                                    "size": 28
                                }
                            }
                        ]
                    }
                }


@app.callback(Output('demo-race-bar','figure'),
				  [
                Input('demo-my-date-picker-range', 'start_date'),
                 Input('demo-my-date-picker-range', 'end_date'),
                 Input('demo-city-picker', 'value'),
                 Input('demo-ptType-picker', 'value')
                ])
def update_demo_race(start_date,end_date,selected_city, selected_ptType):
		
    if (selected_city == 'All Cities') & (selected_ptType == 'All Patients') : 
        demo_filtered_df  = thDemo[(thDemo['DOS'] >= start_date) & 
                                   (thDemo['DOS'] <= end_date) ]  
    elif (selected_city == 'All Cities') & (selected_ptType != 'All Patients'): 
        demo_filtered_df  = thDemo[(thDemo['DOS'] >= start_date) & 
                                   (thDemo['DOS'] <= end_date) &
                                   (thDemo['new_est'] == selected_ptType)]  
    elif (selected_city != 'All Cities') & (selected_ptType == 'All Patients'): 
        demo_filtered_df  = thDemo[(thDemo['DOS'] >= start_date) & 
                                   (thDemo['DOS'] <= end_date) &
                                   (thDemo['cityState'] == selected_city) ]
    else: 
         demo_filtered_df  = thDemo[(thDemo['DOS'] >= start_date) & 
                                   (thDemo['DOS'] <= end_date) & 
                                    (thDemo['cityState'] == selected_city) & 
                                    (thDemo['new_est'] == selected_ptType)] 
   
    if not demo_filtered_df.empty:
        race_pt = demo_filtered_df.groupby(['race_ethnicity', 'new_est']).sum()['countPerson'].reset_index()
        race_pt =race_pt.sort_values(by='countPerson', ascending=False)
        
        race_est = race_pt[race_pt['new_est']=='Est']      
        race_new = race_pt[race_pt['new_est']=='New']      
                
        traces = [
				    	  
            				  go.Bar(
                                        x=race_est['race_ethnicity'],
                                        y= race_est['countPerson'],        
                                        marker_color='#2D2926',  
                                        textposition='auto', 
                                        opacity=0.7, 
                                        name='Established'
                                        ),
                             
                            go.Bar(
                                        x=race_new['race_ethnicity'],
                                        y= race_new['countPerson'],        
                                        marker_color='#E94B3C',  
                                        textposition='auto', 
                                        opacity=0.7, 
                                        name='New'
                                        ),
                          
                        ]
        start_date = dt.strptime(re.split('T| ', start_date)[0], '%Y-%m-%d')
        start_date_string = start_date.strftime('%m/%d/%y')
        
        end_date = dt.strptime(re.split('T| ', end_date)[0], '%Y-%m-%d')
        end_date_string = end_date.strftime('%m/%d/%y')
        
        demoLayout = go.Layout(title='Patients by Race and Ethnicity ' + start_date_string + '-' + end_date_string + ' - ' + selected_city + ' - ' + selected_ptType)          
        
        return  {'data':traces, 
                 'layout': demoLayout}    
    else: 
         return {
                    "layout": {
                        "xaxis": {
                            "visible": False
                        },
                        "yaxis": {
                            "visible": False
                        },
                        "annotations": [
                            {
                                "text": "No matching data found",
                                "xref": "paper",
                                "yref": "paper",
                                "showarrow": False,
                                "font": {
                                    "size": 28
                                }
                            }
                        ]
                    }
                }

if __name__ == '__main__':
    app.run_server(debug=True)