require 'rails_helper'

RSpec.feature "USER wathces another users games", type: :feature do
  let(:user) { FactoryBot.create :user, id: '47', name: "Вася" }
  let(:anon_user) { FactoryBot.create :user, id: '11', name: "Anon" }

  let!(:game_one) do
    FactoryBot.create :game,
    user: user,
    created_at: Time.parse('2020.07.08, 10:00'),
    finished_at: Time.parse('2020.07.08, 12:00'),
    current_level: 51,
    is_failed: true,
    prize: 25000
  end

  let!(:game_two) do
    FactoryBot.create :game,
    user: user,
    created_at: Time.parse('2020.07.08, 13:00'),
    finished_at: nil,
    current_level: 34,
    is_failed: false,
    prize: 15000
  end

  after(:all) { logout }

  scenario 'rendered correctly for anonymous user' do
    visit '/'

    click_link "Вася"
    expect(page).not_to have_content('Сменить имя и пароль')

    expect(page).to have_current_path "/users/#{user.id}"

    expect(page).to have_content(game_one.id)
    expect(page).to have_content('время')
    expect(page).to have_content('08 июля, 10:00')
    expect(page).to have_content(game_one.current_level)
    expect(page).to have_content('25 000 ₽')

    expect(page).to have_content(game_two.id)
    expect(page).to have_content('в процессе')
    expect(page).to have_content('08 июля, 13:00')
    expect(page).to have_content("#{game_two.current_level}")
    expect(page).to have_content('15 000 ₽')
  end


  scenario 'rendered correctly for another user' do
    login_as anon_user

    visit '/'

    click_link "Вася"
    expect(page).not_to have_content('Сменить имя и пароль')

    expect(page).to have_current_path "/users/#{user.id}"

    expect(page).to have_content(game_one.id)
    expect(page).to have_content('время')
    expect(page).to have_content('08 июля, 10:00')
    expect(page).to have_content(game_one.current_level)
    expect(page).to have_content('25 000 ₽')

    expect(page).to have_content(game_two.id)
    expect(page).to have_content('в процессе')
    expect(page).to have_content('08 июля, 13:00')
    expect(page).to have_content(game_two.current_level)
    expect(page).to have_content('15 000 ₽')
  end


  scenario 'rendered correctly for user' do
    login_as user

    visit '/'

    click_link "Вася"
    expect(page).to have_content('Сменить имя и пароль')

    expect(page).to have_current_path "/users/#{user.id}"

    expect(page).to have_content(game_one.id)
    expect(page).to have_content('время')
    expect(page).to have_content('08 июля, 10:00')
    expect(page).to have_content(game_one.current_level)
    expect(page).to have_content('25 000 ₽')

    expect(page).to have_content(game_two.id)
    expect(page).to have_content('в процессе')
    expect(page).to have_content('08 июля, 13:00')
    expect(page).to have_content(game_two.current_level)
    expect(page).to have_content('15 000 ₽')
  end
end
