require 'mongo'
require 'document_hydrator'

class MongoHydrator
  # Create a new MongoHydrator instance
  #
  # collection -- The Mongo::Collection instance from which to fetch
  #   subdocuments during hydration
  # options -- Optional hash containing options to pass to
  #   collection.find. Typically used to specify a :fields
  #   option to limit the fields included in the subdocuments.
  #
  # Returns the new MongoHydrator instance.
  def initialize(collection, options = {})
    @hydration_proc = Proc.new do |ids|
      if options[:fields]
        # We need the_id key in order to assemble the results hash.
        # If the caller has requested that it be omitted from the
        # result, re-enable it and then strip later.
        field_selectors = options[:fields]
        id_key = field_selectors.keys.detect { |k| k.to_s == '_id' }
        if id_key && field_selectors[id_key] == 0
          field_selectors.delete(id_key)
          strip_id = true
        end
      end
      subdocuments = collection.find({ '_id' => { '$in' => ids } }, options)
      subdocuments.inject({}) do |hash, subdocument|
        hash[subdocument['_id']] = subdocument
        subdocument.delete('_id') if strip_id
        hash
      end
    end
  end

  def hydrate_document(document, path_or_paths)
    DocumentHydrator.hydrate_document(document, path_or_paths, @hydration_proc)
  end

  def hydrate_document(document, path_or_paths)
    DocumentHydrator.hydrate_document(document, path_or_paths, @hydration_proc)
  end
end