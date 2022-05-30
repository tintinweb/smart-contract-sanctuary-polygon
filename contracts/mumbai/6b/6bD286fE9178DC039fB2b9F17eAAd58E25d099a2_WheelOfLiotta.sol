/**
 *Submitted for verification at polygonscan.com on 2022-05-29
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <=0.8.14;

contract WheelOfLiotta {
    string[] public oeuvre = ["Goodfellas","Blow","Field of Dreams","Marriage Story","Identity","Cop Land","Narc","Ticker","John Q","The Place Beyond the Pines",
    "Something Wild","The Iceman","Hannibal","Local Color","Sin City: A Dame to Kill For","Killing Them Softly","No Sudden Move","The Many Saints of Newark"];

    function get() public view returns (string memory){  
        return oeuvre[spinTheWheel()];
    }

    function spinTheWheel() private view returns (uint) {
        // Yes this could be manipulated by miners...to select a great Liotta movie for you!
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % oeuvre.length;
    }
}