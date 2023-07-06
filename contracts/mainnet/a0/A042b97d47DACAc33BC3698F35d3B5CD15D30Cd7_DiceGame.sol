// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
contract DiceGame is Ownable{

    struct BetDetails{
        address user;
        uint256 amount;
        uint256 time;
        uint result;
        uint256 profit;
        uint predeterminedNumber;
        bool isLess;
        uint dice1;
        uint dice2;
    }
    
    uint256 public minBetNumber = 3;
    uint256 public maxBetNumber = 11;
    uint256 public minBet= 0.0001 ether;
    uint256 public maxBet = 10 ether;
    uint256 public ContractFees= 0;
    uint256 public betId= 0;
    address payable devAddress = payable(0x211E1d8764C13E57bC4DD9fB86002c24A6b7Cf6A);
    mapping(address => uint256) public balances;
    mapping(uint256=>BetDetails) public bets;
    mapping(uint => uint) public Minor;
    mapping(uint => uint) public Mayor;

    // Event for game completion
    event BetResolved(address indexed player, uint256 indexed betId,uint256 amount,uint result,uint predeterminedNumber,bool isLess,uint dice1,uint dice2,uint256 profit);
    event WithdrawEvent(address indexed player,uint256 amount,uint time);
    constructor(address _owner) payable {
       transferOwnership(_owner);

        Minor[1] = 0;
        Minor[2] = 0;
        Minor[3] = 3400;
        Minor[4] = 1100;
        Minor[5] = 500;
        Minor[6] = 300;
        Minor[7] = 200;
        Minor[8] = 130;
        Minor[9] = 130;
        Minor[10] = 115;
        Minor[11] = 105;

        Mayor[1] = 0;
        Mayor[2] = 0;
        Mayor[3] = 105;
        Mayor[4] = 115;
        Mayor[5] = 130;
        Mayor[6] = 150;
        Mayor[7] = 200;
        Mayor[8] = 300;
        Mayor[9] = 500;
        Mayor[10] = 1100;
        Mayor[11] = 3400;

    }

    function playGame(uint _predeterminedNumber,bool _isLess) public payable {
        require(_predeterminedNumber >= minBetNumber && _predeterminedNumber<=maxBetNumber, "Bet Number range is between 3 to 11");
         require(msg.value >= minBet && msg.value<=maxBet, "Invalid bet amount");
            betId++;
       
        // Generate random numbers between 1 and 6
        uint dice1 = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 6 + 1;
        uint dice2 = uint(keccak256(abi.encodePacked(block.timestamp + 1, msg.sender))) % 6 + 1;

        uint sum = dice1 + dice2;
        bool isWinner;
        uint256 payoutAmount = 0;
       
          BetDetails storage bet = bets[betId];

            bet.user = msg.sender;
            bet.amount = msg.value;
            bet.time = block.timestamp;
            bet.predeterminedNumber = _predeterminedNumber;
            bet.isLess = _isLess;
            bet.dice1 = dice1;
            bet.dice2 = dice2;

        if (_isLess) {
            isWinner = sum < _predeterminedNumber;
        } else {
            isWinner = sum > _predeterminedNumber;
        }

        if (isWinner) {
            // (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
            // require(success, "Failed to send the winnings to the winner.");
            if(_isLess)
            {
            payoutAmount = msg.value*(Minor[_predeterminedNumber])/(100);
            balances[msg.sender] += payoutAmount;
            bet.profit = payoutAmount;
            bet.result = 1;
            setProfit(payoutAmount,1);
            }
            else 
            {
            payoutAmount = msg.value*(Mayor[_predeterminedNumber])/(100);
            balances[msg.sender] += payoutAmount;
            bet.profit = payoutAmount;
            bet.result = 1;
            setProfit(payoutAmount,1);
            }

            //event BetResolved(player,betId,amount,result,predeterminedNumber,isLess,dice1,dice2);
        emit BetResolved(msg.sender, betId,msg.value,1,_predeterminedNumber,_isLess,dice1,dice2,payoutAmount);
        }
        else 
        {
             setProfit(msg.value,0);

            //event BetResolved(address indexed player, uint256 indexed betId,uint256 amount,uint result,uint predeterminedNumber,bool isLess,uint dice1,uint dice2);
        emit BetResolved(msg.sender, betId,msg.value,0,_predeterminedNumber,_isLess,dice1,dice2,payoutAmount);
        }

       
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
        emit WithdrawEvent(msg.sender,_amount,block.timestamp);
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
}

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