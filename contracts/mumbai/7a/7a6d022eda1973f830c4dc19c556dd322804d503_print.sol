/**
 *Submitted for verification at polygonscan.com on 2022-06-28
*/

pragma solidity 0.8;	

contract print
{
    string public name = "aaa";
    int public number = 0;

    function changeName(string memory input) public{
        name = input;
    }

    function change_num (int input) public{
        number = input;
    }

    function get_name() public view returns (string memory){
        return name;
    }

        function get_num() public view returns (int){
        return number;
    }
}