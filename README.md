# Shrine::Plugins::Rom

Provides [ROM] integration for [Shrine].

_Note: This is still a work in progress. I'm currently working on wrapping up the demo application, and then I'll release the gem._

## Installation

Put the gem in your Gemfile:

```rb
# Gemfile
gem "shrine-rom"
```

## Quick start

Let's asume we have "photos" that have an "image" attachment. We start by
configuring Shrine in our initializer, and loading the `rom` plugin provided by
shrine-rom:

```rb
# Gemfile
gem "shrine", "~> 3.0"
gem "shrine-rom"
```
```rb
require "shrine"
require "shrine/storage/file_system"

Shrine.storages = {
  cache: Shrine::Storage::FileSystem.new("public", prefix: "uploads/cache"), # temporary
  store: Shrine::Storage::FileSystem.new("public", prefix: "uploads"),       # permanent
}

Shrine.plugin :rom                    # ROM integration, provided by shrine-rom
Shrine.plugin :cached_attachment_data # for retaining the cached file across form redisplays
Shrine.plugin :rack_file              # for accepting Rack uploaded file hashes
Shrine.plugin :form_assign            # for assigning file from form fields
Shrine.plugin :restore_cached_data    # re-extract metadata when attaching a cached file
Shrine.plugin :validation_helpers     # for validating uploaded files
Shrine.plugin :determine_mime_type    # determine MIME type from file content
```

Next, we run a migration that adds an `image_data` text or JSON column to our
`photos` table:

```rb
ROM::SQL.migration do
  change do
    add_column :photos, :image_data, :text # or :jsonb
  end
end
```

Now we can define an `ImageUploader` class and include an attachment module
into our `Photo` entity:

```rb
class ImageUploader < Shrine
  # we add some basic validation
  Attacher.validate do
    validate_max_size 20*1024*1024
    validate_mime_type %w[image/jpeg image/png image/webp]
    validate_extension %w[jpg jpeg png webp]
  end
end
```
```rb
class PhotoRepo < ROM::Repository[:photos]
  commands :create, update: :by_pk, delete: :by_pk
  struct_namespace Entities

  def find(id)
    photos.fetch(id)
  end
end
```
```rb
module Entities
  class Photo < ROM::Struct
    include ImageUploader::Attachment[:image]
  end
end
```

Let's now add fields for our `image` attachment to our HTML form for creating
photos:

```rb
# with Forme gem:
form @photo, action: "/photos", enctype: "multipart/form-data", namespace: "photo" do |f|
  f.input :title, type: :text
  f.input :image, type: :hidden, value: @attacher&.cached_data
  f.input :image, type: :file
  f.button "Create"
end
```

Now in our controller we can attach the uploaded file from request params.
We'll assume you're using [dry-validation] for validating user input.

```rb
post "/photos" do
  @photo    = Entities::Photo.new
  @attacher = @photo.image_attacher

  @attacher.form_assign(params["photo"]) # assigns file and performs validation

  contract = CreatePhotoContract.new(image_attacher: @attacher)
  result   = contract.call(params["photo"])

  if result.success?
    @attacher.finalize # upload cached file to permanent storage

    attributes = result.to_h
    attributes.merge!(@attacher.column_values)

    photo_repo.create(attributes)
    # ...
  else
    # ... render view with form ...
  end
end
```
```rb
class CreatePhotoContract < Dry::Validation::Contract
  option :image_attacher

  params do
    required(:title).filled(:string)
  end

  # copy any attacher's validation errors into our dry-validation contract
  rule(:image) do
    key.failure("must be present") unless image_attacher.attached?
    image_attacher.errors.each { |message| key.failure(message) }
  end
end
```

Once the image has been successfully attached to our photo, we can retrieve the
image URL by calling `#image_url` on the entity:

```erb
<img src="<%= @photo.image_url %>" />
```

If you want to see a complete example with direct uploads and backgrounding,
see the [demo app][demo].

## Understanding

The `rom` plugin builds upon Shrine's [`entity`][entity] plugin, providing
persistence functionality.

The attachment module included into the entity provides convenience methods for
reading the data attribute:

```rb
photo.image_data #=> '{"id":"path/to/file","storage":"store","metadata":{...}}'

photo.image          #=> #<Shrine::UploadedFile @id="path/to/file" @storage_key=:store ...>
photo.image_url      #=> "https://s3.amazonaws.com/..."
photo.image_attacher #=> #<Shrine::Attacher ...>
```

### Updating

When updating the attached file for an existing record, it's important to
initialize the attacher from that record's current attachment. That way the old
file will be automatically deleted on `Attacher#finalize`.

```rb
photo = photo_repo.find(photo_id)
photo.image #=> #<Shrine::UploadedFile @id="foo" ...>

attacher = photo.image_attacher # has current attachment
attacher.assign(file)

photo_repo.update(photo_id, attacher.column_values)

attacher.finalize # deletes previous attachment
```

### Attacher state

Unlike the [`model`][model] plugin, the `entity` plugin doesn't memoize the
`Shrine::Attacher` instance:

```rb
photo.image_attacher #=> #<Shrine::Attacher:0x00007ffe564085d8>
photo.image_attacher #=> #<Shrine::Attacher:0x00007ffe53b2f378> (different instance)
```

So, if you want to update the attacher state, you need to first assign it to a
variable:

```rb
attacher = photo.image_attacher
attacher.assign(file)
attacher.finalize
```

### Persisting

Normally you'd persist attachment changes explicitly, by using
`Attacher#column_data` or `Attacher#column_values`:

```rb
attacher = photo.image_attacher
attacher.attach(file)

photo_repo.create(image_data: attacher.column_data)
# or
photo_repo.create(attacher.column_values)
```

## Backgrounding

If you want to delay promotion into a background job, you need to call
`Attacher#finalize` _after_ you've persisted the cached file, so that your
background job is able to retrieve the record. We'll assume your repository
objects are registered using [dry-container].

```rb
Shrine.plugin :backgrounding
Shrine::Attacher.destroy_block { Attachment::DestroyJob.perform_async(self.class, data) }
```
```rb
attacher = photo.image_attacher
attacher.assign(file)

photo = photo_repo.create(attacher.column_values)

attacher.promote_block do |attacher|
  Attachment::PromoteJob.perform_async(:photo_repo, photo.id, :image, attacher.file_data)
end

attacher.finalize # calls the promote block
```
```rb
class Attachment::PromoteJob
  include Sidekiq::Worker

  def perform(repo_name, record_id, name, file_data)
    repo   = Application[repo_name] # retrieve repo from container
    entity = repo.find(record_id)

    attacher = Shrine::Attacher.retrieve(
      entity:     entity,
      name:       name,
      file:       file_data,
      repository: repo, # repository needs to be passed in
    )

    attacher.atomic_promote
  rescue Shrine::AttachmentChanged,   # attachment has changed
         ROM::TupleCountMismatchError # record has been deleted
  end
end
```
```rb
class Attachment::DestroyJob
  include Sidekiq::Worker

  def perform(attacher_class, data)
    attacher = Object.const_get(attacher_class).from_data(data)
    attacher.destroy
  end
end
```

## Contributing

Tests are run with:

```sh
$ bundle exec rake test
```

## Code of Conduct

Everyone interacting in the Shrine::Rom project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/janko/shrine-rom/blob/master/CODE_OF_CONDUCT.md).

## License

[MIT](/LICENSE.txt)

[ROM]: https://rom-rb.org
[Shrine]: https://shrinerb.com
[entity]: https://github.com/shrinerb/shrine/blob/master/doc/plugins/entity.md#readme
[model]: https://github.com/shrinerb/shrine/blob/master/doc/plugins/model.md#readme
[dry-validation]: https://dry-rb.org/gems/dry-validation/
[dry-container]: https://dry-rb.org/gems/dry-container/
[demo]: /demo
