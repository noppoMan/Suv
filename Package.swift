import PackageDescription

let package = Package(
	name: "Suv",
	dependencies: [
      .Package(url: "https://github.com/noppoMan/swifty-libuv.git", majorVersion: 0, minor: 1),
      .Package(url: "https://github.com/slimane-swift/Time.git", majorVersion: 0, minor: 2),
      .Package(url: "https://github.com/open-swift/C7", majorVersion: 0, minor: 9),
  ]
)
