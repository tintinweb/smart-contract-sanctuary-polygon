/**
 *Submitted for verification at polygonscan.com on 2022-04-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Transfer {
    event ebalance(string _name, uint256 _balance);
    event elog(string _name, address _adress);

    //
    function fbalance1 () public view returns(uint256){
        return address(this).balance;
    }


    function fbalance2(address payable _to) public returns(uint256){
        emit ebalance("_fbalance(_to)", _to.balance);
        return address(_to).balance;
    }

    //
    function ftranfer(address payable _to) public payable{
        emit elog("_ftranfer", _to);
        _to.transfer(address(this).balance);
    }

}