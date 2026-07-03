FactoryBot.define do
  factory :ebook do
    title { Faker::Book.title }
    author { Faker::Book.author }
    description { Faker::Lorem.sentence }

    after(:build) do |ebook|
      ebook.file.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/sample.pdf")),
        filename: "sample.pdf",
        content_type: "application/pdf"
      )
    end
  end
end
