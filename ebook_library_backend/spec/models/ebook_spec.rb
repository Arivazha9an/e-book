require "rails_helper"

RSpec.describe Ebook, type: :model do
  describe "validations" do
    it "is valid with a title and an attached PDF" do
      ebook = build(:ebook)
      expect(ebook).to be_valid
    end

    it "is invalid without a title" do
      ebook = build(:ebook, title: nil)
      expect(ebook).not_to be_valid
      expect(ebook.errors[:title]).to include("can't be blank")
    end

    it "is invalid without an attached file" do
      ebook = Ebook.new(title: "No File Book")
      expect(ebook).not_to be_valid
      expect(ebook.errors[:file]).to include("must be attached")
    end

    it "rejects unsupported file types" do
      ebook = build(:ebook)
      ebook.file.attach(
        io: StringIO.new("not a real book"),
        filename: "notes.txt",
        content_type: "text/plain"
      )
      expect(ebook).not_to be_valid
      expect(ebook.errors[:file]).to include("must be a PDF or EPUB file")
    end

    it "rejects files larger than the configured maximum" do
      ebook = build(:ebook)
      oversized_blob = instance_double(
        ActiveStorage::Blob,
        content_type: "application/pdf",
        byte_size: Ebook::MAX_FILE_SIZE + 1,
        filename: ActiveStorage::Filename.new("huge.pdf")
      )
      allow(ebook.file).to receive(:attached?).and_return(true)
      allow(ebook.file).to receive(:blob).and_return(oversized_blob)

      expect(ebook).not_to be_valid
      expect(ebook.errors[:file].join).to match(/too large/)
    end
  end

  describe "#progress_percent" do
    it "computes percent from current_page and total_pages" do
      ebook = build(:ebook, current_page: 30, total_pages: 120)
      expect(ebook.progress_percent).to eq(25.0)
    end

    it "falls back to last_position when page counts are absent" do
      ebook = build(:ebook, current_page: nil, total_pages: nil, last_position: 0.42)
      expect(ebook.progress_percent).to eq(42.0)
    end

    it "returns 0 when no progress data exists yet" do
      ebook = build(:ebook, current_page: nil, total_pages: nil, last_position: nil)
      expect(ebook.progress_percent).to eq(0.0)
    end
  end

  describe "#update_progress!" do
    it "persists the new position and stamps last_opened_at" do
      ebook = create(:ebook)
      expect {
        ebook.update_progress!(current_page: 10, total_pages: 200, last_position: 0.05)
      }.to change(ebook, :current_page).to(10)
        .and change(ebook, :total_pages).to(200)
        .and change(ebook, :last_opened_at).from(nil)
    end

    it "keeps prior values when a field isn't provided" do
      ebook = create(:ebook, current_page: 5, total_pages: 100)
      ebook.update_progress!(last_position: 0.5)
      expect(ebook.reload.current_page).to eq(5)
      expect(ebook.reload.total_pages).to eq(100)
    end
  end

  describe "scopes" do
    it ".search_by_keyword matches title, author, or filename" do
      match = create(:ebook, title: "The Pragmatic Programmer", author: "Hunt")
      create(:ebook, title: "Something Else", author: "Nobody")

      expect(Ebook.search_by_keyword("pragmatic")).to contain_exactly(match)
    end

    it ".by_file_type filters by inferred file type" do
      pdf = create(:ebook)
      expect(Ebook.by_file_type("pdf")).to include(pdf)
      expect(Ebook.by_file_type("epub")).not_to include(pdf)
    end

    it ".ordered(:title) sorts case-insensitively" do
      create(:ebook, title: "banana")
      create(:ebook, title: "Apple")

      expect(Ebook.ordered(:title).map(&:title)).to eq(%w[Apple banana])
    end
  end
end
