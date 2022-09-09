# SFTD
### Chess program written in Transd

SFTD (short for "SunFish in TransD") is a Transd translation of [Sunfish chess engine](https://github.com/thomasahle/sunfish) by Thomas Dybdahl Ahle. Sunfish, being one of the most compact yet powerful chess engines, is written in Python. Its code actively employs Python's rich capabilities for writing very concise code. SFTD's code is a very close translation of the original, except that 'yield' keyword in Transd works differently than in Python.

In general terms, SFTD implements an algorithm for optimized combinatorial search in a large space of solutions (chess positions). It performs recursive traversing of positions tree for doing so called "iterative deepening search". Intermediate results and search history are stored in several data structures, optimized for quick retrieval of data.

SFTD is an example of how to use various Transd features for processing large sets of structured and well-organized data: 

* Hashed containers (HashIndex and HashSet). 
* Recursive function calls.
* Lazy evaluation with 'yield' keyword.

### Running

SFTD contains both chess engine and GUI to it, and can be used to play chess in the computer terminal in "Human vs. Computer" mode. For this you need the Transd interpreter, and your terminal must support Unicode chess characters.

Transd interpeter TREE3 can be downloaded [here](https://github.com/transd-lang/TREE3).

SFTD is started in the terminal with the following command:

```
<PATH_TO...>/tree3 <PATH_TO...>/chess_sf.td
```
Moves are entered in "e2e4" form.
