require 'teststrap'

context "overridable" do
  setup do
    false
  end

  asserts "i'm a failure :(" do
    topic
  end
end
