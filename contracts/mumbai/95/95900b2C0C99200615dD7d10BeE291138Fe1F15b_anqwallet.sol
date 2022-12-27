pragma solidity ^0.8.0;

contract anqwallet{

    event Deposit(address indexed sender, uint amount, uint balance);

    address paymaster = 0x358AA13c52544ECCEF6B0ADD0f801012ADAD5eE3;
    uint256 number;

    function withdraw(uint256 _number)public{
        number = number + _number;
    }

    function withdraw_ERC20(uint256 _number)public{
         number = number + _number;
    }




    function get_total_balance_ERC20()public view returns(uint256){
     return number;

    }

    function get_total_balance_Native()public view returns(uint256){

    }

    function GET_BALANCE()public view returns(uint256 ERC20_balance,uint256 NATIVE_BALANCE ){

    }
 


}