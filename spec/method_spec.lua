helpers = require('helpers')

local function loadfiles()
  helpers.addon_loadfile("AddonToolkit", 'lib/fenv.lua')
  helpers.addon_loadfile("AddonToolkit", 'lib/method.lua')
end

local identity_self = function(self, args, ...)
  return self, args, ...
end
local identity = function(args, ...)
  return args, ...
end
insulate("An AddOn using Method that describes a method that only takes varargs", function()
  loadfiles()
  local _, MyAddon = AddonToolkit.AddOn("MyAddon", {})
  local method = import("method", "AddonToolkit.Method")

  MyAddon.do_stuff = method{
    name = "do_stuff",
    impl = identity
  }

  unisolated(function()
    it("strips undefined keyword arguments, while passing through varargs", function()
      assert.are.same(
        {
          {},
          'a', 'b', 'c'
        },
        {
          MyAddon.do_stuff({'a', something=true, 'b', 'c'})
        }
      )
    end)
  end)
end)

insulate("An AddOn using Method that describes a method that has required arguments", function()
  loadfiles()
  local _, MyAddon = AddonToolkit.AddOn("MyAddon", {})
  local method = import("method", "AddonToolkit.Method")

  MyAddon.do_stuff = method{
    name = "do_stuff",
    required_arguments = {'a', 'b'},
    impl = identity
  }

  unisolated(function()
    it("passes through the required args, while passing through varargs", function()
      assert.are.same(
        {
          {
            a = "abc",
            b = "def"
          },
          'a', 'b', 'c'
        },
        {
          MyAddon.do_stuff({a="abc", 'a', something=true, 'b', b="def", 'c'})
        }
      )
    end)

    it("errors when passed args missing a required argument", function()
      assert.has.errors(function()
        MyAddon.do_stuff({})
      end)
    end)
  end)
end)

insulate("An AddOn using Method that describes a method that has default arguments", function()
  loadfiles()
  local _, MyAddon = AddonToolkit.AddOn("MyAddon", {})
  local method = import("method", "AddonToolkit.Method")

  MyAddon.do_stuff = method{
    name = "do_stuff",
    default_arguments = {
      a = 'abc',
      b = 'def'
    },
    impl = identity
  }

  unisolated(function()
    it("sets defaults accordingly, while passing through varargs", function()
      assert.are.same(
        {
          {
            a = "abc",
            b = "ghi"
          },
          'a', 'b', 'c'
        },
        {
          MyAddon.do_stuff({'a', something=true, 'b', b = 'ghi', 'c'})
        }
      )
    end)
  end)
end)
