// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

//Code by 9571  2023-02-27


contract LogLib {
   
    event debugstr(string msg,address user_addr,address contract_addr,string exec,uint256 num,uint256 time);
    event debugnum(string msg,address user_addr,address contract_addr,uint256 exec,uint256 num,uint256 time);
    event debugaddr(string msg,address user_addr,address contract_addr,address target_addr,uint256 exec,uint256 num,uint256 time);

    function LogStr (string memory value,string memory exec,uint256 num )  public {
        emit debugstr(value, tx.origin,address(msg.sender),exec,num,block.timestamp);
    }

    
    function LogNum (string memory value,uint256 exec,uint256 num )  public {
        emit debugnum(value, tx.origin,address(msg.sender),exec,num,block.timestamp);
    }

    function LogAddr (string memory value,address target_addr,uint256 exec,uint256 num )  public {
        emit debugaddr(value, tx.origin,address(msg.sender),target_addr,exec,num,block.timestamp);
    }

}


/*

interface LogLib  {
    function LogStr(string memory value,string memory exec,uint256 num) external;
    function LogNum (string memory value,uint256 exec,uint256 num)  external ;
    function LogAddr (string memory value,address target_addr,uint256 exec,uint256 num)  external ;
}

*/