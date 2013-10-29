require "action_view/template"
require "prawn"

ActionController::Renderers.add :pdf do |filename, options|
  GambasImage::PdfCreator.create (options[:pdf_options]) do |pdf|
    instance_eval render_to_string
  end
end

module GambasImage
  @options = {}
  
  def self.options
    @options
  end
  
  def self.configure (options)
    @options = options 
  end 
  
  class PdfCreator
    def self.create (options = nil)
      pdf = pdf_document(options)
      yield pdf
      pdf.render.html_safe
    end  

    def self.pdf_document (options = nil)
      _options = (GambasImage.options || {}).merge(options || {})
      Prawn::Document.new(_options)
    end
  end 
  
  class PDF 
    class_attribute :default_format
    self.default_format = :pdf
           
    def self.call (template)
      return new.call(template)
    end
    
    # delegates to the default ERB handler to return the source as is
    # this means that the instatiation of the Prawn::Document will happen 
    # in the renderer
    def call (template)
      handler = ActionView::Template.registered_template_handler("erb")
      handler.call(template)
    end
    
  end
  
  class Railtie < Rails::Railtie
    config.gambas_options = ActiveSupport::OrderedOptions.new
    
    initializer "gambas_options.configure" do |app|
      GambasImage.configure app.config.gambas_options
    end
    
    ActionView::Template.register_template_handler :prawn, GambasImage::PDF
  end
end


