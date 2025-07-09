# Pundit Authorization Example for Rayces Booking Platform
# This file demonstrates how to set up role-based authorization with Pundit

# app/policies/application_policy.rb
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    raise Pundit::NotAuthorizedError, "must be logged in" unless user
    @user = user
    @record = record
  end

  def index?
    user.admin? || user.staff?
  end

  def show?
    user.admin? || user.staff? || owner?
  end

  def create?
    user.admin? || user.staff?
  end

  def new?
    create?
  end

  def update?
    user.admin? || owner?
  end

  def edit?
    update?
  end

  def destroy?
    user.admin?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      raise Pundit::NotAuthorizedError, "must be logged in" unless user
      @user = user
      @scope = scope
    end

    def resolve
      if user.admin?
        scope.all
      else
        scope.none
      end
    end
  end

  private

  def owner?
    return false unless record.respond_to?(:user)
    record.user == user
  end
end

# app/policies/appointment_policy.rb
class AppointmentPolicy < ApplicationPolicy
  def index?
    true # All users can view appointments index
  end

  def show?
    user.admin? || user.staff? || parent_of_student? || assigned_professional?
  end

  def create?
    user.admin? || user.staff? || (user.parent? && parent_of_student?)
  end

  def update?
    case user.role
    when 'admin'
      true
    when 'staff'
      true
    when 'professional'
      assigned_professional? && !record.executed?
    when 'parent'
      parent_of_student? && record.draft?
    else
      false
    end
  end

  def destroy?
    user.admin? || (user.staff? && !record.executed?)
  end

  def confirm?
    user.admin? || user.staff? || assigned_professional?
  end

  def cancel?
    user.admin? || user.staff? || assigned_professional? || parent_of_student?
  end

  def execute?
    assigned_professional? && record.confirmed?
  end

  def view_notes?
    user.admin? || user.staff? || assigned_professional?
  end

  def edit_notes?
    user.admin? || user.staff? || assigned_professional?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      case user.role
      when 'admin'
        scope.all
      when 'staff'
        scope.all
      when 'professional'
        scope.where(professional: user)
      when 'parent'
        scope.where(parent: user)
      else
        scope.none
      end
    end
  end

  private

  def parent_of_student?
    record.parent == user
  end

  def assigned_professional?
    record.professional == user
  end
end

# app/policies/student_policy.rb
class StudentPolicy < ApplicationPolicy
  def index?
    user.admin? || user.staff? || user.professional?
  end

  def show?
    user.admin? || user.staff? || assigned_professional? || parent_of_student?
  end

  def create?
    user.admin? || user.staff?
  end

  def update?
    user.admin? || user.staff? || (user.professional? && assigned_professional?)
  end

  def destroy?
    user.admin?
  end

  def view_medical_info?
    user.admin? || user.staff? || assigned_professional?
  end

  def edit_medical_info?
    user.admin? || user.staff?
  end

  def view_progress_notes?
    user.admin? || user.staff? || assigned_professional? || parent_of_student?
  end

  def edit_progress_notes?
    user.admin? || user.staff? || assigned_professional?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      case user.role
      when 'admin'
        scope.all
      when 'staff'
        scope.all
      when 'professional'
        # Show students assigned to this professional
        scope.joins(:appointments).where(appointments: { professional: user }).distinct
      when 'parent'
        # Show only own children
        scope.joins(:student_relationships).where(student_relationships: { user: user })
      else
        scope.none
      end
    end
  end

  private

  def parent_of_student?
    record.parents.include?(user)
  end

  def assigned_professional?
    record.appointments.exists?(professional: user)
  end
end

# app/policies/user_policy.rb
class UserPolicy < ApplicationPolicy
  def index?
    user.admin? || user.staff?
  end

  def show?
    user.admin? || user.staff? || record == user
  end

  def create?
    user.admin?
  end

  def update?
    user.admin? || record == user
  end

  def destroy?
    user.admin? && record != user
  end

  def change_role?
    user.admin? && record != user
  end

  def view_sensitive_data?
    user.admin?
  end

  def impersonate?
    user.admin? && record != user
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      case user.role
      when 'admin'
        scope.all
      when 'staff'
        scope.where.not(role: 'admin')
      when 'professional'
        # Show only parents of their students
        scope.where(
          id: Student.joins(:appointments)
                    .where(appointments: { professional: user })
                    .joins(:student_relationships)
                    .select('student_relationships.user_id')
        )
      when 'parent'
        scope.where(id: user.id)
      else
        scope.none
      end
    end
  end
end

# app/policies/organization_policy.rb
class OrganizationPolicy < ApplicationPolicy
  def show?
    user.admin? || user.staff?
  end

  def update?
    user.admin?
  end

  def destroy?
    false # Organizations should not be deleted
  end

  def view_settings?
    user.admin?
  end

  def edit_settings?
    user.admin?
  end

  def view_billing?
    user.admin?
  end

  def manage_users?
    user.admin?
  end

  def view_reports?
    user.admin? || user.staff?
  end

  def export_data?
    user.admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.where(id: user.organization_id)
      else
        scope.none
      end
    end
  end
end

# app/policies/report_policy.rb
class ReportPolicy < ApplicationPolicy
  def index?
    user.admin? || user.staff?
  end

  def show?
    user.admin? || user.staff?
  end

  def create?
    user.admin? || user.staff?
  end

  def financial_reports?
    user.admin?
  end

  def student_progress_reports?
    user.admin? || user.staff? || user.professional?
  end

  def appointment_reports?
    user.admin? || user.staff?
  end

  def export?
    user.admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      case user.role
      when 'admin'
        scope.all
      when 'staff'
        scope.where(type: ['appointment', 'student_progress'])
      when 'professional'
        scope.where(type: 'student_progress', professional: user)
      else
        scope.none
      end
    end
  end
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  include ActsAsTenant::ControllerExtensions
  include Pundit::Authorization

  set_current_tenant_by_subdomain(:organization, :subdomain)

  before_action :authenticate_user!
  after_action :verify_authorized, unless: :devise_controller?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    error_message = I18n.t("pundit.#{policy_name}.#{exception.query}", 
                          default: 'You are not authorized to perform this action.')
    
    render json: { error: error_message }, status: :forbidden
  end

  def record_not_found
    render json: { error: 'Record not found' }, status: :not_found
  end
end

# app/controllers/api/v1/appointments_controller.rb
class Api::V1::AppointmentsController < ApplicationController
  before_action :set_appointment, only: [:show, :update, :destroy, :confirm, :cancel, :execute]

  def index
    @appointments = policy_scope(Appointment)
    render json: @appointments
  end

  def show
    authorize @appointment
    render json: @appointment, include_notes: policy(@appointment).view_notes?
  end

  def create
    @appointment = Appointment.new(appointment_params)
    authorize @appointment

    if @appointment.save
      render json: @appointment, status: :created
    else
      render json: { errors: @appointment.errors }, status: :unprocessable_entity
    end
  end

  def update
    authorize @appointment

    if @appointment.update(permitted_attributes(@appointment))
      render json: @appointment
    else
      render json: { errors: @appointment.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @appointment
    @appointment.destroy
    head :no_content
  end

  def confirm
    authorize @appointment, :confirm?
    @appointment.confirm!
    render json: @appointment
  end

  def cancel
    authorize @appointment, :cancel?
    @appointment.cancel!
    render json: @appointment
  end

  def execute
    authorize @appointment, :execute?
    @appointment.execute!
    render json: @appointment
  end

  private

  def set_appointment
    @appointment = Appointment.find(params[:id])
  end

  def appointment_params
    params.require(:appointment).permit(policy(@appointment || Appointment).permitted_attributes)
  end
end

# app/controllers/api/v1/students_controller.rb
class Api::V1::StudentsController < ApplicationController
  before_action :set_student, only: [:show, :update, :destroy]

  def index
    @students = policy_scope(Student)
    render json: @students
  end

  def show
    authorize @student
    render json: @student, 
           include_medical_info: policy(@student).view_medical_info?,
           include_progress_notes: policy(@student).view_progress_notes?
  end

  def create
    @student = Student.new(student_params)
    authorize @student

    if @student.save
      render json: @student, status: :created
    else
      render json: { errors: @student.errors }, status: :unprocessable_entity
    end
  end

  def update
    authorize @student

    if @student.update(permitted_attributes(@student))
      render json: @student
    else
      render json: { errors: @student.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @student
    @student.destroy
    head :no_content
  end

  private

  def set_student
    @student = Student.find(params[:id])
  end

  def student_params
    params.require(:student).permit(policy(@student || Student).permitted_attributes)
  end
end

# app/serializers/appointment_serializer.rb
class AppointmentSerializer < ActiveModel::Serializer
  attributes :id, :start_time, :end_time, :status, :created_at, :updated_at
  
  belongs_to :professional
  belongs_to :student
  belongs_to :parent

  attribute :notes, if: :include_notes?
  attribute :internal_notes, if: :include_internal_notes?

  private

  def include_notes?
    @instance_options[:include_notes]
  end

  def include_internal_notes?
    @instance_options[:include_internal_notes] && 
    AppointmentPolicy.new(current_user, object).view_notes?
  end
end

# config/locales/pundit.en.yml
en:
  pundit:
    default: 'You are not authorized to perform this action.'
    appointment_policy:
      index?: 'You cannot view appointments.'
      show?: 'You cannot view this appointment.'
      create?: 'You cannot create appointments.'
      update?: 'You cannot update this appointment.'
      destroy?: 'You cannot delete this appointment.'
      confirm?: 'You cannot confirm this appointment.'
      cancel?: 'You cannot cancel this appointment.'
      execute?: 'You cannot execute this appointment.'
    student_policy:
      index?: 'You cannot view students.'
      show?: 'You cannot view this student.'
      create?: 'You cannot create students.'
      update?: 'You cannot update this student.'
      destroy?: 'You cannot delete this student.'
    user_policy:
      index?: 'You cannot view users.'
      show?: 'You cannot view this user.'
      create?: 'You cannot create users.'
      update?: 'You cannot update this user.'
      destroy?: 'You cannot delete this user.'
      change_role?: 'You cannot change user roles.'

# spec/policies/appointment_policy_spec.rb
require 'rails_helper'

RSpec.describe AppointmentPolicy do
  subject { described_class }

  let(:organization) { create(:organization) }
  let(:admin) { create(:user, :admin, organization: organization) }
  let(:staff) { create(:user, :staff, organization: organization) }
  let(:professional) { create(:user, :professional, organization: organization) }
  let(:parent) { create(:user, :parent, organization: organization) }
  let(:student) { create(:student, organization: organization) }
  let(:appointment) { create(:appointment, professional: professional, parent: parent, student: student) }

  permissions :show? do
    it "grants access to admin" do
      expect(subject).to permit(admin, appointment)
    end

    it "grants access to staff" do
      expect(subject).to permit(staff, appointment)
    end

    it "grants access to assigned professional" do
      expect(subject).to permit(professional, appointment)
    end

    it "grants access to parent of student" do
      expect(subject).to permit(parent, appointment)
    end

    it "denies access to other users" do
      other_user = create(:user, :parent, organization: organization)
      expect(subject).not_to permit(other_user, appointment)
    end
  end

  permissions :update? do
    it "grants access to admin" do
      expect(subject).to permit(admin, appointment)
    end

    it "grants access to staff" do
      expect(subject).to permit(staff, appointment)
    end

    it "grants access to professional for non-executed appointments" do
      expect(subject).to permit(professional, appointment)
    end

    it "denies access to professional for executed appointments" do
      appointment.execute!
      expect(subject).not_to permit(professional, appointment)
    end

    it "grants access to parent for draft appointments" do
      expect(subject).to permit(parent, appointment)
    end

    it "denies access to parent for confirmed appointments" do
      appointment.pre_confirm!
      appointment.confirm!
      expect(subject).not_to permit(parent, appointment)
    end
  end

  permissions :destroy? do
    it "grants access to admin" do
      expect(subject).to permit(admin, appointment)
    end

    it "grants access to staff for non-executed appointments" do
      expect(subject).to permit(staff, appointment)
    end

    it "denies access to staff for executed appointments" do
      appointment.execute!
      expect(subject).not_to permit(staff, appointment)
    end

    it "denies access to professional" do
      expect(subject).not_to permit(professional, appointment)
    end

    it "denies access to parent" do
      expect(subject).not_to permit(parent, appointment)
    end
  end
end