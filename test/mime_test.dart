import 'package:unittest/unittest.dart';

var mime1 = "blah/wibble";
var mime2 = "a/a";
var mime3 = "abc/def;xyz=efg";
var mime4 = 'abc/def;x=";";y=1';
var mime41 = 'abc/def;x=";\\"";y=1';
var mime42 = 'abc/def;x=",";y=1';
var mime5 = "abc/def ; xyz=0.2";
var mime6 = "abc/def ; a=1 ; b=2";
var mime7 = "abc/def;a=1;b=2";
var mime8 = "a/b,c/d , e/f, g/h";
var mime9 = "*";
var mime10 = "a/b;q=0.5";
var mime11 = "a/b;q=0";
var mime12 = "a/b;q=1";
var mime13 = "a/b;q=-1";
var mime14 = "a/b;q=2";
var mime15 = "a/b;q=z";

//TODO should send 406 Not Acceptable if, er, not acceptable

// q=0.000 .. 0.999 .. 1.000

class AcceptRange {
  AcceptRange(this.type, this.subtype);
  String type;
  String subtype;
  Map<String, dynamic> params = new Map<String, dynamic>();
}

List<AcceptRange> parse(String accept) {
  var ranges = new List<AcceptRange>();
  var splits = accept.split(",");
  splits.forEach((split) {
    var params = split.split(";");
    var type = params[0];
    if (type == "*") {
      type = "*/*";
    };
    var parts = type.split("/");
    var range = new AcceptRange(parts[0].trim(), parts[1].trim());
    ranges.add(range);
    params.removeRange(0, 1);
    params.forEach((param) {
      var paramParts = param.split("=");
      var paramName = paramParts[0].trim();
      var paramValue = paramParts[1].trim();
      range.params[paramName] = paramValue;
    });
  });
  return ranges;
}

updateQValues(List<AcceptRange> ranges) {
  ranges.forEach((range) {
    if (range.params.containsKey("q")) {
      var q = range.params["q"];
      q = double.parse(q, (error) => 1.0);
      if (q < 0 || q > 1) {
        q = 1.0;
      }
      range.params["q"] = q;
    } else {
      range.params["q"] = 1.0;      
    }
  });
}

main() {
  group("mime", () {
    test("split really simple one", () {
      var mimes = parse(mime1);
      expect(mimes, isList);
      expect(mimes, hasLength(1));
      expect(mimes[0].type, equals("blah"));
      expect(mimes[0].subtype, equals("wibble"));
    });
    
    test("split another simple one", () {
      var mimes = parse(mime2);
      expect(mimes, isList);
      expect(mimes, hasLength(1));
      expect(mimes[0].type, equals("a"));
      expect(mimes[0].subtype, equals("a"));
    });
    
    test("split with params", () {
      var mimes = parse(mime3);
      expect(mimes, isList);
      expect(mimes, hasLength(1));
      expect(mimes[0].type, equals("abc"));
      expect(mimes[0].subtype, equals("def"));
      expect(mimes[0].params, hasLength(1));
      expect(mimes[0].params["xyz"], equals("efg"));
    });
    
    test("split with quotes", () {
      var mimes = parse(mime4);
      expect(mimes, isList);
      expect(mimes, hasLength(1));
      expect(mimes[0].type, equals("abc"));
      expect(mimes[0].subtype, equals("def"));
      expect(mimes[0].params, hasLength(1));
      expect(mimes[0].params["x"], equals(";"));
      expect(mimes[0].params["y"], equals("1"));
    });

    test("split params and spaces", () {
      var mimes = parse(mime5);
      expect(mimes, isList);
      expect(mimes, hasLength(1));
      expect(mimes[0].type, equals("abc"));
      expect(mimes[0].subtype, equals("def"));
      expect(mimes[0].params, hasLength(1));
      expect(mimes[0].params["xyz"], equals("0.2"));
    });

    test("split two params and spaces", () {
      var mimes = parse(mime6);
      expect(mimes, isList);
      expect(mimes, hasLength(1));
      expect(mimes[0].type, equals("abc"));
      expect(mimes[0].subtype, equals("def"));
      expect(mimes[0].params, hasLength(2));
      expect(mimes[0].params["a"], equals("1"));
      expect(mimes[0].params["b"], equals("2"));
    });

    test("split two params", () {
      var mimes = parse(mime7);
      expect(mimes, isList);
      expect(mimes, hasLength(1));
      expect(mimes[0].type, equals("abc"));
      expect(mimes[0].subtype, equals("def"));
      expect(mimes[0].params, hasLength(2));
      expect(mimes[0].params["a"], equals("1"));
      expect(mimes[0].params["b"], equals("2"));
    });

    test("split multi", () {
      var mimes = parse(mime8);
      expect(mimes, isList);
      expect(mimes, hasLength(4));
      expect(mimes[0].type, equals("a"));
      expect(mimes[0].subtype, equals("b"));
      expect(mimes[1].type, equals("c"));
      expect(mimes[1].subtype, equals("d"));
      expect(mimes[2].type, equals("e"));
      expect(mimes[2].subtype, equals("f"));
      expect(mimes[3].type, equals("g"));
      expect(mimes[3].subtype, equals("h"));
    });

    test("split malformed", () {
      var mimes = parse(mime9);
      expect(mimes, isList);
      expect(mimes, hasLength(1));
      expect(mimes[0].type, equals("*"));
      expect(mimes[0].subtype, equals("*"));
    });

    test("mid q", () {
      var mimes = parse(mime10);
      updateQValues(mimes);
      expect(mimes, isList);
      expect(mimes, hasLength(1));
      expect(mimes[0].type, equals("a"));
      expect(mimes[0].subtype, equals("b"));
      expect(mimes[0].params, hasLength(1));
      expect(mimes[0].params["q"], equals(0.5));
    });

    test("zero q", () {
      var mimes = parse(mime11);
      updateQValues(mimes);
      expect(mimes, isList);
      expect(mimes, hasLength(1));
      expect(mimes[0].type, equals("a"));
      expect(mimes[0].subtype, equals("b"));
      expect(mimes[0].params, hasLength(1));
      expect(mimes[0].params["q"], equals(0.0));
    });

    test("one q", () {
      var mimes = parse(mime12);
      updateQValues(mimes);
      expect(mimes, isList);
      expect(mimes, hasLength(1));
      expect(mimes[0].type, equals("a"));
      expect(mimes[0].subtype, equals("b"));
      expect(mimes[0].params, hasLength(1));
      expect(mimes[0].params["q"], equals(1.0));
    });

    test("too big q", () {
      var mimes = parse(mime13);
      updateQValues(mimes);
      expect(mimes, isList);
      expect(mimes, hasLength(1));
      expect(mimes[0].type, equals("a"));
      expect(mimes[0].subtype, equals("b"));
      expect(mimes[0].params, hasLength(1));
      expect(mimes[0].params["q"], equals(1.0));
    });

    test("too loq q", () {
      var mimes = parse(mime14);
      updateQValues(mimes);
      expect(mimes, isList);
      expect(mimes, hasLength(1));
      expect(mimes[0].type, equals("a"));
      expect(mimes[0].subtype, equals("b"));
      expect(mimes[0].params, hasLength(1));
      expect(mimes[0].params["q"], equals(1.0));
    });

    test("invalid q", () {
      var mimes = parse(mime15);
      updateQValues(mimes);
      expect(mimes, isList);
      expect(mimes, hasLength(1));
      expect(mimes[0].type, equals("a"));
      expect(mimes[0].subtype, equals("b"));
      expect(mimes[0].params, hasLength(1));
      expect(mimes[0].params["q"], equals(1.0));
    });
  });
}
//var mime10 = "a/b;q=0.5";
//var mime11 = "a/b;q=0";
//var mime12 = "a/b;q=1";
//var mime13 = "a/b;q=-1";
//var mime14 = "a/b;q=2";
//var mime15 = "a/b;q=z";
