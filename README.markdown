# MongoHydrator
MongoHydrator makes turning a document with embedded references like this:

    status_update = {
      "_id" => 37,
      "user_id" => 1,
      "text" => "May the Force be with you.",
      "liker_ids" => [3, 4],
      "comments" => [
        { "user_id" => 2,
          "text" => "Thanks, but I'll stick with my blaster."
        },
        { "user_id" => 3,
          "text" => "Hey, show some respect!"
        }
      ]
    }

into a document with expanded subdocuments like this:

    {
      "_id" => 37,
      "user" => { "_id"=>1, "name"=>"Obi-Wan Kenobi", "occupation"=>"Hermit" },
      "text" => "May the Force be with you.",
      "likers" => [
        {"_id" => 3, "name" => "Luke Skywalker", "occupation" => "Farmer"},
        {"_id" => 4, "name" => "Yoda", "occupation" => "Jedi Master"}
      ],
      "comments" => [
        { "user" => { "_id" => 2, "name" => "Han Solo", "occupation" => "Smuggler" },
          "text" => "Thanks, but I'll stick with my blaster."
        },
        { "text" => "Hey, show some respect!",
          "user" => { "_id" => 3, "name" => "Luke Skywalker", "occupation" => "Farmer"}
        }
      ]
    }

as simple as this:

    # users is an instance of Mongo::Collection
    hydrator = MongoHydrator.new(users)
    hydrator.hydrate_document(status_update,
      ['user_id', 'liker_ids', 'comments.user_id'])

Behind the scenes, a single MongoDB query is used to retrieve the user
documents corresponding to the IDs referenced by the specified paths:
'user_id', 'liker_ids', and 'comments.user_id'.

Integers are used above to make the example cleaner, but, of course, any form of valid MongoDB IDs can be used.

## Installation
Install the gem:

    gem install mongo_hydrator
    
Require the file:

    require 'mongo_hydrator'

Or, if you use Bundler, add this to your Gemfile:

    gem 'mongo_hydrator'

## Paths
A call to MongoHydrator#hydrate_document requires one or more paths to tell the hydrator which key or keys to replace in the original document. Paths use the same dot notation used in MongoDB queries.  The example above uses three paths:

* user_id -- a top-level key holding an ID
* liker_ids -- an top-level key holding an array of IDs
* comments.user_id -- an array of objects, each with an embedded ID

Intermediate steps in the path may be hashes or arrays of hashes. The final step in the path may be an ID or an array of IDs.

MongoHydrate#hydrate_document accepts either a single path or an array of paths.  E.g.:

    hydrator.hydrate_document(document, 'user_id')
    hydrator.hydrate_document(document, ['user_id', 'liker_ids'])

## ID Suffix Stripping
If the paths in the original dehydrated document end in '_id' or '_ids', those suffixes will be stripped during hydration so that the key names continue to make sense. Pluralization is taken into account, so 'user_id' becomes 'user' and 'user_ids' becomes 'users'.

## Limiting Fields
To limit the fields that are included in the hydrated subdocuments, use the `:fields` option when creating the hydrator:

    hydrator = MongoHydrator.new(users_collection, :fields => { :_id => 0, :name => 1 })

Then only the specified fields will show up in the hydrated result.  E.g.,:

    hydrator.hydrate_document(status_update,
      ['user_id', 'liker_ids', 'comments.user_id'])
    # =>

## Hydrating Multiple Documents
To hydrate multiple documents at once, use `hydrate_documents`. The arguments are the same as for `hydrate_document` with the exception that the first argument is an array of documents to hydrate. As with `hydrate_document` a single MongoDB query will be used to retrieve the required documents.

## Additional Notes
MongoHydrator expects the document being hydrated to have strings for keys. This will already be the case if the document came from the Mongo driver. If, however, the document is using symbols for keys, you will need to convert the keys to strings before hydration.

## Copyright
Copyright (c) 2011 Greg Spurrier. Released under the MIT license. See LICENSE.txt for further details.
