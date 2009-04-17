# add ../lib to the load path
$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

# add . to the load path
$:.unshift(File.dirname(__FILE__))

require 'test/unit'
require 'greenstripes'
require 'config'

class TestGreenStripes < Test::Unit::TestCase
  def setup
    # TODO: it would actually be better if this was run just once, before all tests
    @session = GreenStripes::Session.new(APPLICATION_KEY, 'GreenStripes', 'tmp', 'tmp')
    @session.login(USERNAME, PASSWORD)
    @session.process_events until @session.connection_state == GreenStripes::ConnectionState::LOGGED_IN

    # TODO: it would be better if we created a designated test playlist here
    playlist_container = @session.playlist_container
    @session.process_events until playlist_container.num_playlists > 0
    @playlist = playlist_container.playlist(0)
    @session.process_events until @playlist.loaded?
  end

  def teardown
    @session.logout
    @session.process_events until @session.connection_state == GreenStripes::ConnectionState::LOGGED_OUT
  end

  def test_user
    user = @session.user
    @session.process_events until user.loaded?
    assert_not_nil(user.display_name)
    assert_not_nil(user.canonical_name)
  end

  def test_playlist
    assert_not_nil(@playlist.name)
    assert_not_nil(@playlist.owner)
    assert_not_nil(@playlist.collaborative?)
    assert_not_equal(0, @playlist.num_tracks)
    assert_not_nil(@playlist.track(0))
  end

  def test_search
    query = 'a'
    search = GreenStripes::Search.new(@session, query, 0, 1)
    @session.process_events until search.loaded?
    assert_equal(GreenStripes::Error::OK, search.error)
    assert_equal(query, search.query)
    assert_not_nil(search.did_you_mean)
    assert_not_equal(0, search.num_artists)
    assert_not_nil(search.artist(0))
    assert_not_equal(0, search.num_albums)
    assert_not_nil(search.album(0))
    assert_not_equal(0, search.num_tracks)
    assert_not_nil(search.track(0))
  end

  def test_artist_browse
    track = @playlist.track(0)
    @session.process_events until track.loaded?
    artist_browse = GreenStripes::ArtistBrowse.new(@session, track.artist(0))
    @session.process_events until artist_browse.loaded?
    assert_equal(GreenStripes::Error::OK, artist_browse.error)
    assert_equal(track.artist(0), artist_browse.artist)
    assert_not_equal(0, artist_browse.num_tracks)
    assert_not_nil(artist_browse.track(0))
    assert_not_equal(0, artist_browse.num_similar_artists)
    assert_not_nil(artist_browse.similar_artist(0))
    assert_not_nil(artist_browse.biography)
  end

  def test_album_browse
    track = @playlist.track(0)
    @session.process_events until track.loaded?
    album_browse = GreenStripes::AlbumBrowse.new(@session, track.album)
    @session.process_events until album_browse.loaded?
    assert_equal(GreenStripes::Error::OK, album_browse.error)
    assert_equal(track.album, album_browse.album)
    assert_equal(track.album.artist, album_browse.artist)
    assert_not_equal(0, album_browse.num_tracks)
    assert_not_nil(album_browse.track(0))
    assert_not_equal(0, album_browse.num_copyrights)
    assert_not_nil(album_browse.copyright(0))
    assert_not_nil(album_browse.review)
  end

  def test_link_from_objects
    track = @playlist.track(0)
    search = GreenStripes::Search.new(@session, 'a', 0, 1)
    @session.process_events until track.loaded? and search.loaded?
    [@playlist, search, track.artist(0), track.album, track].each do |obj|
      assert_kind_of(GreenStripes::Link, GreenStripes::Link.new(obj))
      assert_kind_of(GreenStripes::Link, obj.to_link)
    end
  end

  def test_link_from_strings
    %w{spotify:artist:3mvkWMe6swnknwscwvGCHO
       spotify:album:57SkIVhE1QfVnShjmvKw3O
       spotify:track:3DTrAmImiol2ugB5wsqFcx
       spotify:user:sarnesjo:playlist:3nCwOiwDiZtv9xsuEIFw4q
       spotify:search:a}.each do |str|
      assert_kind_of(GreenStripes::Link, GreenStripes::Link.new(str))
      assert_kind_of(GreenStripes::Link, str.to_link)
    end
  end

  def test_fake_array_for_playlist_container
    playlist_container = @session.playlist_container
    assert_not_equal(0, playlist_container.num_playlists)
    assert_equal(playlist_container.num_playlists, playlist_container.playlists.size)
    assert_not_nil(playlist_container.playlist(0))
    assert_equal(playlist_container.playlist(0), playlist_container.playlists[0])
    playlist_container.playlists.each do |p|
      assert_not_nil(p)
    end
  end

  def test_fake_array_for_playlist
    assert_not_equal(0, @playlist.num_tracks)
    assert_equal(@playlist.num_tracks, @playlist.tracks.size)
    assert_not_nil(@playlist.track(0))
    assert_equal(@playlist.track(0), @playlist.tracks[0])
    @playlist.tracks.each do |t|
      assert_not_nil(t)
    end
  end

  def test_fake_array_for_search
    search = GreenStripes::Search.new(@session, 'a', 0, 1)
    @session.process_events until search.loaded?
    assert_equal(GreenStripes::Error::OK, search.error)

    assert_not_equal(0, search.num_artists)
    assert_equal(search.num_artists, search.artists.size)
    assert_not_nil(search.artist(0))
    assert_equal(search.artist(0), search.artists[0])
    search.artists.each do |a|
      assert_not_nil(a)
    end

    assert_not_equal(0, search.num_albums)
    assert_equal(search.num_albums, search.albums.size)
    assert_not_nil(search.album(0))
    assert_equal(search.album(0), search.albums[0])
    search.albums.each do |a|
      assert_not_nil(a)
    end

    assert_not_equal(0, search.num_tracks)
    assert_equal(search.num_tracks, search.tracks.size)
    assert_not_nil(search.track(0))
    assert_equal(search.track(0), search.tracks[0])
    search.tracks.each do |t|
      assert_not_nil(t)
    end
  end

  def test_fake_array_for_artist_browse
    track = @playlist.track(0)
    @session.process_events until track.loaded?
    artist_browse = GreenStripes::ArtistBrowse.new(@session, track.artist(0))
    @session.process_events until artist_browse.loaded?
    assert_equal(GreenStripes::Error::OK, artist_browse.error)

    assert_not_equal(0, artist_browse.num_tracks)
    assert_equal(artist_browse.num_tracks, artist_browse.tracks.size)
    assert_not_nil(artist_browse.track(0))
    assert_equal(artist_browse.track(0), artist_browse.tracks[0])
    artist_browse.tracks.each do |t|
      assert_not_nil(t)
    end

    assert_not_equal(0, artist_browse.num_similar_artists)
    assert_equal(artist_browse.num_similar_artists, artist_browse.similar_artists.size)
    assert_not_nil(artist_browse.similar_artist(0))
    assert_equal(artist_browse.similar_artist(0), artist_browse.similar_artists[0])
    artist_browse.similar_artists.each do |a|
      assert_not_nil(a)
    end
  end

  def test_fake_array_for_album_browse
    track = @playlist.track(0)
    @session.process_events until track.loaded?
    album_browse = GreenStripes::AlbumBrowse.new(@session, track.album)
    @session.process_events until album_browse.loaded?
    assert_equal(GreenStripes::Error::OK, album_browse.error)

    assert_not_equal(0, album_browse.num_tracks)
    assert_equal(album_browse.num_tracks, album_browse.tracks.size)
    assert_not_nil(album_browse.track(0))
    assert_equal(album_browse.track(0), album_browse.tracks[0])
    album_browse.tracks.each do |t|
      assert_not_nil(t)
    end

    assert_not_equal(0, album_browse.num_copyrights)
    assert_equal(album_browse.num_copyrights, album_browse.copyrights.size)
    assert_not_nil(album_browse.copyright(0))
    assert_equal(album_browse.copyright(0), album_browse.copyrights[0])
    album_browse.copyrights.each do |c|
      assert_not_nil(c)
    end
  end

  def test_fake_array_for_track
    track = @playlist.track(0)
    @session.process_events until track.loaded?

    assert_not_equal(0, track.num_artists)
    assert_equal(track.num_artists, track.artists.size)
    assert_not_nil(track.artist(0))
    assert_equal(track.artist(0), track.artists[0])
    track.artists.each do |a|
      assert_not_nil(a)
    end
  end

  def test_search_with_callback
    done = false
    search = GreenStripes::Search.new(@session, 'a', 0, 1) do |result|
      assert_equal(search, result)
      done = true
    end
    @session.process_events until done
  end

  def test_search_without_callback
    search = GreenStripes::Search.new(@session, 'a', 0, 1)
    @session.process_events until search.loaded?
    assert_equal(GreenStripes::Error::OK, search.error)
  end
end
