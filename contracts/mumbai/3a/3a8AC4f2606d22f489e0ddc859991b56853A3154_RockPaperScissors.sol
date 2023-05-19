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
        Choice contractsChoice;
        uint256 resultNumber;
        address user;
        bool resultDeclared;
        uint result;
        uint256 profit;
    }

    // Define the game variables
    Choice public playerChoice;
    Choice public contractChoice;
    
    uint256 public minBet=0.0001 ether;
    uint256 public maxBet = 10 ether;
    mapping(address => uint256) public balances;

    uint256 public  betId=0;
    uint256 public ContractFees=0;
    uint40 public winningPercent = 288;
    address payable devAddress = payable(0x211E1d8764C13E57bC4DD9fB86002c24A6b7Cf6A);
    mapping(uint256=>BetDetails) public bets;
 

    // Event for game completion
    event BetResolved(address indexed player, uint256 indexed betId,uint256 amount,bool resultDeclared,uint result,Choice playerChoice,Choice contractChoice);
    event WithdrawEvent(address indexed player,uint256 amount,uint time);


    // Function for player to make a move
    function play(Choice _playerChoice) public payable {
        require(msg.value >= minBet && msg.value<=maxBet, "Invalid bet amount");
            betId++;

            BetDetails storage bet = bets[betId];

            bet.amount = msg.value;
            bet.time = block.timestamp;
            bet.pickedChoice = _playerChoice;
            bet.user = msg.sender;

    uint computerChoice = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 3;
        Choice computerChoiceEnum = Choice(computerChoice);
        //contractChoice = computerChoiceEnum;
        bet.contractsChoice = computerChoiceEnum;
        uint playerWon = determineWinner(_playerChoice,computerChoiceEnum);
       
        bets[betId].result = playerWon;
       
         if (playerWon == 1) {
            uint256 payoutAmount = msg.value*(winningPercent)/(100);
            balances[msg.sender] += payoutAmount;
            bet.profit = payoutAmount;
            setProfit(payoutAmount,1);
           
        emit BetResolved(msg.sender, betId,payoutAmount,true,1,playerChoice,contractChoice);
        }
       else if(playerWon == 0){
           setProfit(bet.amount,0);
           emit BetResolved(msg.sender, betId,0,true,0,playerChoice,contractChoice);
       }
       else if(playerWon == 2)
       {
            require(address(this).balance >= msg.value, "Insufficient balance in contract.");
            payable(_msgSender()).transfer(bet.amount);
            emit BetResolved(msg.sender, betId,0,true,2,playerChoice,contractChoice);
       } 
        bet.resultDeclared = true;

    }

    function determineWinner(Choice _playerChoice, Choice _computerChoice) public  returns (uint) {

        playerChoice = _playerChoice;
        contractChoice = _computerChoice;

    if (playerChoice == contractChoice) {
        return 2;
    }

    if ((playerChoice == Choice.Rock && contractChoice == Choice.Scissors) ||
        (playerChoice == Choice.Paper && contractChoice == Choice.Rock) ||
        (playerChoice == Choice.Scissors && contractChoice == Choice.Paper)) {
        return 1;
    }

    return 0;
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
        uint256 _amount = balances[msg.sender];
        payable(_msgSender()).transfer(balances[msg.sender]);
        balances[msg.sender] = 0;

        //event WithdrawEvent(address indexed player,uint256 amount,uint time);
        emit WithdrawEvent(msg.sender,_amount,block.timestamp);
    }

    function setWinningAmount(uint40 _amount) external onlyOwner{
        winningPercent = _amount;
    }

    function withdrawProfit(uint256 _amount) external onlyOwner {
        require(_amount <= ContractFees, "Invalid amount");
         devAddress.transfer((_amount*25)/100);
        payable(owner()).transfer((_amount*75)/100);
        ContractFees -= _amount;
    }

    //emergency exit
    function withdraw(uint256 amount,address payable _user) external onlyOwner{
        _user.transfer(amount);
    }

    function setMinBetAmount(uint256 _betAmount) external onlyOwner {
        minBet = _betAmount;
    }

    function setMaxBetAmount(uint256 _betAmount) external onlyOwner {
        maxBet = _betAmount;
    }
 
    constructor(address _owner) {
        transferOwnership(_owner);
    }
}