import PackageDescription

#if os(OSX)
    let openSSLRepo = "https://github.com/noppoMan/COpenSSL-OSX.git"
#else
    let openSSLRepo = "https://github.com/noppoMan/COpenSSL.git"
#endif

let package = Package(
	name: "Suv",
	dependencies: [
      .Package(url: "https://github.com/noppoMan/CLibUv.git", majorVersion: 0, minor: 1),
      .Package(url: openSSLRepo, majorVersion: 0, minor: 1)
  ]
)
