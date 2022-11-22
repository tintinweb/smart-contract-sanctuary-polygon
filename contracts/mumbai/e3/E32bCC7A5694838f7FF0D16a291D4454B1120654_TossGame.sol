/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** @title A Random Number Generator Library
  * @author Mohammad Z. Rad
  * @notice You can use this library to generate a random number by giving a noune
  * @dev The truly randomness comes with Chainlink VRF v2 off-chain but this on-chain method also gives a solution. 
*/
library RNG{
    /** @dev For calculating possibility between 0 and 100 with 10*1 decimal we get random number between 0 and 1000 by calculating a random number % 1001
    */
    function generate(uint _nounce) internal view returns(uint16){
        return uint16(uint(keccak256(abi.encodePacked(_nounce, block.number-1, block.difficulty,  
        msg.sender))) % 1001);
    }
}

/** @title A Toss Game Contract
  * @author Mohammad Z. Rad
  * @notice Users can send native token directly to contract and Win(2x) or Lose
  * @dev All function calls are currently implemented without side effects
*/
contract TossGame {    
    /// @notice These events emit after each phase(Win, Lose, Return)
    event Returned(address sender, uint value);
    event Won(address winner, uint value);
    event Lost(address loser, uint value);

    /// @notice admin address to control treasuty funds
    address immutable public admin;
    /// @notice defined for visibility of address(this).balance 
    uint256 public treasuryBalance;
    /// @notice nounce used in generating random number
    uint256 private nounce;
    /// @notice generated possibility between 0 and 1000 which represents 0 to 100 percent with 10 ** 1 decimal precision
    uint16 private generated;

    /// @dev must send initial native token while deploying to charge treasury for use
    constructor() payable {
        require(msg.value > 0, "Contract must have initial balance");
        treasuryBalance = msg.value;
        admin = msg.sender;
    }

    /// @notice checks before if sender has admin access
    modifier onlyOwner{
        require(msg.sender == admin, "Only owner can deposit in treasury");
        _;
    }

    /// @notice deposit native token to treasury if treasury is empty
    function deposit() external onlyOwner payable returns(uint){
        treasuryBalance += msg.value;
        return treasuryBalance;
    }

    /** @notice admin can withdraw from treasury and control treasury balance
    * @param _value the amount of native token admin wish to withdraw from treasury
    */
    function withdraw(uint _value) external onlyOwner returns(uint){
        require(_value <= treasuryBalance, "You can't withdraw more than treasury balance");
        treasuryBalance -= _value;
        payable(admin).transfer(_value);
        return treasuryBalance;
    }

    /** @notice The function that decide the Winner with 50.1% chance and Loser with 49.9% chance and Return the sent native token if that is higher than treasury balance 
    */
    function toss() private {
        require(msg.value > 0, "Send a none zero value Ether.");
        generated = RNG.generate(nounce);
        nounce++;
        if(msg.value <= treasuryBalance){
            if(generated > 499){
                treasuryBalance += msg.value;
                emit Lost(msg.sender, msg.value);
            } else {
                treasuryBalance -= 2 * msg.value;
                payable(msg.sender).transfer(2 * msg.value);
                emit Won(msg.sender, 2 * msg.value);
            }
        } else {
            payable(msg.sender).transfer(msg.value);
            emit Returned(msg.sender, msg.value);
        }
    }

    /// @notice the function which calls toss() upon receiving native token
    receive() external payable {
        toss();
    }
}