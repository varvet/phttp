module PHTTP
  class TCPSocket
    extend Forwardable

    class << self
      alias_method :open, :new
    end

    def initialize(remote_host, remote_port)
      if block_given?
        raise ArgumentError, "block form is not supported"
      end

      @io = ::TCPSocket.open(remote_host, remote_port)
    end

    # HTTP::Client
    def_delegators :@io, :readpartial, :closed?, :close

    # HTTP::Request::Writer
    def_delegators :@io, :<<
  end
end
