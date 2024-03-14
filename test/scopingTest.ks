ClearScreen.

print "L0: Start".
if 0 = 0 {
  print "L1: Start".
  if 1 = 1 {
    print "L2: Start".
    for eI in range(1, 5, 1)
    {
        print "=======".
        print "L3: *** FOR_0 ({0})":Format(eI).
        print " ".
        if eI < 3 {
            print "L4: Start".
            print "-------".
            for i in range(9, 2, 1)
            {
                print "L5: ***** FOR_1 ({0})":Format(i).
                if i > 7 {
                    print "L5: Valid".
                }
                else {
                    print "L5: FOR_1 BREAK *****".
                    print " ".
                    print " ".
                    print " ".
                    break.
                }
                print "L5: End".
                print "-------".
            }
            print "L4: End".
        }
        else
        {
            print "L3: FOR_0 BREAK ***".
            print " ".
            break.
        }
        print "L3: End".
        print "=======".
    }
    print "L2: End".
  }
  print "L1: End".
}
print "L0 :End".
