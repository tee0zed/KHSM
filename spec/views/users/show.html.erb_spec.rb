require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  context 'viewed by foreign user' do
    before(:each) do
      current_user = assign(:user, FactoryBot.build_stubbed(:user, name: 'Вася Пупкин'))
      allow(view).to receive(:current_user).and_return(current_user)

      render
    end

    it 'renders user name' do
      expect(rendered).to match 'Вася Пупкин'
    end

    it 'doesnt render change password button' do
      expect(rendered).to match 'Сменить имя и пароль'
    end

    it 'renders game partial' do
      assign(:games, [FactoryBot.build_stubbed(:game)])
      stub_template 'users/_game.html.erb' => "User game goes here"

      render
      expect(rendered).to match "User game goes here"
    end
  end

  context 'viewed by foreign user' do
    before(:each) do
      assign(:user, FactoryBot.build_stubbed(:user, name: 'Вася Пупкин'))

      render
    end

    it 'renders change password button' do
      expect(rendered).not_to match 'Сменить имя и пароль'
    end
  end
end