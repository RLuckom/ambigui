(function() {
  var almostEqual, matrixEqual, vectorEquals;

  almostEqual = function(actual, expected, epsilon, message) {
    if (message == null) {
      message = "expected: " + expected + "  got: " + actual;
    }
    return QUnit.push((Math.abs(actual - expected) <= epsilon) || (actual === expected), actual, expected, message);
  };

  matrixEqual = function(actual, expected, epsilon) {
    var actualString, e, el, expectedString, i, m, message, _i, _j, _k, _len, _len1, _len2, _results;
    actual = actual.elements;
    expected = expected.elements;
    ok(actual.length === expected.length, "matrices are different sizes");
    expectedString = '';
    for (_i = 0, _len = expected.length; _i < _len; _i++) {
      e = expected[_i];
      expectedString += "" + e + ", ";
    }
    actualString = '';
    for (_j = 0, _len1 = actual.length; _j < _len1; _j++) {
      e = actual[_j];
      actualString += "" + e + ", ";
    }
    message = "expected: " + expectedString + " got: " + actualString;
    m = function(i) {
      return "Element " + i + " not equal:\nExpected has " + expected[i] + "\n Actual has " + actual[i] + "\nExpected: " + expectedString + "\n Actual:" + actualString;
    };
    _results = [];
    for (i = _k = 0, _len2 = actual.length; _k < _len2; i = ++_k) {
      el = actual[i];
      _results.push(QUnit.almostEqual(el, expected[i], epsilon, m(i)));
    }
    return _results;
  };

  vectorEquals = function(actual, expected, epsilon) {
    var actualString, e, el, expectedString, i, m, message, _i, _j, _k, _len, _len1, _len2, _results;
    actual = actual.toArray();
    expected = expected.toArray();
    ok(actual.length === expected.length, "matrices are different sizes");
    expectedString = '';
    for (_i = 0, _len = expected.length; _i < _len; _i++) {
      e = expected[_i];
      expectedString += "" + e + ", ";
    }
    actualString = '';
    for (_j = 0, _len1 = actual.length; _j < _len1; _j++) {
      e = actual[_j];
      actualString += "" + e + ", ";
    }
    message = "expected: " + expectedString + " got: " + actualString;
    m = function(i) {
      return "Element " + i + " not equal:\nExpected has " + expected[i] + "\n Actual has " + actual[i] + "\nExpected: " + expectedString + "\n Actual:" + actualString;
    };
    _results = [];
    for (i = _k = 0, _len2 = actual.length; _k < _len2; i = ++_k) {
      el = actual[i];
      _results.push(QUnit.almostEqual(el, expected[i], epsilon, m(i)));
    }
    return _results;
  };

  QUnit.extend(QUnit, {
    'almostEqual': almostEqual,
    'matrixEqual': matrixEqual,
    'vectorEquals': vectorEquals
  });

  test("testQUnitExtensions testAlmostEqual", function() {
    QUnit.almostEqual(100 / 3, 33.333, .001);
    QUnit.almostEqual(9, 9, 0);
    return QUnit.almostEqual(Infinity, Infinity, 1);
  });

  test("testQUnitExtensions testMatrixEqual", function() {
    var m1, m2;
    m1 = new THREE.Matrix4(Math.PI / 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, Math.sqrt(2, 0, 0, 0, 0));
    m2 = m1.clone();
    QUnit.matrixEqual(m1, m2, 0);
    m2.elements[0] += 0.0001;
    return QUnit.matrixEqual(m1, m2, 0.001);
  });

  test("testThreeDNavController normalizeMouseTravel", function() {
    var actual, controller, end, expected, height, start, width;
    controller = new lasertutor.ThreeDNavController();
    height = 400;
    width = 600;
    start = {
      x: 0,
      y: 0
    };
    end = {
      x: 600,
      y: 400
    };
    expected = {
      x: 1,
      y: -1
    };
    actual = controller.normalizeMouseTravel(width, height, start, end);
    deepEqual(actual, expected);
    start = end;
    end = {
      x: -600,
      y: -400
    };
    expected = {
      x: -2,
      y: 2
    };
    actual = controller.normalizeMouseTravel(width, height, start, end);
    deepEqual(actual, expected);
    start = end;
    end = {
      x: -300,
      y: -600
    };
    expected = {
      x: 0.5,
      y: 0.5
    };
    actual = controller.normalizeMouseTravel(width, height, start, end);
    return deepEqual(actual, expected);
  });

  test("testThreeDNavController calculateRotationVector", function() {
    var actual, controller, expected, normalizedTravel, zoom, zoomFactor;
    controller = new lasertutor.ThreeDNavController();
    zoom = 4;
    normalizedTravel = {
      x: 1,
      y: 0
    };
    expected = {
      yaw: Math.PI / 2,
      pitch: 0
    };
    actual = controller.calculateRotationVector(normalizedTravel, zoom);
    deepEqual(actual, expected);
    zoom = 2;
    zoomFactor = 2;
    normalizedTravel = {
      x: 1,
      y: 0
    };
    expected = {
      yaw: Math.PI / 2,
      pitch: 0
    };
    actual = controller.calculateRotationVector(normalizedTravel, zoom, null, zoomFactor);
    return deepEqual(actual, expected);
  });

  test("testtThreeDNavController clampAngle0_2PI", function() {
    var actual, controller, epsilon, expected;
    controller = new lasertutor.ThreeDNavController();
    epsilon = 0.00001;
    expected = Math.PI / 2;
    actual = controller.clampAngle0_2PI(Math.PI * 2.5);
    return ok(Math.abs(expected - actual) < epsilon);
  });

  test("testThreeDNavController testCameraRotation", function() {
    var actual, check, controller, epsilon, expected, frameWidthsOfMouseTravel, radiansPerFrameWidth;
    controller = new lasertutor.ThreeDNavController();
    epsilon = 0.00001;
    check = function(m1, m2) {};
    radiansPerFrameWidth = Math.PI / 2;
    frameWidthsOfMouseTravel = 1;
    expected = new THREE.Matrix4(0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
    actual = controller.mouseXYToCameraRotation(frameWidthsOfMouseTravel, 0, Math.PI, radiansPerFrameWidth);
    return QUnit.matrixEqual(actual, expected, epsilon);
  });

  test("testThreeDNavController testCameraRotation", function() {
    var controller, epsilon, expected, yaw;
    epsilon = 0.00001;
    controller = new lasertutor.ThreeDNavController();
    yaw = Math.PI / 2;
    expected = new THREE.Vector3(0, -1, 0);
    return QUnit.vectorEquals(controller.pitchRotationAxis(yaw), expected, epsilon);
  });

  test('test mouseDownCallback', function() {
    var div, evt, navElement;
    div = document.createElement('div');
    div.setAttribute('style', 'position: fixed; left: 0px; top: 0px;');
    document.body.appendChild(div);
    navElement = new lasertutor.NavigationUI(div);
    evt = document.createEvent("MouseEvent");
    evt.initMouseEvent("mousedown", true, true, window, 1, 0, 0, 0, 0, false, false, false, false, 0, null);
    div.dispatchEvent(evt);
    ok(navElement.interacting, "mousedown doesn't set interacting");
    return deepEqual({
      x: 0,
      y: 0
    }, navElement.startPoint);
  });


  /*
  COULD NOT GET THIS TO WORK
  see http://stackoverflow.com/questions/23597493/how-can-i-trigger-a-touchevent-in-a-grunt-run-qunit-test-with-plain-javascript
  test "test TouchStartCallback", ->
    div = document.createElement 'div'
    div.setAttribute 'style', 'position: fixed; left: 0px; top: 0px;'
    div.addEventListener 'touchstart', -> console.log '1ts'
    document.body.appendChild div
    navElement = new lasertutor.NavigationUI div
    evt = document.createEvent "TouchEvent"
    touch1 = document.createTouch window, div, 11211, 0, 0, 0, 0
    touchList = document.createTouchList touch1
    evt.initTouchEvent("touchstart", true, true, window,
      null, 0, 0, 0, 0, false, false, false, false,
      touchList, touchList, touchList, 1, 0)
    console.log div.dispatchEvent evt
    ok navElement.interacting, "touchstart doesn't set interacting"
    deepEqual {x: 0, y: 0}, navElement.startPoint
   */

}).call(this);
