module DirtyAssociations
  attr_accessor :dirty
  attr_accessor :_old_tehsils, :_new_tehsils, :_old_user_categories, :_new_user_categories, :_new_ucs, :_old_ucs



  def add_tehsils_dirty(record)
    self.dirty = true
    self._new_tehsils ||= []
    self._new_tehsils << record.tehsil_name
  end

  def delete_tehsils_dirty(record)
    self.dirty = true
    self._old_tehsils ||= []
    self._old_tehsils << record.tehsil_name
  end

  def add_user_categories_dirty(record)
    self.dirty = true
    self._new_user_categories ||= []
    self._new_user_categories << record.category_name

  end

  def delete_user_categories_dirty(record)
    self.dirty = true
    self._old_user_categories ||= []
    self._old_user_categories << record.category_name
  end

  def add_ucs_dirty(record)
    self.dirty = true
    self._new_ucs ||= []
    self._new_ucs << record.uc_name
  end

  def delete_ucs_dirty(record)
    self.dirty = true
    self._old_ucs ||= []
    self._old_ucs << record.uc_name
  end


  def changed?
    dirty || super
  end
  def reload(*)
    super.tap do
      self._old_tehsils = nil
      self._new_tehsils = nil
      self._old_user_categories = nil
      self._new_user_categories = nil
      self._old_ucs = nil
      self._new_ucs = nil
    end
  end
end