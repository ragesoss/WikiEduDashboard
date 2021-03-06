course_meetings_manager = CourseMeetingsManager.new(course)

json.weeks course.weeks.eager_load(blocks: [:gradeable]) do |week|
  json.call(week, :id, :title, :order)
  json.blocks week.blocks do |block|
    json.call(block, :id, :kind, :content, :week_id,
              :gradeable_id, :title, :order, :due_date,
              :training_module_ids)
    unless block.gradeable.nil?
      json.gradeable block.gradeable, :id, :title, :points,
                     :gradeable_item_type, :gradeable_item_id
    end
    if block.training_modules.any?
      json.training_modules block.training_modules do |tm|
        progress_manager = TrainingProgressManager.new(current_user, tm)
        due_date_manager = TrainingModuleDueDateManager.new(
          course: course,
          training_module: tm,
          user: current_user,
          course_meetings_manager: course_meetings_manager
        )
        json.call(tm, :slug, :id, :name)
        json.module_progress progress_manager.module_progress
        json.due_date due_date_manager.computed_due_date
        json.overdue due_date_manager.overdue?
        json.deadline_status due_date_manager.deadline_status
      end
    end
  end
end
