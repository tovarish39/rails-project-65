# frozen_string_literal: true

module Web
  class BulletinsController < Web::ApplicationController
    before_action :set_bulletin, only: %i[show edit update archive to_moderate]
    after_action :verify_authorized, only: %i[show new create edit update archive to_moderate]

    def index
      @q = Bulletin.published.ransack(params[:q])
      @bulletins = @q
                   .result
                   .with_attached_image
                   .includes(:category)
                   .order(created_at: :desc)
                   .page(params[:page])
                   .per(12)
    end

    def show
      authorize @bulletin
    end

    def new
      @bulletin = Bulletin.new
      authorize @bulletin
    end

    def edit
      authorize @bulletin
    end

    def create
      @bulletin = Bulletin.new(bulletin_params)
      authorize @bulletin

      @bulletin.user = current_user

      if @bulletin.save
        redirect_to profile_path, notice: t('.notice')
      else
        flash[:alert] = t('.alert')
        render :new, status: :unprocessable_entity
      end
    end

    def update
      authorize @bulletin

      if @bulletin.update(bulletin_params)
        redirect_to profile_path, notice: t('.notice')
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def to_moderate
      authorize @bulletin
      if @bulletin.may_to_moderate?
        @bulletin.to_moderate
        @bulletin.save
        flash[:notice] = t('.notice')
      else
        flash[:alert] = t('.alert')
      end
      redirect_to profile_path
    end

    def archive
      authorize @bulletin
      if @bulletin.may_archive?
        @bulletin.archive
        @bulletin.save
        flash[:notice] = t('.notice')
      else
        flash[:alert] = t('.alert')
      end
      redirect_to profile_path
    end

    private

    def bulletin_params
      params.require(:bulletin).permit(:title, :description, :category_id, :image)
    end
  end
end
