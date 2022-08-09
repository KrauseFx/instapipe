require "sequel"
require "google/cloud/storage"

class Database
  def self.database
    @_db ||= Sequel.connect(ENV["DATABASE_URL"])

    unless @_db.table_exists?("stories")
      @_db.create_table :stories do
        primary_key :id
        String :ig_id
        String :signed_url
        String :bucket_path

        Integer :height
        Integer :width
        Integer :timestamp
        Boolean :is_video

        # New as of using the official API
        String :media_product_type
        String :caption
        String :permalink
        String :username

        # Deprecated (those were from the old API)
        String :story_location
        String :user_id
      end
    end

    unless @_db.table_exists?("views")
      @_db.create_table :views do
        primary_key :id
        Date :date
        Integer :prefetches
        Integer :count
        String :user_id
      end
    end

    unless @_db.table_exists?("facebook_access_tokens")
      @_db.create_table :facebook_access_tokens do
        primary_key :id
        String :user_access_token_used
        String :long_lived_access_token
        String :user_id
        Time :expires_at
      end
    end

    return @_db
  end

  def self.file_storage_bucket
    credentials = "./gc_keys.json"
    credentials = JSON.parse(ENV["GC_KEYS"]) if ENV["GC_KEYS"]

    storage = Google::Cloud::Storage.new(
      project_id: ENV["GC_PROJECT_ID"],
      credentials: credentials
    )

    return storage.bucket(ENV["GC_BUCKET_NAME"])
  end
end
