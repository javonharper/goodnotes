module Async
  class ArtistFinder
    include Celluloid

    def initialize(lastfm, artist_name)
      @lastfm = lastfm
      @artist_name = artist_name
    end

    def run
      results = @lastfm.artist.search({artist: @artist_name.strip, limit: 5})
      matches = results['results']['artistmatches']

      if matches.empty?
        nil
      else
        artists = [matches['artist']].flatten

        exact_match = artists.find do |artist|
          artist['name'].downcase == @artist_name.downcase
        end

        artist = exact_match || artists.first

        artist
      end
    end
  end

  class TopTracksFinder
    include Celluloid

    def initialize(lastfm, artist_name, num_songs)
      @lastfm = lastfm
      @artist_name = artist_name
      @num_songs = num_songs
    end

    def run
      @lastfm.artist.get_top_tracks({artist: @artist_name, limit: @num_songs})
    end
  end

  class SimilarArtistsFinder
    include Celluloid

    def initialize(lastfm, artist_name, pool, select)
      @lastfm = lastfm
      @artist_name = artist_name
      @pool = pool
      @select = select
    end

    def run
      results = @lastfm.artist.get_similar(artist: @artist_name.strip, limit: @pool)    
    
      # Remove first element, since it is just the query.
      if results.class == Array
        results.shift
      else
        return []
      end
    
      selection_pool = results.first(@pool).map do |r|
        {
          name: r['name'],
          image: r['image'].last['content']
        }
      end
    
      selection_pool.shuffle.first(@select).map do |artist|
        {
          name: artist[:name], 
          escaped_name: CGI::escape(artist[:name]),
          image_url: artist[:image]
        }
      end
    end
  end

  class ArtistInfoFinder
    include Celluloid

    def initialize(lastfm, artist_name)
      @lastfm = lastfm
      @artist_name = artist_name
    end

    def run
      results = @lastfm.artist.get_info(artist: @artist_name.strip)
      results["bio"]["summary"]
    end
  end

  class SongFinder
    include Celluloid

    def initialize(google_client, youtube, artist_name, song_name, index)
      @google_client = google_client
      @youtube = youtube
      @artist_name = artist_name
      @song_name = song_name
      @index = index
      @google_client.authorization = nil
    end

    def run
      results = @google_client.execute!(
        api_method: @youtube.search.list,
        parameters: {
          q: "#{@artist_name} #{@song_name}",
          part: 'id',
          maxResults: 1 })
      
      video_id = results.data.items.first.id.videoId

      {
        number: @index + 1,
        artist: @artist_name,
        name: @song_name,
        media_source: 'youtube',
        media_id: video_id,
        media_url: "https://www.youtube.com/watch?v=#{video_id}" }
    end
  end
end
