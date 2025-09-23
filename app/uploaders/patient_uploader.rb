class PatientUploader < CarrierWave::Uploader::Base
    storage :file
  
    def store_dir
      if Rails.env.production?
        "/#{ENV['NFS_PATH']}/revamp-dts/#{model.class.to_s.underscore}/#{model.created_at.year}/#{model.created_at.month}/#{model.created_at.to_date.strftime('%d')}/#{mounted_as}/#{model.try(:id)}"
      else
        "/home/idrees/Downloads/#{model.class.to_s.underscore}/#{model.created_at.year}/#{model.created_at.month}/#{model.created_at.strftime('%d')}/#{mounted_as}/#{model.try(:id)}"
      end
    end

    def extension_whitelist
      %w[jpg jpeg pdf]
    end
  
    def content_type_whitelist
      [/image\//, 'application/pdf']
    end
end