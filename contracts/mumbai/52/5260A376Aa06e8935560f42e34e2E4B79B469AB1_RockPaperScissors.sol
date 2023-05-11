// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 *Submitted for verification at BscScan.com on 2023-04-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
contract RockPaperScissors is Ownable{
    // Define the possible choices
    enum Choice { Rock, Paper, Scissors }


 struct BetDetails{
        uint256 amount;
        uint256 time;
        Choice pickedChoice;
        uint256 resultNumber;
        address user;
        bool resultDeclared;
        uint result;
        uint256 profit;
    }

    // Define the game variables
    
    Choice public winnerPlayerChoice;
    Choice public playerChoice;
    Choice public contractChoice1;
    Choice public contractChoice2;
    
    uint256 public minBet=0.001 ether;
    uint256 public maxBet = 10 ether;
    mapping(address => uint256) public balances;

    mapping(uint8 => uint) public betAmount;


      uint256 betId=0;
      uint256 public ContractFees=0;
     uint40 public winningPercent = 288;
     address payable devAddress = payable(0x211E1d8764C13E57bC4DD9fB86002c24A6b7Cf6A);
    mapping(uint256=>BetDetails) public bets;
    //  uint256 public minBetAmount = 0.001 ether;

    // Event for game completion
    event BetResolved(address indexed player, uint256 indexed betId, Choice winningChoice,uint256 amount,bool resultDeclared,uint result);
    event testEv(Choice playerChoice, Choice contractChoice1,Choice contractChoice2,uint256 result);
    // Function for player to make a move
    function play(Choice _playerChoice) public payable {
        require(msg.value >= minBet && msg.value<=maxBet, "Invalid bet amount");
        // Ensure only the player can make a move
       
        betId++;

            BetDetails storage bet = bets[betId];

            bet.amount = msg.value;
            bet.time = block.timestamp;
            bet.pickedChoice = _playerChoice;
            bet.user = msg.sender;

        // Set the player's choice
        playerChoice = _playerChoice;

        // Generate two random choices for the contract
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.number)));
        contractChoice1 = Choice(rand % 3 + 1);
        contractChoice2 = Choice((rand / 3) % 3 + 1);

        // Determine the winner
        uint playerWon = determineWinner();
       
        bets[betId].result = playerWon;


         if (playerWon == 1) {
            uint256 payoutAmount = msg.value*(winningPercent)/(100);
            balances[msg.sender] += payoutAmount;
            bet.profit = payoutAmount;
            //emit BetResolved(bet.user, _betId, bet.pickedNo, winningNumber,bet.amount,payoutAmount);
            setProfit(payoutAmount,1);
            emit BetResolved(msg.sender, betId,winnerPlayerChoice,payoutAmount,true,1);
        }
       else if(playerWon == 0){
           setProfit(bet.amount,0);
           emit BetResolved(msg.sender, betId,winnerPlayerChoice,0,true,0);
           
       }
       else if(playerWon == 2)
       {
            require(address(this).balance >= msg.value, "Insufficient balance in contract.");
            payable(_msgSender()).transfer(balances[msg.sender]);
            emit BetResolved(msg.sender, betId,winnerPlayerChoice,0,true,2);
       } 
        bet.resultDeclared = true;

        // Emit the game completion event
      //  winnerPlayerChoice
       //event BetResolved(address indexed player, uint256 indexed betId, Choice winningChoice,uint256 amount,bool resultDeclared,uint result);
       // emit BetResolved(msg.sender, betId,winnerPlayerChoice,msg.value,true,playerWon);

    }

    // Function to determine the winner
    function determineWinner() private returns (uint) {
      Choice choice1 = playerChoice;
      Choice choice2 = contractChoice1;
      Choice choice3 = contractChoice2;

    // If any of the choices are the same, no winner can be determined
    if (choice1 == choice2 || choice1 == choice3 || choice2 == choice3) {
       // winnerPlayerChoice = Choice.None;
        return 2;
    }   
    // If choice1 wins
    if ((choice1 == Choice.Rock && choice2 == Choice.Scissors && choice3 == Choice.Scissors) ||
        (choice1 == Choice.Paper && choice2 == Choice.Rock && choice3 == Choice.Rock) ||
        (choice1 == Choice.Scissors && choice2 == Choice.Paper && choice3 == Choice.Paper)) {
            winnerPlayerChoice = choice1;
        return 1;
    }
    // If choice2 wins
    if ((choice2 == Choice.Rock && choice1 == Choice.Scissors && choice3 == Choice.Scissors) ||
        (choice2 == Choice.Paper && choice1 == Choice.Rock && choice3 == Choice.Rock) ||
        (choice2 == Choice.Scissors && choice1 == Choice.Paper && choice3 == Choice.Paper)) {
            winnerPlayerChoice = choice2;
        return 0;
    }
    // If choice3 wins
    if ((choice3 == Choice.Rock && choice1 == Choice.Scissors && choice2 == Choice.Scissors) ||
        (choice3 == Choice.Paper && choice1 == Choice.Rock && choice2 == Choice.Rock) ||
        (choice3 == Choice.Scissors && choice1 == Choice.Paper && choice2 == Choice.Paper)) {
            winnerPlayerChoice = choice3;
        return 0;
    }
//winnerPlayerChoice = Choice.None;
    return 2;
    }

function setProfit(uint256 amount,uint _type) internal{
        if(_type==1){
            if(ContractFees>amount){
                ContractFees -= amount;
            }
            else{
                ContractFees = 0;
            }
        }
        else if(_type == 0)
        {
            ContractFees += amount;
        }
       
    }

 function withdrawEarnings() external{
        payable(_msgSender()).transfer(balances[msg.sender]);
        balances[msg.sender] = 0;
    }

    function setWinningAmount(uint40 _amount) external onlyOwner{
        winningPercent = _amount;
    }

    

    function withdraw(uint256 _amount) external onlyOwner {
        require(_amount <= ContractFees, "Invalid amount");
         devAddress.transfer(_amount/2);
        payable(owner()).transfer(_amount/2);
    }

    function setMinBetAmount(uint256 _betAmount) external onlyOwner {
        minBet = _betAmount;
    }

    function setMaxBetAmount(uint256 _betAmount) external onlyOwner {
        maxBet = _betAmount;
    }
    // Constructor to set the player address
    constructor(address _owner) {
        transferOwnership(_owner);
    }

    // function test(Choice _playerChoice) public
    // {
    //     // Generate two random choices for the contract
    //     uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.number)));
    //     contractChoice1 = Choice(rand % 3 + 1);
    //     contractChoice2 = Choice((rand / 3) % 3 + 1);
    // //event testEv(Choice playerChoice, Choice contractChoice1,Choice contractChoice2,uint256 result);
    // emit testEv(_playerChoice, contractChoice1,contractChoice2,0);
    // }
}