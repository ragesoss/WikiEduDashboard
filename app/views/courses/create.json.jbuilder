json.course do
  json.call(@course, :title, :description,
            :start, :end, :school, :term, :subject, :slug)
end
