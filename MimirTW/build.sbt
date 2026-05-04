ThisBuild / scalaVersion := "3.8.3"

lazy val root = (project in file("."))
  .settings(
    name := "MimirTW",
    idePackagePrefix := Some("tree.walk.mimir")
  )
