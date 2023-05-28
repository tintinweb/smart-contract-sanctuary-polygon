// SPDX-License-Identifier: MIT;
// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8;

import "./IERC20.sol";

contract contractTransfer {

    address owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this");
        _;
    }
    modifier notAddress(address _useAdd){
        require(_useAdd != address(0), "address is error");
        _;
    }
    event Received(address, uint);
    constructor() payable{
        owner = msg.sender;
    }
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    function pay() public payable{

    }

    function checkBalance() 
        public 
        view 
        returns (uint) {
        return address(this).balance;
    }

    function destroy() 
        public
        onlyOwner
    {
		selfdestruct(payable(msg.sender));
    }

    function transferTokens(address _constractAdd, address from, address[] memory _tos,uint[] memory _values)
        public 
        onlyOwner
        returns (bool){
        require(_tos.length > 0);
        require(_values.length > 0);
        require(_values.length == _tos.length);
        bool status;
        bytes memory msgs;
   
        for(uint i=0;i<_tos.length;i++){
            require(_tos[i] != address(0));
            require(_values[i] > 0);
            (status,msgs) = _constractAdd.call(abi.encodeWithSignature("transferFrom(address,address,uint256)",from,_tos[i],_values[i]));
            require(status == true);
        }
        return true;
    }
}