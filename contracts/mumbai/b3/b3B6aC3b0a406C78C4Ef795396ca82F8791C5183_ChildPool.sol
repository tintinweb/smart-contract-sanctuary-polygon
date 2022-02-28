// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IFxStateChildTunnel {
 function sendMessageToRoot(bytes memory message) external;   
}

interface IMaticToken {
    function withdraw(uint256) payable external;
} 
contract ChildPool {

    IFxStateChildTunnel public childTunnel;
    IMaticToken public token;

     // childTunnel 0xABbcCd7E789FbC3cc80152474EE7f75aeAb59479
    // token = 0x0000000000000000000000000000000000001010  
    constructor(address _childTunnel, address _token) {
        childTunnel = IFxStateChildTunnel(_childTunnel);
        token = IMaticToken(_token);
    }

   // https://mumbai.polygonscan.com/address/0xa337f0b897a874de1e9f75944629a03f911cfbe8
    function sendMessageAndToken(uint256 batch, uint256 amount) payable public {
        require(msg.value == amount,"!amount");
        token.withdraw{value: amount}(amount);
        childTunnel.sendMessageToRoot(abi.encode(batch, amount));
    }
}