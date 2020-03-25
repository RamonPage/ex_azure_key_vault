defmodule Mix.Tasks.Version do
  use Mix.Task

  @impl Mix.Task
  def run(args) do
    version = Enum.at(args, 0)
    description = Enum.at(args, 1)

    Mix.shell().info("Updating DOCS...")
    {:ok, docs} = File.read("DOCS.md")

    File.write(
      "DOCS.md",
      Regex.replace(
        ~r/{:ex_azure_key_vault, "~> (.*)"}/,
        docs,
        "{:ex_azure_key_vault, \"~> #{version}\"}"
      )
    )

    Mix.shell().info("DOCS updated!")

    Mix.shell().info("")

    Mix.shell().info("Updating README...")
    {:ok, readme} = File.read("README.md")

    File.write(
      "README.md",
      Regex.replace(
        ~r/{:ex_azure_key_vault, "~> (.*)"}/,
        readme,
        "{:ex_azure_key_vault, \"~> #{version}\"}"
      )
    )

    Mix.shell().info("README updated!")

    Mix.shell().info("")

    Mix.shell().info("Updating mix.exs...")
    {:ok, mix_exs} = File.read("mix.exs")
    File.write("mix.exs", Regex.replace(~r/@version "(.*)"/, mix_exs, "@version \"#{version}\""))
    Mix.shell().info("mix.exs updated!")

    Mix.shell().info("")

    if description do
      Mix.shell().info("Updating CHANGELOG...")
      {:ok, changelog} = File.read("CHANGELOG.md")
      changelog = Regex.replace(~r/# Changelog\n/, changelog, "")
      description = Regex.replace(~r/\\n/, description, "\n")
      updated_changelog = "# Changelog\n\n## v#{version}\n\n#{description}\n#{changelog}"
      File.write("CHANGELOG.md", updated_changelog)
      Mix.shell().info("CHANGELOG updated!")
    end
  end
end
