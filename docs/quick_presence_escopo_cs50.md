# QuickPresence — Projeto Final CS50

## 1. Visão geral do projeto

O **QuickPresence** é uma aplicação web open source para criação de listas de presença temporárias com campos personalizados, link público, QR Code e exportação CSV.

A ideia principal é permitir que uma pessoa ou instituição crie rapidamente uma lista de presença para uma aula, palestra, evento, reunião, workshop ou treinamento. Após criar a lista, o sistema gera um link público e um QR Code. Os participantes acessam esse formulário, preenchem os campos definidos pelo criador e enviam a presença. Ao final, o criador pode visualizar as respostas e exportar os dados em formato `.csv`.

O projeto será desenvolvido como uma aplicação Rails full-stack, usando SQLite como banco de dados e Devise para autenticação.

---

## 2. Objetivo do projeto

Criar uma aplicação web simples e funcional que permita:

- cadastro e login de usuários;
- criação de listas de presença;
- definição de até 5 campos personalizados por lista;
- geração automática de link público;
- geração de QR Code para acesso rápido;
- preenchimento público da presença sem necessidade de login;
- controle de validade por data e hora;
- visualização das respostas recebidas;
- exportação das respostas em CSV.
- exclusão automática das respostas 48 horas após o fim da validade da lista.

---

## 3. Stack definida

```txt
Ruby on Rails
SQLite
Devise
ERB
Turbo
Stimulus
Tailwind CSS
Bootstrap
Gem rqrcode
Gem prawn
Gem prawn-svg
Gem csv
Foreman
```

A recomendação inicial é usar Rails renderizando views diretamente, sem React ou Angular no primeiro momento, para reduzir a complexidade e permitir uma entrega mais completa e bem acabada para o CS50.

Decisão atual do projeto:

- usar Tailwind CSS via `tailwindcss-rails`;
- usar Bootstrap para a interface principal e UX das páginas;
- usar `bin/dev` com Foreman para subir Rails e Tailwind watcher;
- cada lista possui seu próprio timezone, permitindo listas em São Paulo, Boston, California, Paris etc.;
- o timezone da lista é detectado automaticamente pelo navegador do criador, sem exigir escolha manual;
- os horários informados no formulário são interpretados no timezone detectado para a lista;
- contas de organizadores usam apenas username, sem e-mail;
- recuperação e troca de senha não estão disponíveis nesta versão, então a interface deve avisar o usuário para guardar a senha com segurança;
- manter todo conteúdo versionado do projeto em inglês;
- versionar os documentos de arquitetura, regras, escopo e operação em `docs/`;
- usar `docs/project-guidelines.md` como fonte central das regras de engenharia.

---

## 4. Nome sugerido

```txt
QuickPresence
```

Outras opções possíveis:

```txt
Open Attendance
Presence List
Presença Fácil
Lista QR
```

---

## 5. Tipo de usuário

### 5.1 Criador da lista

Usuário autenticado no sistema.

Pode:

- criar listas de presença;
- editar listas próprias;
- definir campos personalizados;
- definir período de validade;
- gerar link público;
- visualizar QR Code;
- acompanhar respostas;
- encerrar uma lista manualmente;
- exportar respostas em CSV.

### 5.2 Participante

Usuário público, sem login.

Pode:

- acessar o formulário via link ou QR Code;
- preencher os campos definidos pelo criador;
- enviar a presença enquanto a lista estiver aberta.

---

## 6. Fluxo principal da aplicação

Exemplo de uso:

1. O professor ou organizador cria uma conta.
2. Faz login.
3. Cria uma lista chamada `Aula de Banco de Dados`.
4. Define uma validade, por exemplo, das `19:00` às `19:20`.
5. Define os campos:
   - RA;
   - Nome;
   - Classe.
6. O sistema gera um link público, por exemplo:

```txt
https://seudominio.com/a/abc123
```

7. O sistema gera um QR Code apontando para esse link.
8. Os alunos acessam o QR Code e preenchem o formulário.
9. O sistema grava as respostas com timestamp fixo.
10. Após o envio, o participante vê uma página final de confirmação, sem voltar
    para o formulário em branco.
11. Após o fim da validade, o formulário não aceita mais respostas.
12. O professor baixa um CSV com os dados.

Exemplo de CSV:

```csv
Timestamp,RA,Nome,Classe
2026-06-08 19:03:12,123456,João Silva,DSM 3
2026-06-08 19:04:25,654321,Maria Souza,DSM 3
```

---

## 7. Escopo MVP

O MVP deve conter obrigatoriamente:

```txt
1. Criar app Rails com SQLite
2. Instalar Devise
3. Criar AttendanceList
4. Criar AttendanceField
5. Criar AttendanceResponse e AttendanceAnswer
6. Criar CRUD das listas
7. Criar formulário com até 5 campos
8. Gerar link público
9. Gerar QR Code
10. Exportar CSV
```

---

## 8. Funcionalidades do MVP

### 8.1 Autenticação

Usar Devise para:

- cadastro de usuário;
- login;
- logout;
- recuperação de senha, se desejar manter o módulo padrão.

### 8.2 CRUD de listas de presença

O usuário autenticado pode:

- listar suas listas;
- criar nova lista;
- visualizar detalhes da lista;
- editar lista;
- excluir lista;
- encerrar lista manualmente.

### 8.3 Campos personalizados

Cada lista pode ter no máximo 5 campos personalizados.

O timestamp de envio é gerado automaticamente pelo sistema e não conta como um dos 5 campos personalizados.

Exemplos:

```txt
RA
Nome
Classe
Cidade
Telefone
E-mail
Empresa
Curso
```

Para o MVP, os campos podem ser todos do tipo texto.

### 8.4 Link público

Cada lista deve ter um `public_token` único.

Esse token será usado para gerar uma rota pública:

```txt
/a/:public_token
```

Exemplo:

```txt
/a/abc123token
```

### 8.5 QR Code

O QR Code deve apontar para o link público da lista.

Usar a gem:

```ruby
gem "rqrcode"
```

### 8.6 Validade da lista

Cada lista poderá ter:

- data/hora de início: `starts_at`;
- data/hora de fim: `ends_at`;
- status ativo/inativo: `active`.

A lista estará aberta apenas se:

```txt
active == true
E agora >= starts_at, quando starts_at existir
E agora <= ends_at
```

Para proteger dados de terceiros, `ends_at` é obrigatório. As respostas ficam disponíveis para visualização/exportação por 48 horas após `ends_at`. Depois desse prazo, `AttendanceResponse` e `AttendanceAnswer` são removidos automaticamente pelo job recorrente `PurgeExpiredAttendanceResponsesJob`.

### 8.7 Respostas públicas

Participantes podem preencher o formulário público sem login.

Cada resposta deve salvar:

- lista relacionada;
- timestamp do envio;
- IP do participante, opcional;
- user agent, opcional;
- respostas dos campos.

### 8.8 Exportação CSV

O criador da lista pode baixar um `.csv` contendo:

- timestamp;
- uma coluna para cada campo personalizado;
- uma linha para cada resposta.

---

## 9. Modelagem de dados

Models principais:

```txt
User
AttendanceList
AttendanceField
AttendanceResponse
AttendanceAnswer
```

Relacionamentos:

```txt
User
 └── has_many AttendanceLists

AttendanceList
 ├── belongs_to User
 ├── has_many AttendanceFields
 └── has_many AttendanceResponses

AttendanceResponse
 ├── belongs_to AttendanceList
 └── has_many AttendanceAnswers

AttendanceAnswer
 ├── belongs_to AttendanceResponse
 └── belongs_to AttendanceField
```

---

## 10. Criação do projeto Rails

Comando sugerido:

```bash
rails new quick_presence -d sqlite3
cd quick_presence
```

Rodar o servidor:

```bash
bin/dev
```

---

## 11. Gems necessárias

No `Gemfile`, adicionar:

```ruby
gem "devise", "~> 5.0"
gem "rqrcode", "~> 3.2"
gem "tailwindcss-rails", "~> 4.4"
gem "foreman", "~> 0.90.0", group: :development
gem "csv", "~> 3.3"
```

Depois rodar:

```bash
bundle install
```

Status atual:

- Devise instalado com `bin/rails generate devise:install`;
- Tailwind instalado com `bin/rails tailwindcss:install`;
- Bootstrap adicionado ao layout via CDN para melhorar a interface e navegação;
- gem `csv` adicionada explicitamente, pois o Ruby atual não a carrega como dependência padrão;
- `bin/dev` ajustado para usar `bundle exec foreman`;
- README e licença em inglês;
- licença MIT adicionada;
- pasta `docs/` versionada com regras, escopo, deploy e aprendizados.

Instalar Devise:

```bash
bin/rails generate devise:install
bin/rails generate devise User
bin/rails db:migrate
```

---

## 12. Model User

Gerado pelo Devise.

Exemplo esperado:

```ruby
class User < ApplicationRecord
  has_many :attendance_lists, dependent: :destroy

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable
end
```

---

## 13. Model AttendanceList

### 13.1 Generator

```bash
bin/rails generate model AttendanceList user:references title:string description:text public_token:string starts_at:datetime ends_at:datetime active:boolean
```

### 13.2 Migration sugerida

Ajustar a migration para algo semelhante a:

```ruby
class CreateAttendanceLists < ActiveRecord::Migration[8.0]
  def change
    create_table :attendance_lists do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :public_token, null: false
      t.datetime :starts_at
      t.datetime :ends_at
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :attendance_lists, :public_token, unique: true
  end
end
```

### 13.3 Model

```ruby
class AttendanceList < ApplicationRecord
  belongs_to :user

  has_many :attendance_fields, dependent: :destroy
  has_many :attendance_responses, dependent: :destroy

  accepts_nested_attributes_for :attendance_fields, allow_destroy: true

  before_validation :generate_public_token, on: :create

  validates :title, presence: true
  validates :public_token, presence: true, uniqueness: true
  validate :maximum_of_five_fields
  validate :ends_at_after_starts_at

  def open?
    return false unless active?

    now = Time.current

    return false if starts_at.present? && now < starts_at
    return false if ends_at.present? && now > ends_at

    true
  end

  def closed?
    !open?
  end

  private

  def generate_public_token
    self.public_token ||= SecureRandom.urlsafe_base64(10)
  end

  def maximum_of_five_fields
    valid_fields = attendance_fields.reject(&:marked_for_destruction?)

    if valid_fields.size > 5
      errors.add(:attendance_fields, "permite no máximo 5 campos")
    end
  end

  def ends_at_after_starts_at
    return if starts_at.blank? || ends_at.blank?

    if ends_at <= starts_at
      errors.add(:ends_at, "deve ser depois da data/hora inicial")
    end
  end
end
```

---

## 14. Model AttendanceField

### 14.1 Generator

```bash
bin/rails generate model AttendanceField attendance_list:references label:string field_type:string required:boolean position:integer
```

### 14.2 Migration sugerida

```ruby
class CreateAttendanceFields < ActiveRecord::Migration[8.0]
  def change
    create_table :attendance_fields do |t|
      t.references :attendance_list, null: false, foreign_key: true
      t.string :label, null: false
      t.string :field_type, null: false, default: "text"
      t.boolean :required, null: false, default: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
```

### 14.3 Model

```ruby
class AttendanceField < ApplicationRecord
  belongs_to :attendance_list

  validates :label, presence: true
  validates :field_type, presence: true
  validates :position, numericality: { greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position, :id) }
end
```

---

## 15. Model AttendanceResponse

### 15.1 Generator

```bash
bin/rails generate model AttendanceResponse attendance_list:references submitted_at:datetime ip_address:string user_agent:string
```

### 15.2 Migration sugerida

```ruby
class CreateAttendanceResponses < ActiveRecord::Migration[8.0]
  def change
    create_table :attendance_responses do |t|
      t.references :attendance_list, null: false, foreign_key: true
      t.datetime :submitted_at, null: false
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end
  end
end
```

### 15.3 Model

```ruby
class AttendanceResponse < ApplicationRecord
  belongs_to :attendance_list

  has_many :attendance_answers, dependent: :destroy

  accepts_nested_attributes_for :attendance_answers

  before_validation :set_submitted_at, on: :create

  validates :submitted_at, presence: true
  validate :attendance_list_must_be_open

  private

  def set_submitted_at
    self.submitted_at ||= Time.current
  end

  def attendance_list_must_be_open
    return if attendance_list&.open?

    errors.add(:base, "Esta lista de presença está fechada")
  end
end
```

---

## 16. Model AttendanceAnswer

### 16.1 Generator

```bash
bin/rails generate model AttendanceAnswer attendance_response:references attendance_field:references value:text
```

### 16.2 Migration sugerida

```ruby
class CreateAttendanceAnswers < ActiveRecord::Migration[8.0]
  def change
    create_table :attendance_answers do |t|
      t.references :attendance_response, null: false, foreign_key: true
      t.references :attendance_field, null: false, foreign_key: true
      t.text :value

      t.timestamps
    end
  end
end
```

### 16.3 Model

```ruby
class AttendanceAnswer < ApplicationRecord
  belongs_to :attendance_response
  belongs_to :attendance_field

  validate :required_field_must_have_value

  private

  def required_field_must_have_value
    return unless attendance_field&.required?

    if value.blank?
      errors.add(:value, "não pode ficar em branco")
    end
  end
end
```

---

## 17. Rodar migrations

Depois de criar e ajustar as migrations:

```bash
bin/rails db:migrate
```

---

## 18. Rotas

Arquivo `config/routes.rb` sugerido:

```ruby
Rails.application.routes.draw do
  devise_for :users

  authenticated :user do
    root "attendance_lists#index", as: :authenticated_root
  end

  unauthenticated do
    root "home#index"
  end

  resources :attendance_lists do
    member do
      get :qr_code
      get :responses
      get :export
      patch :close
    end
  end

  get "/a/:public_token", to: "public_attendance#show", as: :public_attendance
  post "/a/:public_token", to: "public_attendance#create"
  get "/a/:public_token/confirmed", to: "public_attendance#confirmed", as: :public_attendance_confirmation
end
```

Rotas privadas:

```txt
/attendance_lists
/attendance_lists/new
/attendance_lists/:id
/attendance_lists/:id/edit
/attendance_lists/:id/responses
/attendance_lists/:id/export
/attendance_lists/:id/qr_code
```

Rotas públicas:

```txt
/a/:public_token
```

---

## 19. Controllers necessários

Criar controllers:

```bash
bin/rails generate controller Home index
bin/rails generate controller AttendanceLists
bin/rails generate controller PublicAttendance
```

---

## 20. AttendanceListsController

Responsável pela área logada do criador da lista.

```ruby
class AttendanceListsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_attendance_list, only: [
    :show,
    :edit,
    :update,
    :destroy,
    :responses,
    :export,
    :close
  ]

  def index
    @attendance_lists = current_user.attendance_lists.order(created_at: :desc)
  end

  def show
  end

  def new
    @attendance_list = current_user.attendance_lists.new
    3.times { @attendance_list.attendance_fields.build }
  end

  def create
    @attendance_list = current_user.attendance_lists.new(attendance_list_params)

    if @attendance_list.save
      redirect_to @attendance_list, notice: "Lista criada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @attendance_list.update(attendance_list_params)
      redirect_to @attendance_list, notice: "Lista atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @attendance_list.destroy
    redirect_to attendance_lists_path, notice: "Lista removida com sucesso."
  end

  def responses
    @responses = @attendance_list.attendance_responses
      .includes(attendance_answers: :attendance_field)
      .order(submitted_at: :desc)
  end

  def close
    @attendance_list.update!(active: false)
    redirect_to @attendance_list, notice: "Lista encerrada com sucesso."
  end

  def export
    fields = @attendance_list.attendance_fields.ordered
    responses = @attendance_list.attendance_responses
      .includes(attendance_answers: :attendance_field)
      .order(:submitted_at)

    csv_data = CSV.generate(headers: true) do |csv|
      csv << ["Timestamp"] + fields.map(&:label)

      responses.each do |response|
        answers_by_field_id = response.attendance_answers.index_by(&:attendance_field_id)

        row = [response.submitted_at.strftime("%Y-%m-%d %H:%M:%S")]

        fields.each do |field|
          row << answers_by_field_id[field.id]&.value
        end

        csv << row
      end
    end

    send_data csv_data,
      filename: "attendance-list-#{@attendance_list.id}.csv",
      type: "text/csv"
  end

  private

  def set_attendance_list
    @attendance_list = current_user.attendance_lists.find(params[:id])
  end

  def attendance_list_params
    params.require(:attendance_list).permit(
      :title,
      :description,
      :starts_at,
      :ends_at,
      :active,
      attendance_fields_attributes: [
        :id,
        :label,
        :field_type,
        :required,
        :position,
        :_destroy
      ]
    )
  end
end
```

Importante: adicionar no topo do controller ou em um arquivo adequado:

```ruby
require "csv"
```

---

## 21. PublicAttendanceController

Responsável pelo formulário público acessado via QR Code ou link.

```ruby
class PublicAttendanceController < ApplicationController
  before_action :set_attendance_list

  def show
    unless @attendance_list.open?
      render :closed
      return
    end

    @attendance_response = @attendance_list.attendance_responses.new

    @attendance_list.attendance_fields.ordered.each do |field|
      @attendance_response.attendance_answers.build(attendance_field: field)
    end
  end

  def create
    unless @attendance_list.open?
      redirect_to public_attendance_path(@attendance_list.public_token),
        alert: "Esta lista de presença está fechada."
      return
    end

    @attendance_response = @attendance_list.attendance_responses.new(
      submitted_at: Time.current,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )

    build_answers

    if @attendance_response.save
      redirect_to public_attendance_confirmation_path(@attendance_list.public_token),
        notice: "Presença registrada com sucesso.",
        status: :see_other
    else
      render :show, status: :unprocessable_entity
    end
  end

  def confirmed
  end

  private

  def set_attendance_list
    @attendance_list = AttendanceList.find_by!(public_token: params[:public_token])
  end

  def build_answers
    answers_params = params.fetch(:answers, {})

    @attendance_list.attendance_fields.ordered.each do |field|
      @attendance_response.attendance_answers.build(
        attendance_field: field,
        value: answers_params[field.id.to_s]
      )
    end
  end
end
```

---

## 22. Helper para QR Code

Criar um helper, por exemplo em `app/helpers/qr_code_helper.rb`:

```ruby
module QrCodeHelper
  def qr_code_svg(url)
    qrcode = RQRCode::QRCode.new(url)

    qrcode.as_svg(
      color: "000",
      shape_rendering: "crispEdges",
      module_size: 6,
      standalone: true,
      use_path: true
    ).html_safe
  end
end
```

Na view:

```erb
<%= qr_code_svg(public_attendance_url(@attendance_list.public_token)) %>
```

---

## 23. Views principais

Criar views para:

```txt
app/views/home/index.html.erb
app/views/attendance_lists/index.html.erb
app/views/attendance_lists/show.html.erb
app/views/attendance_lists/new.html.erb
app/views/attendance_lists/edit.html.erb
app/views/attendance_lists/_form.html.erb
app/views/attendance_lists/responses.html.erb
app/views/public_attendance/show.html.erb
app/views/public_attendance/closed.html.erb
```

---

## 24. Formulário de criação da lista

O formulário da lista deve permitir:

- título;
- descrição;
- data/hora de início;
- data/hora de fim;
- ativo/inativo;
- até 5 campos personalizados.

Exemplo de estrutura esperada:

```erb
<%= form_with model: @attendance_list do |form| %>
  <div>
    <%= form.label :title, "Título" %>
    <%= form.text_field :title, required: true %>
  </div>

  <div>
    <%= form.label :description, "Descrição" %>
    <%= form.text_area :description %>
  </div>

  <div>
    <%= form.label :starts_at, "Início" %>
    <%= form.datetime_field :starts_at %>
  </div>

  <div>
    <%= form.label :ends_at, "Fim" %>
    <%= form.datetime_field :ends_at %>
  </div>

  <h2>Campos da lista</h2>

  <%= form.fields_for :attendance_fields do |field_form| %>
    <div>
      <%= field_form.label :label, "Nome do campo" %>
      <%= field_form.text_field :label %>

      <%= field_form.hidden_field :field_type, value: "text" %>
      <%= field_form.hidden_field :position %>

      <%= field_form.label :required, "Obrigatório" %>
      <%= field_form.check_box :required %>
    </div>
  <% end %>

  <%= form.submit "Salvar" %>
<% end %>
```

Observação: no MVP, construir inicialmente 3 campos no `new`. Depois, se desejar, evoluir com Stimulus para adicionar/remover campos dinamicamente até o limite de 5.

---

## 25. View pública do formulário

Arquivo sugerido:

```txt
app/views/public_attendance/show.html.erb
```

Exemplo:

```erb
<h1><%= @attendance_list.title %></h1>

<p><%= @attendance_list.description %></p>

<p>
  Os dados informados serão usados apenas para controle de presença desta lista.
</p>

<%= form_with url: public_attendance_path(@attendance_list.public_token), method: :post do %>
  <% @attendance_list.attendance_fields.ordered.each do |field| %>
    <div class="mb-3">
      <%= label_tag "answers_#{field.id}", field.label, class: "form-label" %>

      <%= text_field_tag "answers[#{field.id}]",
                         nil,
                         class: "form-control",
                         required: field.required? %>
    </div>
  <% end %>

  <%= submit_tag "Registrar presença", class: "btn btn-primary" %>
<% end %>
```

---

## 25.1 View de confirmação pública

Depois de salvar uma resposta com sucesso, o participante deve ser redirecionado
para uma página final de confirmação:

```txt
/a/:public_token/confirmed
```

Essa página não deve exibir o formulário novamente. Ela deve informar que a
presença foi registrada e oferecer um caminho claro para voltar ao início da
aplicação.

Arquivo:

```txt
app/views/public_attendance/confirmed.html.erb
```

Motivo da regra: voltar ao formulário vazio após um envio bem-sucedido pode
confundir o participante e levá-lo a preencher a presença novamente.

---

## 26. View de lista fechada

Arquivo:

```txt
app/views/public_attendance/closed.html.erb
```

Exemplo:

```erb
<h1>Lista encerrada</h1>

<p>Esta lista de presença não está mais aceitando respostas.</p>
```

---

## 27. View de detalhes da lista

A tela `show` da lista deve mostrar:

- título;
- descrição;
- status aberta/fechada;
- período de validade;
- link público;
- QR Code;
- botão para ver respostas;
- botão para exportar CSV;
- botão para encerrar lista.

Exemplo de link público:

```erb
<%= public_attendance_url(@attendance_list.public_token) %>
```

Exemplo de QR Code:

```erb
<%= qr_code_svg(public_attendance_url(@attendance_list.public_token)) %>
```

Exemplo de botão CSV:

```erb
<%= link_to "Baixar CSV", export_attendance_list_path(@attendance_list), class: "btn btn-success" %>
```

Exemplo de botão encerrar:

```erb
<%= button_to "Encerrar lista", close_attendance_list_path(@attendance_list), method: :patch, class: "btn btn-warning" %>
```

---

## 28. View de respostas

A tela de respostas deve montar uma tabela dinâmica.

Cabeçalho:

```txt
Timestamp + labels dos campos
```

Linhas:

```txt
Uma linha por AttendanceResponse
```

Lógica esperada:

```erb
<table>
  <thead>
    <tr>
      <th>Timestamp</th>
      <% @attendance_list.attendance_fields.ordered.each do |field| %>
        <th><%= field.label %></th>
      <% end %>
    </tr>
  </thead>

  <tbody>
    <% @responses.each do |response| %>
      <% answers_by_field_id = response.attendance_answers.index_by(&:attendance_field_id) %>

      <tr>
        <td><%= response.submitted_at.strftime("%Y-%m-%d %H:%M:%S") %></td>

        <% @attendance_list.attendance_fields.ordered.each do |field| %>
          <td><%= answers_by_field_id[field.id]&.value %></td>
        <% end %>
      </tr>
    <% end %>
  </tbody>
</table>
```

---

## 29. Regras de negócio

### 29.1 Limite de campos

Cada lista deve ter no máximo 5 campos personalizados.

O timestamp é uma coluna automática da resposta/exportação CSV e não entra nessa contagem de 5 campos.

Implementado no model `AttendanceList` com validação:

```ruby
validate :maximum_of_five_fields
```

### 29.2 Token público único

Cada lista deve ter um token público único.

Implementado com:

```ruby
before_validation :generate_public_token, on: :create
validates :public_token, presence: true, uniqueness: true
```

E índice único no banco:

```ruby
add_index :attendance_lists, :public_token, unique: true
```

### 29.3 Validade da lista

A lista só aceita respostas quando estiver aberta.

Método:

```ruby
def open?
  return false unless active?

  now = Time.current

  return false if starts_at.present? && now < starts_at
  return false if ends_at.present? && now > ends_at

  true
end
```

### 29.4 Timestamp fixo

Toda resposta deve salvar `submitted_at` automaticamente.

```ruby
before_validation :set_submitted_at, on: :create
```

### 29.5 Campos obrigatórios

Se o campo estiver marcado como obrigatório, a resposta não pode ficar vazia.

Implementado em `AttendanceAnswer`.

---

## 30. Cuidados com privacidade

Como o sistema pode coletar dados pessoais, a página pública deve exibir uma mensagem simples:

```txt
Os dados informados serão usados apenas para controle de presença desta lista.
```

Evitar no MVP campos sensíveis como:

```txt
CPF
RG
Endereço completo
Dados de saúde
Dados financeiros
```

Status atual:

- o projeto não usa analytics, pixels de publicidade, cookies de marketing ou
  perfilamento comportamental;
- o projeto usa cookies de sessão e tokens de segurança necessários para login,
  autenticação e proteção dos formulários;
- assets versionados podem ser guardados no cache do navegador para melhorar
  carregamento;
- o aviso de privacidade pode guardar uma marca local no navegador apenas para
  lembrar que o usuário já reconheceu o aviso;
- a rota `/privacy` explica o uso de armazenamento essencial e o que não é
  usado atualmente;
- qualquer analytics, marketing, pixel, tracker ou armazenamento não essencial
  deve ser opt-in e não pode carregar antes do consentimento do usuário.

Observação operacional: Bootstrap ainda é carregado via CDN no layout atual. Ele
não é usado como tracker, mas envolve requisição a um terceiro. Para uma postura
mais conservadora de privacidade, preferir empacotar dependências de interface
localmente em uma evolução futura.

No README, incluir aviso:

```txt
Este projeto foi criado para fins educacionais. Ao usar em ambientes reais, colete apenas os dados necessários para a finalidade da lista de presença.
```

---

## 31. Melhorias futuras

Após o MVP, considerar:

```txt
Evitar respostas duplicadas usando um campo identificador, como RA ou e-mail
Permitir download da imagem do QR Code
Adicionar dashboard com total de listas e respostas
Adicionar templates de campos
Adicionar suporte a tipos de campo, como e-mail, telefone e número
Adicionar internacionalização pt-BR/en-US
Adicionar testes automatizados
Adicionar Docker
Adicionar modo dark
Adicionar API JSON no futuro
```

---

## 32. Evitar duplicidade — ideia futura

Não é obrigatório no MVP.

Uma melhoria possível é permitir que o criador marque um campo como identificador único.

Exemplo:

```txt
RA
E-mail
Telefone
```

Adicionar em `attendance_fields`:

```ruby
t.boolean :unique_identifier, null: false, default: false
```

Quando uma nova resposta for enviada, o sistema verifica se já existe uma resposta com o mesmo valor para aquele campo naquela lista.

Para o MVP, não implementar ainda, a menos que sobre tempo.

---

## 33. Estrutura de pastas esperada

```txt
quick_presence/
├── app/
│   ├── controllers/
│   │   ├── attendance_lists_controller.rb
│   │   ├── public_attendance_controller.rb
│   │   └── home_controller.rb
│   ├── helpers/
│   │   └── qr_code_helper.rb
│   ├── models/
│   │   ├── user.rb
│   │   ├── attendance_list.rb
│   │   ├── attendance_field.rb
│   │   ├── attendance_response.rb
│   │   └── attendance_answer.rb
│   └── views/
│       ├── attendance_lists/
│       │   ├── index.html.erb
│       │   ├── show.html.erb
│       │   ├── new.html.erb
│       │   ├── edit.html.erb
│       │   ├── _form.html.erb
│       │   └── responses.html.erb
│       ├── public_attendance/
│       │   ├── show.html.erb
│       │   └── closed.html.erb
│       └── home/
│           └── index.html.erb
├── config/
│   └── routes.rb
├── db/
│   ├── migrate/
│   └── schema.rb
├── Gemfile
└── README.md
```

---

## 34. Ordem de implementação recomendada

### Passo 1 — Criar app Rails com SQLite

```bash
rails new quick_presence -d sqlite3
cd quick_presence
bin/dev
```

### Passo 2 — Instalar Devise

```bash
bundle add devise
bin/rails generate devise:install
bin/rails generate devise User
bin/rails db:migrate
```

Adicionar relação no `User`:

```ruby
has_many :attendance_lists, dependent: :destroy
```

### Passo 3 — Criar AttendanceList

```bash
bin/rails generate model AttendanceList user:references title:string description:text public_token:string starts_at:datetime ends_at:datetime active:boolean
```

Ajustar migration e model conforme especificado.

### Passo 4 — Criar AttendanceField

```bash
bin/rails generate model AttendanceField attendance_list:references label:string field_type:string required:boolean position:integer
```

Ajustar migration e model conforme especificado.

### Passo 5 — Criar AttendanceResponse e AttendanceAnswer

```bash
bin/rails generate model AttendanceResponse attendance_list:references submitted_at:datetime ip_address:string user_agent:string
bin/rails generate model AttendanceAnswer attendance_response:references attendance_field:references value:text
```

Ajustar migrations e models conforme especificado.

### Passo 6 — Rodar migrations

```bash
bin/rails db:migrate
```

### Passo 7 — Criar rotas

Configurar `config/routes.rb` conforme especificado.

### Passo 8 — Criar controllers

```bash
bin/rails generate controller Home index
bin/rails generate controller AttendanceLists
bin/rails generate controller PublicAttendance
```

Implementar controllers conforme escopo.

### Passo 9 — Criar CRUD das listas

Criar views:

```txt
index
show
new
edit
_form
```

### Passo 10 — Criar formulário com até 5 campos

Usar `accepts_nested_attributes_for :attendance_fields`.

No `new`, iniciar com alguns campos:

```ruby
3.times { @attendance_list.attendance_fields.build }
```

Validar limite no model.

### Passo 11 — Gerar link público

Usar `public_token` e rota:

```txt
/a/:public_token
```

### Passo 12 — Criar formulário público

Criar `PublicAttendanceController` com `show` e `create`.

### Passo 13 — Gerar QR Code

Instalar:

```bash
bundle add rqrcode
```

Criar helper `qr_code_svg`.

### Passo 14 — Exportar CSV

Implementar action `export` em `AttendanceListsController`.

### Passo 15 — Melhorar visual

O projeto já está configurado com Tailwind CSS via gem `tailwindcss-rails`, mas a interface principal usa Bootstrap no layout e nas views para uma UX mais amigável.

---

## 35. README inicial sugerido

```md
# QuickPresence

QuickPresence is an open source web application built with Ruby on Rails and SQLite for creating temporary attendance lists with custom fields, public links, QR Codes, and CSV export.

## Features

- User authentication with Devise
- Create attendance lists
- Add up to 5 custom fields per list
- Generate public attendance links
- Generate QR Codes
- Accept public responses without login
- Control list availability by start and end time
- View submitted responses
- Export responses to CSV

## Tech Stack

- Ruby on Rails
- SQLite
- Devise
- RQRCode
- ERB
- Turbo
- Stimulus

## Privacy Notice

This project was created for educational purposes. When using it in real
environments, collect only the data necessary for attendance control.

The application provides a `/privacy` page and a first-access notice explaining
that QuickPresence currently uses only essential cookies and browser storage.
Optional analytics, marketing, advertising pixels, behavioral profiling, or any
other non-essential browser storage must be disabled by default and enabled only
after clear user consent.
```

---

## 36. Licença open source recomendada

Usar licença MIT.

Arquivo:

```txt
LICENSE
```

No README:

```md
## License

This project is licensed under the MIT License.
```

---

## 37. Resumo final do escopo

O projeto final será uma aplicação Rails chamada **QuickPresence**, criada para gerar listas de presença temporárias com QR Code.

O usuário autenticado cria uma lista, define até 5 campos personalizados, escolhe o período de validade e compartilha o link ou QR Code. Os participantes acessam o formulário público, registram presença e o criador pode visualizar as respostas e exportar tudo em CSV.

Este projeto é adequado para o CS50 porque demonstra:

```txt
autenticação
CRUD
modelagem relacional
validações
rotas privadas e públicas
geração de token
controle de tempo
formulários dinâmicos
exportação CSV
geração de QR Code
interface web
boas práticas de privacidade
```
