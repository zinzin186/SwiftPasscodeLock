Pod::Spec.new do |s|
s.name = 'PasscodeLock'
s.version = '3.0.2'
s.license = { :type => "MIT", :file => 'LICENSE.txt' }
s.summary = 'An iOS passcode lock with Touch ID authentication written in Swift.'
s.homepage = 'https://github.com/zahlz/SwiftPasscodeLock'
s.authors = { 'Yanko Dimitrov' => '', 'moogle19' => 'mail@kseidel.org' }
s.source = { :git => 'https://github.com/zahlz/SwiftPasscodeLock.git' }

s.ios.deployment_target = '9.0'

s.source_files = 'PasscodeLock/*.{h,swift}',
				 'PasscodeLock/*/*.{swift}'

s.resources = [
				'PasscodeLock/Views/PasscodeLockView.xib',
				'PasscodeLock/en.lproj/*',
                'Images/*.png',
                'Pod/Assets/*.xcassets',
                'Pod/Resources/Fonts/*.ttf'
			  ]

s.requires_arc = true
end
