require "rails_helper"

RSpec.describe "Api::V1::Ebooks", type: :request do
  let(:sample_pdf) do
    fixture_file_upload(Rails.root.join("spec/fixtures/files/sample.pdf"), "application/pdf")
  end

  describe "GET /api/v1/ebooks" do
    it "returns a paginated envelope with data and meta" do
      create_list(:ebook, 3)

      get "/api/v1/ebooks", params: { page: 1, per_page: 2 }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].length).to eq(2)
      expect(body["meta"]).to include(
        "current_page" => 1,
        "per_page" => 2,
        "total_count" => 3,
        "total_pages" => 2
      )
    end

    it "returns the second page correctly" do
      create_list(:ebook, 3)

      get "/api/v1/ebooks", params: { page: 2, per_page: 2 }

      body = JSON.parse(response.body)
      expect(body["data"].length).to eq(1)
      expect(body["meta"]["current_page"]).to eq(2)
    end

    it "returns an empty data array when the library is empty" do
      get "/api/v1/ebooks"

      body = JSON.parse(response.body)
      expect(body["data"]).to eq([])
      expect(body["meta"]["total_count"]).to eq(0)
    end

    it "caps per_page at the configured maximum" do
      create_list(:ebook, 3)

      get "/api/v1/ebooks", params: { per_page: 1000 }

      body = JSON.parse(response.body)
      expect(body["meta"]["per_page"]).to eq(Api::V1::EbooksController::MAX_PER_PAGE)
    end

    it "sorts by title when requested" do
      create(:ebook, title: "Zebra")
      create(:ebook, title: "Apple")

      get "/api/v1/ebooks", params: { sort: "title" }

      titles = JSON.parse(response.body)["data"].map { |e| e["title"] }
      expect(titles).to eq(%w[Apple Zebra])
    end
  end

  describe "GET /api/v1/ebooks/search" do
    it "finds ebooks matching the query in title or author" do
      match = create(:ebook, title: "Domain-Driven Design", author: "Evans")
      create(:ebook, title: "Clean Code", author: "Martin")

      get "/api/v1/ebooks/search", params: { q: "domain" }

      body = JSON.parse(response.body)
      expect(body["data"].map { |e| e["id"] }).to eq([match.id])
      expect(body["meta"]["query"]).to eq("domain")
    end

    it "returns an empty result set (not an error) when nothing matches" do
      create(:ebook, title: "Clean Code")

      get "/api/v1/ebooks/search", params: { q: "nonexistent-xyz" }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"]).to eq([])
    end

    it "supports pagination on search results" do
      create_list(:ebook, 3, title: "Ruby Basics")

      get "/api/v1/ebooks/search", params: { q: "ruby", per_page: 2, page: 1 }

      body = JSON.parse(response.body)
      expect(body["data"].length).to eq(2)
      expect(body["meta"]["total_count"]).to eq(3)
    end
  end

  describe "POST /api/v1/ebooks" do
    it "uploads a new ebook with valid params" do
      expect {
        post "/api/v1/ebooks", params: {
          ebook: { title: "New Book", author: "Some Author", file: sample_pdf }
        }
      }.to change(Ebook, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["title"]).to eq("New Book")
      expect(body["file_type"]).to eq("pdf")
      expect(body["download_url"]).to be_present
    end

    it "rejects an upload without a title" do
      expect {
        post "/api/v1/ebooks", params: { ebook: { file: sample_pdf } }
      }.not_to change(Ebook, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to include("Title can't be blank")
    end

    it "rejects an upload without a file" do
      post "/api/v1/ebooks", params: { ebook: { title: "No File" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to include("File must be attached")
    end

    it "rejects unsupported file types" do
      bad_file = fixture_file_upload(Rails.root.join("spec/fixtures/files/sample.txt"), "text/plain")

      post "/api/v1/ebooks", params: { ebook: { title: "Bad Type", file: bad_file } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"].join).to match(/PDF or EPUB/)
    end
  end

  describe "GET /api/v1/ebooks/:id" do
    it "returns ebook details" do
      ebook = create(:ebook)

      get "/api/v1/ebooks/#{ebook.id}"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["id"]).to eq(ebook.id)
    end

    it "returns 404 for a missing ebook" do
      get "/api/v1/ebooks/999999"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/ebooks/:id/download" do
    it "redirects to the file's blob URL" do
      ebook = create(:ebook)

      get "/api/v1/ebooks/#{ebook.id}/download"

      expect(response).to have_http_status(:found)
    end

    it "returns 404 when the ebook doesn't exist" do
      get "/api/v1/ebooks/999999/download"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/ebooks/:id" do
    it "deletes the ebook" do
      ebook = create(:ebook)

      expect {
        delete "/api/v1/ebooks/#{ebook.id}"
      }.to change(Ebook, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "returns 404 when deleting a missing ebook" do
      delete "/api/v1/ebooks/999999"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "reading progress ('continue where they left off')" do
    it "returns default (unread) progress for a freshly uploaded ebook" do
      ebook = create(:ebook)

      get "/api/v1/ebooks/#{ebook.id}/progress"

      body = JSON.parse(response.body)
      expect(body["current_page"]).to eq(0)
      expect(body["last_opened_at"]).to be_nil
    end

    it "updates and then returns the saved progress" do
      ebook = create(:ebook)

      patch "/api/v1/ebooks/#{ebook.id}/progress", params: {
        current_page: 57, total_pages: 320, last_position: 0.178
      }
      expect(response).to have_http_status(:ok)

      get "/api/v1/ebooks/#{ebook.id}/progress"
      body = JSON.parse(response.body)

      expect(body["current_page"]).to eq(57)
      expect(body["total_pages"]).to eq(320)
      expect(body["percent"]).to eq(17.8)
      expect(body["last_opened_at"]).to be_present
    end

    it "rejects an invalid current_page" do
      ebook = create(:ebook)

      patch "/api/v1/ebooks/#{ebook.id}/progress", params: { current_page: -5 }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
