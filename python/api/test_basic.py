import os
import unittest
import requests

from app import app

def test_main_page(self):
    response = requests.get("http://localhost:5000/?start_date=01.07.2012&end_date=01.07.2013")
    self.assertEqual(response.status_code, 200)

if __name__ == "__main__":
    unittest.main()
