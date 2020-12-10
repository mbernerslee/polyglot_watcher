defmodule PolyglotWatcher.Result do
  def and_then(:ok, fun), do: fun.()
  def and_then({:ok, result}, fun), do: fun.(result)
  def and_then(other, _), do: other

  def otherwise(:error, fun), do: fun.()
  def otherwise({:error, reason}, fun), do: fun.(reason)
  def otherwise(other, _), do: other
end
