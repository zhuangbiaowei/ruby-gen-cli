# frozen_string_literal: true

begin
  require 'ruby_rich'
  RUBY_RICH_AVAILABLE = true
rescue LoadError
  RUBY_RICH_AVAILABLE = false
end

module RubyGenCli
  module UI
    # Progress display utilities using RubyRich
    class Progress
      attr_reader :config_manager

      def initialize(config_manager)
        @config_manager = config_manager
      end

      # Create a progress bar for determinate tasks
      def bar(description, total:, &block)
        if RUBY_RICH_AVAILABLE
          style = @config_manager.get('ui.progress_style', 'bar')
          
          progress_bar = RubyRich::ProgressBar.new(
            description,
            total: total,
            style: style
          )
          
          if block_given?
            progress_bar.with_progress(&block)
          else
            progress_bar
          end
        else
          # Fallback to simple progress
          puts("#{description} [0/#{total}]")
          if block_given?
            (1..total).each do |i|
              result = yield
              puts("#{description} [#{i}/#{total}]")
            end
            result
          end
        end
      end

      # Create a spinner for indeterminate tasks
      def spinner(description, &block)
        print("⏳ #{description}... ")
        
        if block_given?
          begin
            result = yield
            puts("✅ Done")
            result
          rescue StandardError => e
            puts("❌ Failed: #{e.message}")
            raise
          end
        end
      end

      # Step-by-step progress indicator
      def steps(total_steps, &block)
        current_step = 0
        
        step_proc = proc do |description = nil|
          current_step += 1
          percentage = (current_step.to_f / total_steps * 100).round(1)
          
          status = "[#{current_step}/#{total_steps}] (#{percentage}%)"
          status += " #{description}" if description
          
          puts(status)
        end
        
        if block_given?
          yield(step_proc)
        else
          step_proc
        end
      end

      # Multi-task progress display
      def multi_task(tasks, &block)
        completed = 0
        total = tasks.length
        
        task_proc = proc do |task_name|
          puts("Starting: #{task_name}")
          
          begin
            result = yield(task_name) if block_given?
            completed += 1
            percentage = (completed.to_f / total * 100).round(1)
            puts("✅ Completed: #{task_name} [#{completed}/#{total}] (#{percentage}%)")
            result
          rescue StandardError => e
            puts("❌ Failed: #{task_name} - #{e.message}")
            raise
          end
        end
        
        tasks.each(&task_proc)
      end

      # Time-based progress (e.g., for streaming operations)
      def timed(description, duration: nil)
        start_time = Time.now
        print("⏳ #{description}... ")
        
        if duration
          # Show estimated completion
          Thread.new do
            sleep(duration)
            elapsed = Time.now - start_time
            puts("\n⏱️  Completed in #{elapsed.round(2)} seconds")
          end
        end
        
        yield if block_given?
        
        elapsed = Time.now - start_time
        puts("✅ Done (#{elapsed.round(2)}s)")
      end

      # File operation progress
      def file_operation(operation, files, &block)
        total_files = files.length
        processed = 0
        
        puts("#{operation} #{total_files} files...")
        
        files.each do |file|
          processed += 1
          percentage = (processed.to_f / total_files * 100).round(1)
          
          print("\r[#{processed}/#{total_files}] (#{percentage}%) #{File.basename(file)}")
          
          yield(file) if block_given?
        end
        
        puts("\n✅ #{operation} completed for #{total_files} files")
      end

      # Download progress simulation
      def download(description, size: nil, &block)
        if size
          bar(description, total: size, &block)
        else
          spinner(description, &block)
        end
      end

      # Installation/setup progress
      def installation(steps, &block)
        total_steps = steps.length
        current_step = 0
        
        puts("🚀 Installation Progress")
        puts("=" * 50)
        
        steps.each do |step_description|
          current_step += 1
          percentage = (current_step.to_f / total_steps * 100).round(1)
          
          print("#{current_step}. #{step_description}... ")
          
          begin
            yield(step_description, current_step) if block_given?
            puts("✅")
          rescue StandardError => e
            puts("❌ Error: #{e.message}")
            raise
          end
        end
        
        puts("=" * 50)
        puts("🎉 Installation completed successfully!")
      end

      # Build progress (for compilation, etc.)
      def build(description, stages: [], &block)
        puts("🔨 #{description}")
        puts("-" * 50)
        
        if stages.empty?
          spinner("Building", &block)
        else
          stages.each_with_index do |stage, index|
            stage_num = index + 1
            puts("Stage #{stage_num}: #{stage}")
            
            begin
              yield(stage, stage_num) if block_given?
              puts("✅ Stage #{stage_num} completed")
            rescue StandardError => e
              puts("❌ Stage #{stage_num} failed: #{e.message}")
              raise
            end
          end
        end
        
        puts("-" * 50)
        puts("✅ Build completed successfully!")
      end

      # Test progress
      def test_suite(test_categories, &block)
        total_categories = test_categories.length
        passed_categories = 0
        
        puts("🧪 Running Test Suite")
        puts("=" * 50)
        
        test_categories.each do |category|
          print("Testing #{category[:name]}... ")
          
          begin
            result = yield(category) if block_given?
            
            if result[:passed]
              puts("✅ #{result[:passed]} tests passed")
              passed_categories += 1
            else
              puts("❌ Some tests failed")
            end
            
            if result[:failed] && result[:failed] > 0
              puts("   ❗ #{result[:failed]} tests failed")
            end
            
          rescue StandardError => e
            puts("❌ Error running tests: #{e.message}")
          end
        end
        
        puts("=" * 50)
        puts("📊 Results: #{passed_categories}/#{total_categories} test categories passed")
      end

      private

      def print(text)
        STDOUT.print(text)
        STDOUT.flush
      end

      def puts(text)
        STDOUT.puts(text)
        STDOUT.flush
      end
    end
  end
end