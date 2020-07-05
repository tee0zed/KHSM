# (c) goodprogrammer.ru

require 'rails_helper'
require 'support/my_spec_helper' # наш собственный класс с вспомогательными методами

# Тестовый сценарий для игрового контроллера
# Самые важные здесь тесты:
#   1. на авторизацию (чтобы к чужим юзерам не утекли не их данные)
#   2. на четкое выполнение самых важных сценариев (требований) приложения
#   3. на передачу граничных/неправильных данных в попытке сломать контроллер
#
RSpec.describe GamesController, type: :controller do
  # обычный пользователь
  let(:user) { FactoryBot.create(:user) }
  # админ
  let(:admin) { FactoryBot.create(:user, is_admin: true) }
  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }
  # анонимная игра с прописанными игровыми вопросами
  let(:anon_game_w_questions) { FactoryBot.create(:game_with_questions) }
  # группа тестов для незалогиненного юзера (Анонимус)
  context 'Anon' do
    it 'kicks from #show' do
      get :show, id: game_w_questions.id

      expect(response.status).not_to eq(200) # статус не 200 ОК
      expect(response).to redirect_to(new_user_session_path) # devise должен отправить на логин
      expect(flash[:alert]).to be # во flash должен быть прописана ошибка
    end

    let(:game) { assigns(:game) }
    
    ##другие контроллеры
    it 'kicks from #create' do
      generate_questions(15)

      post :create

      expect(game).to be_nil
      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    it 'kicks from #answer' do
      put :answer, id: anon_game_w_questions.id, letter: anon_game_w_questions.current_game_question.correct_answer_key

      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    it 'kicks from #take_money' do
      put :take_money, id: anon_game_w_questions.id

      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end
  end

  context 'Usual user' do
    before(:each) { sign_in user }
    let(:game) { assigns :game }
    let(:id) { game_w_questions.id }

    it '#create game' do
      generate_questions(15)

      post :create

      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)
      expect(response).to redirect_to(game_path(game))
      expect(flash[:notice]).to be
    end

    it '#show game' do
      get :show, id: id

      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)

      expect(response.status).to eq(200) # должен быть ответ HTTP 200
      expect(response).to render_template('show') # и отрендерить шаблон show
    end
    
    ## неправильный ответ
    it 'answers incorrect' do
      correct_answer = game_w_questions.current_game_question.correct_answer_key
      put :answer, id: id, letter: game_w_questions.current_game_question.variants.except(correct_answer).to_a.sample[0]

      expect(game.finished?).to be_truthy
      expect(game.current_level).to eq 0
      expect(response).to redirect_to(user_path(game))
      expect(flash[:alert]).to be
    end

    it 'kicks from #show foreign game' do
      get :show, id: anon_game_w_questions.id

      expect(response.status).not_to eq 200
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be
    end

    it 'takes money' do
      game_w_questions.update_attribute(:current_level, 2)

      put :take_money, id: id

      expect(game.finished?).to be_truthy
      expect(game.prize).to eq(200)

      user.reload
      expect(user.balance).to eq(200)

      expect(response).to redirect_to(user_path(user))
      expect(flash[:warning]).to be
    end

    it 'try to create second game' do
      expect(game_w_questions.finished?).to be_falsey

      expect { post :create }.to change(Game, :count).by(0)

      expect(game).to be_nil

      expect(response).to redirect_to(game_path(game_w_questions))
      expect(flash[:alert]).to be
    end

    it 'uses audience help' do
      # сперва проверяем что в подсказках текущего вопроса пусто
      expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
      expect(game_w_questions.audience_help_used?).to be false

      # фигачим запрос в контроллен с нужным типом
      put :help, id: game_w_questions.id, help_type: :audience_help

      # проверяем, что игра не закончилась, что флажок установился, и подсказка записалась
      expect(game.finished?).to be false
      expect(game.audience_help_used?).to be true
      expect(game.current_game_question.help_hash[:audience_help]).to be
      expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
      expect(response).to redirect_to(game_path(game))
    end

    it 'uses fifty fifty' do
      expect(game_w_questions.current_game_question.help_hash[:fifty_fifty]).not_to be
      expect(game_w_questions.fifty_fifty_used?).to be false

      put :help, id: game_w_questions.id, help_type: :fifty_fifty
      ca = game.current_game_question.correct_answer_key

      expect(game.finished?).to be false
      expect(game.fifty_fifty_used?).to be true
      expect(game.current_game_question.help_hash[:fifty_fifty]).to be
      expect(game.current_game_question.help_hash[:fifty_fifty].size).to eq 2
      expect(game.current_game_question.help_hash[:fifty_fifty]).to include ca
      expect(response).to redirect_to(game_path(game))
    end
  end
end
