import PackageDescription

let package = Package(
	name: "Suv",
	dependencies: [
      .Package(url: "https://github.com/noppoMan/CLibUv.git", majorVersion: 0, minor: 1)
  ]
)
