pragma solidity ^0.8.0;

import "./anqwallet.sol";


contract anqfactory{

    mapping(address => address)depolyed_address_per_wallet;

    function get_withdraw_calldata(address _address,uint256 numer)public view returns(bytes memory _data,address Anq_wallet,address _user){
    address user_address=  depolyed_address_per_wallet[msg.sender];
     return (
           abi.encodeWithSelector(anqwallet(user_address).withdraw.selector,numer),
            depolyed_address_per_wallet[_address],
            msg.sender
        ); 
    }

    function deploy(bytes32 salt)public {
        address deployed_address = create(salt);
        depolyed_address_per_wallet[msg.sender] = deployed_address;
    }

    function create(
        bytes32 _salt
    ) internal returns (address) {
        return address(new anqwallet{salt: _salt}());
    }
    
}

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