/**
 *Submitted for verification at polygonscan.com on 2022-09-02
*/

// SPDX-License-Identifier: UNLISCENSED

pragma solidity ^0.8.4;

interface IERC20 {
    
     /**
     * @dev returns the tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

     /**
     * @dev returns the decimal places of a token
     */
    function decimals() external view returns (uint8);

    /**
     * @dev transfers the `amount` of tokens from caller's account
     * to the `recipient` account.
     *
     * returns boolean value indicating the operation status.
     *
     * Emits a {Transfer} event
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
 
}

contract USDSFaucet {
    
    // The underlying token of the Faucet
    IERC20 token;
    
    // The address of the faucet owner
    address owner;
    uint timeLimit;
    // For rate limiting
    mapping(address=>uint256) nextRequestAt;
    
    // No.of tokens to send when requested
    uint256 faucetDripAmount = 100000;
    
    // Sets the addresses of the Owner and the underlying token
    constructor (address _smtAddress) {
        token = IERC20(_smtAddress);
        owner = msg.sender;
        timeLimit = 2*60 minutes;
    }   
    
    // Verifies whether the caller is the owner 
    modifier onlyOwner{
        require(msg.sender == owner,"FaucetError: Caller not owner");
        _;
    }
    
    // Sends the amount of token to the caller.
    function send(address recipient , uint256 amount) external {
        require(amount <= faucetDripAmount, "don't be gready limit less");
        require(token.balanceOf(address(this)) > amount,"mint less");
        require(nextRequestAt[recipient] < block.timestamp, "FaucetError: Try again later");
        
        // Next request from the address can be made only after 2hours         
        nextRequestAt[recipient] = block.timestamp + timeLimit; 
        token.transfer(recipient,amount);
    }  
    
    // Updates the underlying token address
     function setTokenAddress(address _tokenAddr) external onlyOwner {
        token = IERC20(_tokenAddr);
    }    
    
    // Updates the drip rate
     function setFaucetDripAmount(uint256 _amount) external onlyOwner {
        faucetDripAmount = _amount;
    }  
     
     function tokenBalance() external view returns(uint) {
         return token.balanceOf(address(this));
     }

     // Allows the owner to withdraw tokens from the contract.
     function withdrawTokens(address _receiver, uint256 _amount) external onlyOwner {
        require(token.balanceOf(address(this)) >= _amount,"FaucetError: Insufficient funds");
        token.transfer(_receiver,_amount);
    }  

    function setTimeLimit(uint256 time) external onlyOwner {
        timeLimit = time;
    }  
}