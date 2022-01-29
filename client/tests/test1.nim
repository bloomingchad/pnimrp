import unittest, client

test "can create":
  check create() is ptr handle 

test "can errorString":
  check errorString(-20) is cstring
