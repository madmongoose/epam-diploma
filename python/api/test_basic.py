import os
import unittest

from app import app


def test_main_page(self):
    response = self.app.get('/', follow_redirects=False)
    self.assertEqual(response.status_code, 200)


if __name__ == "__main__":
    unittest.main()
