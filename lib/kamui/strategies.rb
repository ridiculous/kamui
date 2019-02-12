if defined? ActiveRecord
  Kamui.strategies.merge! lost_connection: Kamui.build(ActiveRecord::StatementInvalid,
                                                       message: /(gone away)|(closed MySQL connection)/,
                                                       on_retry: proc { ActiveRecord::Base.connection.reconnect! }),
                          deadlock: Kamui.build(ActiveRecord::StatementInvalid,
                                                message: /Deadlock/,
                                                on_retry: proc { |n| sleep 0.01 * n },
                                                tries: 10)
end

Kamui.strategies.merge! network_errors: Kamui.build([EOFError, Errno::ETIMEDOUT, Errno::ECONNREFUSED, Errno::EINVAL, Errno::ECONNRESET],
                                                    on_retry: proc { |n| sleep 10 * n },
                                                    tries: 12)
