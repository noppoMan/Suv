import PackageDescription

let package = Package(
	name: "Suv",
    targets: [
        Target(name: "ClusterTest", dependencies: ["Suv"])
    ],
	dependencies: [
      .Package(url: "https://github.com/noppoMan/CLibUv.git", majorVersion: 0, minor: 1),
      .Package(url: "https://github.com/slimane-swift/Core.git", majorVersion: 0, minor: 1),
      .Package(url: "https://github.com/Zewo/CPOSIX.git", majorVersion: 0, minor: 14)
  ]
)
