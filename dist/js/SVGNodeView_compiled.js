(function() {
  var SVGNodeView, drawSVG, exports, module, registerGlobal,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

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

    function SVGNodeView(options) {
      this.textClick = __bind(this.textClick, this);
      this.circleClick = __bind(this.circleClick, this);
      this.spinIn = __bind(this.spinIn, this);
      this.spinOut = __bind(this.spinOut, this);
      this.retractFlagpole = __bind(this.retractFlagpole, this);
      this.getRetractedLinePoints = __bind(this.getRetractedLinePoints, this);
      this.hideCallback = __bind(this.hideCallback, this);
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
      this.updatePosition = __bind(this.updatePosition, this);
      this.updateChildren = __bind(this.updateChildren, this);
      this.initialize = __bind(this.initialize, this);
      this.moveChildren = __bind(this.moveChildren, this);
      this.updateChild = __bind(this.updateChild, this);
      this.newChild = __bind(this.newChild, this);
      this.register = __bind(this.register, this);
      this.new_child = __bind(this.new_child, this);
      var _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8;
      this.children = [];
      this.hidden = [];
      this.referenceChildren = [];
      if (options.parent == null) {
        this.x = (_ref = options.x) != null ? _ref : 5;
        this.y = (_ref1 = options.y) != null ? _ref1 : 40;
        this.indent = (_ref2 = options.indent) != null ? _ref2 : 40;
        this.textDX = (_ref3 = options.textDX) != null ? _ref3 : 5;
        this.textDY = (_ref4 = options.textDY) != null ? _ref4 : -10;
        this.circleRadius = (_ref5 = options.circleRadius) != null ? _ref5 : 4;
        this.circleDY = (_ref6 = options.circleDY) != null ? _ref6 : 0;
        this.nodeHeight = (_ref7 = options.nodeHeight) != null ? _ref7 : 35;
        this.flagpoleLength = this.circleDY + this.circleRadius;
        this.isRoot = true;
      } else {
        this.parent = options.parent;
        this.parent.register(this);
      }
      this.name = (_ref8 = options.text) != null ? _ref8 : "Root";
      SVGNodeView.__super__.constructor.call(this, options);
    }

    SVGNodeView.prototype.new_child = function(name) {
      var child_el, spacer_el, transform_spec;
      if (name == null) {
        name = "child";
      }
      transform_spec = {
        transform: "translate(" + this.indent + ", 0)"
      };
      spacer_el = this.svgElement("g", transform_spec);
      child_el = this.svgElement("g");
      spacer_el.appendChild(child_el);
      this.el.appendChild(spacer_el);
      new SVGNodeView({
        el: child_el,
        parent: this,
        text: name
      });
      this.trigger('new_child');
      if (this.isRoot) {
        return this.updatePosition();
      }
    };

    SVGNodeView.prototype.register = function(child) {
      this.children.push(child);
      this.referenceChildren.push(child);
      this.updateChildren();
      return this.listenTo(child, "new_child", this.newChild);
    };

    SVGNodeView.prototype.newChild = function() {
      this.trigger("new_child");
      if (this.isRoot) {
        return this.updatePosition();
      }
    };

    SVGNodeView.prototype.updateChild = function(child, index) {
      child.x = this.x + this.indent;
      child.y = this.y + this.nodeHeight * index;
      child.indent = this.indent;
      child.textDX = this.textDX;
      child.textDY = this.textDY;
      child.circleRadius = this.circleRadius;
      child.circleDY = this.circleDY;
      child.nodeHeight = this.nodeHeight;
      return child.flagpoleLength = this.circleDY + this.circleRadius;
    };

    SVGNodeView.prototype.moveChildren = function() {
      var child, _i, _len, _ref, _results;
      _ref = this.children;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        _results.push(child.updatePosition());
      }
      return _results;
    };

    SVGNodeView.prototype.initialize = function() {
      this.line = this.makeLine();
      this.circle = this.makeCircle();
      this.circle.addEventListener("click", this.circleClick);
      this.text = this.makeText();
      this.text.addEventListener("click", this.textClick);
      this.el.appendChild(this.line);
      this.el.appendChild(this.circle);
      return this.el.appendChild(this.text);
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

    SVGNodeView.prototype.updatePosition = function() {
      this.updateChildren();
      this.moveChildren();
      this.animateLine();
      this.animateText();
      return this.animateCircle();
    };

    SVGNodeView.prototype.getLinePoints = function() {
      var last, n;
      this.priorLinePoints = this.linePoints;
      last = this.children[this.children.length - 1];
      n = last ? last.numDescendants() : 0;
      this.flagpoleLength = (this.numDescendants() - n) * this.nodeHeight;
      this.linePoints = "" + 0 + " " + this.y + " " + this.indent + " " + this.y + " ";
      this.linePoints += "" + this.indent + " " + (this.y + this.flagpoleLength);
      if (this.priorLinePoints == null) {
        this.priorLinePoints = this.linePoints;
      }
      return this.linePoints;
    };

    SVGNodeView.prototype.numDescendants = function() {
      var c, n, _i, _len, _ref;
      n = 0;
      _ref = this.children;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        c = _ref[_i];
        n += c.numDescendants();
      }
      return n + this.children.length;
    };

    SVGNodeView.prototype.makeLine = function() {
      return this.svgElement("polyline", {
        fill: "none",
        points: this.getLinePoints(),
        'stroke-width': "2px",
        stroke: "blue"
      });
    };

    SVGNodeView.prototype.animateLine = function() {
      var animation, animationSpec;
      animationSpec = {
        attributeName: 'points',
        to: this.getLinePoints(),
        from: this.priorLinePoints,
        dur: "0.4s",
        repeatCount: 1,
        begin: "indefinite",
        fill: "freeze"
      };
      animation = this.svgElement("animate", animationSpec);
      this.line.appendChild(animation);
      return animation.beginElement();
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

    SVGNodeView.prototype.animateText = function() {
      var animation, animationSpec;
      animationSpec = {
        attributeName: 'y',
        to: this.y + this.textDY,
        from: this.textY,
        dur: "0.4s",
        repeatCount: 1,
        begin: "indefinite",
        fill: "freeze"
      };
      this.textY = this.y + this.textDY;
      animation = this.svgElement("animate", animationSpec);
      this.text.appendChild(animation);
      return animation.beginElement();
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

    SVGNodeView.prototype.animateCircle = function() {
      var animation, animationSpec;
      animationSpec = {
        attributeName: 'cy',
        to: this.y + this.circleDY,
        from: this.circleY,
        dur: "0.4s",
        repeatCount: 1,
        begin: "indefinite",
        fill: "freeze"
      };
      this.circleY = this.y + this.circleDY;
      animation = this.svgElement("animate", animationSpec);
      this.circle.appendChild(animation);
      return animation.beginElement();
    };

    SVGNodeView.prototype.showChildren = function() {
      var c, child, new_children, tmp, _i, _j, _len, _len1, _ref, _ref1;
      tmp = this.children.concat(this.hidden);
      new_children = [];
      _ref = this.referenceChildren;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        c = _ref[_i];
        if (__indexOf.call(tmp, c) >= 0) {
          new_children.push(c);
        }
      }
      this.children = new_children;
      this.updateChildren();
      this.hidden = [];
      _ref1 = this.children;
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        child = _ref1[_j];
        child.spinIn();
      }
      this.trigger("new_child");
      if (this.isRoot) {
        return this.updatePosition();
      }
    };

    SVGNodeView.prototype.hideChildren = function() {
      var child, f, _i, _len, _ref, _results;
      f = this.hideCallback((function(_this) {
        return function() {
          return _this.trigger("new_child");
        };
      })(this));
      if (this.isRoot) {
        f = this.hideCallback(this.updatePosition);
      }
      _ref = this.children;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        _results.push(child.hide(f));
      }
      return _results;
    };

    SVGNodeView.prototype.hide = function(callback) {
      var cb, child, _i, _len, _ref, _results;
      if (this.children.length === 0) {
        this.spinOut((function(_this) {
          return function() {
            return callback(_this);
          };
        })(this));
      }
      cb = this.hideCallback((function(_this) {
        return function() {
          return _this.retractFlagpole(function() {
            return _this.spinOut(function() {
              return callback(_this);
            });
          });
        };
      })(this));
      _ref = this.children;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        _results.push(child.hide(cb));
      }
      return _results;
    };

    SVGNodeView.prototype.hideCallback = function(callback) {
      return (function(_this) {
        return function(child) {
          var indx;
          _this.hidden.push(child);
          indx = _this.children.indexOf(child);
          _this.children.splice(indx, 1);
          if (_this.children.length === 0) {
            return callback();
          }
        };
      })(this);
    };

    SVGNodeView.prototype.getRetractedLinePoints = function() {
      return "" + 0 + " " + this.y + " " + this.indent + " " + this.y + " " + this.indent + " " + this.y;
    };

    SVGNodeView.prototype.retractFlagpole = function(callback) {
      var animation, animationSpec;
      animationSpec = {
        attributeName: 'points',
        from: this.priorLinePoints,
        to: this.getRetractedLinePoints(),
        dur: "0.4s",
        repeatCount: 1,
        begin: "indefinite",
        fill: "freeze"
      };
      animation = this.svgElement("animate", animationSpec);
      this.line.appendChild(animation);
      if (callback != null) {
        animation.addEventListener("endEvent", callback);
      }
      return animation.beginElement();
    };

    SVGNodeView.prototype.spinOut = function(callback) {
      var animation, animationSpec;
      animationSpec = {
        attributeName: 'transform',
        type: "scale",
        from: "1 1",
        to: "0 1",
        dur: "0.4s",
        repeatCount: 1,
        begin: "indefinite",
        fill: "freeze"
      };
      animation = this.svgElement("animateTransform", animationSpec);
      this.el.appendChild(animation);
      if (callback != null) {
        animation.addEventListener("endEvent", callback);
      }
      return animation.beginElement();
    };

    SVGNodeView.prototype.spinIn = function(callback) {
      var animation, animationSpec;
      this.circleY = this.y + this.circleDY;
      this.circle.setAttribute("cy", this.circleY);
      this.textY = this.y + this.textDY;
      this.text.setAttribute("y", this.textY);
      this.priorLinePoints = this.getLinePoints();
      this.line.setAttribute('points', this.priorLinePoints);
      animationSpec = {
        attributeName: 'transform',
        type: "scale",
        from: "0 1",
        to: "1 1",
        dur: "0.4s",
        repeatCount: 1,
        begin: "indefinite",
        fill: "freeze"
      };
      animation = this.svgElement("animateTransform", animationSpec);
      this.el.appendChild(animation);
      if (callback != null) {
        animation.addEventListener("endEvent", callback);
      }
      return animation.beginElement();
    };

    SVGNodeView.prototype.circleClick = function(evt) {
      return this.new_child();
    };

    SVGNodeView.prototype.textClick = function(evt) {
      if (this.hidden.length !== 0) {
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
