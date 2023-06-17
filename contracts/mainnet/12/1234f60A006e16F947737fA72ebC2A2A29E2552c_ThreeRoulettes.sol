// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
contract ThreeRoulettes is Ownable{
   
    uint256 public minBet= 0.0001 ether;
    uint256 public maxBet = 10 ether;
    uint256 public ContractFees= 0;
    uint256 public betId= 0;
    uint40 public winningPercent = 288;
    address payable devAddress = payable(0x211E1d8764C13E57bC4DD9fB86002c24A6b7Cf6A);
    uint256 public constant ROULETTE_OPTIONS_FIRST_2_WHEEL = 5;
    uint256 public constant ROULETTE_OPTIONS_THIRD_WHEEL = 6;

    mapping(address => uint256) public balances;

    mapping(uint256 => uint) public Wheel1;
    mapping(uint256 => uint) public Wheel2;
    mapping(uint256 => uint) public Wheel3;
    
    struct BetDetails {
        address payable user;
        uint256 amount;
        uint256 rouletteOption;
        uint256 time;
        uint256 profit;
        uint firstWheelResult;
        uint SecondWheelResult;
        uint ThirdWheelResult;
        bool isSecondWheelPlay;
        bool isThirdWheelPlay;
        bool isEligibleForNextRound;
        bool isBetResolve;

    }
    
    mapping(uint256=> BetDetails) public bets;
    mapping(address => uint256) playerBets;

    // Event for game completion
    event BetResolved(address indexed user, uint256 indexed betId,uint8 wheel, uint256 amount,uint result,uint256 rouletteChoice,uint256 profit,bool isEligibleForNextRound);
    
    constructor(address _owner) {
        transferOwnership(_owner);

        Wheel1[1] = 0;
        Wheel1[2] = 50;
        Wheel1[3] = 150;
        Wheel1[4] = 200;
        Wheel1[5] = 1;

        Wheel2[1] = 0;
        Wheel2[2] = 150;
        Wheel2[3] = 200;
        Wheel2[4] = 500;
        Wheel2[5] = 1;


        Wheel3[1] = 0;
        Wheel3[2] = 200;
        Wheel3[3] = 300;
        Wheel3[4] = 500;
        Wheel3[5] = 1000;
        Wheel3[6] = 3500;
      
    }
    
   
    function bet() public payable {
         require(msg.value >= minBet && msg.value<=maxBet, "Invalid bet amount");
        
        betId++;
        
        //Bets memory newBet = Bet(payable(msg.sender), msg.value, _rouletteOption, block.timestamp,0,0,0);

        BetDetails storage newBet = bets[betId];

        newBet.user = payable(msg.sender);
        newBet.amount = msg.value;
        
        newBet.time = block.timestamp;
       
        //betsByRoulette[1].push(newBet);
        
        ContractFees += msg.value;
        
        playerBets[msg.sender]++;
        
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % (ROULETTE_OPTIONS_FIRST_2_WHEEL+1);
        
        newBet.firstWheelResult = randomNumber;
        if (randomNumber == ROULETTE_OPTIONS_FIRST_2_WHEEL) {
            newBet.isSecondWheelPlay = true;
            newBet.isEligibleForNextRound = true; 
            newBet.isBetResolve = false;
            //nextRoulette();
            emit BetResolved(msg.sender, betId,1,msg.value,0,randomNumber,0,true);
        }
        else if(randomNumber == 1 || randomNumber == 0)
        {
             newBet.isSecondWheelPlay = false;
             newBet.isThirdWheelPlay = false;
             newBet.isBetResolve = true;
             setProfit(msg.value, 0);
           // BetResolved(address indexed player, uint256 indexed betId,uint8 wheel, uint256 amount,uint result,uint256 playerRouletteChoice);
        emit BetResolved(msg.sender, betId,1,msg.value,0,1,0,false);
        }
         else {
             newBet.isSecondWheelPlay = false;
             newBet.isThirdWheelPlay = false;
             newBet.isBetResolve = true;
            uint256 payout = msg.value * (Wheel1[randomNumber])/100;
            balances[msg.sender] += payout;
          //  newBet.user.transfer(payout);
            newBet.profit = payout;
            setProfit(payout, 1);
            emit BetResolved(msg.sender, betId,1,msg.value,1,randomNumber,payout,false);
        }
    }
    
    function secondRoulette(uint256 _betId)  public {
       
        require(bets[_betId].isBetResolve == false, "Bet already resolved");
        require(bets[_betId].user == msg.sender, "Invalid bet id");
        require(bets[_betId].isEligibleForNextRound == true, "You not eligible for second round");
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % (ROULETTE_OPTIONS_FIRST_2_WHEEL+1);
       
       bets[_betId].isEligibleForNextRound == false;
        if (randomNumber == ROULETTE_OPTIONS_FIRST_2_WHEEL) {
             bets[_betId].isThirdWheelPlay = true;
             bets[_betId].isEligibleForNextRound == true;
             bets[_betId].isBetResolve = false;
           // lastRoulette(_betId);
           emit BetResolved(msg.sender, _betId,2,bets[_betId].amount,0,randomNumber,0,true);
        }
        else if(randomNumber == 1 || randomNumber == 0)
        {
              bets[_betId].isThirdWheelPlay = false;
              bets[_betId].isBetResolve = true;
             setProfit(bets[_betId].amount, 0);
             emit BetResolved(msg.sender, _betId,2,bets[_betId].amount,0,1,0,false);
        }
          else {
               bets[_betId].isThirdWheelPlay = false;
               bets[_betId].isBetResolve = true;
                uint256 payout = bets[_betId].amount * (Wheel2[randomNumber])/100;
                balances[msg.sender] += payout;
                setProfit(payout, 1);
               // bets[_betId].user.transfer(payout);
                emit BetResolved(msg.sender, _betId,2,bets[_betId].amount,1,randomNumber,payout,false);
            }
        
       
    }
    
    function thirdRoulette(uint256 _betId) public {

        require(bets[_betId].isBetResolve == false, "Bet already resolved");
        require(bets[_betId].user == msg.sender, "Invalid bet id");
        require(bets[_betId].isEligibleForNextRound == true, "You not eligible for third round");
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % (ROULETTE_OPTIONS_THIRD_WHEEL+1);
        
        if(randomNumber == 1 || randomNumber == 0)
        {
            bets[_betId].isBetResolve = true;
            setProfit(bets[_betId].amount, 0);
            emit BetResolved(msg.sender, _betId,3,bets[_betId].amount,1,randomNumber,0,false);
        }
          else {
               bets[_betId].isBetResolve = true;
                uint256 payout = bets[_betId].amount * (Wheel3[randomNumber])/100;
                balances[msg.sender] += payout;
                setProfit(payout, 1);
               // bets[_betId].user.transfer(payout);
                emit BetResolved(msg.sender, _betId,3,bets[_betId].amount,1,randomNumber,payout,false);
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
        payable(_msgSender()).transfer(balances[msg.sender]);
        balances[msg.sender] = 0;
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