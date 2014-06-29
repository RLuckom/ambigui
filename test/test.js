(function() {
  test('test testGetnumsFromString', function() {
    var fmt, fmt_string, m, nums, r;
    fmt_string = "transform scale(30, 0 0 67);";
    nums = [30, 0, 0, 67];
    fmt = ["transform scale(", null, ", ", null, " ", null, " ", null, ");"];
    m = {
      0: 1,
      1: 3,
      2: 5,
      3: 7
    };
    r = new ambigui.Animator().valAndFormatArrays(fmt_string);
    deepEqual(nums, r[0]);
    deepEqual(fmt, r[1]);
    deepEqual(m, r[2]);
    fmt_string = "30.3, 0 0 67";
    nums = [30.3, 0, 0, 67];
    m = {
      0: 0,
      1: 2,
      2: 4,
      3: 6
    };
    fmt = [null, ", ", null, " ", null, " ", null];
    r = new ambigui.Animator().valAndFormatArrays(fmt_string);
    deepEqual(nums, r[0]);
    deepEqual(fmt, r[1]);
    deepEqual(m, r[2]);
    fmt_string = "30";
    nums = [30];
    m = {
      0: 0
    };
    fmt = [null];
    r = new ambigui.Animator().valAndFormatArrays(fmt_string);
    deepEqual(nums, r[0]);
    deepEqual(fmt, r[1]);
    deepEqual(m, r[2]);
    fmt_string = "300px";
    nums = [300];
    m = {
      0: 0
    };
    fmt = [null, "px"];
    r = new ambigui.Animator().valAndFormatArrays(fmt_string);
    deepEqual(nums, r[0]);
    deepEqual(fmt, r[1]);
    return deepEqual(m, r[2]);
  });

}).call(this);
