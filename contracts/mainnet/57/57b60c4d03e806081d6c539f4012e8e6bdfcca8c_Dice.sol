/**
 *Submitted for verification at polygonscan.com on 2022-05-29
*/

pragma solidity ^0.8.14;

// SPDX-License-Identifier: GPL-3.0-or-later

contract Dice {
 /*

Written by John Rigler ([email protected])

Randomness is determined after this transaction is run. This is done
by examining the transaction id (which is not knows when this runs). While
the transation id could conceivably be gamed by the user, the block id
would be impossible. For this reason, I suggest using the first byte of
the block id to find an unpredictable start point within the transaction id.

  
0x3ac69665dbe99a97594f38b5b05434da9cbe47418facc3f6a6794560e634d4a1
  ^
  |
  ---> Our starting value is at position 3 (fourth starting at 0) 


0x2ebaf29d452cc0937d2a368619946055dfe53a46dd5cfc363ba3a495b5b8981d
     ^
     |
     ---> Use the modulus operator to figure out the roll from here

In order to emulate the best roll, you must consider the fact that a
traditional die is 6-sided. Because each byte of a hex string is
16 bits, a modulus of 2, 4, 8, and 16 would fit perfectly into one
byte. A modulus of 6 would require three bytes, so a traditional 
6-sided die would be best represented by three bytes. In this case,
starting with the 4th byte, we would pull "af2", convert to decimal
and then modulus 6. Thus a 6-sided dice roll would be calculated:

af2 (hex) = 2802 (decimal)
2802 % 6 = 0
Always add one because we usually don't number dice starting at 0.

If you wish to roll multiple dice, then simply move right to get a 
new set of values. A second 6-sided die would thus be seeded with
9d4. The game Dungeons & Dragons uses a standard set of somewhat
odd looking dice with the following number of sides:

D4, D6, D8, D10, D12, D20 (a Percentage Dice is a special D10)

So to fairly represent each of the dice, you need this many 
characters:

D4 = one 
D6 = three 
D8 = one
D10 = five
D12 = three
D20 = five
 */

    function roll (
       string memory Random
              ) public  { 
/*
You will notice that any sort of code will be ominously missing
from this section. Because the random value must be read after
the fact, simply calling this function with some meaningful 
commitment would create a cohesive record which is completely
self-contained in the single transaction itself. I chose to use 
a LISP format to create a commitment, so two 6-sides dice could
be represented as : ( random 6 6 )

The LISP format is relatively readable and extensible. Other formats 
could work as long as the reader can understand what it intended.
*/
        }
}