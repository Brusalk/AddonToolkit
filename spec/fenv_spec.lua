fenv = assert(loadfile('lib/fenv.lua'))
fenv("AddonToolkit", {})


insulate("", function()
  describe("An Isolated Addon Namespace", function ()
    local name, MyAddon = "MyAddon", {}
    local name2, MyAddon2 = AddonToolkit.AddOn(name, MyAddon)
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
        assert.is.falsy(pcall(implictly_expose_global))
      end)

      it("Exposing a global intentionally updates the global namespace", function()
        assert.is.truthy(pcall(explicitly_expose_global))
        assert.equal(12345, MyLameGlobal)
      end)
    end)
    
    local import_global = function()
      local assert = import("assert")
      assert(3==4, "3 did not equal 4")
    end

    unisolated(function()
      it("Can import a global value", function()
        assert.has.errors(import_global)
      end)
    end)
  end)
end)