module Ppds
  class ClassFactory
    def initialize(data=[])
      for att in data
        set(att.name.gsub(/-/,'_'), att.value)
      end
    end

    def get(name)
      instance_variable_get("@#{name}")
    end

    def set(name, value)
      instance_variable_set("@#{name}", value)
    end
  end
end
