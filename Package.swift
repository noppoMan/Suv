import PackageDescription

let package = Package(
	name: "Suv",
    targets: [
        Target(name: "ClusterTest", dependencies: ["Suv"])
    ],
	dependencies: [
      .Package(url: "https://github.com/noppoMan/swifty-libuv.git", majorVersion: 0, minor: 6),
      .Package(url: "https://github.com/slimane-swift/Core.git", majorVersion: 0, minor: 1)
  ]
)
