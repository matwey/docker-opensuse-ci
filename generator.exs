#!/usr/bin/env elixir

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
	defp variables({:clang, clang_version}) do
		[cc: "clang-#{clang_version}", cxx: "clang++-#{clang_version}"]
	end

	defp baseimage({:opensuse, opensuse_version}) do
		"opensuse:#{opensuse_version}"
	end

	def path(%{:compiler => {:gcc, 4.8}, :qt => qt_version}) do
		"gcc4.8/qt5#{qt_version}"
	end
	def path(%{:compiler => {comp, comp_version}, :qt => qt_version}) do
		"#{comp}#{comp_version}/qt5#{qt_version}"
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

qt_minor_versions = [7, 8, 9, 10, 11]
gcc_versions = [7, 8]
clang_versions = [4, 5, 6]

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

Enum.map(environments_and_distros, fn {env, distro} -> path = Generator.path(env); :ok = File.mkdir_p(path); :ok = File.write(Path.join(path, "Dockerfile"), Generator.dockerfile(env, distro), [:binary]) end )
