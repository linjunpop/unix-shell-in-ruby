#!/usr/bin/env ruby

require 'shellwords'

class Shirt
  BUILTINS = {
    'exit' => ->(code = 0) { exit(code.to_i) },
    'cd' => ->(dir = ENV['HOME']) { Dir.chdir(dir) },
    'exec' => ->(*command) { exec *command },
    'set' => ->(args) {
      key, value = args.split('=')
      ENV[key] = value
    }
  }

  def run
    loop do
      $stdout.print ENV['PROMPT']

      line = $stdin.gets.strip

      command, *arguments = line.shellsplit

      if BUILTINS[command]
        BUILTINS[command].call(*arguments)
      else
        pid = fork { exec(command, *arguments) }

        Process.wait pid
      end
    end
  end
end

ENV['PROMPT'] = '$ -> '

Shirt.new.run

