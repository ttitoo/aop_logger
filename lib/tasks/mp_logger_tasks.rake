# frozen_string_literal: true

Rake::Task['assets:precompile'].enhance do
  Rake::Task['miracle_plus:logger:copy_assets'].invoke
end

namespace :miracle_plus do
  namespace :logger do
    task :copy_assets do
      system("cd #{MiraclePlus::Logger::Engine.root};yarn run build")
      dir = File.join(MiraclePlus::Logger::Engine.root, 'dist')
      Dir.glob("#{dir}/*").map do |asset|
        dst = File.join(Rails.root, 'public', 'assets', File.basename(asset))
        FileUtils.copy_file(asset, dst, true)
      end
    end
  end
end
