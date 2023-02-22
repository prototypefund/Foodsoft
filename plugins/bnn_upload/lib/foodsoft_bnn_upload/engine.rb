module FoodsoftBnnUpload
  class Engine < ::Rails::Engine
    config.to_prepare do
      Dir.glob(Rails.root + "app/decorators/**/*_decorator*.rb").each do |c|
        require_dependency(c)
      end
    end
    def default_foodsoft_config(cfg)
      cfg[:use_bnn_upload] = true
    end
  end
end
