require 'set'

class WikiLinksController < ApplicationController
  unloadable

  menu_item :wiki

  before_filter :find_project_by_project_id
  before_filter :authorize
  before_filter :only => [:links_from, :links_to, :orphan, :wanted]

  def links_from
    @page = @project.wiki.pages.find_by_title(params[:page_id])

    # We prettify the title without loading the page itself,
    # and then sort by the pretty title.
    @link_pages = WikiLink.where(:from_page_id => @page.id)
                          .select(:to_page_name)
                          .all
                          .collect{|x| _title_versions(x[:to_page_name])}
                          .sort{|x, y| x[:pretty] <=> y[:pretty]}
  end

  def links_to
    @page = @project.wiki.pages.find_by_title(params[:page_id])

    # Obtain the ids of all the pages that link to this one
    ids_to = WikiLink.where(:wiki_id => @project.wiki.id)
                     .where(:to_page_name => Wiki.titleize(@page.title))
                     .select("DISTINCT from_page_id")
                     .map(&:from_page_id)

    # Collect the pretty and ugly titles and sort by pretty title
    @link_pages = WikiPage.select(:title)
                          .find(ids_to)
                          .collect{|x| _title_versions(x.title)}
                          .sort{|x, y| x[:pretty] <=> y[:pretty]}
  end

  def orphan
    @link_pages = (_available_pages(@project.wiki) - _existing_targets(@project.wiki))
      .delete(@project.wiki.start_page)
      .collect{|x| _title_versions(x)}
      .sort{|x, y| x[:pretty] <=> y[:pretty]}
  end

  def wanted
    @link_pages = (_existing_targets(@project.wiki) - _available_pages(@project.wiki))
      .collect{|x| _title_versions(x)}
      .sort{|x, y| x[:pretty] <=> y[:pretty]}
  end

  # private area

  def _existing_targets(wiki)
    WikiLink.where(:wiki_id => @project.wiki.id)
      .select("DISTINCT to_page_name")
      .map(&:to_page_name).to_set
  end

  def _available_pages(wiki)
    wiki.pages.select("DISTINCT title").map(&:title).to_set
  end

  def _title_versions(title)
    { :pretty => title.tr('_', ' '), :ugly => title }
  end

end
