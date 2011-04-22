require 'open-uri'
require 'hpricot'
require 'sqlite3'
require 'time'

class Dupe < Linkbot::Plugin
  def self.regex
    /!stats/
  end
  Linkbot::Plugin.register('dupe', self.regex, self)
  
  
  def self.on_message(user, message, matches) 
    rows = Linkbot.db.execute("select u.username,s.total,s.dupes from stats s, users u where u.user_id = s.user_id order by s.total desc")
    mess = "Link stats:\n--------------------------\n"
    max = 1
    divvy = 10
    rows.each do |row|
      while true do
        if row[1].to_i / divvy > 0
          max = max + 1
          divvy = divvy * 10
        else
          break
        end
      end
    end
    rows.each {|row| mess = mess + sprintf("%#{max}d: #{row[0]} (%d dupes, %.2f%% new)\n", row[1], row[2], (row[1]/(row[1]+row[2]).to_f)*100)}
    [mess]
  end
  
  def self.on_dupe(user, message, duped_user, duped_timestamp)
    total,dupes = self.stats(user)
    Linkbot.db.execute("update stats set dupes = #{dupes+1} where user_id='#{user['id']}'")
    username = Linkbot.db.execute("select username from users where user_id='#{user['id']}'")[0][0]
    puts duped_timestamp
    return ["DUPE: Previously posted by #{username} #{::Util.ago_in_words(Time.now, Time.at(duped_timestamp))}"]
  end
  
  def self.on_newlink(user, message)
    total,dupes = self.stats(user)
    Linkbot.db.execute("update stats set total = #{total+1} where user_id='#{user['id']}'")
  end
  
  
  def self.stats(user)
    total = 0
    dupes = 0
    rows = Linkbot.db.execute("select user_id,total,dupes from stats where user_id = '#{user['id']}'")
    if rows.empty?
      Linkbot.db.execute("insert into stats (user_id,total,dupes) values ('#{user['id']}', 0, 0)")
    else
      total = rows[0][1]
      dupes = rows[0][2]
    end
    return total,dupes
  end
  
  if Linkbot.db.table_info('stats').empty?
    Linkbot.db.execute('CREATE TABLE stats (user_id INTEGER, dupes INTEGER, total INTEGER)');
  end
end