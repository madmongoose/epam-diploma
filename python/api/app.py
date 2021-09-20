import flask
import xml.etree.ElementTree as ET
import pymysql
import json

import requests
from flask import request

app = flask.Flask(__name__)
app.config["DEBUG"] = True


@app.route('/', methods=['GET'])
def home():
    conn = pymysql.connect(user='cbr',
							password='$epm-rds-pass',
							host='$epm-rds-host',
							database='cbr')
    if (conn) :
      print ("Connected Successfully")
    else :
      print ("Connected Failed")
    start_date = request.args.get("start_date")
    end_date = request.args.get("end_date")
    start = start_date.replace('.', '/')
    end = end_date.replace('.', '/')
    cursor = conn.cursor()
    print ("conn  cursos")
    cursor.execute("CREATE TABLE IF NOT EXISTS mkr (Date VARCHAR(255) PRIMARY KEY, "
        "C1 VARCHAR(255), C7 VARCHAR(255), C30 VARCHAR(255), "
        "C90 VARCHAR(255), C180 VARCHAR(255), C360 VARCHAR(255))")
    print ("table created")
    tree = ET.fromstring(requests.get("https://www.cbr.ru/scripts/xml_mkr.asp?date_req1="+start+"&date_req2="+end).text)
    data2 = tree.findall('Record')
    objectsList = list()
    for i, j in zip(data2, range(1, 10000)):
      Date = data2[j-1].get('Date')
      C1 = i.find('C1').text
      C7 = i.find('C7').text
      C30 = i.find('C30').text
      C90 = i.find('C90').text
      C180 = i.find('C180').text
      C360 = i.find('C360').text
      object = [Date, C1, C7, C30, C90, C180, C360]
      objectsList.append(object)
      
    data = """INSERT IGNORE INTO mkr(Date,C1,C7,C30,C90,C180,C360) VALUES(%s,%s,%s,%s,%s,%s,%s)"""
    cursor = conn.cursor()
    cursor.executemany(data, objectsList)
    print ("cursor execute")
    conn.commit()
    print ("conn commit")
	  
    def run_query(query):
       with conn.cursor() as cur:
             cur.execute(query)
             return cur.fetchall()
    rows = run_query("SELECT * from mkr;")
    jsonObj = json.dumps(rows)
	  
    return (jsonObj)

@app.route('/clear', methods=['GET'])
def clear():
    conn = pymysql.connect(user='cbr',
                            password='epm-rds-pass',
                            host='epm-rds-host',
                            database='cbr')
    cursor = conn.cursor()
    cursor.execute("DROP TABLE mkr")
    conn.commit()
    conn.close()
    return ''

app.run()
