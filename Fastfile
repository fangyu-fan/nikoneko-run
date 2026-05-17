default_platform(:ios)

platform :ios do
  desc "Run tests"
  lane :test do
    run_tests(
      scheme: "nikoneko",
      device: "iPhone 15 Pro"
    )
  end

  desc "Build and upload to TestFlight"
  lane :beta do
    build_app(scheme: "nikoneko")
    upload_to_testflight(skip_waiting_for_build_processing: true)
  end

  desc "Submit to App Store"
  lane :release do
    build_app(scheme: "nikoneko")
    upload_to_app_store
  end
end
