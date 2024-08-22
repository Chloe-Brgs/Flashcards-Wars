class TrainingsController < ApplicationController

  def index
    @trainings = current_user.trainings
    @subcategories = Subcategory.all
    @Locked_missions_count = @subcategories.count - @trainings.count
  end

  def show
    @training = Training.find(params[:id])
  end

  def play
    # On recup le training en cour
    @training = Training.find(params[:training_id])
    # On prend tout les training answer qui sont pas résolu
    @training_answers = TrainingAnswer.where(
      training: @training,
      solved: false
    )
    # On en prends 1 au hasard
    @training_answer = @training_answers.sample
    # On récup la question
    @question = @training_answer.question
    # On récup les réponses de la question
    @possibilities = @question.possibilities
  end

  def next
    # On recup le training en cour
    @training = Training.find(params[:training_id])
    # On prend tout les training answer qui sont pas résolu (faux ou jamais répondu)
    @training_answers = TrainingAnswer.where(
      training: @training,
      solved: false
    )

    if @training_answers.empty?
      # Il n'y a plus de question on redirege a la fin
      redirect_to training_finished_path
    else
      #Il reste des question
      # On en prends une training answer au hasard
      @training_answer = @training_answers.sample
      # on recup la question
      @question = @training_answer.question
      # on recup les possibilité
      @possibilities = @question.possibilities
      # On affiche la vue qui pose la question (views/trainings/play)
      # Elle existe déjà grâçe à la méthode play
      render :play
    end
  end

  def resolve
    # On récup le training answer au quel l'utilisateur a répondu
    @training_answer = TrainingAnswer.find(params[:training_answer_id])
    # On récup la réponse qu'il a donné
    @answer = Possibility.find(params[:possibility_id])
    # On récupe la solution de la question posé
    @question = @training_answer.question

    # On calcul le nouveau compte de try
    @try = @training_answer.count_try += 1

    # On ajoute un au nobmre de try
    @training_answer.update(count_try: @try)
    # On cree une variable savoir si il a la bonne réponse
    @correct = @answer == @question.solution
    # Si bonne réponse on passe solved a true
    @training_answer.update(solved: true) if @correct
  end

  def finished
     # On recup le training en cour
    @training = Training.find(params[:training_id])
    # Set up the gold/exp winned from the quiz
    @gold_exp_winned = 0
    @first_attempt = 0
    @total_questions = 0
    @all = @training.training_answers
    @all.each do |ta|
      if ta.count_try == 1
        if @gold_exp_winned < 100
          @gold_exp_winned += 5
        else
          @gold_exp_winned = 100
        end
        @first_attempt = @first_attempt + 1
      end
      @total_questions += 1
    end
    @actual_gold = @training.user.gold_count
    @new_gold = @actual_gold + 100 + @gold_exp_winned
    @training.user.update(gold_count: @new_gold)
    @training.user.experience += (100 + @gold_exp_winned)
    @actual_exp = @training.user.experience
    @new_exp = @actual_exp + 100 + @gold_exp_winned
    @training.user.update(experience: @new_exp)
    @training.update(finished: true)
  end

end
