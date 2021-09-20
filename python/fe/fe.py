import requests
import json

import streamlit as st

import pandas as pd

#draw the form when the page loads
with st.form(key='my_form'):
    date_start = st.text_input(label='start date')
    date_end = st.text_input(label='end date')
    submit_button = st.form_submit_button(label='Submit')
    clear_button = st.form_submit_button(label='Clear')
#check if the submit button is pressed
if submit_button:

 #send a request to the backend with the entered parameters from the form
 data = requests.get("http://api.default.svc.cluster.local:5000/?start_date="+date_start+"&end_date="+date_end)
 #converting the response to json
 jsonObj = data.json()


 #draw a table with data
 df = pd.DataFrame(jsonObj)

 st.table(df)
 
if submit_button:
  requests.get("http://api.default.svc.cluster.local:5000/clear")


