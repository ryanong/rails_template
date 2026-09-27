# typed: false

class SilentLogger
  def initialize
    @silencers = []
  end

  def add_silencer(&block)
    @silencers << block
  end

  def call(severity, timestamp, progname, msg)
    backtrace = (String === msg) ? "#{msg}\n" : "#{msg.inspect}\n"

    return backtrace if @silencers.empty?

    @silencers.each do |s|
      backtrace = backtrace.split("\n").delete_if { |line| s.call(line) }
    end

    backtrace.join("\n")
  end
end
