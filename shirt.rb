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

      commands = split_on_pipes(line)

      placeholder_in = $stdin
      placeholder_out = $stdout
      pipe = []

      commands.each_with_index do |command, index|
        program, *arguments = command.shellsplit

        if builtin?(program)
          BUILTINS[program].call(*arguments)
        else
          if index + 1 < commands.size
            pipe = IO.pipe
            placeholder_out = pipe.last
          else
            placeholder_out = $stdout
          end

          spawn_program(program, *arguments, placeholder_out, placeholder_in)

          placeholder_out.close unless placeholder_out == $stdout
          placeholder_in.close unless placeholder_in == $stdin
          placeholder_in = pipe.first
        end

        Process.waitall
      end
    end
  end

  private

  def split_on_pipes(line)
    line.scan( /([^"'|]+)|["']([^"']*)["']/ ).flatten.compact
  end

  def builtin?(program)
    !! BUILTINS[program]
  end

  def spawn_program(program, *arguments, placeholder_out, placeholder_in)
    fork {
      unless placeholder_out == $stdout
        $stdout.reopen(placeholder_out)
        placeholder_out.close
      end

      unless placeholder_in == $stdin
        $stdin.reopen(placeholder_in)
        placeholder_in.close
      end

      exec program, *arguments
    }
  end
end

ENV['PROMPT'] = '$ -> '

Shirt.new.run

