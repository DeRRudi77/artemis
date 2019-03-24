require 'test_helper'

describe "#{GraphQL::Client} Autoloading" do
  describe ".load_constant" do
    it "loads the specified constant if there is a matching graphql file" do
      Metaphysics.send(:remove_const, :Artist) if Metaphysics.constants.include?(:Artist)

      Metaphysics.load_constant(:Artist)

      assert_equal 'constant', defined?(Metaphysics::Artist)
    end

    it "does nothing and returns nil if there is no matching file" do
      assert_nil Metaphysics.load_constant(:DoesNotExist)
    end
  end

  describe ".preload!" do
    it "preloads all the graphQL files in the query paths" do
      %i(Artist Artwork ArtistFragment)
        .select {|const_name| Metaphysics.constants.include?(const_name) }
        .each {|const_name| Metaphysics.send(:remove_const, const_name) }

      Metaphysics.preload!

      assert_equal 'constant', defined?(Metaphysics::Artist)
      assert_equal 'constant', defined?(Metaphysics::Artwork)
    end
  end

  it "dynamically loads the matching GraphQL query and sets it to a constant" do
    Metaphysics.send(:remove_const, :Artist) if Metaphysics.constants.include?(:Artist)

    query = Metaphysics::Artist

    assert_equal <<~GRAPHQL.strip, query.document.to_query_string
      query Metaphysics__Artist($id: String!) {
        artist(id: $id) {
          name
          bio
          birthday
        }
      }
    GRAPHQL
  end

  it "dynamically loads the matching GraphQL fragment and sets it to a constant" do
    Metaphysics.send(:remove_const, :ArtistFragment) if Metaphysics.constants.include?(:ArtistFragment)

    query = Metaphysics::ArtistFragment

    assert_equal <<~GRAPHQL.strip, query.document.to_query_string
      fragment Metaphysics__ArtistFragment on Artist {
        hometown
        deathday
      }
    GRAPHQL
  end

  it "correctly loads the matching GraphQL query even when the top-level constant with the same name exists" do
    # In Ruby <= 2.4 top-level constants can be looked up through a namespace, which turned out to be a bad practice.
    # This has been removed in 2.5, but in earlier versions still suffer from this behaviour.
    Metaphysics.send(:remove_const, :Artist) if Metaphysics.constants.include?(:Artist)
    Object.send(:remove_const, :Artist) if Object.constants.include?(:Artist)

    begin
      Object.send(:const_set, :Artist, 1)

      Metaphysics.artist
    ensure
      Object.send(:remove_const, :Artist)
    end

    query = Metaphysics::Artist

    assert_equal <<~GRAPHQL.strip, query.document.to_query_string
      query Metaphysics__Artist($id: String!) {
        artist(id: $id) {
          name
          bio
          birthday
        }
      }
    GRAPHQL
  end

  it "raises an exception when the path was resolved but the file does not exist" do
    begin
      Metaphysics.graphql_file_paths << "metaphysics/removed.graphql"

      assert_raises Errno::ENOENT do
        Metaphysics::Removed
      end
    ensure
      Metaphysics.graphql_file_paths.delete("metaphysics/removed.graphql")
    end
  end

  it "raises an NameError when there is no graphql file that matches the const name" do
    assert_raises NameError do
      Metaphysics::DoesNotExist
    end
  end

  it "defines the query method when the matching class method gets called for the first time" do
    skip
    Metaphysics.undef_method(:artwork) if Metaphysics.public_instance_methods.include?(:artwork)

    Metaphysics.artwork

    assert_includes :artwork, Metaphysics.public_instance_methods
  end

  it "raises an NameError when there is no graphql file that matches the class method name" do
    assert_raises NameError do
      Metaphysics.does_not_exist
    end
  end

  it "raises an NameError when the class method name matches a fragment name" do
    assert_raises NameError do
      Metaphysics.artist_fragment
    end
  end

  it "responds to a class method that has a matching graphQL file" do
    assert_respond_to Metaphysics, :artwork
  end

  it "does not respond to class methods that do not have a matching graphQL file" do
    refute_respond_to Metaphysics, :does_not_exist
  end

  it "defines the query method when the matching instance method gets called for the first time" do
    skip
    Metaphysics.undef_method(:artwork) if Metaphysics.public_instance_methods.include?(:artwork)

    Metaphysics.new.artwork

    assert_include :artwork, Metaphysics.public_instance_methods
  end

  it "raises an NameError when there is no graphql file that matches the instance method name" do
    assert_raises NameError do
      Metaphysics.new.does_not_exist
    end
  end

  it "raises an NameError when the instance method name matches a fragment name" do
    assert_raises NameError do
      Metaphysics.new.artist_fragment
    end
  end

  it "responds to the method that has a matching graphQL file" do
    assert_respond_to Metaphysics.new, :artworka
  end

  it "does not respond to methods that do not have a matching graphQL file" do
    refute_respond_to Metaphysics.new, :does_not_exist
  end
end