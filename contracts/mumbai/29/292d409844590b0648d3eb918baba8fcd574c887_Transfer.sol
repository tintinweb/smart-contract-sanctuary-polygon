/**
 *Submitted for verification at polygonscan.com on 2022-04-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Transfer {
    event _ebalance(string _name, uint256 _balance);
    event _elog(string _name, address _adress);

    //
    function _fbalance () public view returns(uint256){
        return address(this).balance;
    }


    function _fbalance(address payable _to) public returns(uint256){
        emit _ebalance("_fbalance(_to)", _to.balance);
        return address(_to).balance;
    }

    //
    function _ftranfer(address payable _to) public payable{
        emit _elog("_ftranfer", _to);
        _to.transfer(address(this).balance);
    }

}