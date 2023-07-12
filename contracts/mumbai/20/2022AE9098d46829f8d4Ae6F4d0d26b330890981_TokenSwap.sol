/**
 *Submitted for verification at polygonscan.com on 2023-07-11
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: Unlicensed


interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
contract TokenSwap {

    
    address public receiver;
    uint256 public amount;
    uint256 public expiry;
    bool public locked = false;
    // Mapping of user addresses to their locked token amounts
    mapping(address => uint256) public lockedTokens;
    
    // Mapping of user addresses to the time when their tokens were locked
    mapping(address => uint256) public lockTimestamps;
    
    // Time duration during which token locking is not allowed after a swap
    uint256 public lockDuration;
    
    // Token contract address
    address public tokenContract;
    
    constructor(address _tokenContract, uint256 _lockDuration) {
        tokenContract = _tokenContract;
        lockDuration = _lockDuration;
    }
    
    // Modifier to check if tokens are locked
    modifier tokensNotLocked() {
        require(block.timestamp >= lockTimestamps[msg.sender] + lockDuration, "Tokens are locked");
        _;
    }
    
    // Function to swap tokens
    function swapTokens(uint256 _amount) external tokensNotLocked {
        // Perform the token swap logic
        
        // Lock the swapped tokens
        lockedTokens[msg.sender] += _amount;
        lockTimestamps[msg.sender] = block.timestamp;
    }




    // constructor (address _token) {
    //     token = IERC20(_token);
    // }

    function lock(address _from, address _receiver, uint256 _amount, uint256 _expiry) external {
        IERC20 token = IERC20(tokenContract);
        require(!locked, "We have already locked tokens.");
        token.transferFrom(_from, address(this), _amount);
        receiver = _receiver;
        amount = _amount;
        expiry = _expiry;
        locked = true;
    }

    // function withdraw() external {
    //     require(locked, "Funds have not been locked");
    //     require(block.timestamp > expiry, "Tokens have not been unlocked");
    //     require(!claimed, "Tokens have already been claimed");
    //     claimed = true;
    //     token.transfer(receiver, amount);
    // }

    function getTime() external view returns (uint256) {
        return block.timestamp;
    }
}