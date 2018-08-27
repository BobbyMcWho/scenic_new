#
#  Created by Boyd Multerer on August, 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Mix.Tasks.Scenic.New do
  use Mix.Task

  import Mix.Generator

  # import IEx

  @switches [
    app: :string,
    module: :string
  ]

  @scenic_version Mix.Project.config()[:version]
  @parrot_bin File.read!("static/scenic_parrot.png")

  @parrot_hash      "UfHCVlANI2cFbwSpJey64FxjT-0"

  # --------------------------------------------------------
  def run(argv) do
    {opts, argv} = OptionParser.parse!(argv, strict: @switches)

    case argv do
      [] ->
        Mix.raise("Expected app PATH to be given, please use \"mix scenic.new PATH\"")

      [path | _] ->
        app = opts[:app] || Path.basename(Path.expand(path))
        check_application_name!(app, !opts[:app])
        mod = opts[:module] || Macro.camelize(app)
        check_mod_name_validity!(mod)
        check_mod_name_availability!(mod)

        unless path == "." do
          check_directory_existence!(path)
          File.mkdir_p!(path)
        end

        File.cd!(path, fn ->
          generate(app, mod, path, opts)
        end)
    end
  end

  # --------------------------------------------------------
  defp generate(app, mod, _path, _opts) do
    assigns = [
      app: app,
      mod: mod,
      elixir_version: get_version(System.version()),
      scenic_version: @scenic_version
    ]

    create_file("README.md", readme_template(assigns))
    create_file(".formatter.exs", formatter_template(assigns))
    create_file(".gitignore", gitignore_template(assigns))
    create_file("mix.exs", mix_exs_template(assigns))
    create_file("Makefile", makefile_template(assigns))

    create_directory("config")
    create_file("config/config.exs", config_template(assigns))

    create_directory("lib")
    create_file("lib/#{app}.ex", lib_template(assigns))

    create_directory("static")
    create_file("static/images/scenic_parrot.png.#{@parrot_hash}", @parrot_bin)

    create_directory("lib/scenes")
    create_file("lib/scenes/first.ex", first_scene_template(assigns))
    create_file("lib/scenes/second.ex", second_scene_template(assigns))

    create_directory("lib/components")
    create_file("lib/components/nav.ex", nav_template(assigns))

    # create_directory("test")
    # create_file("test/test_helper.exs", test_helper_template(assigns))
    # create_file("test/#{app}_test.exs", test_template(assigns))

    """

    Your Scenic project was created successfully.

    Next:
      cd into your app directory and run "mix deps.get"

    Then:
      Run "mix scenic.run" (in the app directory) to start your app
      Run "iex -S mix" (in the app directory) to debug your app

    """
    # |> String.trim_trailing()
    |> Mix.shell().info()
  end

  # --------------------------------------------------------
  defp get_version(version) do
    {:ok, version} = Version.parse(version)

    "#{version.major}.#{version.minor}" <>
      case version.pre do
        [h | _] -> "-#{h}"
        [] -> ""
      end
  end

  # ============================================================================
  # template files

  # --------------------------------------------------------
  embed_template(:readme, """
  Readme text goes here
  """)

  # --------------------------------------------------------
  embed_template(:formatter, """
  # Used by "mix format"
  [
    inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
  ]
  """)

  # --------------------------------------------------------
  embed_template(:gitignore, """
  # The directory Mix will write compiled artifacts to.
  /_build/

  # If you run "mix test --cover", coverage assets end up here.
  /cover/

  # The directory Mix downloads your dependencies sources to.
  /deps/

  # Where 3rd-party dependencies like ExDoc output generated docs.
  /doc/

  # Ignore .fetch files in case you like to edit your project deps locally.
  /.fetch

  # If the VM crashes, it generates a dump, let's ignore it too.
  erl_crash.dump

  # Also ignore archive artifacts (built via "mix archive.build").
  *.ez
  <%= if @app do %>
  # Ignore package tarball (built via "mix hex.build").
  <%= @app %>-*.tar
  <% end %>

  # Ignore scripts marked as secret - usually passwords and such in config files
  *.secret.exs
  *.secrets.exs
  """)

  # --------------------------------------------------------
  embed_template(:mix_exs, """
  defmodule <%= @mod %>.MixProject do
    use Mix.Project

    def project do
      [
        app: :<%= @app %>,
        version: "0.1.0",
        elixir: "~> <%= @elixir_version %>",
        start_permanent: Mix.env() == :prod,
        compilers: [:elixir_make] ++ Mix.compilers,
        make_env: %{"MIX_ENV" => to_string(Mix.env)},
        make_clean: ["clean"],
        deps: deps()
      ]
    end

    # Run "mix help compile.app" to learn about applications.
    def application do
      [
        mod: {<%= @mod %>, []},
        extra_applications: []
      ]
    end

    # Run "mix help deps" to learn about dependencies.
    defp deps do
      [
        {:elixir_make, "~> 0.4"},
        # {:scenic, "~> <%= @scenic_version %>"},
        # {:scenic_driver_glfw, "~> <%= @scenic_version %>"},

        # this clock is optional. It is. included as an example of a set
        # of components wrapped up in their own Hex package
        # {:scenic_clock, ">= 0.0.0"},

        # the https versions
        # { :scenic, git: "https://github.com/boydm/scenic.git", override: true },
        # { :scenic_driver_glfw, git: "https://github.com/boydm/scenic_driver_glfw.git"},
        # { :scenic_clock, git: "https://github.com/boydm/scenic_clock.git"},
        
        # the ssh versions
        { :scenic, git: "git@github.com:boydm/scenic.git" },
        { :scenic_driver_glfw, git: "git@github.com:boydm/scenic_driver_glfw.git"},
        { :scenic_clock, git: "git@github.com:boydm/scenic_clock.git"},


        # {:dep_from_hexpm, "~> 0.3.0"},
        # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      ]
    end
  end
  """)

  # --------------------------------------------------------
  embed_template(:makefile, """
  .PHONY: all clean

  all: priv static

  priv:
  \tmkdir -p priv

  static: priv/
  \tln -fs ../static priv/

  clean:
  \t$(RM) -r priv
  """)

  # --------------------------------------------------------
  embed_template(:config, """
  # This file is responsible for configuring your application
  # and its dependencies with the aid of the Mix.Config module.
  use Mix.Config


  # Configure the main viewport for the Scenic application
  config :<%= @app %>, :viewport, %{
        name: :main_viewport,
        size: {700, 600},
        default_scene: {<%= @mod %>.Scene.First, nil},
        drivers: [
          %{
            module: Scenic.Driver.Glfw,
            name: :glfw,
            opts: [resizeable: false, title: "<%= @app %>"],
          }
        ]
      }


  # It is also possible to import configuration files, relative to this
  # directory. For example, you can emulate configuration per environment
  # by uncommenting the line below and defining dev.exs, test.exs and such.
  # Configuration from the imported file will override the ones defined
  # here (which is why it is important to import them last).
  #
  #     import_config "#{Mix.env()}.exs"
  """)

  # --------------------------------------------------------
  embed_template(:lib, """
  defmodule <%= @mod %> do
    @moduledoc \"""
    Starter application using the Scenic framework.
    \"""

    def start(_type, _args) do
      import Supervisor.Spec, warn: false

      # load the viewport configuration from config
      main_viewport_config = Application.get_env(:<%= @app %>, :viewport)

      # start the application with the viewport
      children = [
        supervisor(Scenic, [viewports: [main_viewport_config]]),
      ]
      Supervisor.start_link(children, strategy: :one_for_one)
    end

  end
  """)

  # --------------------------------------------------------
  embed_template(:first_scene, """
  defmodule <%= @mod %>.Scene.First do
    @moduledoc \"""
    Sample scene.
    \"""

    use Scenic.Scene
    alias <%= @mod %>.Component.Nav
    alias Scenic.Graph
    import Scenic.Primitives

    @parrot       "/static/images/scenic_parrot.png.#{@parrot_hash}"
    @parrot_hash  "#{@parrot_hash}"

    @graph Graph.build()
      |> text("First Scene", font: :roboto, font_size: 60, translate: {20, 120})
      |> rect({100, 200}, fill: {:image, @parrot_hash}, translate: {20, 180})
      |> Nav.add_to_graph(__MODULE__)

    def init( _, _styles, _viewport ) do

      # load the dog texture into the cache
      :code.priv_dir(:<%= @app %>)
      |> Path.join( @parrot )
      |> Scenic.Cache.Texture.load()

      push_graph(@graph)
      {:ok, @graph}
    end

  end
  """)

  # --------------------------------------------------------
  embed_template(:second_scene, """
  defmodule <%= @mod %>.Scene.Second do
    @moduledoc \"""
    Sample scene.
    \"""

    use Scenic.Scene
    alias <%= @mod %>.Component.Nav
    alias Scenic.Graph
    import Scenic.Primitives

    @graph Graph.build()
      |> text("Second Scene", font: :roboto, font_size: 60, translate: {20, 120})
      |> Nav.add_to_graph(__MODULE__)

    def init( _, _styles, _viewport ) do
      push_graph(@graph)
      {:ok, @graph}
    end

  end
  """)

  # --------------------------------------------------------
  embed_template(:nav, """
  defmodule Temp.Component.Nav do
    @moduledoc \"""
    Sample componentized nav bar.
    \"""

    use Scenic.Component
    alias Scenic.Graph
    alias Scenic.ViewPort

    import Scenic.Primitives, only: [{:text, 3}]
    import Scenic.Components, only: [{:dropdown, 3}]
    import Scenic.Clock.Components

    #--------------------------------------------------------
    def verify( scene ) when is_atom(scene), do: {:ok, scene}
    def verify( {scene,_} = data ) when is_atom(scene), do: {:ok, data}
    def verify( _ ), do: :invalid_data

    #--------------------------------------------------------
    def init( current_scene, _styles, viewport ) do

      # get the viewport width to position the clock
      {:ok, %ViewPort.Status{size: {width,_}}} = ViewPort.info(viewport)

      graph = Graph.build(font_size: 20)
      |> text("Scene:", translate: {14, 40}, align: :right)
      |> dropdown({[
          {"First Scene", Temp.Scene.First},
          {"Second Scene", Temp.Scene.Second},
        ], current_scene, :nav}, translate: {70, 20})
      |> digital_clock( text_align: :right, translate: {width - 20, 40} )
      |> push_graph()

      {:ok, %{graph: graph, viewport: viewport}}
    end

    #--------------------------------------------------------
    def filter_event( {:value_changed, :nav, scene}, _, %{viewport: vp} = state )
    when is_atom(scene) do
       Scenic.ViewPort.set_root( vp, {scene, nil} )
      {:stop, state }
    end

    #--------------------------------------------------------
    def filter_event( {:value_changed, :nav, scene}, _, %{viewport: vp} = state ) do
       Scenic.ViewPort.set_root( vp, scene )
      {:stop, state }
    end

  end
  """)


  # ============================================================================
  # validity functions taken from Elixir new task

  defp check_application_name!(name, inferred?) do
    unless name =~ Regex.recompile!(~r/^[a-z][a-z0-9_]*$/) do
      Mix.raise(
        "Application name must start with a lowercase ASCII letter, followed by " <>
          "lowercase ASCII letters, numbers, or underscores, got: #{inspect(name)}" <>
          if inferred? do
            ". The application name is inferred from the path, if you'd like to " <>
              "explicitly name the application then use the \"--app APP\" option"
          else
            ""
          end
      )
    end
  end

  defp check_mod_name_validity!(name) do
    unless name =~ Regex.recompile!(~r/^[A-Z]\w*(\.[A-Z]\w*)*$/) do
      Mix.raise(
        "Module name must be a valid Elixir alias (for example: Foo.Bar), got: #{inspect(name)}"
      )
    end
  end

  defp check_mod_name_availability!(name) do
    name = Module.concat(Elixir, name)

    if Code.ensure_loaded?(name) do
      Mix.raise("Module name #{inspect(name)} is already taken, please choose another name")
    end
  end

  defp check_directory_existence!(path) do
    msg = "The directory #{inspect(path)} already exists. Are you sure you want to continue?"

    if File.dir?(path) and not Mix.shell().yes?(msg) do
      Mix.raise("Please select another directory for installation")
    end
  end
end
