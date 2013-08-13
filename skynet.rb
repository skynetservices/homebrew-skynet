require 'formula'

class Skynet < Formula
  homepage 'https://github.com/skynetservices/skynet2'

  url 'http://homebrew-skynet.s3.amazonaws.com/skynet-0.1.0.tar.gz'
  sha1 '1e05c04f314539d871711a8da59d61d0ae441ac2'

  depends_on 'go' => :recommended

  option 'without-skydaemon', 'Disable installation of daemon'

  fails_with :clang do
    cause "clang: error: no such file or directory: 'libgcc.a'"
  end

  def install
    ENV.deparallelize
    ENV.no_optimization

    ENV['CGO_CFLAGS'] = "-I#{pwd}/src/github.com/skynetservices/skynet2/tools/starter-kit-osx/zookeeper/include"
    ENV['CGO_LDFLAGS'] = "#{pwd}/src/github.com/skynetservices/skynet2/tools/starter-kit-osx/zookeeper/lib/libzookeeper_mt.a"
    ENV['GOPATH'] = pwd

    cd 'src/github.com/skynetservices/skynet2/cmd/sky' do
      system 'go build -a'

      bin.install 'sky'
    end

    unless build.without? 'skydaemon'
      cd 'src/github.com/skynetservices/skynet2/cmd/skydaemon' do
        system 'go build -a'

        bin.install 'skydaemon'

        mkdir_p 'lib/skynet'

        cd 'lib' do
          system 'touch skynet/.skystate'
          lib.install 'skynet'
        end
      end
    end
  end

  def caveats; <<-EOS.undent
    If ZooKeeper is not located at "localhost:2181", please set your SKYNET_ZOOKEEPER environment variable appropriately
    When using launchd you may also need to set your zookeeper enviroment variable there as well: launchctl setenv SKYNET_ZOOKEEPER host:2181
    EOS
  end

  plist_options :manual => "skydaemon"

  def plist; <<-EOS.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>KeepAlive</key>
      <true/>
      <key>Label</key>
      <string>skynet</string>
      <key>EnableGlobbing</key>
      <true/>
      <key>ProgramArguments</key>
      <array>
        <string>#{bin}/skydaemon</string>
      </array>
      <key>RunAtLoad</key>
      <true/>
      <key>StandardOutPath</key>
      <string>~/Library/Logs/skydaemon.log</string>

      <key>StandardErrorPath</key>
      <string>~/Library/Logs/skydaemon_err.log</string>
    </dict>
    </plist>
    EOS
  end
end
