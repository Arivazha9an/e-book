module Api
  module V1
    class EbooksController < ApplicationController
      before_action :set_ebook, only: %i[show destroy download progress update_progress]

      DEFAULT_PER_PAGE = 20
      MAX_PER_PAGE = 50

      # GET /api/v1/ebooks?page=1&per_page=20&sort=recent&file_type=pdf
      def index
        ebooks = Ebook.by_file_type(params[:file_type]).ordered(params[:sort])
        render_paginated(ebooks)
      end

      # GET /api/v1/ebooks/search?q=keyword&page=1&per_page=20
      def search
        query = params[:q]
        ebooks = Ebook.search_by_keyword(query).by_file_type(params[:file_type]).ordered(params[:sort])
        render_paginated(ebooks, query: query)
      end

      # GET /api/v1/ebooks/:id
      def show
        render json: EbookSerializer.new(@ebook, request: request).as_json
      end

      # POST /api/v1/ebooks
      # multipart/form-data with:
      #   ebook[title]        (required)
      #   ebook[author]       (optional)
      #   ebook[description]  (optional)
      #   ebook[file]         (required - the PDF/EPUB)
      #   ebook[cover_image]  (optional)
      def create
        ebook = Ebook.new(ebook_params)

        if ebook.save
          render json: EbookSerializer.new(ebook, request: request).as_json, status: :created
        else
          render json: { errors: ebook.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/ebooks/:id
      def destroy
        @ebook.destroy
        head :no_content
      end

      # GET /api/v1/ebooks/:id/download
      def download
        unless @ebook.file.attached?
          return render json: { error: "No file attached to this ebook" }, status: :not_found
        end

        redirect_to rails_blob_url(@ebook.file, disposition: "attachment"), allow_other_host: true
      end

      # GET /api/v1/ebooks/:id/progress
      def progress
        render json: {
          ebook_id: @ebook.id,
          current_page: @ebook.current_page,
          total_pages: @ebook.total_pages,
          last_position: @ebook.last_position,
          percent: @ebook.progress_percent,
          last_opened_at: @ebook.last_opened_at&.iso8601
        }
      end

      # PATCH /api/v1/ebooks/:id/progress
      # body: { "current_page": 42, "total_pages": 300, "last_position": 0.14 }
      # Called by the Flutter reader whenever the user changes page / closes
      # the book, so the app can resume at the same spot next time it's opened.
      def update_progress
        if @ebook.update_progress!(
          current_page: params[:current_page],
          total_pages: params[:total_pages],
          last_position: params[:last_position]
        )
          render json: {
            ebook_id: @ebook.id,
            current_page: @ebook.current_page,
            total_pages: @ebook.total_pages,
            last_position: @ebook.last_position,
            percent: @ebook.progress_percent,
            last_opened_at: @ebook.last_opened_at&.iso8601
          }
        else
          render json: { errors: @ebook.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: [e.message] }, status: :unprocessable_entity
      end

      private

      def set_ebook
        @ebook = Ebook.find(params[:id])
      end

      def ebook_params
        params.require(:ebook).permit(:title, :author, :description, :file, :cover_image)
      end

      def render_paginated(scope, extra_meta = {})
        per_page = [ (params[:per_page] || DEFAULT_PER_PAGE).to_i, MAX_PER_PAGE ].min
        per_page = DEFAULT_PER_PAGE if per_page <= 0
        page = [ (params[:page] || 1).to_i, 1 ].max

        paginated = scope.page(page).per(per_page)

        render json: {
          data: paginated.map { |ebook| EbookSerializer.new(ebook, request: request).as_json },
          meta: {
            current_page: paginated.current_page,
            per_page: per_page,
            total_pages: paginated.total_pages,
            total_count: paginated.total_count,
            **extra_meta
          }
        }
      end
    end
  end
end
