module PHTTP
  class TCPSocket
    extend Forwardable

    def self.open(*args)
      if block_given?
        raise ArgumentError, "block form is not supported"
      end

      new(*args)
    end

    def initialize(*args)
      @io = ::TCPSocket.open(*args)
    end

    # HTTP::Client
    def_delegators :@io, :readpartial, :closed?, :close

    # HTTP::Request::Writer
    def_delegators :@io, :<<
  end
end
