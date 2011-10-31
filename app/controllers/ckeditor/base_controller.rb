class Ckeditor::BaseController < ApplicationController
  respond_to :html, :json
  layout "ckeditor"
  
  before_filter :set_locale
  before_filter :find_asset, :only => [:destroy]
  before_filter :find_assetable
  before_filter :ckeditor_authenticate
  skip_filter :verify_authenticity_token

  protected
    
    def set_locale
      if !params[:langCode].blank? && I18n.available_locales.include?(params[:langCode].to_sym)
        I18n.locale = params[:langCode]
      end
    end
    
    def respond_with_asset(asset)
      file = params[:CKEditor].blank? ? params[:qqfile] : params[:upload]
	    asset.data = Ckeditor::Http.normalize_param(file, request)
	    asset.assetable = @assetable || (current_user if respond_to?(:current_user))

	    callback = ckeditor_before_create_asset(asset)
	    
      if callback && asset.save
        body = params[:CKEditor].blank? ? asset.to_json(:only=>[:id, :type]) : %Q"<script type='text/javascript'>
          window.parent.CKEDITOR.tools.callFunction(#{params[:CKEditorFuncNum]}, '#{Ckeditor::Utils.escape_single_quotes(asset.url_content)}');
        </script>"
        
        render :text => body
      else
        Rails.logger.error "[Ckeditor] Error: #{asset.errors.full_messages}" rescue nil
        render :text => %|<script type="text/javascript">alert("Error: #{asset.errors.full_messages}");</script>|
      end
    end


    def find_assetable
      @assetable = params[:assetable_type].constantize.find(params[:assetable_id]) if params[:assetable_id].present? && params[:assetable_type].present?
      true
    end

end
