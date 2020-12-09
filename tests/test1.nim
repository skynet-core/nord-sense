# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest
import nsensepkg/config
import streams
import yaml

suite "correct welcome":
   
   test "test yaml":
      var cfg = Config()
      var s = newFileStream("./configs/AcerP515-51.yaml",fmRead)
      load(s,cfg)
      s.close()
      cfg.normalize()
      echo $(cfg.zones[1].fans[0].levelConfig(0x32))
               
         