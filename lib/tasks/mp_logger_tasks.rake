# frozen_string_literal: true

# 当调用 rake assets:precompile 时，会自动调用 miracle_plus:logger:copy_assets 任务
Rake::Task['assets:precompile'].enhance do
  Rake::Task['miracle_plus:logger:copy_assets'].invoke
end

namespace :miracle_plus do
  namespace :logger do
    task :copy_assets do
      # 进入根目录，运行 yarn install 和 yarn run build
      system("cd #{MiraclePlus::Logger::Engine.root};yarn install;yarn run build")
      
      # 将编译后的文件拷贝到 public/assets 目录下
      dir = File.join(MiraclePlus::Logger::Engine.root, 'dist')
      Dir.glob("#{dir}/*").each do |asset|
        dst = File.join(Rails.root, 'public', 'assets', File.basename(asset))
        FileUtils.copy_file(asset, dst, true)
      end
    end
  end
end
