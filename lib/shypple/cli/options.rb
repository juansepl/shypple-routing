module Shypple
  module CLI
    # Parsed command-line options. command is :search, :pending or :ack;
    # ack_id keeps the raw --ack value for RequestIdForm.
    Options = Data.define(:feed_path, :command, :ack_id)
  end
end
