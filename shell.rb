#!/usr/bin/env ruby

class Shelly
  def run
    print_prompt

    $stdin.each_line do |line|
      pid = fork {
        exec line
      }

      Process.wait pid
      print_prompt
    end
  end

  private

  def print_prompt
    $stdout.print '$-> '
  end
end

Shelly.new.run

