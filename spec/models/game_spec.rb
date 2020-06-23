
# Стандартный rspec-овский помощник для rails-проекта
require 'rails_helper'

# Наш собственный класс с вспомогательными методами
require 'support/my_spec_helper'

# Тестовый сценарий для модели Игры
#
# В идеале — все методы должны быть покрыты тестами, в этом классе содержится
# ключевая логика игры и значит работы сайта.
RSpec.describe Game, type: :model do
  # Пользователь для создания игр
  let(:user) { FactoryBot.create(:user) }

  # Игра с прописанными игровыми вопросами
  let(:game_w_questions) do
    FactoryBot.create(:game_with_questions, user: user)
  end

  # Группа тестов на работу фабрики создания новых игр
  context 'Game Factory' do
    it 'Game.create_game! new correct game' do
      # Генерим 60 вопросов с 4х запасом по полю level, чтобы проверить работу
      # RANDOM при создании игры.
      generate_questions(60)

      game = nil

      # Создaли игру, обернули в блок, на который накладываем проверки
      expect {
        game = Game.create_game_for_user!(user)
        # Проверка: Game.count изменился на 1 (создали в базе 1 игру)
      }.to change(Game, :count).by(1).and(
        # GameQuestion.count +15
        change(GameQuestion, :count).by(15).and(
          # Game.count не должен измениться
          change(Question, :count).by(0)
        )
      )

      # Проверяем статус и поля
      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)

      # Проверяем корректность массива игровых вопросов
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  describe 'game mechanics' do
    before(:each) { @q = game_w_questions.current_game_question }

    context 'continues game' do
      before { @level = game_w_questions.current_level }

      it 'in_progress' do
        expect(game_w_questions.status).to eq(:in_progress)
        game_w_questions.answer_current_question!(@q.correct_answer_key)
        # Перешли на след. уровень
        expect(game_w_questions.current_level).to eq(@level + 1)
        # Ранее текущий вопрос стал предыдущим
        expect(game_w_questions.current_game_question).not_to eq(@q)
        # Игра продолжается
        expect(game_w_questions.status).to eq(:in_progress)
        expect(game_w_questions.finished?).to be_falsey
      end
    end

    context 'finishes the game' do
      let(:prize) { game_w_questions.prize }

      it 'take_money!' do
        game_w_questions.answer_current_question!(@q.correct_answer_key)

        # взяли деньги
        game_w_questions.take_money!

        expect(prize).to be > 0

        # проверяем что закончилась игра и пришли деньги игроку
        expect(game_w_questions.status).to eq :money
        expect(game_w_questions.finished?).to be_truthy
        expect(user.balance).to eq prize
      end
    end
  end

  # группа тестов на проверку статуса игры
  describe 'Game#status' do
    before(:each) {
      game_w_questions.finished_at = Time.now
      expect(game_w_questions.finished?).to be_truthy
    }

    context  'when won' do
      it ':won' do
        game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
        expect(game_w_questions.status).to eq(:won)
      end
    end

    context  'when fail' do
      it ':fail' do
        game_w_questions.is_failed = true
        expect(game_w_questions.status).to eq(:fail)
      end
    end

    context  'when timeout' do
      it ':timeout' do
        game_w_questions.created_at = 1.hour.ago
        game_w_questions.is_failed = true
        expect(game_w_questions.status).to eq(:timeout)
      end
    end

    context  'when take money' do
      it ':money' do
        expect(game_w_questions.status).to eq(:money)
      end
    end
  end

  describe 'Game#current_game_question' do
    context 'when level correct' do
      let(:level) { game_w_questions.current_level }
      let(:q) { game_w_questions.game_questions[level] }

      it 'current_question' do
        expect(game_w_questions.current_game_question).to eq(q)
      end
    end

    context 'when level incorrect' do
      before { game_w_questions.current_level = 16 }

      it 'nil' do
        expect(game_w_questions.current_game_question).to be_nil
      end
    end
  end

  describe 'Game#previous_level' do
    context 'when level above max' do
    before { game_w_questions.current_level = 5 }

      it '4' do
        expect(game_w_questions.previous_level).to eq(4)
      end
    end

    context 'when first level' do
    before { game_w_questions.current_level = 0 }

      it '-1' do
        expect(game_w_questions.previous_level).to eq(- 1)
      end
    end
  end

  describe 'Game#answer_current_question!' do
    context 'when time is out' do
      let(:letter) { game_w_questions.current_game_question.correct_answer_key }
      before { game_w_questions.created_at = 1.hour.ago }

      it 'false' do
        expect(game_w_questions.answer_current_question!(letter)).to be false
        expect(game_w_questions.status).to eq(:timeout)
        expect(game_w_questions).to be_finished
      end
    end

    before(:each) { game_w_questions.created_at = Time.now }

    context 'when answer is out of letter range' do
      let(:letter) { 'e' }

      it 'false' do
        expect(game_w_questions.answer_current_question!(letter)).to be false
        expect(game_w_questions.status).to eq(:fail)
        expect(game_w_questions).to be_finished
      end
    end

    context 'when answer is correct' do
      let(:letter) { game_w_questions.current_game_question.correct_answer_key }

      it 'in_progress' do
        expect(game_w_questions.answer_current_question!(letter)).to be_truthy
        expect(game_w_questions.status).to eq(:in_progress)
        expect(game_w_questions).not_to be_finished
      end

      context 'when question is last and answer is correct' do
        let(:letter) { game_w_questions.current_game_question.correct_answer_key }
        before { game_w_questions.current_level = Question::QUESTION_LEVELS.max }

        it 'won' do
          expect(game_w_questions.answer_current_question!(letter)).to be_truthy
          expect(game_w_questions.status).to eq(:won)
          expect(game_w_questions).to be_finished
        end
      end
    end
  end
end