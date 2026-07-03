# Plain-Ruby serializer (no extra gem dependency) that turns an Ebook
# into the exact JSON shape documented in docs/API_DOCUMENTATION.md.
class EbookSerializer
  def initialize(ebook, request:)
    @ebook = ebook
    @request = request
  end

  def as_json(*)
    {
      id: ebook.id,
      title: ebook.title,
      author: ebook.author,
      description: ebook.description,
      file_type: ebook.file_type,
      file_size: ebook.file_size,
      original_filename: ebook.original_filename,
      cover_url: cover_url,
      download_url: download_url,
      created_at: ebook.created_at.iso8601,
      updated_at: ebook.updated_at.iso8601,
      progress: {
        current_page: ebook.current_page,
        total_pages: ebook.total_pages,
        last_position: ebook.last_position,
        percent: ebook.progress_percent,
        last_opened_at: ebook.last_opened_at&.iso8601
      }
    }
  end

  private

  attr_reader :ebook, :request

  def cover_url
    return nil unless ebook.cover_image.attached?

    Rails.application.routes.url_helpers.rails_blob_url(
      ebook.cover_image,
      host: request.base_url
    )
  end

  def download_url
    Rails.application.routes.url_helpers.download_api_v1_ebook_url(
      ebook,
      host: request.base_url
    )
  end
end
