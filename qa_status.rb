require 'builder'

# Definindo as tags em variáveis
tags = ['@unit', '@api', '@manual', '@e2e']

# Inicializando um hash para armazenar os cenários por tag e a contagem de cenários por tag
scenarios_by_tag = Hash.new { |hash, key| hash[key] = {} }

# Listando todos os arquivos com a extensão .feature no diretório
Dir.glob('*.feature').each do |file_name|
  # Inicializando variáveis para armazenar os dados do arquivo atual
  current_tag = nil
  current_scenario = ''
  current_feature = ''

  # Abrindo cada arquivo .feature para leitura
  File.open(file_name, 'r') do |file|
    # Resetando o valor atual do recurso (Feature)
    current_feature = ''

    # Iterando por cada linha do arquivo
    file.each_line do |line|
      # Verificando se a linha contém o nome do recurso (Feature)
      if line.strip.start_with?('Feature:')
        current_feature = line.strip.gsub('Feature:', '').strip
      # Verificando se a linha contém uma tag e atualizando a tag atual
      elsif tags.any? { |tag| line.include?(tag) }
        current_tag = line.strip
      # Verificando se a linha contém a descrição do cenário e armazenando-o no hash correspondente à tag atual
      elsif line.strip.start_with?('Scenario:')
        # Adicionando o cenário ao hash com o nome do arquivo e do recurso (Feature)
        scenarios_by_tag[current_tag][current_feature] ||= []
        scenarios_by_tag[current_tag][current_feature] << { file: file_name, scenario: current_scenario } unless current_scenario.empty?
        current_scenario = line.strip
      elsif line.strip.start_with?('Given', 'When', 'Then', 'And', 'But')
        # Concatenando as linhas que contêm passos do cenário na descrição do cenário
        current_scenario += "\n" + line.strip
      end
    end

    # Adicionando o último cenário ao hash
    scenarios_by_tag[current_tag][current_feature] ||= []
    scenarios_by_tag[current_tag][current_feature] << { file: file_name, scenario: current_scenario } unless current_scenario.empty?
  end
end

# Criando o arquivo HTML
File.open('test_results.html', 'w') do |html|
  builder = Builder::XmlMarkup.new(target: html, indent: 2)

  # Começando a estrutura do HTML
  builder.html do
    builder.head do
      builder.title 'Resultados dos Testes'
      builder.style <<-CSS
        body {
          font-family: Arial, sans-serif;
          margin: 20px;
        }
        .tag {
          margin-bottom: 20px;
        }
        .tag h2 {
          margin-bottom: 5px;
          color: blue;
        }
        .feature {
          margin-bottom: 10px;
          padding-left: 20px;
          border-left: 2px solid green;
        }
        .scenario {
          list-style-type: none;
          margin-left: 0;
          padding-left: 20px;
        }
        .scenario li {
          margin-bottom: 5px;
        }
      CSS
    end
    builder.body do
      # Iterando sobre cada tag e quantidade de cenários
      scenarios_by_tag.each do |tag, features|
        builder.div class: 'tag' do
          builder.h2 tag
          builder.p "Quantidade de cenários: #{features.values.flatten.size}"

          # Iterando sobre cada recurso (Feature) dentro da tag
          features.each do |feature, scenarios|
            builder.div class: 'feature' do
              builder.h3 feature
              builder.ul class: 'scenario' do
                # Listando cada cenário com o nome do arquivo
                scenarios.each do |scenario_info|
                  builder.li "#{scenario_info[:file]}: #{scenario_info[:scenario]}"
                end
              end
            end
          end
        end
      end
    end
  end
end
