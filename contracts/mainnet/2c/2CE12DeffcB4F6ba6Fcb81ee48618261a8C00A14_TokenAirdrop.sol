/**
 *Submitted for verification at polygonscan.com on 2022-02-26
*/

pragma solidity ^0.4.23;

contract ERC20 {
    uint public _totalSupply;
    function totalSupply() public view returns (uint);
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public;
    function allowance(address owner, address spender) public view returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
}

contract TokenAirdrop {

    // WETH Contract (Wrapped Ether) mainnet.
    address eth_address = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    event transfer(address from, address to, uint amount,address tokenAddress);
    
    // Transfer ERC20 to any ERC20 Token, ()ex: ETH, BSC, MATIC, etc)
    function transferTo(address[] receivers, uint256[] amounts) public payable {
        require(msg.value != 0 && msg.value == getAllSendingAmount(amounts));
        for (uint256 i = 0; i < amounts.length; i++) {
            receivers[i].transfer(amounts[i]);
            emit transfer(msg.sender, receivers[i], amounts[i], eth_address);
        }
    }
    
    // Transfer any ERC20 Token
    // MATIC contract: 0x7d1afa7b718fb893db30a3abc0cfc608aacfebb0
    function transferERC20Token(address tokenAddress, address[] receivers, uint256[] amounts) public {
        require(receivers.length == amounts.length && receivers.length != 0);
        ERC20 token = ERC20(tokenAddress);

        for (uint i = 0; i < receivers.length; i++) {
            require(amounts[i] > 0 && receivers[i] != 0x0);
            token.transferFrom(msg.sender,receivers[i], amounts[i]);
        
            emit transfer(msg.sender, receivers[i], amounts[i], tokenAddress);
        }
    }
    
    //get the Total of Sending Amount
    function getAllSendingAmount(uint256[] _amounts) private pure returns (uint allSendingAmount) {
        for (uint i = 0; i < _amounts.length; i++) {
            require(_amounts[i] > 0);
            allSendingAmount += _amounts[i];
        }
    }
}