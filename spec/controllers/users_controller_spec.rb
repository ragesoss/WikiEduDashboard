require 'rails_helper'

describe UsersController do
  describe '#enroll' do
    let!(:course) { create(:course) }
    let(:request_params) do
      { course_id: course.slug, passcode: course.passcode, titleterm: 'foobar' }
    end
    let(:user) { create(:user) }
    let(:admin) { create(:admin) }

    before do
      allow(WikiEdits).to receive(:enroll_in_course)
      allow(WikiEdits).to receive(:update_course)
      allow(WikiEdits).to receive(:remove_assignment)
      allow(WikiEdits).to receive(:update_assignments)
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:require_participating_user)
    end

    subject { response.status }

    context 'POST, when the user is not part of the course' do
      let(:post_params) do
        { id: course.slug,
          user: { user_id: user.id, role: CoursesUsers::Roles::STUDENT_ROLE }.as_json }
      end
      before { post 'enroll', post_params }
      it 'creates a CoursesUsers' do
        expect(CoursesUsers.count).to eq(1)
      end
      it 'renders a json template' do
        expect(subject).to render_template('users')
      end
      it 'succeeds' do
        expect(subject).to eq(200)
      end
    end

    context 'POST with student role, when the user is the instructor' do
      let(:post_params) do
        { id: course.slug,
          user: { user_id: user.id, role: CoursesUsers::Roles::STUDENT_ROLE }.as_json }
      end
      before do
        create(:courses_user, user_id: user.id,
                              course_id: course.id,
                              role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
        post 'enroll', post_params
      end
      it 'returns a 404' do
        expect(subject).to eq(404)
      end
      it 'does not enroll the user' do
        expect(CoursesUsers.where(role: CoursesUsers::Roles::STUDENT_ROLE).count).to eq(0)
      end
    end

    context 'POST with nonstudent role, when the user is an admin' do
      let(:post_params) do
        { id: course.slug,
          user: { user_id: admin.id, role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE }.as_json }
      end
      before do
        post 'enroll', post_params
      end
      it 'returns a 200' do
        expect(subject).to eq(200)
      end
      it 'enrolls the user' do
        expect(CoursesUsers.where(role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE).count).to eq(1)
      end
    end

    context 'DELETE' do
      let(:delete_params) do
        { id: course.slug,
          user: { user_id: user.id, role: CoursesUsers::Roles::STUDENT_ROLE }.as_json }
      end
      before do
        create(:courses_user, user_id: user.id,
                              course_id: course.id,
                              role: CoursesUsers::Roles::STUDENT_ROLE)
        article = create(:article)
        create(:assignment,
               course_id: course.id,
               user_id: user.id,
               article_id: article.id)
        delete 'enroll', delete_params
      end
      it 'destroys the courses user' do
        expect(CoursesUsers.count).to eq(0)
      end
      it 'succeeds' do
        expect(subject).to eq(200)
      end
    end
  end
end
