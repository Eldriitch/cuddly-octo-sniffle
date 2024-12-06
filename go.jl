module SmallGo
import Base: copy, hash

# Set these as you'd like
const M, N = 19, 19
# Boards are MxN arrays of Symbols (specifically :e, :b, :w) by defualt
# initialised to :e. Along with this we store the hash of the board, the hashes
# of previous boards and fields to track which player is moving and what the
# previous move was. 
export GameState
struct GameState
	board::Array{Symbol} # Should be MxN
	previousBoardHashes::Set{UInt}
	blackToMove::Bool # false is White, true is Black. 
	lastMoveWasPass::Bool
end
function isequal(g::GameState, h::GameState)
	isequal(g.board, h.board) && isequal(g.previousBoardHashes, h.previousBoardHashes) && isequal(g.blackToMove, h.blackToMove) && isequal(g.lastMoveWasPass, h.lastMoveWasPass)
end
function hash(gameState::GameState, h::UInt)
	hash(gameState.board, hash(gameState.previousBoardHashes, hash(gameState.blackToMove, hash(gameState.lastMoveWasPass, h))))
end
# Default GameState constructor, starts a new game.
function GameState()
	board = Array{Symbol, 2}(undef, M, N)
	for i in 1:M
		for j in 1:N
			board[i,j] = :e
		end
	end
	GameState(board, 
		  Set{UInt}([hash(board)]),
		  true,
		  false)
end
function copy(gameState::GameState)
	GameState(gameState.board,
		  gameState.previousBoardHashes,
		  gameState.blackToMove,
		  gameState.lastMoveWasPass)
end
# Updates a board ignoring legality (this function is just to minimise duplicate code and take advantage
# of Julia's compiler optimisations)
export updateBoard
function updateBoard(board::Array{Symbol}, i::Int, j::Int, color::Symbol)
	newBoard = copy(board)
	newBoard[i,j] = color
	if color == :b
		newBoard = clearColors(newBoard, :w)
		newBoard = clearColors(newBoard, :b)
	else
		newBoard = clearColors(newBoard, :b)
		newBoard = clearColors(newBoard, :w)
	end
	return newBoard
end
## Tests legality of a candidate move.
export isLegal
function isLegal(gameState::GameState, i::Int, j::Int, color::Symbol)
	if xor(color == :b, gameState.blackToMove) || gameState.board[i,j] != :e
		return false
	end
	newBoard = updateBoard(gameState.board, i, j, color)
	if hash(newBoard) in gameState.previousBoardHashes
		return false
	end
	true
end
# Makes a non-pass move, updating all fields as needed.
export makeMove
function makeMove(gameState::GameState, i::Int, j::Int, color::Symbol)
	# Legality check
	if !isLegal(gameState, i, j, color)
		print("Illegal move! Please try again")
		return gameState
	end
	newBoard = updateBoard(gameState.board, i, j, color)
	GameState(newBoard,
		  union(gameState.previousBoardHashes, [hash(newBoard)]),
		  !gameState.blackToMove,
		  false)
end
# Makes a pass, ending and scoring the game if needed.
export pass
function pass(gameState::GameState)
	if gameState.lastMoveWasPass
		s = score(gameState.board)
		println("Game over, the scores are ", s)
	end
	GameState(gameState.board,
		  gameState.previousBoardHashes,
		  !gameState.blackToMove,
		  true)
end
# Clears colors, algorithmically implementing the removal of dead stones.
export clearColors
function clearColors(board::Array{Symbol}, color::Symbol)
	newBoard = copy(board)
	for i in 1:M
		for j in 1:N
			if board[i,j] == color
				if !reaches(board, i, j, :e)
					newBoard[i,j] = :e
				end
			end
		end
	end
	newBoard
end
# Tests if a point P reaches a color C, using Breadth-first search.
export reaches
function reaches(board::Array{Symbol}, i::Int, j::Int, C::Symbol)
	rootColor = board[i,j]
	old = Set([(i,j)])
	new = Set{Tuple{Int64,Int64}}([])
	visited = Set{Tuple{Int64,Int64}}([])
	while !isempty(old)
		for n in old
			if 1 <= n[1] - 1 && !((n[1]-1, n[2]) in visited)
				if board[CartesianIndex(n[1]-1, n[2])] == C
					return true
				elseif board[CartesianIndex(n[1]-1, n[2])] == rootColor
					union!(new, [(n[1]-1, n[2])])
				end
			end
			if n[1] + 1 <= M && !((n[1]+1, n[2]) in visited)
				if board[CartesianIndex(n[1]+1, n[2])] == C
					return true
				elseif board[CartesianIndex(n[1]+1, n[2])] == rootColor
					union!(new, [(n[1]+1, n[2])])
				end
			end
			if 1 <= n[2] - 1 && !((n[1], n[2]-1) in visited)
				if board[CartesianIndex(n[1], n[2]-1)] == C
					return true
				elseif board[CartesianIndex(n[1], n[2]-1)] == rootColor
					union!(new, [(n[1], n[2]-1)])
				end
			end
			if n[2] + 1 <= N && !((n[1], n[2]+1) in visited)
				if board[CartesianIndex(n[1], n[2]+1)] == C
					return true
				elseif board[CartesianIndex(n[1], n[2]+1)] == rootColor
					union!(new, [(n[1], n[2]+1)])
				end
			end
		end
		union!(visited, old)
		old = new
		new = Set{Tuple{Int64,Int64}}([])
	end
	false
end
# Scores the game. Returns (B, W) where B is black's score, and W is white's. 
export score
function score(board::Array{Symbol})
	B, W = 0, 0
	for i in 1:M
		for j in 1:N
			# println("i: ", i, ", j: ", j)
			if board[i,j] == :b
				B += 1
				continue
			end
			if board[i,j] == :w
				W += 1
				continue
			end
			if reaches(board, i, j, :b) && !reaches(board, i, j, :w)
				B += 1
				continue
			end
			if reaches(board, i, j, :w) && !reaches(board, i, j, :b)
				W += 1
				continue
			end
		end
	end
	(B,W)
end
# Prints out a board in a much more readable way than the internal symbols this code uses (though it's far
# from amazingly pretty!)
export printBoard
function printBoard(board::Array{Symbol})
	for i in 1:M
		row = ""
		for j in 1:N
			if board[i,j] == :e
				row = row * "+" # I like that * is used, concatenation isn't commutative!
			elseif board[i,j] == :b
				row = row * "●"
			else
				row = row * "○"
			end
		end
		println(row)
	end
end
### Engines ###
# The following part of the code will provide utilities for and critical functionality of some, admittedly
# primitive go engines which use various tree search algorithms. All results will be hardware dependent.
## [x]  TODO: Move generation 
## [x]  TODO: Static evaluation
## [x]  TODO: Alpha-Beta pruning 
## [x]  TODO: Alpha-Beta with transposition tables

# Generates a list of legal moves in a position. This is the starting point for any tree-search algorithm.
# Otherwise, there simply isn't a tree to search!
export moveGen
function moveGen(gameState::GameState, color::Symbol)
	moveList::Array{Tuple{Int, Int}} = []
	for i in 1:M
		for j in 1:N
			if isLegal(gameState, i, j, color)
				push!(moveList, (i,j))
			end
		end
	end
	moveList
end
# This is an extremely naive static evaluator, which just scores the board and takes the difference.
# This will only be accurate when the search is deep enough to reach the end of the game, which won't
# happen for larger boards ever. 
# For the negamax trick to work, it's important that the static evals for each player sum to 0.
export staticEval
function staticEval(board::Array{Symbol}, color::Symbol)
	(B, W) = score(board)
	if color == :b
		return B-W
	else
		return W-B
	end
end
## Minimax tree search with alpha-beta pruning.
# This function computes (an estimate of) the value of the position. 
# The alphaBetaRoot variant also returns the best move, according to this evaluation.
# This function uses the "negamax" identity max(a,b) = -min(-a,-b) to avoid havining seperate
# cases for the maximising and minimising player. 
export alphaBeta
function alphaBeta(gameState::GameState, depth::Int, alpha::Int, beta::Int)
	#println("alpha: ", alpha, ", beta: ", beta)
	#printBoard(gameState.board)
	if gameState.blackToMove
		color = :b
	else
		color = :w
	end
	if depth == 0
		#println("Depth 0, returning eval")
		return staticEval(gameState.board, color)
	end
	nextState = copy(gameState)
	# In the unlikely event passing fails high, we check it first. Should only happen if passing
	# is only legal move or beta accidentally set too low.
	eval = 0
	if gameState.lastMoveWasPass
		eval = staticEval(nextState.board, color)
	else
		nextState = pass(nextState)
		eval = -alphaBeta(nextState, depth-1, -beta, -alpha)
	end
	if eval >= beta
		#println("Pass fails high, returning beta")
		return beta
	elseif eval > alpha
		#println("Pass fails low, updating alpha")
		alpha = eval
	end
	moveList = moveGen(gameState, color)
	for move in moveList
		nextState = copy(gameState)
		nextState = makeMove(nextState, move[1], move[2], color)
		eval = -alphaBeta(nextState, depth-1, -beta, -alpha)
		if eval >= beta
			#println("Move fails high, returning beta")
			return beta
		elseif eval > alpha
			#println("Move fails low, updating alpha")
			alpha = eval
		end
	end
	alpha
end
export alphaBetaRoot
function alphaBetaRoot(gameState::GameState, depth::Int)
	if gameState.blackToMove
		color = :b
	else
		color = :w
	end
	if depth == 0
		print("Nothing to search, try depth > 0")
		return gameState
	end
	alpha = -10^9 
	beta = 10^9 # A billion is actually infinity, ultrafinitists unite!
	bestState = copy(gameState)
	nextState = copy(gameState)
	eval = 0
	if gameState.lastMoveWasPass
		eval = staticEval(nextState.board, color)
	else
		nextState = pass(nextState)
		eval = -alphaBeta(nextState, depth-1, -beta, -alpha)
	end
	if eval > alpha 
		bestState = copy(nextState)
		alpha = eval
	end
	moveList = moveGen(gameState, color)
	for move in moveList
		nextState = copy(gameState)
		nextState = makeMove(nextState, move[1], move[2], color)
		eval = -alphaBeta(nextState, depth-1, -beta, -alpha)
		if eval > alpha
			bestState = copy(nextState)
			alpha = eval
		end
	end
	if bestState == gameState
		bestState = pass(bestState)
	end
	bestState
end
# Iterative deepening using julia's tasks! This lets us do stuff with time and compare the performance 
# of different tree-search algorithms
# (This doesn't quite behave ideally, since it waits for the current layer of alphaBetaRoot to finish 
# before returning, but as long as this is consistent with the other methods its fine for comparison). 
# It's kind of like students finishing their sentences at the end of an exam :3 
export iterativeDeepeningAlphaBeta
function iterativeDeepeningAlphaBeta(gameState::GameState, maxDepth::Int=30 , timelimit::Real=10)
	move = alphaBetaRoot(gameState, 1)
	tsk = @task begin 
		for i in 2:maxDepth
			move = alphaBetaRoot(gameState, i)
			print("") # This is necessary for some reason? I don't understand why =_=
		end
		move
	end
	schedule(tsk)
	Timer(timelimit) do timer
		istaskdone(tsk) || Base.throwto(tsk, InterruptException())
	end
	try
		fetch(tsk)
	catch _
		move
	end
end
# AlphaBeta with a transposition table, this helps avoid searching nodes which have already been checked
# It can also be used to improve move ordering with iterative deepening, although that hasn't been implemented here.
# A lot of clever improvements can also be done with transposition table itself, but I don't even handle OOM errors. The principle is there though.
function alphaBeta(gameState::GameState, depth::Int, alpha::Int, beta::Int, transpositionTable::Dict{GameState, Tuple{Int,Int}})
	#println("alpha: ", alpha, ", beta: ", beta)
	#printBoard(gameState.board)
	if haskey(transpositionTable, gameState)
		if transpositionTable[gameState][1] >= beta
			return transpositionTable[gameState][1]
		end
		if transpositionTable[gameState][2] <= alpha
			return transpositionTable[gameState][2]
		end
	end
	if gameState.blackToMove
		color = :b
	else
		color = :w
	end
	if depth == 0
		#println("Depth 0, returning eval")
		eval = staticEval(gameState.board, color)
		transpositionTable[gameState] = (max(eval, alpha), min(eval, beta))
		return eval
	end
	nextState = copy(gameState)
	# In the unlikely event passing fails high, we check it first. 
	eval = 0
	if gameState.lastMoveWasPass
		eval = staticEval(nextState.board, color)
	else
		nextState = pass(nextState)
		eval = -alphaBeta(nextState, depth-1, -beta, -alpha, transpositionTable)
	end
	if eval >= beta
		#println("Pass fails high, returning beta")
		transpositionTable[nextState] = (beta, eval)
		return beta
	elseif eval > alpha
		#println("Pass fails low, updating alpha")
		transpositionTable[nextState] = (eval, alpha)
		alpha = eval
	end
	moveList = moveGen(gameState, color)
	for move in moveList
		nextState = copy(gameState)
		nextState = makeMove(nextState, move[1], move[2], color)
		eval = -alphaBeta(nextState, depth-1, -beta, -alpha, transpositionTable)
		if eval >= beta
			#println("Move fails high, returning beta")
			transpositionTable[nextState] = (beta, eval)
			return beta
		elseif eval > alpha
			#println("Move fails low, updating alpha")
			transpositionTable[nextState] = (eval, alpha)
			alpha = eval
		end
	end
	alpha
end
function alphaBetaRoot(gameState::GameState, depth::Int, transpositionTable::Dict{GameState, Tuple{Int,Int}})
	if gameState.blackToMove
		color = :b
	else
		color = :w
	end
	if depth == 0
		print("Nothing to search, try depth > 0")
		return gameState
	end
	alpha = -10^9 
	beta = 10^9 # A billion is actually infinity, ultrafinitists unite!
	bestState = copy(gameState)
	nextState = copy(gameState)
	eval = 0
	if gameState.lastMoveWasPass
		eval = staticEval(nextState.board, color)
	else
		nextState = pass(nextState)
		eval = -alphaBeta(nextState, depth-1, -beta, -alpha, transpositionTable)
	end
	if eval > alpha 
		bestState = copy(nextState)
		alpha = eval
	end
	moveList = moveGen(gameState, color)
	for move in moveList
		nextState = copy(gameState)
		nextState = makeMove(nextState, move[1], move[2], color)
		eval = -alphaBeta(nextState, depth-1, -beta, -alpha, transpositionTable)
		if eval > alpha
			bestState = copy(nextState)
			alpha = eval
		end
	end
	if bestState == gameState
		bestState = pass(bestState)
	end
	bestState
end
export iterativeDeepeningAlphaBetaTT
function iterativeDeepeningAlphaBetaTT(gameState::GameState, maxDepth::Int=30 , timelimit::Real=10)
	move = alphaBetaRoot(gameState, 1)
	tsk = @task begin 
		for i in 2:maxDepth
			d = Dict{GameState, Tuple{Int,Int}}()
			move = alphaBetaRoot(gameState, i, d)
			print("") # This is necessary for some reason? I don't understand why =_=
		end
		move
	end
	schedule(tsk)
	Timer(timelimit) do timer
		istaskdone(tsk) || Base.throwto(tsk, InterruptException())
	end
	try
		fetch(tsk)
	catch _
		move
	end
end
end
