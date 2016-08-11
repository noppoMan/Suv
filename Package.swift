import PackageDescription

let package = Package(
	name: "Suv",
    targets: [
        Target(name: "ClusterTest", dependencies: ["Suv"])
    ],
	dependencies: [
      .Package(url: "https://github.com/noppoMan/swifty-libuv.git", majorVersion: 0, minor: 3),
      .Package(url: "https://github.com/slimane-swift/Time.git", majorVersion: 0, minor: 2),
      .Package(url: "https://github.com/open-swift/C7.git", majorVersion: 0, minor: 12)
  ]
)
