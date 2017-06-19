module HTML
  class Pipeline
    class LinkButton < Filter

      def call
        doc.search("a").each do |element|
          next unless element["href"]

          button = doc.document.create_element('span', "data-behavior" => "link_actions")
          element.add_child(button)

        end
        doc
      end

    end
  end
end