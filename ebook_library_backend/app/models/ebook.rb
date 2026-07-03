# == Ebook ==
#
# Represents a single ebook in the library, including its metadata,
# the underlying file (PDF/EPUB) and an optional cover image.
# Reading progress ("continue where they left off") is stored directly
# on the record since this is a single-user library.
class Ebook < ApplicationRecord
  ALLOWED_CONTENT_TYPES = %w[application/pdf application/epub+zip].freeze
  MAX_FILE_SIZE = 50.megabytes

  has_one_attached :file
  has_one_attached :cover_image

  before_validation :set_file_metadata, if: -> { file.attached? && file.blob.present? }

  validates :title, presence: true, length: { maximum: 255 }
  validates :author, length: { maximum: 255 }
  validate :file_must_be_attached
  validate :file_type_must_be_supported
  validate :file_size_must_be_within_limit

  # current_page / total_pages / last_position track exactly how far the
  # reader has gotten, so the Flutter app can re-open a book at the same
  # spot instead of always starting from page 1.
  validates :current_page, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :total_pages, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :last_position, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }, allow_nil: true

  scope :search_by_keyword, lambda { |query|
    return all if query.blank?

    sanitized = "%#{sanitize_sql_like(query.strip)}%"
    where(
      "title LIKE :q OR author LIKE :q OR original_filename LIKE :q",
      q: sanitized
    )
  }

  scope :by_file_type, ->(type) { type.present? ? where(file_type: type) : all }

  scope :ordered, lambda { |sort_key|
    case sort_key.to_s
    when "title" then order(Arel.sql("LOWER(title) ASC"))
    when "author" then order(Arel.sql("LOWER(author) ASC"))
    when "oldest" then order(created_at: :asc)
    when "recently_read" then order(Arel.sql("last_opened_at IS NULL, last_opened_at DESC"))
    else order(created_at: :desc) # "recent" (default): newest uploads first
    end
  }

  # Percentage (0-100) derived from current_page/total_pages, falling back
  # to last_position when page counts aren't known (e.g. some EPUB readers
  # report a scroll fraction rather than a page number).
  def progress_percent
    if total_pages.present? && total_pages.positive? && current_page.present?
      ((current_page.to_f / total_pages) * 100).round(1).clamp(0, 100)
    elsif last_position.present?
      (last_position * 100).round(1)
    else
      0.0
    end
  end

  def update_progress!(current_page: nil, total_pages: nil, last_position: nil)
    update!(
      current_page: current_page || self.current_page,
      total_pages: total_pages || self.total_pages,
      last_position: last_position || self.last_position,
      last_opened_at: Time.current
    )
  end

  private

  def set_file_metadata
    self.original_filename = file.blob.filename.to_s if original_filename.blank?
    self.file_size = file.blob.byte_size
    self.file_type = infer_file_type(file.blob.content_type)
  end

  def infer_file_type(content_type)
    case content_type
    when "application/pdf" then "pdf"
    when "application/epub+zip" then "epub"
    else content_type
    end
  end

  def file_must_be_attached
    errors.add(:file, "must be attached") unless file.attached?
  end

  def file_type_must_be_supported
    return unless file.attached? && file.blob.present?

    unless ALLOWED_CONTENT_TYPES.include?(file.blob.content_type)
      errors.add(:file, "must be a PDF or EPUB file")
    end
  end

  def file_size_must_be_within_limit
    return unless file.attached? && file.blob.present?

    if file.blob.byte_size > MAX_FILE_SIZE
      errors.add(:file, "is too large (maximum is #{MAX_FILE_SIZE / 1.megabyte}MB)")
    end
  end
end
