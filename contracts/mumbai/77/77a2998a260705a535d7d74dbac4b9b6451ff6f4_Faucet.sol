/**
 *Submitted for verification at polygonscan.com on 2023-02-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function balanceOf(address account) external view returns (uint256);
}
/**
@title A faucet contract for dispersing ERC20 tokens, such as EUROe
@author Membrane Finance
@notice This contract lets anyone withdraw and top up the tokens in the contract
 */
contract Faucet {
    uint256 constant public tokenAmount = 100000000; // 100 EUROe
    uint256 constant public cooldown = 24 hours; // Must wait 24h between faucet calls per address

    ERC20 public tokenAddress;

    mapping(address => uint256) lastUse;

    constructor(address _tokenAddress) {
        tokenAddress = ERC20(_tokenAddress);
    }

    /**
     * @dev Gives the caller 100 EUROe
     */
    function getEUROe() public {
        require(withdrawalAllowed(msg.sender), "You can only withdraw from the contract every 24 hours");
        tokenAddress.transfer(msg.sender, tokenAmount);
        lastUse[msg.sender] = block.timestamp;
    }

    /**
     * @dev Returns the contract's current EUROe balance. Please notify the team if the contract is empty
     */
    function getBalance() public view returns (uint256) {
        return ERC20(tokenAddress).balanceOf(address(this));
    }

    /**
     * @dev Determines if withdrawals are allowed to caller's address
     */
    function withdrawalAllowed(address _address) public view returns (bool) {
        if (lastUse[_address] == 0) {
            return true;
        } 
        else if (block.timestamp >= lastUse[_address] + cooldown) {
            return true;
        }
        else {
            return false;
        }
        
    }

}