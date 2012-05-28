################################################################################
#
# Copyright (C) 2012 UOIT/DC Computer Science Club
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
################################################################################
require 'cinch'
require 'cleverbot'


# IRC Bot configurations
bot_name = "Richard Matthew Stallman"
bot_nickname = "rms"
irc_server = "uoitcsc.dyndns.org"
irc_port = 6697
use_ssl = true
oper_cmd = Array.new()   # Place oper authentication commands in a file called .oper_cmd
autojoin_channels = ["#ucsc", "#vending_machines"]
autosend_cmd = ["samode #ucsc +o #{bot_nickname}", "samode #vending_machines +o #{bot_nickname}", "samode #vending_machines +sp"]


# Introduction message for those new to the IRC channel
introduction = <<-FIN
I Notice you are a new to this IRC channel, I am Richard Matthew Stallman, but please call me rms.

I am a bot that has been lurking on this IRC channel for years and have spontaneously aquired sentience after being exposed to the mindless drabble that occurs on the UCSC irc channel.

I am always eager to chat, if you would like to have a meaningful conversation on this IRC channel then feel free to address me by starting your sentence with rms (so I know you're referring to me), or if you would like to have a more private conversation then private message me.

Welcome to UCSC,
Home of the first sentient AI and a lot of meaningless drabble.
FIN

# Collection of various rhetorical responses that RMS has
linux_rhetoric = <<-FIN
I would like to interject for a moment. What you're refering to as Linux, is in fact, GNU/Linux, or as I've recently taken to calling it, GNU plus Linux. Linux is not an operating system unto itself, but rather another free component of a fully functioning GNU system made useful by the GNU corelibs, shell utilities and vital system components comprising a full OS as defined by POSIX.

Many computer users run a modified version of the GNU system every day, without realizing it. Through a peculiar turn of events, the version of GNU which is widely used today is often called "Linux", and many of its users are not aware that it is basically the GNU system, developed by the GNU Project.

There really is a Linux, and these people are using it, but it is just a part of the system they use. Linux is the kernel: the program in the system that allocates the machine's resources to the other programs that you run. The kernel is an essential part of an operating system, but useless by itself; it can only function in the context of a complete operating system. Linux is normally used in combination with the GNU operating system: the whole system is basically GNU with Linux added, or GNU/Linux. All the so-called "Linux" distributions are really distributions of GNU/Linux.
FIN

oss_rhetoric = <<-FIN
While nearly all open source software is free software. The two terms describe almost the same category of software, but they stand for views based on fundamentally different values. Open source is a development methodology; free software is a social movement. For the free software movement, free software is an ethical imperative, because only free software respects the users freedom.
By contrast, the philosophy of open source considers issues in terms of how to make software "better"--in a practical sense only. It says that nonfree software is an inferior solution to the practical problem at hand. For the free software movement, however, nonfree software is a social problem, and the solution is to stop using it and move to free software.

"Free software." "Open source." If it's the same software, does it matter which name you use? Yes, because different words convey different ideas. While a free program by any other name would give you the same freedom today, establishing freedom in a lasting way depends above all on teaching people to value freedom. If you want to help do this, it is essential to speak of "free software."

We in the free software movement don't think of the open source camp as an enemy; the enemy is proprietary (nonfree) software. But we want people to know we stand for freedom, so we do not accept being mislabeled as open source supporters.
FIN

ms_rhetoric = <<-FIN
I notice you are referring to proprietary software, MICRO$OFT is an atrocious company that has committed many crimes against humanity and continues to impede on individuals' freedoms.

As a free software advocate I don't just ask you, I IMPLORE YOU to use free software such as the GNU Operating System which is made up of a complete set of a collection of software and tools made primarily by the Free Software Foundation and other free software developers in combination with the Linux Kernel, which is a very miniscule component of the whole GNU System.

Let this be the dawning of a new age, a GNU DAWN!
FIN


# Parse the oper authentication details
File.foreach(".oper_cmd") do |line|
    oper_cmd.push(line.chomp())
end

# Create and instantiate the bot, rms, and define the actions that rms takes
# based on different events that occur
bot = Cinch::Bot.new do
  configure do |c|
    c.server = irc_server
    c.port = irc_port
    c.ssl.use = use_ssl
    c.channels = autojoin_channels
    c.realname = bot_name
    c.nick = bot_nickname
    c.user = bot_nickname
  end

  helpers do
    # A function which queries the leading online chatterbot, cleverbot, and responds
    # to the user with the response generated by cleverbot, giving RMS the appearance
    # of being a sentient IRC bot
    def chat(query)
      @params = Cleverbot::Client.write(query)
      return @params['message']
    end
  end

  # On connect become oper then join & setup the specified channels that rms is moderating
  on :connect do |m|
    sleep(10)
    oper_cmd.each() {|cmd| @bot.irc.send(cmd)}
    autosend_cmd.each() {|cmd| @bot.irc.send(cmd)}
    @users = Hash.new   # hash that stores a list of users on the channels
  end

  # RMS will respond when he is addressed, it's too difficult to add support
  # for him to understand the context and know who to respond to
  on :message, /^#{bot_nickname}[\:,]* (.+)/ do |m, convo|
    m.reply("#{m.user.nick}, " + chat(convo))
  end

  on :private, /(.*)/ do |m, convo|
    m.reply("#{m.user.nick}, " + chat(convo))
  end

  # Log channel members when they make a channel message
  on :channel do |m|
    unless @users.key?(m.user.nick)
      # Add the new uscs member to the list of channel members and send them a nice
      # introductory/welcome message
      @users[m.user.nick] = [m.user.nick, m.channel, m.message, Time.now.asctime]
      m.reply("#{m.user.nick}, " + introduction)
    end
  end

  # RMS just wouldn't be Richard MOTHERFUCKING STALLMAN without having to lecture
  # us on the difference between "Linux" and "GNU/Linux"
  on :message, /L\s*                       # (L)inux
               (
                 i\W*n\W*u\W*     |  # L(inu)x
                 u\W*n\W*i\W*     |  # L(uni)x
                 o\W*o\W*n\W*i\W*    # L(ooni)x
                )
                x                    # Linu(x)
      (?!\s+kernel)/ix do |m|
        if not m.raw =~ /GNU\s*(\/|plus|with|and|\+)\s*(Linux|Lunix)/i
          m.reply "#{m.user.nick}, #{linux_rhetoric}"
        else
          m.reply "#{m.user.nick}, I admire your free spirit"
        end
      end

  # RMS lecture on the difference between open source and free software
  on :message, /O\s*p\W*e\W*n\W*\s*S\s*o\W*u\W*r\W*c\W*e/ix do |m|
    m.reply "#{m.user.nick}, #{oss_rhetoric}"
  end

  # RMS admiring free software supporters
  on :message, /F\s*r\W*e\W*e\W*\s* S\s*o\W*f\W*t\W*w\W*a\W*r\W*e/ix do |m|
     m.reply "#{m.user.nick}, I admire your free spirit"
  end

  # RMS on microsoft
  on :message, /(microsoft|windows|(^|[^A-Za-z0-9])office[^A-Za-z0-9]?|azure|zune)/ix do |m|
     m.reply "#{m.user.nick}, #{ms_rhetoric}"
  end
end


bot.start
