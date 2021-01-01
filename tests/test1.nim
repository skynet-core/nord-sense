# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest
import sequtils
import nsensepkg/[config,cli]
import streams
import yaml

suite "nsense misc tests":
   
   test "test yaml":
      var cfg = Config()
      var s = newFileStream("./configs/AcerPredatorPT515-51.yaml",fmRead)
      load(s,cfg)
      s.close()
      cfg.normalize()
      assert cfg.zones[1].fans[0].levelConfig(0x32).unsafeGet.info == "L:2 T:50.0 F:50.0 (0x32 0x80)"
   
   test "option parser":
      let app = parseCli(["-c","some","-p","/run/mypid","-f"].toSeq)
      assert app.config.get == "some"
      assert app.pidfile == "/run/mypid"
      assert app.force == true