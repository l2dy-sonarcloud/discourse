# frozen_string_literal: true

module ServiceMatchers
  class RunServiceSuccessfully
    attr_reader :result

    def matches?(result)
      @result = result
      result.success?
    end

    def failure_message
      message = "Expected the service to succeed but it failed."
      error_message_with_inspection(message)
    end

    def failure_message_when_negated
      message = "Expected the service to fail but it succeeded."
      error_message_with_inspection(message)
    end

    def description
      "run the service successfully"
    end

    private

    def error_message_with_inspection(message)
      "#{message}\n\n#{result.inspect_steps}"
    end
  end

  class FailStep
    attr_reader :name, :result

    def initialize(name)
      @name = name
    end

    def matches?(result)
      @result = result
      step_exists? && step_failed? && service_failed?
    end

    def failure_message
      set_unexpected_result
      message =
        if !step_exists?
          step_not_existing_message
        elsif !step_failed?
          step_failed_message
        else
          "expected the service to fail but it succeeded."
        end
      error_message_with_inspection(message)
    end

    def failure_message_when_negated
      set_unexpected_result
      error_message_with_inspection(negated_message)
    end

    def description
      "fail a #{type} named '#{name}'"
    end

    private

    def step_exists?
      result[step].present?
    end

    def step_failed?
      result[step].failure?
    end

    def service_failed?
      result.failure?
    end

    def type
      self.class.name.split("::").last.sub("Fail", "").downcase
    end

    def step
      "result.#{type}.#{name}"
    end

    def error_message_with_inspection(message)
      "#{message}\n\n#{result.inspect_steps}"
    end

    def set_unexpected_result
      return unless result[step]
      result[step]["spec.unexpected_result"] = true
    end

    def step_not_existing_message
      "Expected #{type} '#{name}' (key: '#{step}') was not found in the result object."
    end

    def step_failed_message
      "Expected #{type} '#{name}' (key: '#{step}') to fail but it succeeded."
    end

    def negated_message
      "Expected #{type} '#{name}' (key: '#{step}') to succeed but it failed."
    end
  end

  class FailContract < FailStep
  end

  class FailPolicy < FailStep
  end

  class FailToFindModel < FailStep
    def type
      "model"
    end

    def description
      "fail to find a model named '#{name}'"
    end

    def step_failed?
      super && result[step].not_found
    end
  end

  class FailWithInvalidModel < FailStep
    def type
      "model"
    end

    def description
      "fail to have a valid model named '#{name}'"
    end

    def step_failed?
      super && result[step].invalid
    end
  end

  class FailWithException < FailStep
    attr_reader :exception

    def initialize(exception)
      @exception = exception
      @name = "default"
    end

    def type
      "try"
    end

    def description
      "fail with an exception (#{exception})"
    end

    def step_failed?
      result[step]&.exception&.is_a?(exception)
    end

    def step_not_existing_message
      "Expected try block (key: '#{step}') was not found in the result object."
    end

    def step_failed_message
      message =
        "Expected try block (key: '#{step}') to fail with an exception of type '#{exception}'"
      message +=
        if result[step].exception.blank?
          " but it succeeded."
        else
          " but it failed with an exception of type '#{result[step].exception.class}'"
        end
    end

    def negated_message
      "Expected try block (key: '#{step}') to succeed but it failed."
    end
  end

  def fail_a_policy(name)
    FailPolicy.new(name)
  end

  def fail_a_contract(name = "default")
    FailContract.new(name)
  end

  def fail_to_find_a_model(name = "model")
    FailToFindModel.new(name)
  end

  def fail_with_an_invalid_model(name = "model")
    FailWithInvalidModel.new(name)
  end

  def fail_with_exception(exception = StandardError)
    FailWithException.new(exception)
  end

  def fail_a_step(name = "model")
    FailStep.new(name)
  end

  def run_successfully
    RunServiceSuccessfully.new
  end
end
