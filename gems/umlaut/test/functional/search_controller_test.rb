require 'test_helper'
class SearchControllerTest < ActionController::TestCase
  setup do
    @controller = SearchController.new
  end

  test "index" do
    get :index
    assert_response :success
    assert_select "title", "Find It | Journals"
    assert_select ".umlaut-search-form", 2
    assert_select ".umlaut-results", 0
  end

  # Tests don't currently support contains searching because sdalton can't/won't
  # figure out FULLTEXT indexing in MySQL, so we'll test begins with searching.
  test "journal search" do
    return unless Sfx4::Local::AzTitle.connection_configured?
    get :journal_search, "rft.jtitle"=>"Account", "umlaut.title_search_type"=>"begins"
    assert_response :success

    # some versions of rails escape apostrophes here others don't, we don't care
    assert_select "title", /\AFind It | Journal titles that begin with (&#39;)|(\')Account(&#39;)|(\')\Z/
    assert_select ".umlaut-search-form", 1
    assert_select ".umlaut-results", 1
    assert_select ".umlaut-results .umlaut-result", :minimum => 1
    assert_select ".umlaut-pagination", 2
    assert_select ".umlaut-az", 0
  end

  test "journal list" do
    return unless Sfx4::Local::AzTitle.connection_configured?
    get :journal_list, :id => "A"
    assert_response :success
    assert_select "title", "Find It | Browse by Journal Title: A"
    assert_select ".umlaut-search-form", 1
    assert_select ".umlaut-results", 1
    assert_select ".umlaut-results .umlaut-result", :minimum => 1 
    assert_select ".umlaut-pagination", 2
    assert_select ".umlaut-az", 1
  end
end
