# frozen_string_literal: true

module ActiveadminTableFooter
  # IndexAsTable#build constructs its own table_options hash and does not pass
  # unknown options through. We wrap the user block so the TableFor instance
  # receives @footer_data_proc before columns are evaluated.
  module IndexAsTableExtension
    def build(page_presenter, collection)
      footer_proc = page_presenter[:footer_data]
      return super unless footer_proc && page_presenter.block

      original_block = page_presenter.block
      wrapped = lambda do |table|
        table.instance_variable_set(:@footer_data_proc, footer_proc)
        instance_exec(table, &original_block)
      end

      # Render against a copy. ActiveAdmin builds one PagePresenter per
      # `index do ... end` when it loads the resource and hands that same
      # object to every render, so writing the wrapper back into the presenter
      # would wrap the previous wrapper once per request — growing retained
      # closures and block call depth until a render raises SystemStackError.
      super(ActiveAdmin::PagePresenter.new(page_presenter.options, &wrapped), collection)
    end
  end
end
