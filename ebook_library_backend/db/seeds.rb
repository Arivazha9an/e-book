# Creates a few demo ebooks so the Flutter app has something to show
# immediately after `rails db:seed`. Uses the same fixture PDF the test
# suite uses, so no external files are required.

sample_pdf_path = Rails.root.join("spec/fixtures/files/sample.pdf")

demo_books = [
  { title: "The Pragmatic Programmer", author: "David Thomas & Andrew Hunt" },
  { title: "Clean Code", author: "Robert C. Martin" },
  { title: "Domain-Driven Design", author: "Eric Evans" },
  { title: "Design Patterns", author: "Gang of Four" }
]

demo_books.each do |attrs|
  ebook = Ebook.find_or_initialize_by(title: attrs[:title])
  next if ebook.persisted?

  ebook.author = attrs[:author]
  ebook.file.attach(
    io: File.open(sample_pdf_path),
    filename: "#{attrs[:title].parameterize}.pdf",
    content_type: "application/pdf"
  )
  ebook.total_pages = rand(120..400)
  ebook.save!
  puts "Seeded: #{ebook.title}"
end
