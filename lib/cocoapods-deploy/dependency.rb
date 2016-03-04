module Pod
  class Dependency
    def requirement=(requirement)
      @requirement = requirement
    end

    def external_source=(external_source)
      @external_source = external_source
    end
  end
end
