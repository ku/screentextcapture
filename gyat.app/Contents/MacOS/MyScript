#!/usr/bin/ruby

require 'json'

module ExitStatus
  TextNotFound = 10
  InvalidResponse = 11
  EmptyResponse = 12
  Cancelled = 20
  GCLOUD_FAILED = 21
  OK = 0
end

class Main
  def initialize
    @debug = false
    @logdir = '/tmp'
  end

  def visionapi(filename)
    language_hints = 'ja,en'

    json = `/usr/local/bin/gcloud ml vision detect-text "#{ filename }" --language-hints="#{ language_hints }" `
    File.write("#{@logdir}/json", json) if @debug

    return ExitStatus::GCLOUD_FAILED unless $?.exitstatus == 0

    begin
      result = JSON.parse(json)
    rescue => e
      puts e
      return ExitStatus::InvalidResponse
    end

    exitstatus = ExitStatus::EmptyResponse

    responses = result['responses']
    if responses.length > 0
      responses.each do |response|
        if text_annotations = response['textAnnotations']
          text = text_annotations[0]['description']
          File.write("#{@logdir}/result", text) if @debug
          `echo "#{ text }" | env LANG=en_US.UTF-8 pbcopy`
          exitstatus = ExitStatus::OK
        end
      end
    end

    exitstatus
  end

  def execute
    filename = "#{@logdir}/gyat.tmp"

    File.delete(filename) if File.exist?(filename)

    `screencapture -tjpg -i "#{ filename }"`
    if File.exist?(filename)
      exitstatus = visionapi(filename)
    else
      exitstatus = ExitStatus::Cancelled
    end

    notify(exitstatus)

    exitstatus
  end

  def notify(exitstatus)
    case exitstatus
    when ExitStatus::OK then
      `afplay /System/Library/Sounds/Glass.aiff`
    when ExitStatus::InvalidResponse then
      `afplay /System/Library/Sounds/Sosumi.aiff`
    when ExitStatus::EmptyResponse then
      `afplay /System/Library/Sounds/Frog.aiff`
    when ExitStatus::TextNotFound then
      `afplay /System/Library/Sounds/Pop.aiff`
    when ExitStatus::GCLOUD_FAILED then
      `afplay /System/Library/Sounds/Submarine.aiff`
    else
      `afplay /System/Library/Sounds/Basso.aiff`
    end
  end
end

exit Main.new.execute
