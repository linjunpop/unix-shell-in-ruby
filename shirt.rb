#!/usr/bin/env ruby

require 'shellwords'

class Shirt
  BUILTINS = {
    'exit' => ->(code=0) { exit(code.to_i) },
    'cd' => ->(dir) { Dir.chdir(dir) },
    'exec' => ->(*command) { exec *command }
  }

  def run
    loop do
      print_prompt

      line = $stdin.gets

      if line
        line.strip!
      else
        exit
      end

      command, *arguments = line.shellsplit

      if BUILTINS[command]
        BUILTINS[command].call(*arguments)
      else
        pid = fork {
          exec line
        }

        Process.wait pid
      end
    end
  end

  private

  def print_prompt
    $stdout.print '$-> '
  end
end

Shirt.new.run
