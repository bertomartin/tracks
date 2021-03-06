class Context < ActiveRecord::Base

  has_many :todos, :dependent => :delete_all, :include => :project,
    :order => 'todos.due IS NULL, todos.due ASC, todos.created_at ASC'
  has_many :recurring_todos, :dependent => :delete_all
  belongs_to :user

  scope :active, :conditions => { :state => :active }
  scope :hidden, :conditions => { :state => :hidden }
  scope :closed, :conditions => { :state => :closed }
  scope :with_name, lambda { |name| where("name LIKE ?", name) }

  acts_as_list :scope => :user, :top_of_list => 0

  # state machine
  include AASM
  aasm_column :state
  aasm_initial_state :active

  aasm_state :active
  aasm_state :closed
  aasm_state :hidden

  aasm_event :close do
    transitions :to => :closed, :from => [:active, :hidden], :guard => :no_active_todos?
  end

  aasm_event :hide do
    transitions :to => :hidden, :from => [:active, :closed]
  end

  aasm_event :activate do
    transitions :to => :active, :from => [:closed, :hidden]
  end

  attr_protected :user

  validates_presence_of :name, :message => "context must have a name"
  validates_length_of :name, :maximum => 255, :message => "context name must be less than 256 characters"
  validates_uniqueness_of :name, :message => "already exists", :scope => "user_id"

  def self.null_object
    NullContext.new
  end

  def title
    name
  end

  def new_record_before_save?
    @new_record_before_save
  end

  def no_active_todos?
    return todos.active.count == 0
  end

end

class NullContext

  def nil?
    true
  end

  def id
    nil
  end

  def name
    ''
  end

end
