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
        String :user_id
        Integer :height
        Integer :width
        Integer :timestamp
        Boolean :is_video
      end
    end

    return @_db
  end

  def self.file_storage_bucket
    storage = Google::Cloud::Storage.new(
      project_id: ENV["GC_PROJECT_ID"],
      credentials: ENV["GC_KEYS"] || "./gc_keys.json"
    )

    return storage.bucket(ENV["GC_BUCKET_NAME"])
  end
end
