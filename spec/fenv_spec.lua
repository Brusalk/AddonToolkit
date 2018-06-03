helpers = require('helpers')


insulate("Two Addons loaded with AddonToolkit", function()
  helpers.addon_loadfile("AddonToolkit", 'lib/fenv.lua')

  insulate("FirstAddon", function()
    local _, FirstAddon = AddonToolkit.AddOn("FirstAddon", {})
  end)

  insulate("SecondAddon", function()
    it("fails when trying to overload the FirstAddon", function()
      assert.has.errors(function()
        local _, SecondAddon = AddonToolkit.AddOn("FirstAddon", {})
      end)
    end)
  end)
end)


insulate("An AddOn loaded in two files, loaded with AddonToolkit", function()
  helpers.addon_loadfile("AddonToolkit", 'lib/fenv.lua')
  local FirstAddon = {}

  insulate("File One", function()
    local _, FirstAddon = AddonToolkit.AddOn("FirstAddon", FirstAddon)
    FirstAddon.myvar = 531
  end)

  insulate("File Two", function()
    it("succesfully loads the addon again", function()
      local _, FirstAddon = AddonToolkit.AddOn("FirstAddon", FirstAddon)
      unisolated(function()
        assert.equal(FirstAddon.myvar, 531)
      end)
    end)
  end)
end)

insulate("An AddOn can define modules for discrete components", function()
  helpers.addon_loadfile("AddonToolkit", 'lib/fenv.lua')
  local AddonWithModules = {}

  insulate("File One", function()
    local _, AddonWithModules = AddonToolkit.AddOn("AddonWithModules", AddonWithModules)
    export("config", {a = "custom value"})
  end)

  insulate("File Two - Module", function()
    it("can define an exported values", function()
      local _, AddonWithModules = AddonToolkit.AddOn("AddonWithModules", AddonWithModules)
      local _, Logging = Module("Logging")

      function Logging.debug(var)
        return var
      end
    end)
  end)

  insulate("File Three - User of Module", function()
    it("can use a value imported from the module", function()
      local _, AddonWithModules = AddonToolkit.AddOn("AddonWithModules", AddonWithModules)
      local debug = import("debug", "AddonWithModules.Logging")

      unisolated(function()
        assert.equal(4, debug(4))
      end)
    end)
  end)

  insulate("File Four - Improper creation of a module", function()
    it("can't define a module without first loading/defining an addon", function()
      assert.has.errors(function()
        local _, AssertLib = AddonToolkit.Module("AssertLib")
      end)
    end)
  end)


end)


insulate("", function()
  helpers.addon_loadfile("AddonToolkit", 'lib/fenv.lua')

  describe("An AddOn loaded with AddonToolkit with an Isolated Namespace", function ()
    local name, MyAddon = "MyAddon", {}
    local name2, MyAddon2 = AddonToolkit.AddOn(name, MyAddon)
    local tostring = import("tostring")
    unisolated(function()
      it("AddOn returns the original functions", function ()
        assert.equals(name, name2)
        assert.equals(MyAddon, MyAddon2)
      end)
    end)

    local implictly_expose_global = function()
      MyLameGlobal = 12345
    end

    local explicitly_expose_global = function()
      expose("MyLameGlobal", 12345)
    end

    unisolated(function()
      it("Exposing a global accidentally results in an error", function()
        assert.has.errors(implictly_expose_global)
      end)

      it("Exposing a global intentionally updates the global namespace", function()
        assert.has.no.errors(explicitly_expose_global)
        assert.equal(12345, MyLameGlobal)
      end)
    end)

    local import_global = function()
      local assert = import("assert")
      assert(3==3, "3 equaled 3")
    end

    unisolated(function()
      it("Can import a global value", function()
        assert.has.no.errors(import_global)
      end)
    end)

    local has_tostring = function()
      return tostring(MyAddon2.__namespace)
    end

    unisolated(function()
      it("AddOn has a tostring", function()
        assert.has.no.errors(has_tostring)
      end)
      it("tostring(AddOn) includes the addon name", function()
        assert.string.matches(name2, has_tostring())
      end)
    end)

    local get_undefined_addon = function()
      local t = get_addon("NeverLoaded")
    end

    unisolated(function()
      assert.has.errors(get_undefined_addon)
    end)
  end)
end)

insulate("", function()
  helpers.addon_loadfile("AddonToolkit", 'lib/fenv.lua')

  describe("An AddOn loaded with AddonToolkit with an Unisolated Namespace", function ()
    local name, MyAddon = "UnisolatedAddon", {}
    local name2, MyAddon2 = AddonToolkit.AddOn(name, MyAddon, true)
    it("AddOn returns the original functions", function ()
      assert.equals(name, name2)
      assert.equals(MyAddon, MyAddon2)
    end)

    local implictly_expose_global = function()
      MyLameGlobal = 12345
    end

    local explicitly_expose_global = function()
      AddonToolkit.expose("MyLameGlobal", 12345)
    end
    it("Exposing a global accidentally can happen", function()
      assert.has.no.errors(implictly_expose_global)
    end)

    it("Exposing a global intentionally updates the global namespace", function()
      assert.has.no.errors(explicitly_expose_global)
      assert.equal(12345, MyLameGlobal)
    end)

    local import_global = function()
      local assert = AddonToolkit.import("assert")
      assert(3==3, "3 equaled 3")
    end

    it("Can import a global value", function()
      assert.has.no.errors(import_global)
    end)

    it("Can export a value to it's namespace explicitly", function()
      AddonToolkit.export("myvar", 1234, MyAddon)
      local myvar = AddonToolkit.import("myvar", "UnisolatedAddon")
      assert.equal(myvar, 1234)
    end)

    it("Can't export a value without an explicit target addon", function()
      assert.has.errors(function()
        AddonToolkit.export("myvar", 1234)
      end)
    end)
  end)
end)

insulate("", function()
  helpers.addon_loadfile("AddonToolkit", 'lib/fenv.lua')

  insulate("A simple logging library", function()
    local _, Logging = AddonToolkit.AddOn("Logging", {})
    local assert = import("assert")

    function Logging:direct(a)
      assert(self and a == 3)
    end

    local function from_namespace(self, a)
      assert(self and a == 4)
    end

    export("from_namespace", from_namespace)
  end)

  insulate("Addons can import values from other addons", function()
    local _, App = AddonToolkit.AddOn("App", {})
    local Logging = get_addon("Logging")
    local function direct_call()
      Logging:direct(3)
    end
    unisolated(function()
      it("and can call functions on the AddOn directly", function()
        assert.has.no.errors(direct_call)
      end)
    end)

    local direct = import("direct", Logging)
    local function imported_directly()
      direct(Logging, 3)
    end
    unisolated(function()
      it("and can call functions imported from the AddOn directly", function()
        assert.has.no.errors(direct_call)
      end)
    end)

    local from_namespace = import("from_namespace", "Logging")
    local function imported_from_namespace()
      from_namespace(Logging, 4)
    end
    unisolated(function()
      it("and can import functions exported by libraries to their namespace", function()
        assert.has.no.errors(imported_from_namespace)
      end)
    end)
  end)
end)
