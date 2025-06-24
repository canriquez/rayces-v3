Post.delete_all

Post.create!(
  post_id: 1,
  hash_id: "eadef8f7b6e108b830c3bb388803bbf190e4684f9034a722258ea87124d6f02c",
  source: "docusaurus",
  metadata: {
    "summary" => "This blog post by @henrytg discusses the implementation of dynamic status color adjustment based on Android headers. The solution involves extracting and checking app version and device information from the `user-agent` header and using it to retrieve status colors from the Forms API. The addition of support for status color in older app versions via this method enhances the functionality of the form controller.",
    "tags" => ["status color", "mobile", "spike"],
    "slug" => "status-color-support-for-older-app-versions",
    "authors" => ["henrytg"],
    "title" => "Implementation of dynamic status color adjustment based on Android headers",
    "creation_date" => "2024-04-15"
  }.to_json,
  filename: "2024-04-15-status-color-old-versions-support.md"
)

Post.create!(
  post_id: 2,
  hash_id: "26996d8f3fc1cebc969d1ac089e643f66224bb2a258b4d1a6d4392dc52e8a858",
  source: "docusaurus",
  metadata: {
    "summary" => "This post by @osbornk discusses session validation for Kratos, an authentication software. The blog compares two validation methods: using Redis from Rails and Oathkeeper, a service for validating HTTP requests. Both methods have advantages and disadvantages, ultimately the choice depends on the specific requirements and setup of the system.",
    "tags" => ["security", "authentication"],
    "slug" => "kratos-session-validation",
    "authors" => ["osbornk"],
    "title" => "Session validation for Kratos, comparing Redis from Rails and Oathkeeper",
    "creation_date" => "2023-12-14"
  }.to_json,
  filename: "2023-12-14-kratos-session-validation.md"
)

Post.create!(
  post_id: 3,
  hash_id: "d82fef39d6c3698248eb9ef86dce32720df8b6b89296285321b666e8306fb39c",
  source: "docusaurus",
  metadata: {
    "summary" => "This blogpost by @kdiedrick, discusses the enhancements and improvements brought by using Vite as the bundler tool for the MyHub-components project, enabling faster development through its automatic chunking, hot module reloading, and reduced bundle size. Vite also aligns the project with modern toolchains and leverages existing tools like esbuild and rollup, offering a simplified and efficient bundle process.",
    "tags" => ["bundling", "vite", "ui", "ux"],
    "slug" => "vite-bundler",
    "authors" => ["kdiedrick"],
    "title" => "Enhancements and improvements with Vite as the bundler tool",
    "creation_date" => "2024-04-16"
  }.to_json,
  filename: "2024-04-16-vite-bundler.md"
)

Post.create!(
  post_id: 4,
  hash_id: "fee4607e9310eb0ff49573626eeb1504871ec71e911004b866e1065623d79a07",
  source: "docusaurus",
  metadata: {
    "summary" => "This blog post by @toddrun describes the upcoming changes to how MyHub outputs KML files, which aim to improve compatibility and renderability within Google Earth. The updates include using an updated library for Koop and a new approach for DataExports to overcome issues with invalid `<Icon>` urls and inconsistent output.",
    "tags" => ["kml", "shared views", "data downloader"],
    "slug" => "updating-kml-output",
    "authors" => ["toddrun"],
    "title" => "Upcoming changes to how MyHub outputs KML files",
    "creation_date" => "2024-05-15"
  }.to_json,
  filename: "2024-05-15-updating-kml-output.md"
)

Post.create!(
  post_id: 5,
  hash_id: "a24261cc255c03e28a7b2895e332637bac39b378f7bff9b769a5c405cfcb46f9",
  source: "docusaurus",
  metadata: {
    "summary" => "This blog post, penned by HenryTG and OsbornK, investigates webhook staleness after a Sidekiq 7 upgrade. Their findings indicate persistent unprocessed events and inactive webhooks still receiving data. They propose clarifying the definition of \"processed\" status, refining retry logic, and enhancing monitoring for inactive webhooks to improve system efficiency.",
    "tags" => ["webhooks", "followup", "sidekiq"],
    "slug" => "addressing-webhook-staleness",
    "authors" => ["henrytg", "osbornk"],
    "title" => "Investigating webhook staleness after a Sidekiq 7 upgrade",
    "creation_date" => "2024-04-26"
  }.to_json,
  filename: "2024-04-26-adressing-webhook-staleness.md"
)
