require File.dirname(__FILE__) + '/../test_helper'

class ProjectTest < Test::Unit::TestCase

  def test_invalid_with_blank_attributes
    project = Project.new
    assert !project.valid?
    assert project.errors.invalid?(:name)
    assert !project.errors.invalid?(:description)
    assert project.errors.invalid?(:enterprise_id)
    assert project.errors.invalid?(:supervisor_id)
  end

  def test_invalid_with_invalid_attributes
    project = Project.new :name => 'Invalid Test', :enterprise_id => 10000, :supervisor_id => 20000
    assert !project.valid?
    assert !project.errors.invalid?(:name)
    assert !project.errors.invalid?(:description)
    assert !project.errors.invalid?(:enterprise_id)
    assert project.errors.invalid?(:enterprise)
    assert !project.errors.invalid?(:supervisor_id)
    assert project.errors.invalid?(:supervisor)
  end

  def test_invalid_with_used_name
    @enterprise = Enterprise.find(:first)
    @project = @enterprise.projects.find(:first)
    @supervisor = @enterprise.users.find(:first, :conditions => ['is_supervisor = ?', 1])
    project = Project.new :name => @project.name, :enterprise => @enterprise, :supervisor => @supervisor
    assert !project.valid?
    assert project.errors.invalid?(:name)
    assert !project.errors.invalid?(:description)
    assert !project.errors.invalid?(:enterprise_id)
    assert !project.errors.invalid?(:enterprise)
    assert !project.errors.invalid?(:supervisor_id)
    assert !project.errors.invalid?(:supervisor)
  end

  def test_invalid_with_supervisor_not_supervisor
    @enterprise = Enterprise.find(:first)
    @supervisor = @enterprise.users.find(:first, :conditions => ['is_supervisor = ?', 0])
    project = Project.new :name => 'Invalid Test', :enterprise => @enterprise, :supervisor => @supervisor
    assert !project.valid?
    assert !project.errors.invalid?(:name)
    assert !project.errors.invalid?(:description)
    assert !project.errors.invalid?(:enterprise_id)
    assert !project.errors.invalid?(:enterprise)
    assert !project.errors.invalid?(:supervisor_id)
    assert project.errors.invalid?(:supervisor)
  end

  def test_valid_project
    @enterprise = Enterprise.find_by_short_name('foo')
    @supervisor = @enterprise.users.find(:first, :conditions => ['is_supervisor = ?', 1])
    project = Project.new :name => 'Valid Test', :enterprise => @enterprise, :supervisor => @supervisor
    assert project.valid?
    assert project.save
  end
end