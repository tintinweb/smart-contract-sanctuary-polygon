/**
 *Submitted for verification at polygonscan.com on 2023-01-11
*/

pragma solidity 0.8.17;

contract hello{

    string[] public color;
    function insertValues(string memory lol, uint times)external{
        for(uint i=0;i<=times;i++){
            color.push(lol);
        }

    }
    function getColor()external view  returns(string[] memory){
        return color;
    }
}