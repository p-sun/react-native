# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

# It builds the codegen CLI if it is not present
#
# @parameter react_native_path: the path to the react native installation
# @parameter relative_installation_root: the path to the relative installation root of the pods
# @throws an error if it could not find the codegen folder.
def build_codegen!(react_native_path, relative_installation_root)
    codegen_repo_path = "#{relative_installation_root}/#{react_native_path}/packages/react-native-codegen";
    codegen_npm_path = "#{relative_installation_root}/#{react_native_path}/../react-native-codegen";
    codegen_cli_path = ""

    if Dir.exist?(codegen_repo_path)
      codegen_cli_path = codegen_repo_path
    elsif Dir.exist?(codegen_npm_path)
      codegen_cli_path = codegen_npm_path
    else
      raise "[codegen] Couldn't not find react-native-codegen."
    end

    if !Dir.exist?("#{codegen_cli_path}/lib")
      Pod::UI.puts "[Codegen] building #{codegen_cli_path}."
      system("#{codegen_cli_path}/scripts/oss/build.sh")
    end
  end

# It generates an empty `ThirdPartyProvider`, required by Fabric to load the components
#
# @parameter react_native_path: path to the react native framework
# @parameter new_arch_enabled: whether the New Architecture is enabled or not
# @parameter codegen_output_dir: the output directory for the codegen
def checkAndGenerateEmptyThirdPartyProvider!(react_native_path, new_arch_enabled, codegen_output_dir)
    return if new_arch_enabled

    relative_installation_root = Pod::Config.instance.installation_root.relative_path_from(Pathname.pwd)

    output_dir = "#{relative_installation_root}/#{codegen_output_dir}"

    provider_h_path = "#{output_dir}/RCTThirdPartyFabricComponentsProvider.h"
    provider_cpp_path ="#{output_dir}/RCTThirdPartyFabricComponentsProvider.cpp"

    if(!File.exist?(provider_h_path) || !File.exist?(provider_cpp_path))
        # build codegen
        build_codegen!(react_native_path, relative_installation_root)

        # Just use a temp empty schema list.
        temp_schema_list_path = "#{output_dir}/tmpSchemaList.txt"
        File.open(temp_schema_list_path, 'w') do |f|
            f.write('[]')
            f.fsync
        end

        Pod::UI.puts '[Codegen] generating an empty RCTThirdPartyFabricComponentsProvider'
        Pod::Executable.execute_command(
        'node',
        [
            "#{relative_installation_root}/#{react_native_path}/scripts/generate-provider-cli.js",
            "--platform", 'ios',
            "--schemaListPath", temp_schema_list_path,
            "--outputDir", "#{output_dir}"
        ])
        File.delete(temp_schema_list_path) if File.exist?(temp_schema_list_path)
    end
end