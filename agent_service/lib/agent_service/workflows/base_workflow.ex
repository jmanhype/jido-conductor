defmodule AgentService.Workflows.BaseWorkflow do
  @moduledoc """
  Base module for JIDO workflows with common functionality
  """

  defmacro __using__(_opts) do
    quote do
      use Jido.Workflow
      
      require Logger
      
      # Common workflow helpers
      
      def log_step(message, level \\ :info) do
        Logger.log(level, "[#{__MODULE__}] #{message}")
      end
      
      def with_retry(fun, opts \\ []) do
        max_attempts = Keyword.get(opts, :max_attempts, 3)
        delay = Keyword.get(opts, :delay, 1000)
        
        do_retry(fun, max_attempts, delay, 1)
      end
      
      defp do_retry(fun, max_attempts, _delay, attempt) when attempt > max_attempts do
        {:error, :max_attempts_exceeded}
      end
      
      defp do_retry(fun, max_attempts, delay, attempt) do
        case fun.() do
          {:ok, result} ->
            {:ok, result}
          
          {:error, _reason} = error when attempt < max_attempts ->
            Process.sleep(delay * attempt)
            do_retry(fun, max_attempts, delay, attempt + 1)
          
          error ->
            error
        end
      end
      
      def run_action_with_context(agent, action, params, context) do
        enriched_params = Map.merge(params, context)
        Jido.Agent.run_action(agent, action, enriched_params)
      end
      
      def chain_actions(agent, actions) do
        Enum.reduce_while(actions, {:ok, agent}, fn {action, params}, {:ok, acc_agent} ->
          case Jido.Agent.run_action(acc_agent, action, params) do
            {:ok, result_agent} ->
              {:cont, {:ok, result_agent}}
            
            {:error, _} = error ->
              {:halt, error}
          end
        end)
      end
      
      def parallel_actions(agent, actions) do
        tasks = Enum.map(actions, fn {action, params} ->
          Task.async(fn ->
            Jido.Agent.run_action(agent, action, params)
          end)
        end)
        
        results = Task.await_many(tasks, 30_000)
        
        errors = Enum.filter(results, fn
          {:error, _} -> true
          _ -> false
        end)
        
        if length(errors) > 0 do
          {:error, errors}
        else
          {:ok, results}
        end
      end
    end
  end
end