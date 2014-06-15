(function() {
  var SVGNodeView, drawSVG, exports, module, registerGlobal,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  exports = exports != null ? exports : this;

  registerGlobal = function(uniqueName, objectToRegister) {
    if (objectToRegister == null) {
      objectToRegister = module;
    }
    exports[uniqueName] = objectToRegister;
    return window[uniqueName] = objectToRegister;
  };

  module = {};

  registerGlobal('DOGWOOD', module);

  drawSVG = function() {
    var svg, x;
    svg = document.createElementNS("http://www.w3.org/2000/svg", 'svg');
    svg.setAttribute('style', "width: 600px; height:500px;");
    document.getElementById("svgDiv").appendChild(svg);
    return x = new SVGNodeView({
      el: svg
    });
  };

  SVGNodeView = (function(_super) {
    __extends(SVGNodeView, _super);

    SVGNodeView.prototype.svgElement = function(tag, attributes) {
      var attr, el, value;
      if (attributes == null) {
        attributes = {};
      }
      el = document.createElementNS("http://www.w3.org/2000/svg", tag);
      if (attributes.version == null) {
        attributes.version = "1.1";
      }
      if (attributes.xmlns == null) {
        attributes.xmlns = "http://www.w3.org/2000/svg";
      }
      for (attr in attributes) {
        value = attributes[attr];
        el.setAttribute(attr, value);
      }
      return el;
    };

    SVGNodeView.prototype.animateElement = function(spec, parentElement, callback, animType) {
      var animation;
      if (callback == null) {
        callback = null;
      }
      if (animType == null) {
        animType = "animate";
      }
      if (spec.dur == null) {
        spec.dur = this.animateDuration;
      }
      if (spec.repeatCount == null) {
        spec.repeatCount = 1;
      }
      if (spec.fill == null) {
        spec.fill = "freeze";
      }
      if (spec.begin == null) {
        spec.begin = "indefinite";
      }
      animation = this.svgElement(animType, spec);
      if (callback != null) {
        animation.addEventListener("endEvent", callback);
      }
      parentElement.appendChild(animation);
      return animation.beginElement();
    };

    function SVGNodeView(options) {
      this.textClick = __bind(this.textClick, this);
      this.circleClick = __bind(this.circleClick, this);
      this.animateVisible = __bind(this.animateVisible, this);
      this.visibleChildren = __bind(this.visibleChildren, this);
      this.hide = __bind(this.hide, this);
      this.hideChildren = __bind(this.hideChildren, this);
      this.showChildren = __bind(this.showChildren, this);
      this.animateCircle = __bind(this.animateCircle, this);
      this.makeCircle = __bind(this.makeCircle, this);
      this.animateText = __bind(this.animateText, this);
      this.makeText = __bind(this.makeText, this);
      this.animateLine = __bind(this.animateLine, this);
      this.makeLine = __bind(this.makeLine, this);
      this.numDescendants = __bind(this.numDescendants, this);
      this.getLinePoints = __bind(this.getLinePoints, this);
      this.moveChildren = __bind(this.moveChildren, this);
      this.updateChild = __bind(this.updateChild, this);
      this.updateChildren = __bind(this.updateChildren, this);
      this.updatePosition = __bind(this.updatePosition, this);
      this.requestUpdate = __bind(this.requestUpdate, this);
      this.newChild = __bind(this.newChild, this);
      this.animateElement = __bind(this.animateElement, this);
      var model, _ref, _ref1, _ref10, _ref11, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9;
      SVGNodeView.__super__.constructor.call(this, options);
      this.children = [];
      this.scale = '1 1';
      model = (_ref = options.parent) != null ? _ref : options;
      this.name = (_ref1 = options.text) != null ? _ref1 : "Root";
      this.indent = (_ref2 = model.indent) != null ? _ref2 : 40;
      this.textDX = (_ref3 = model.textDX) != null ? _ref3 : 5;
      this.textDY = (_ref4 = model.textDY) != null ? _ref4 : -10;
      this.circleRadius = (_ref5 = model.circleRadius) != null ? _ref5 : 4;
      this.circleDY = (_ref6 = model.circleDY) != null ? _ref6 : 0;
      this.nodeHeight = (_ref7 = model.nodeHeight) != null ? _ref7 : 35;
      this.flagpoleLength = this.circleDY + this.circleRadius;
      this.animateDuration = (_ref8 = model.animateDuration) != null ? _ref8 : "0.4s";
      this.isHidden = (_ref9 = model.isHidden) != null ? _ref9 : false;
      if (options.parent != null) {
        this.parent = options.parent;
      } else {
        this.isRoot = true;
      }
      this.x = (_ref10 = options.x) != null ? _ref10 : 5;
      this.y = (_ref11 = options.y) != null ? _ref11 : 40;
      this.line = this.makeLine();
      this.circle = this.makeCircle();
      this.circle.addEventListener("click", this.circleClick);
      this.text = this.makeText();
      this.text.addEventListener("click", this.textClick);
      this.el.appendChild(this.line);
      this.el.appendChild(this.circle);
      this.el.appendChild(this.text);
    }

    SVGNodeView.prototype.newChild = function(name) {
      var child, child_el, child_spec, spacer_el, transform_spec, _i, _len, _ref;
      if (name == null) {
        name = "child";
      }
      _ref = this.children;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        child.isHidden = false;
      }
      transform_spec = {
        transform: "translate(" + this.indent + ", 0)"
      };
      spacer_el = this.svgElement("g", transform_spec);
      child_el = this.svgElement("g");
      spacer_el.appendChild(child_el);
      this.el.appendChild(spacer_el);
      child_spec = {
        el: child_el,
        parent: this,
        text: name,
        x: this.x + this.indent,
        y: this.y + this.numDescendants() * this.nodeHeight
      };
      child = new SVGNodeView(child_spec);
      this.children.push(child);
      this.listenTo(child, "request_update", this.requestUpdate);
      this.trigger('request_update');
      if (this.isRoot) {
        return this.updatePosition();
      }
    };

    SVGNodeView.prototype.requestUpdate = function() {
      if (!this.isRoot) {
        return this.trigger("request_update");
      } else {
        return this.updatePosition();
      }
    };

    SVGNodeView.prototype.updatePosition = function(callback) {
      if (callback == null) {
        callback = null;
      }
      this.updateChildren();
      this.moveChildren();
      this.animateLine();
      this.animateText();
      this.animateCircle();
      return this.animateVisible();
    };

    SVGNodeView.prototype.updateChildren = function() {
      var child, descendants, _i, _len, _ref, _results;
      descendants = 0;
      _ref = this.children;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        descendants += 1;
        this.updateChild(child, descendants);
        _results.push(descendants += child.numDescendants());
      }
      return _results;
    };

    SVGNodeView.prototype.updateChild = function(child, index) {
      child.x = this.x + this.indent;
      return child.y = !child.isHidden ? this.y + this.nodeHeight * index : this.y;
    };

    SVGNodeView.prototype.moveChildren = function(callback) {
      var child, _i, _len, _ref, _results;
      if (callback == null) {
        callback = null;
      }
      if (this.children.length === 0 && (callback != null)) {
        callback();
      }
      _ref = this.children;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        _results.push(child.updatePosition(callback));
      }
      return _results;
    };

    SVGNodeView.prototype.getLinePoints = function() {
      var last, n;
      last = this.children[this.children.length - 1];
      n = last ? last.numDescendants() : 0;
      this.flagpoleLength = (this.numDescendants() - n) * this.nodeHeight;
      return "" + 0 + " " + this.y + " " + this.indent + " " + this.y + " " + this.indent + " " + (this.y + this.flagpoleLength);
    };

    SVGNodeView.prototype.numDescendants = function() {
      var c, n, _i, _len, _ref;
      n = 0;
      _ref = this.children;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        c = _ref[_i];
        if (!c.isHidden) {
          n += c.numDescendants() + 1;
        }
      }
      return n;
    };

    SVGNodeView.prototype.makeLine = function() {
      this.linePoints = this.getLinePoints();
      return this.svgElement("polyline", {
        fill: "none",
        points: this.linePoints,
        'stroke-width': "2px",
        stroke: "blue"
      });
    };

    SVGNodeView.prototype.animateLine = function(callback) {
      var newPoints;
      if (callback == null) {
        callback = null;
      }
      newPoints = this.getLinePoints();
      this.animateElement({
        attributeName: 'points',
        from: this.linePoints,
        to: newPoints
      }, this.line, callback);
      return this.linePoints = newPoints;
    };

    SVGNodeView.prototype.makeText = function() {
      var t;
      this.textX = this.textDX;
      this.textY = this.y + this.textDY;
      t = this.svgElement("text", {
        fill: "black",
        x: this.textDX,
        y: this.y + this.textDY
      });
      t.appendChild(document.createTextNode(this.name));
      return t;
    };

    SVGNodeView.prototype.animateText = function(callback) {
      var newY;
      if (callback == null) {
        callback = null;
      }
      newY = this.y + this.textDY;
      this.animateElement({
        attributeName: 'y',
        to: newY,
        from: this.textY
      }, this.text, callback);
      return this.textY = newY;
    };

    SVGNodeView.prototype.makeCircle = function() {
      this.circleX = this.indent;
      this.circleY = this.y + this.circleDY;
      return this.svgElement("circle", {
        fill: "blue",
        cx: this.indent,
        cy: this.y + this.circleDY,
        r: this.circleRadius,
        "stroke-width": "2px",
        stroke: "blue"
      });
    };

    SVGNodeView.prototype.animateCircle = function(callback) {
      var new_cy;
      if (callback == null) {
        callback = null;
      }
      new_cy = this.y + this.circleDY;
      this.animateElement({
        attributeName: 'cy',
        to: new_cy,
        from: this.circleY
      }, this.circle, callback);
      return this.circleY = new_cy;
    };

    SVGNodeView.prototype.showChildren = function() {
      var child, _i, _len, _ref;
      _ref = this.children;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        child.isHidden = false;
      }
      this.updateChildren();
      this.trigger("request_update");
      if (this.isRoot) {
        return this.updatePosition();
      }
    };

    SVGNodeView.prototype.hideChildren = function() {
      var child, f, test, trigger, _i, _len, _ref, _results;
      test = (function(_this) {
        return function() {
          return _this.visibleChildren().length === 0;
        };
      })(this);
      trigger = (function(_this) {
        return function() {
          return _this.trigger("request_update");
        };
      })(this);
      f = this.groupActionCallback(trigger, test);
      if (this.isRoot) {
        f = this.groupActionCallback(this.updatePosition, test);
      }
      _ref = this.visibleChildren();
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        _results.push(child.hide(f));
      }
      return _results;
    };

    SVGNodeView.prototype.hide = function(callback) {
      var cb, child, hideCallback, test, _i, _len, _ref, _results;
      if (this.visibleChildren().length === 0) {
        this.isHidden = true;
        callback(this);
      }
      hideCallback = (function(_this) {
        return function() {
          _this.isHidden = true;
          return callback(_this);
        };
      })(this);
      test = (function(_this) {
        return function() {
          return _this.visibleChildren().length === 0;
        };
      })(this);
      cb = this.groupActionCallback(hideCallback, test);
      _ref = this.visibleChildren();
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        _results.push(child.hide(cb));
      }
      return _results;
    };

    SVGNodeView.prototype.groupActionCallback = function(callback, test) {
      return function(opts) {
        if (test(opts) && (callback != null)) {
          return callback();
        }
      };
    };

    SVGNodeView.prototype.visibleChildren = function() {
      return this.children.filter(function(x) {
        return !x.isHidden;
      });
    };

    SVGNodeView.prototype.animateVisible = function(callback) {
      var newScale, spec;
      if (callback == null) {
        callback = null;
      }
      newScale = this.isHidden ? "0 1" : "1 1";
      spec = {
        attributeName: 'transform',
        type: 'scale',
        from: this.scale,
        to: newScale
      };
      this.scale = newScale;
      return this.animateElement(spec, this.el, callback, 'animateTransform');
    };

    SVGNodeView.prototype.circleClick = function(evt) {
      return this.newChild();
    };

    SVGNodeView.prototype.textClick = function(evt) {
      if (this.visibleChildren().length !== this.children.length) {
        return this.showChildren();
      } else {
        return this.hideChildren();
      }
    };

    return SVGNodeView;

  })(Backbone.View);

  module.SVGNodeView = SVGNodeView;

  module.drawSVG = drawSVG;

}).call(this);
