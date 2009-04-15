# GreenStripes: Ruby bindings for libspotify

GreenStripes provides Ruby bindings for [libspotify][1], letting you write
programs like this one:

[1]: http://developer.spotify.com/libspotify/

    session = GreenStripes::Session.new(APPLICATION_KEY, 'GreenStripes', 'tmp', 'tmp')
    session.login(USERNAME, PASSWORD)
    session.process_events until session.connection_state == GreenStripes::ConnectionState::LOGGED_IN
    
    search = GreenStripes::Search.new(session, 'yakety sax', 0, 100)
    session.process_events until search.loaded?
    puts "found #{search.num_tracks} tracks"
    if search.num_tracks > 0
      track = search.track(0)
      session.process_events until track.loaded? and track.artist(0).loaded?
      puts "the first one is #{track.name} by #{track.artist(0).name}"
    end
    
    session.logout
    session.process_events until session.connection_state == GreenStripes::ConnectionState::LOGGED_OUT

## Copyright

Copyright (c) 2009 Jesper Särnesjö. See LICENSE for details.