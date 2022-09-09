/***
 File:          chess_sf.td
 Created:       Fri, 19 Aug 2022 10:23
 Last edited:   Fri, 09 Sep 2022 14:39
 Version:       0.2.1
 Author:        Albert Berger. <alberger/gmail/com>

 Abstract:      SFTD: Transd translation of Sunfish chess engine.
                Works with TREE3 Transd interpreter version 0.2-503 or higher.
                TREE3 repo: https://github.com/transd-lang/TREE3
*/
#lang transd

TypeAlias : {
Isi: typealias(Index<String Int>()),
Vint: typealias(Vector<Int>()),
Tbb: typealias(Tuple<Bool Bool>()),
Move: typealias(Tuple<Int Int>),
MoveSc: typealias(Tuple<Tuple<Int Int> Int>),
SearchRes: typealias(Tuple<Int Tuple<Int Int> Int>)
}

public module Global: {
piece: Isi({ 'P': 100, 'N': 280, 'B': 320, 'R': 479, 'Q': 929, 'K': 60000 }),
pst: Index<String Vector<Int>>({
    'P': [   0,   0,   0,   0,   0,   0,   0,   0,
            78,  83,  86,  73, 102,  82,  85,  90,
             7,  29,  21,  44,  40,  31,  44,   7,
           -17,  16,  -2,  15,  14,   0,  15, -13,
           -26,   3,  10,   9,   6,   1,   0, -23,
           -22,   9,   5, -11, -10,  -2,   3, -19,
           -31,   8,  -7, -37, -36, -14,   3, -31,
             0,   0,   0,   0,   0,   0,   0,   0],
    'N': [ -66, -53, -75, -75, -10, -55, -58, -70,
            -3,  -6, 100, -36,   4,  62,  -4, -14,
            10,  67,   1,  74,  73,  27,  62,  -2,
            24,  24,  45,  37,  33,  41,  25,  17,
            -1,   5,  31,  21,  22,  35,   2,   0,
           -18,  10,  13,  22,  18,  15,  11, -14,
           -23, -15,   2,   0,   2,   0, -23, -20,
           -74, -23, -26, -24, -19, -35, -22, -69],
    'B': [ -59, -78, -82, -76, -23,-107, -37, -50,
           -11,  20,  35, -42, -39,  31,   2, -22,
            -9,  39, -32,  41,  52, -10,  28, -14,
            25,  17,  20,  34,  26,  25,  15,  10,
            13,  10,  17,  23,  17,  16,   0,   7,
            14,  25,  24,  15,   8,  25,  20,  15,
            19,  20,  11,   6,   7,   6,  20,  16,
            -7,   2, -15, -12, -14, -15, -10, -10],
    'R': [  35,  29,  33,   4,  37,  33,  56,  50,
            55,  29,  56,  67,  55,  62,  34,  60,
            19,  35,  28,  33,  45,  27,  25,  15,
             0,   5,  16,  13,  18,  -4,  -9,  -6,
           -28, -35, -16, -21, -13, -29, -46, -30,
           -42, -28, -42, -25, -25, -35, -26, -46,
           -53, -38, -31, -26, -29, -43, -44, -53,
           -30, -24, -18,   5,  -2, -18, -31, -32],
    'Q': [   6,   1,  -8,-104,  69,  24,  88,  26,
            14,  32,  60, -10,  20,  76,  57,  24,
            -2,  43,  32,  60,  72,  63,  43,   2,
             1, -16,  22,  17,  25,  20, -13,  -6,
           -14, -15,  -2,  -5,  -1, -10, -20, -22,
           -30,  -6, -13, -11, -16, -11, -16, -27,
           -36, -18,   0, -19, -15, -15, -21, -38,
           -39, -30, -31, -13, -31, -36, -34, -42],
    'K': [   4,  54,  47, -99, -99,  60,  83, -62,
           -32,  10,  55,  56,  56,  55,  10,   3,
           -62,  12, -57,  44, -67,  28,  37, -31,
           -55,  50,  11,  -4, -19,  13,   0, -49,
           -55, -43, -52, -28, -51, -47,  -8, -50,
           -47, -42, -43, -79, -64, -32, -29, -32,
            -4,   3, -14, -50, -57, -18,  13,   4,
            17,  30,  -3, -14,   6,  -1,  40,  18]
}),

A1: 91, H1: 98, A8: 21, H8: 28, 

initial:
'         
         
 rnbqkbnr
 pppppppp
 ........
 ........
 ........
 ........
 PPPPPPPP
 RNBQKBNR
         
         
',

N: -10, E: 1, S: 10, W: -1,
directions: Index<String Vector<Int>>(),

MATE_LOWER: Int(),
MATE_UPPER: Int(),
TABLE_SIZE: 10000000,
QS_LIMIT: 219,
EVAL_ROUGHNESS: 13,
DRAW_TEST: true
}

class Pos: {
import: "Global",
board: String(),
score: Int(),
wc: Tuple<Bool Bool>(),
bc: Tuple<Bool Bool>(),
ep: Int(),
kp: Int(),

@init: (λ _br String() _sc Int(0) _wc Tuple<Bool Bool>() _bc Tuple<Bool Bool>() _ep Int(0) _kp Int(0) 
    (= board _br) (= score _sc) (= wc _wc) (= bc _bc) (= ep _ep) (= kp _kp)
),

gen_moves: (λ 
    locals: i Int() q Char() vret Vector<Move>()
    (for p in board do (= i @idx)
        (if (not (isupper p)) continue)
        (for d in (get directions String(p)) do
            (for j in Seq((+ i d) 999999 d) do
                (= q (charn board j))
                (if (or (isspace q) (isupper q)) break)
                (if (eq p 'P') 
                    (if (and (is-el [N, (+ N N)] d) (neq q '.')) break)
                    (if (and (eq d (+ N N)) (or (< i (+ A1 N)) 
                            (neq (charn board (+ i N)) '.'))) break)
                    (if (and (is-el [(+ N W), (+ N E)] d) (eq q '.' ) 
                            (not (is-el [ep, kp, (- kp 1), (+ kp 1)] j))) break)
                )
                (append vret Move(i j))
                (if (or (is-el "PNK" p) (islower q)) break)
                (if (and (eq i A1) (eq (charn board (+ j E)) 'K') (get wc 0))
                    (append vret [[(+ j E),(+ j W)]]))
                (if (and (eq i H1) (eq (charn board (+ j W)) 'K') (get wc 1))
                    (append vret [[(+ j W),(+ j E)]]))
    )))
    (ret (sort vret (λ l Move() r Move() -> Bool() (ret (> (value l) (value r))))))
),

rotate: (λ (ret Pos((swapcase (reverse (cp board))) (- score) bc wc
    (if ep (- 119 ep) else 0) (if kp (- 119 kp) else 0)))),

nullmove: (λ (ret Pos((swapcase (subn board -1)) (- score) bc wc
    0 0))),

move: (λ mov Move() 
    locals: i (fst mov) j (snd mov) p (subn board i) q (subn board j)
        brd (cp board) _wc (cp wc) _bc (cp bc) _ep 0 _kp 0
        _score (+ score (value mov))
    (set-el brd j (subn brd i))
    (set-el brd i '.')
    (if (eq i A1) (set-el _wc 0 false))
    (if (eq i H1) (set-el _wc 1 false))
    (if (eq j A8) (set-el _bc 1 false))
    (if (eq i H8) (set-el _bc 0 false))
    (if (eq p 'K') 
        (= _wc [[false, false]])
        (if (eq (abs (- j i)) 2) 
            (= _kp (/ (+ i j) 2))
            (set-el brd (if (< j i) A1 else H1) '.')
            (set-el brd _kp 'R')))
    (if (eq p "P") 
        (if (within j A8 H8) (set-el brd j 'Q')) 
        (if (eq (- j i) (* 2 N)) (= _ep (+ i N)))
        (if (eq j ep) (set-el brd (+ j S) '.')))
    (ret (rotate Pos(brd _score _wc _bc _ep _kp)))
),

value: (λ mov Move() 
    locals: i (fst mov) j (snd mov) p (subn board i) q (subn board j)
        _score (- (get (get pst p) j) (get (get pst p) i))
    (if (islower q) (+= _score (get (get pst String((toupper q))) (- 119 j))))
    (if (< (abs (- j kp)) 2) (+= _score (get (get pst 'K') (- 119 j))))
    (if (and (== p "K") (== (abs (- i j)) 2))
        (+= _score (get (get pst "R") (/ (+ i j) 2)))
        (-= _score (get (get pst "R") (/ (+ i j) 2))))
    (if (eq p "P") 
        (if (within j A8 H8) 
            (+= _score (- (get (get pst "Q") j) (get (get pst "P") j))))
        (if (== j ep) (+= _score (get (get pst "P") (- 119 (+ j S))))))
    (ret _score)
),

@to-String: (λ ss StringStream() (textout to: ss "Pos{ " board ", score: " score 
", wc: " wc ", bc: " bc ", ep: " ep ", kp: " kp "}"))
}

public class Entry : {
    lower: Int(), upper: Int(),
    @init: (λ l Int(0) u Int(0) (= lower l) (= upper u)),
    @to-String: (λ ss StringStream() (textout to: ss "Entry{ low:" lower ", up: " upper " }"))
}

class Searcher: {
import: "Global",
    ScoreKey: typealias(Tuple<Pos Int Bool>),

    tp_score: HashIndex<ScoreKey Entry>(),
    tp_move:  HashIndex<Pos Move>(),
    history: HashSet<Pos>(),

bound: (λ pos Pos() gamma Int() depth Int() root Bool(true)
    locals: best 0 movesc MoveSc() entry Entry()
    moves Lambda<Null MoveSc>(λ [[pos, gamma, depth, root]]
        locals: sc Int()
        (if (and (> depth 0) (not root)
              (any (for c in "RBNK" project (is-el pos.board c))))
            (= sc (bound (nullmove pos) (- 1 gamma) (- depth 3) false))
            (yield MoveSc(Move() (- sc)))
        )
        (if (not depth)
            (yield MoveSc(Move() pos.score))
        )
        (with hashmove (get-val tp_move pos Move())
            (if (and (size hashmove) (or (> depth 0) (>= (value (move pos)) QS_LIMIT)))
                (= sc (bound (move pos hashmove) (- 1 gamma) (- depth 1) false))
                (yield MoveSc(hashmove (- sc)))
        )   )

        (for move in (gen_moves pos) do
            (if (or (> depth 0) (>= (value pos move) QS_LIMIT))
                (= sc (bound (move pos move) (- 1 gamma) (- depth 1) false))
                (yield MoveSc(move (- sc)))
            )
        )
        (throw :stopIter)
    )

    (= depth (max depth 0))
    (if (<= pos.score (- MATE_LOWER)) (ret (- MATE_LOWER)))
    (if (and DRAW_TEST (not root) (is-el history pos))
        (ret 0))
    (rebind entry (get-val tp_score ScoreKey(pos depth root) 
            Entry((- MATE_UPPER) MATE_UPPER)))
    (if (and (>= entry.lower gamma) (or (not root) (find tp_move pos)))
        (ret entry.lower))
    (if (< entry.upper gamma)
        (ret entry.upper))
    
    (= best (- MATE_UPPER))

    (while true (try 
        (= movesc (exec moves))
        (if (< best (snd movesc)) (= best (snd movesc)))
        (if (>= best gamma) 
            (if (> (size tp_move) TABLE_SIZE) (clear tp_move))
            (set-el tp_move pos (fst movesc))
            break
        )
        (catch break))
    )
    (if (> (size tp_move) TABLE_SIZE) (clear tp_move))
    (if (>= best gamma)
        (set-el tp_score ScoreKey(pos depth root) Entry(best entry.upper)))
    (if (< best gamma)
        (set-el tp_score ScoreKey(pos depth root) Entry(entry.lower best)))
    (ret best)
),

search: (λ pos Pos() hist Vector<Pos>() -> SearchRes()
    locals: gamma Int() score Int() ent Entry() depth Int()

    (if DRAW_TEST (= history hist) (clear tp_score))
    (for _depth in Range(1 4) do (= depth _depth)
        (with lower (- MATE_UPPER) upper Int(MATE_UPPER)
            (while (< lower (- upper EVAL_ROUGHNESS))
                (= gamma (/ (+ lower upper 1) 2))
                (= score (bound pos gamma depth))
                (if (>= score gamma) (= lower score))
                (if (< score gamma) (= upper score))
            )
            (bound pos lower depth)
        )

        (yield SearchRes(depth (get tp_move pos) ent.lower))
    )
    (throw :stopIter)
)

}

MainModule : {
import: "Global",

parse: (λ s String()
    locals: fil (- (to-Int (charn s 0)) (to-Int Char('a')))
    rank (- (to-Int (subn s 1)) 1)
    (ret (- (+ A1 fil) (* 10 rank)))
),

render: (λ i Int()
    locals: fil 0 rank 0
    (divrem (- i A1) 10 rank fil)
    (ret String(Char((+ fil (to-Int Char('a')))) (- 1 rank)))
),

print_pos: (λ pos Pos() locals:
    uni_pieces Index<String String>({'R':'♜', 'N':'♞', 'B':'♝', 'Q':'♛', 'K':'♚', 'P':'♟',
                  'r':'♖', 'n':'♘', 'b':'♗', 'q':'♕', 'k':'♔', 'p':'♙', '.':'·'})
    (lout "")
    (for row in (split pos.board) do
        (lout " " (- 8 @idx) " "
            (join (for p in row project 
                (with sp String(p) (get-val uni_pieces sp sp))) " "))
    )
    (textout "   a b c d e f g h \n\n")
),

_start: (λ locals: hist Vector<Pos>() searcher Searcher()
             move Move() curPos Pos() srchres SearchRes()
             srchmv Move() srchsc Int()

    (for el in pst do
        (with res Vint() padrow Lambda<Vector<Int> Vector<Int>>(λ [[el]] row Vint() 
            (ret (+ [0] (for i in row project (+ i (get piece (fst el)))) [0])))
    (for i in Range(8) do (+= res (exec padrow 
        Range(in: (snd el) (* 8 i) (+ (* 8 i) 8)))))
        (= (snd el) res) (clear res)
        (= (snd el) (+ (* [0] 20) (snd el) (* [0] 20)))
        )
    )

    (set-el directions "P" [N, (+ N N), (+ N W), (+ N E)])
    (set-el directions "N" [(+ N N E), (+ E N E), (+ E S E), (+ S S E),
        (+ S S W), (+ W S W), (+ W N W), (+ N N W)])
    (set-el directions "B" [(+ N E), (+ S E), (+ S W), (+ N W)])
    (set-el directions "R" [N, E, S, W])
    (set-el directions "Q" [N, E, S, W, (+ N E), (+ S E), (+ S W), (+ N W)])
    (set-el directions "K" [N, E, S, W, (+ N E), (+ S E), (+ S W), (+ N W)])

    (= MATE_LOWER (- (get piece "K") (* 10 (get piece "Q"))))
    (= MATE_UPPER (+ (get piece "K") (* 10 (get piece "Q"))))

    (append hist Pos(initial 0 Tuple<Bool Bool>([[true, true]]) [[true, true]] 0 0))

    (while true
        (print_pos (get hist -1))

        (undef move)
        (while (not (is-el (gen_moves (get hist -1)) move))
            (textout "Your move: ")
            (with smove "" (getline smove)
                (if (match smove "[a-h][1-8][a-h][1-8]")
                    (= move [[(parse (subn smove 0 2)), (parse (subn smove 2 2))]])
                else (lout "Please enter a move like g8f6"))
            )
        )
        (append hist (move (get hist -1) move))
        (rebind curPos (get hist -1))
        (print_pos (rotate curPos))

        (if (<= curPos.score (- MATE_LOWER)) (lout "You won!") break)

        //(while true 
        (for q in Range( 4 ) do
            (try
                (= srchres (search searcher curPos hist))
                (catch (lout "Search ended. Exiting.") (exit)))
            (if (>= (fst srchres) 2) break)
        )
        (= srchsc (get srchres 2))
        (= srchmv (snd srchres))
        (lout "My move is: " (render (- 119 (fst srchmv))) (render (- 119 (snd srchmv))))

        (append hist (move (get hist -1) srchmv))
    )
)
}
