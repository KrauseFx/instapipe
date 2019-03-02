require "sequel"

class Database
  def self.database
    @_db ||= Sequel.connect(ENV["DATABASE_URL"])

    unless @_db.table_exists?("stories")
      @_db.create_table :stories do
        primary_key :id
        String :ig_id
        String :url
        Integer :height
        Integer :width
        Integer :timestamp
        Boolean :is_video
      end
    end

    return @_db
  end
end
