/**
 *Submitted for verification at polygonscan.com on 2022-08-14
*/

pragma solidity ^0.4.25;

contract Formatic{

    address public owner;
    address public comission;
    address public winer;
    uint public stoptime;
    uint public lastpaytime;
    uint public chai;

    event ownershipTransferred(address indexed previousowner, address indexed newowner);
    
    event winerTransferred(address winer, address newwiner);
    event chaiTransferred(uint chai, uint newchai);

    constructor() public {
       comission = 0x6Fb33366BB7F3e4eCec483ddCc412eb5b739e9C3; 
       owner = msg.sender;
       winer = 0;
       chai = 1;
    } 

    function () external payable{
        if(msg.value >= 4000000000000000000){
        if(chai >= 2){
        require (now < stoptime);
        }
        uint cash = msg.value/4;
        comispay(cash);
        address newwiner = msg.sender;
        winertransfers(newwiner);
        lastpaytime = now;
        stoptime = lastpaytime + 86400;
        uint newchai = chai + 1;
        chaiplus(newchai);
        }else if(msg.value < 4000000000000000000){
          win();
    }
    }
        function comispay(uint cash) private {
            comission.transfer(cash);
        }

        function chaiplus (uint newchai) private{
         emit chaiTransferred(chai, newchai);
        chai = newchai;
        }
        
        function win() private{
            require (now > stoptime);
            uint wincash = address(this).balance;
            winer.transfer(wincash);


        }

        function transferowner(address newowner) public onlyOwner {
        require(newowner != address(0));
        emit ownershipTransferred(owner, newowner);
        owner = newowner;
    }

    function winertransfers(address newwiner) private {
        require(newwiner != address(0));
        emit winerTransferred(winer, newwiner);
        winer = newwiner;
    }


    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    }