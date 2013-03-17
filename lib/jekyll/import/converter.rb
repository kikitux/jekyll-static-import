require 'kramdown'

module Jekyll
  module Import
    class Converter

      # XPath/CSS-path expression for the content node.
      #
      # @return [String]
      attr_reader :content_xpath

      # List of XPath/CSS-path expressions for nodes to inline.
      #
      # @return [Array<String>]
      attr_reader :inline_xpaths

      # List of XPath/CSS-path expressions for nodes to remove.
      #
      # @return [Array<String>]
      attr_reader :remove_xpaths

      def initialize(content_xpath,options={})
        @content_xpath = content_xpath

        @inline_xpaths = Array(options[:inline])
        @remove_xpaths = Array(options[:remove])
      end

      #
      # Finds the HTML node containing the content.
      #
      # @param [Nokogiri::HTML::Document] doc
      #   The HTML document to convert.
      #
      # @return [Nokogiri::HTML::Node, nil]
      #   The HTML content node.
      #
      def content(doc)
        doc.at(@content_xpath)
      end

      #
      # Sanitizes the HTML node containing the content.
      #
      # @param [Nokogiri::HTML::Node] content_node
      #   The HTML node containing the content.
      #
      # @return [Nokogiri::HTML::Node]
      #   The sanitized node.
      #
      def sanitize(content_node)
        # remove all comments
        content_node.traverse do |node|
          node.remove if node.comment?
        end

        # remove additional nodes
        @remove_xpaths.each do |expr|
          content_node.search(expr).each do |node|
            node.remove
          end
        end

        # inline the text of various nodes
        @inline_xpaths.each do |expr|
          content_node.search(expr).each do |node|
            node.replace(node.inner_text)
          end
        end

        return content_node
      end

      #
      # Converts the content node into a Markdown document.
      #
      # @param [Nokogiri::HTML::Node] content_node
      #   The HTML node containing the content.
      #
      # @return [Kramdown::Document]
      #   The Markdown document.
      #
      def convert(content_node)
        Kramdown::Document.new(
          content_node.inner_html,
          :input => :html
        )
      end

      #
      # Converts HTML into Markdown.
      #
      # @param [Nokogiri::HTML::Document] doc
      #   The HTML document to convert.
      #
      # @return [String]
      #   The converted markdown.
      #
      def markdown(doc)
        if (content_node = content(doc))
          convert(sanitize(content_node)).to_kramdown
        else
          ''
        end
      end

    end
  end
end
