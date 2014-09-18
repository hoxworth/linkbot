require 'json'
require 'pp'
require 'eventmachine'
require 'chronic'
require 'open-uri'
require 'hpricot'
require 'sqlite3'
require 'time'

# run: bin/linkbot to test things out

# Successes
# !pingpong @KyleSum, tomorrow at 1:20 PM, 20
# !pingpong @JonSnow, tomorrow at 3:25 PM, 10
# !pingpong @TyrionLannister @TheHound, tomorrow at 5:05 PM, 15
# !pingpong @Brienne, tomorrow at 8:00 AM, 10
# !pingpong @KyleSum, tomorrow at noon, 30
# !pingpong @KyleSum, 1 day from now at 8:15 AM, 30

# Errors
# !pingpong @CerseiLannister, yesterday at 1:20 PM, 5
# !pingpong @CerseiLannister, 5 days from now at 1:20 PM, 5
# !pingpong @LittleFinger, today at 9:20 AM, 5
# !pingpong @LittleFinger, tomorrow at 1:25 PM, 10
# !pingpong @LittleFinger, tomorrow at 1:35 PM, 10
# !pingpong @LittleFinger, tomorrow at 3:20 PM, 10
# !pingpong @LittleFinger, tomorrow at 8:20 PM, 30
# !pingpong @LittleFinger, tomorrow at 8:20 PM, 4
# !pingpong @KyleSum, tomorrow at 1:10 PM, 20
# !pingpong @KyleSum, tomorrow at 1:10 PM, 90

class PingPong < Linkbot::Plugin

  register :regex => /!pingpong/, :periodic => {:handler => :periodic}

  description "Ping Pong management to enourage procrastination"

  MIN_TIME_LENGTH = 1
  MAX_TIME_LENGTH = 30
  LOOKAHEAD_BUFFER = 25

  EMPTY_QUEUE_MESSAGE = "No one is currently scheduled to play"
  RESERVATION_CONFIRMATION = "Your reservation has been placed"
  HELP_MESSAGE = "
This is the ping pong plugin. You can only book 2 days in advance. You cannot book over other reservations' time slots.
1. !pingpong list
2. !pingpong @user1 @user2, start time, duration in minutes
   e.g. !pingpong @JonSnow @TyrionLannister, today at noon, 30
"

  DURATION_MISSING_ERROR = "Please specify the number of minutes you plan to play at the end of your input"
  DURATION_INVALID_ERROR = "The duration must be the number of minutes you want to play"
  DURATION_INVALID_RANGE_ERROR = "The number of minutes must be between #{MIN_TIME_LENGTH} and #{MAX_TIME_LENGTH}"
  TIME_DEPRECATED_ERROR = "No reservations in the past, please"
  TIME_OVEREXTENSION_ERROR = "You can only book 2 days in advance"
  CONFLCTING_RESERVATION_ERRORS = "Your reservation is conflicting with an existing one"

  def self.on_message(message, matches, config)
    #puts message.body
    #puts message.user_name

    message_split = message.body.split(" ")
    puts message_split

    # only !pingpong was command, so print help
    if message_split.length == 1
      return HELP_MESSAGE

    elsif message_split.length == 2
      if message_split[1] == "list"
        puts "list command received"
        rows = Linkbot.db.execute("select * from pingpong order by st")
        puts "rows in pingpong in order: " + rows.to_s
        if rows.empty?
          return EMPTY_QUEUE_MESSAGE
        else
          return ping_pong_queue_to_string(rows)
        end
      end

    elsif message_split.length > 2
      players = parse_player_list(message.body)
      if players == nil
        return INVALID_COMMAND_ERROR
      end

      time = parse_reservation_time(message.body)
      duration = parse_duration(message.body)

      if time.class == String
        return time
      elsif duration.class == String
        return duration
      end

      return create_reservation(players, time, duration)
    end

    return HELP_MESSAGE
  end

  # takes a list of players (array of strings), start_time (Time object), end_time (Time object)
  def self.create_reservation(players, start_time, duration)
    # addition in int form is based on seconds, so convert to minutes
    end_time = Time.at(start_time.to_i() + duration.to_i() * 60)

    puts "creating reservation"
    puts "players: " + players.to_s()
    puts "start timestamp: " + start_time.to_s()
    puts "end timestamp: " + end_time.to_s()

    # store the reservation in the db
    rows = Linkbot.db.execute("select * from pingpong order by st")

    # db is empty, no worries about conflicts
    if rows.empty?
      puts "pingpong table is empty"
      Linkbot.db.execute("insert into pingpong (users, st, et, notified) VALUES (?, ?, ?, ?)", players.join(" "), start_time.to_s, end_time.to_s, 0)
      return RESERVATION_CONFIRMATION

    # insert reservation into db if it isn't conflicting with any other
    # reservation
    else
      rows.each_with_index { |reservation, index|
        # times pulled from db are in string form, so get them back into Dates
        sample_start_time = Chronic.parse(reservation[1])
        sample_end_time = Chronic.parse(reservation[2])

        # check for a conflicting reservation
        if start_time >= sample_start_time and start_time < sample_end_time
            return CONFLCTING_RESERVATION_ERRORS
        elsif end_time > sample_start_time and end_time <= sample_end_time
            return CONFLCTING_RESERVATION_ERRORS
        elsif start_time < sample_start_time
          # new reservation comes before current one, so make sure new
          # reservation doesn't run past current (time block is contiguous)
          if end_time > sample_start_time
            return CONFLCTING_RESERVATION_ERRORS
          end
        end
      }
      # haven't returned, so we never found a conflicting reservation - insert
      # players is an array of strings, so convert them to required string
      # form for db storage
      Linkbot.db.execute("insert into pingpong (users, st, et, notified) VALUES (?, ?, ?, ?)", players.join(" "), start_time.to_s, end_time.to_s, 0)
      return RESERVATION_CONFIRMATION
    end
  end

  # returns the reservation time (Time object) the user entered in the command.
  # If the reservation time is invalid, return an error message instead.
  def self.parse_reservation_time(body)
    # isolate the time string
    time_input = body.split(",")[1].lstrip().rstrip()

    result = Chronic.parse(time_input)

    puts "inputted time: " + time_input.to_s()
    puts "Chronic result: " + result.to_s()

    if result < Chronic.parse("5 minutes ago")
      return TIME_DEPRECATED_ERROR
    elsif result > Chronic.parse("2 days from now at midnight")
      return TIME_OVEREXTENSION_ERROR
    end

    return result
  end

  # returns the session duration (string) the user entered in the command
  def self.parse_duration(body)
    duration = body.split(",")[2].rstrip().lstrip()

    puts "duration: " + duration

    if (Float duration rescue nil) == nil
      return DURATION_INVALID_ERROR

    elsif duration.to_i() < MIN_TIME_LENGTH or duration.to_i() > MAX_TIME_LENGTH
      return DURATION_INVALID_RANGE_ERROR

    else
      return duration.to_i()
    end
  end

  # get list of players with '@' property and place them in array
  def self.parse_player_list(body)
    lo = body.index('@')
    if lo == nil
      return nil
    end

    # get rid of '!pingpong'
    body = body.slice(lo, body.length - 1)

    # return array of player names
    return body.split(',')[0].split(" ")
  end

  # convert the ping pong list (alredy ordered by query) passed as arg into an
  # easily-readable form
  def self.ping_pong_queue_to_string(rows)
    if rows == nil
      return "rows is nil"
    else
      result = "\n"
      rows.each_with_index { |reservation, index|
        puts "current raw reservation: " + reservation.to_s
        result += (index + 1).to_s() + ". "

        # players field from DB is a string, so just remove the '@'s
        result += reservation[0].tr("@", "") + " "

        # times are stored in db as strings in hard-to-read timestamp, so
        # convert to Date objects for more formatting
        result += "start: #{Chronic.parse(reservation[1]).strftime('%A %I:%M %p')}, "
        result += "end: #{Chronic.parse(reservation[2]).strftime('%A %I:%M %p')} \n"
      }
      return result
    end
  end

  # repeatedly called - notify players and clean out expired reservations
  def self.periodic
    notifications = notify_impending_reservations()
    Linkbot.db.execute("delete from pingpong where et < " + "'" + Time.now.to_s + "'");

    {:messages => notifications, :options => {:room=>"50263_ping_pong"}}
  end

  # remind users of upcoming games
  def self.notify_impending_reservations()
    puts "running notify_impending_reservations"
    notifications = []
    rows = Linkbot.db.execute("select * from pingpong where notified = 0 order by st")
    rows.each { |reservation|
      start_time = Chronic.parse(reservation[1])
      current_time = Chronic.parse("now")
      lookahead_buffer = Chronic.parse("#{LOOKAHEAD_BUFFER} seconds from now")

      # if game hasn't happened yet and game will be starting within the
      # lookahead buffer, alert users. Note that players are stored in db as a
      # string, so no parsing needed (we want @'s to appear for alert)
      if current_time < start_time and start_time < lookahead_buffer
        result = reservation[0]
        notifications.push(result + " your ping pong game is starting")
        Linkbot.db.execute("update pingpong SET notified=1 where users=? and st=? and et=?", result, reservation[1], reservation[2])
      end
    }
    puts "notifications to be returned: " + notifications.to_s
    return notifications
  end

end
