defmodule Mix.Tasks.Version do
  use Mix.Task

  @impl Mix.Task
  def run(_) do
    Mix.shell().info("Getting latest release...")
    {:ok, latest} = File.read("LATEST.md")
    version = (Regex.run(~r/## v(.*)\n\n/, latest) || []) |> Enum.at(1)
    latest_release = Regex.replace(~r/# Latest release\n/, latest, "")

    unless version do
      Mix.shell().info("Version not found.")
      exit(:normal)
    end

    Mix.shell().info("➜ Version #{version} found.")

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

    Mix.shell().info("➜ DOCS updated!")

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

    Mix.shell().info("➜ README updated!")

    Mix.shell().info("Updating mix.exs...")
    {:ok, mix_exs} = File.read("mix.exs")
    File.write("mix.exs", Regex.replace(~r/@version "(.*)"/, mix_exs, "@version \"#{version}\""))
    Mix.shell().info("➜ mix.exs updated!")

    Mix.shell().info("Updating CHANGELOG...")
    {:ok, changelog} = File.read("CHANGELOG.md")

    if !Regex.run(~r/## v#{version}\n\n/, changelog) do
      changelog = Regex.replace(~r/# Changelog\n/, changelog, "")
      updated_changelog = "# Changelog\n#{latest_release}\n#{changelog}"
      File.write("CHANGELOG.md", updated_changelog)
      Mix.shell().info("➜ CHANGELOG updated!")
    else
      Mix.shell().info("➜ CHANGELOG is already up to date.")
    end
  end
end
