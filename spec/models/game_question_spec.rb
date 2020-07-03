
require 'rails_helper'

# Тестовый сценарий для модели игрового вопроса, в идеале весь наш функционал
# (все методы) должны быть протестированы.
RSpec.describe GameQuestion, type: :model do
  # Задаем локальную переменную game_question, доступную во всех тестах этого
  # сценария: она будет создана на фабрике заново для каждого блока it,
  # где она вызывается.
  let(:game_question) do
    FactoryBot.create(:game_question, a: 2, b: 1, c: 4, d: 3)
  end

  let(:bad_game_question) do
    FactoryBot.create(:game_question, a: 2, b: 2, c: 3, d: 4)
  end

  # Группа тестов на игровое состояние объекта вопроса
  context 'game status' do

    # Тест на правильную генерацию хэша с вариантами
    it 'correct .variants' do
      expect(game_question.variants).to eq(
        'a' => game_question.question.answer2,
        'b' => game_question.question.answer1,
        'c' => game_question.question.answer4,
        'd' => game_question.question.answer3
      )
    end

    # Тест на наличие делегатов level и text
    it 'correct .level & .text delegates' do
      expect(game_question.text).to eq(game_question.question.text)
      expect(game_question.level).to eq(game_question.question.level)
    end

    it 'correct .answer_correct?' do
      # Именно под буквой b в тесте мы спрятали указатель на верный ответ
      expect(game_question.answer_correct?('b')).to be_truthy
    end

    it 'correct.correct_answer_key' do
      expect(game_question.correct_answer_key).to eq 'b'
    end

    it 'bad .correct_answer_key' do
      expect(bad_game_question.correct_answer_key).to be_nil
    end

    context 'user helpers' do
      it 'correct audience_help' do
        expect(game_question.help_hash).not_to include(:audience_help)

        game_question.apply_help!('audience_help')

        expect(game_question.help_hash).to include(:audience_help)

        ah = game_question.help_hash[:audience_help]
        expect(ah.keys).to contain_exactly('a', 'b', 'c', 'd')
      end

      it 'correct fifty_fifty' do
        # сначала убедимся, в подсказках пока нет нужного ключа
        expect(game_question.help_hash).not_to include(:fifty_fifty)
        # вызовем подсказку
        game_question.apply_help!('fifty_fifty')

        # проверим создание подсказки
        expect(game_question.help_hash).to include(:fifty_fifty)
        ff = game_question.help_hash[:fifty_fifty]

        expect(ff).to include('b') # должен остаться правильный вариант
        expect(ff.size).to eq 2 # всего должно остаться 2 варианта
      end

      it 'correct friend_call' do
        # сначала убедимся, в подсказках пока нет нужного ключа
        expect(game_question.help_hash).not_to include(:friend_call)
        # вызовем подсказку
        game_question.apply_help!('friend_call')

        expect(game_question.help_hash).to include(:friend_call)

        fc = game_question.help_hash[:friend_call]
        expect(fc).to be_a(String)
        expect(fc).to include("считает, что это вариант")
      end
    end
  end
end
