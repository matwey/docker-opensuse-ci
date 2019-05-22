#!/usr/bin/env elixir

defmodule Git do
	defp write_object(repo, type, content) do
		object = type <> <<" ">> <> (byte_size(content) |> to_string) <> <<0>> <> content
		hash = :crypto.hash(:sha, object)
		object = object |> :zlib.compress

		<<hash_head :: binary-size(1), hash_tail :: binary>> = hash
		filebase = Path.join([
			repo, ".git", "objects",
			hash_to_text(hash_head)
		])
		filename = hash_to_text(hash_tail)

		:ok = File.mkdir_p(filebase)
		:ok = File.write(Path.join(filebase, filename), object)

		hash
	end

	def write_blob(repo, content) do
		write_object(repo, "blob", content)
	end

	def write_tree(repo, tree) do
		content = Enum.join((for {mask, hash, name} <- tree, do: "#{mask} #{name}\0#{hash}"), "")

		write_object(repo, "tree", content)
	end

	def write_commit(repo, tree, parents, message) do
		tree_txt = hash_to_text(tree)
		parent_args =  Enum.flat_map(parents, fn(p) -> ["-p", p] end)
		{commit, 0} = System.cmd("git", ["-C", repo, "commit-tree", tree_txt] ++ parent_args ++ ["-m", message])

		commit |> String.trim()
	end

	def show_ref(repo, refname) do
		{result, code} = System.cmd("git", ["-C", repo, "show-ref", "--verify", refname])

		case code do
			0 -> [commit|_tail] = String.split(result, " ", trim: true);
				{:ok, commit}
			128 -> {:error, :not_found}
		end
	end

	def update_ref(repo, refname, commit) do
		{_result, 0} = System.cmd("git", ["-C", repo, "update-ref", refname, commit])
	end

	def hash_to_text(hash) when is_binary(hash) do
		hash |> Base.encode16() |> String.downcase()
	end
	def hash_to_text(hash) when is_list(hash) do
		hash
	end
end

defmodule Generator do
	require EEx
	EEx.function_from_file :defp, :dockerfile2, "Dockerfile.eex", [:baseimage, :variables, :repos, :packages]

	defp repo({:gcc, _gcc_version}, {:opensuse, :tumbleweed}) do
		"https://download.opensuse.org/repositories/devel:/gcc/openSUSE_Factory/devel:gcc.repo"
	end
	defp repo({:gcc, _gcc_version}, {:opensuse, opensuse_version}) do
		"https://download.opensuse.org/repositories/devel:/gcc/openSUSE_Leap_#{opensuse_version}/devel:gcc.repo"
	end
	defp repo({:clang, _clang_version}, {:opensuse, :tumbleweed}) do
		"https://download.opensuse.org/repositories/devel:/tools:/compiler/openSUSE_Factory/devel:tools:compiler.repo"
	end
	defp repo({:qt, 7}, {:opensuse, :tumbleweed}) do
		"https://download.opensuse.org/repositories/KDE:/Qt:/5.7/openSUSE_Factory/KDE:Qt:5.7.repo"
	end
	defp repo({:qt, qt_version}, {:opensuse, :tumbleweed}) do
		"https://download.opensuse.org/repositories/KDE:/Qt:/5.#{qt_version}/openSUSE_Tumbleweed/KDE:Qt:5.#{qt_version}.repo"
	end
	defp repo({:qt, qt_version}, {:opensuse, opensuse_version}) do
		"https://download.opensuse.org/repositories/KDE:/Qt:/5.#{qt_version}/openSUSE_Leap_#{opensuse_version}/KDE:Qt:5.#{qt_version}.repo"
	end

	defp package({:gcc, 4.8}) do
		"gcc48-c++"
	end
	defp package({:gcc, gcc_version}) do
		"gcc#{gcc_version}-c++"
	end
	defp package({:clang, clang_version}) do
		"clang#{clang_version}"
	end
	defp package({:qt, _qt_version}) do
		"libQt5Widgets-devel libQt5Test-devel libQt5Gui-devel libQt5Core-devel"
	end

	defp variables({:gcc, 4.8}) do
		[cc: "gcc-4.8", cxx: "g++-4.8"]
	end
	defp variables({:gcc, gcc_version}) do
		[cc: "gcc-#{gcc_version}", cxx: "g++-#{gcc_version}"]
	end
	defp variables({:clang, _clang_version}) do
		[cc: "clang", cxx: "clang++"]
	end

	defp baseimage({:opensuse, :tumbleweed}) do
		"opensuse/tumbleweed"
	end
	defp baseimage({:opensuse, opensuse_version}) when opensuse_version < 42.3 do
		"opensuse:#{opensuse_version}"
	end
	defp baseimage({:opensuse, opensuse_version}) do
		"opensuse/leap:#{opensuse_version}"
	end

	def branch(%{:compiler => {:gcc, 4.8}, :qt => qt_version}) do
		"docker-gcc4.8-qt5#{qt_version}"
	end
	def branch(%{:compiler => {comp, comp_version}, :qt => qt_version}) do
		"docker-#{comp}#{comp_version}-qt5#{qt_version}"
	end

	def dockerfile(%{:compiler => comp, :qt => qt}, distro) do
		baseimage = baseimage(distro)
		repos = [repo(comp, distro), repo({:qt, qt}, distro)]
		variables = variables(comp)
		packages = [package(comp), package({:qt, qt}), "cmake", "make"]
		dockerfile2(baseimage, variables, repos, packages)
	end
end

defmodule ResolveDistro do
	def resolve(%{:compiler => comp, :qt => qt_version}) do
		resolve2(comp, qt_version)
	end
	defp resolve2({:gcc, gcc_version}, qt_version) when gcc_version >= 7 and qt_version >= 7 do
		{:opensuse, :tumbleweed}
	end
	defp resolve2({:gcc, 4.8}, qt_version) when qt_version <= 8 do
		{:opensuse, 42.2}
	end
	defp resolve2({:gcc, 4.8}, qt_version) when qt_version >= 9 do
		{:opensuse, 42.3}
	end
	defp resolve2({:clang, _clang_version}, qt_version) when qt_version >= 7 do
		{:opensuse, :tumbleweed}
	end
	defp resolve2(_comp, _qt_version) do
		{:unresolved, nil}
	end
end

:ok = Application.ensure_started(:crypto)

qt_minor_versions = [9, 10, 11, 12]
gcc_versions = [7, 8, 9]
clang_versions = [4, 5, 6, 7]

environments_extra = [
	%{compiler: {:gcc, 4.8}, qt: 6},
	%{compiler: {:gcc, 4.8}, qt: 7},
	%{compiler: {:gcc, 4.8}, qt: 8},
	%{compiler: {:gcc, 4.8}, qt: 9},
	%{compiler: {:gcc, 4.8}, qt: 10},
	%{compiler: {:gcc, 4.8}, qt: 11},
]

compilers = (for x <- gcc_versions, do: {:gcc, x}) ++ (for x <- clang_versions, do: {:clang, x})
environments = (for comp <- compilers, qt <- qt_minor_versions, do: %{:compiler => comp, :qt => qt}) ++ environments_extra
environments_and_distros = for x <- environments, do: {x, ResolveDistro.resolve x}

{:ok, git_repo} = File.cwd()
{:ok, master_commit} = Git.show_ref(".", "refs/heads/master")

Enum.map(environments_and_distros, fn {env, distro} ->
	branch = "refs/heads/" <> Generator.branch(env);
	parents = case Git.show_ref(git_repo, branch) do
		{:ok, commit} -> [master_commit, commit]
		{:error, :not_found} -> [master_commit]
	end

	dockerfile = Generator.dockerfile(env, distro);
	dockerfile_hash = Git.write_blob(git_repo, dockerfile);
	tree_hash = Git.write_tree(git_repo, [{100755, dockerfile_hash, "Dockerfile"}]);

	commit = Git.write_commit(git_repo, tree_hash, parents, "Update Dockerfile");
	Git.update_ref(git_repo, branch, commit)
end)
