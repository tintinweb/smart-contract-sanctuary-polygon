/**
 *Submitted for verification at polygonscan.com on 2022-04-03
*/

pragma solidity 0.6.0;

contract Transfer {
    event _balance(string, uint);

    //
    function _fbalance () public returns(uint){
        uint balance = address(this).balance;
        emit _balance("_fbalance", balance);
        return balance;
    }


    function _fbalance(address _to) public returns(uint){
        uint balance = address(_to).balance;
        emit _balance("_fbalance", balance);
        return balance;
    }

}