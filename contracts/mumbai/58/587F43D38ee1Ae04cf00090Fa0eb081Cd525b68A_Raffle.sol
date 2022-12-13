/**
 *Submitted for verification at polygonscan.com on 2022-12-12
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol


pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// File: @chainlink/contracts/src/v0.8/AutomationBase.sol


pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// File: @chainlink/contracts/src/v0.8/AutomationCompatible.sol


pragma solidity ^0.8.0;



abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/RaffleAutomated.sol



pragma solidity 0.8.7;



contract Raffle is AutomationCompatibleInterface {
    
    
    address public admin;
    address treasuryAddress = 0xb1Fbaaf20db44A04041C2f2584F592769cc630D3;
    IERC20 token;
    uint256 public PRIZE_PERCENTAGE;
    uint256 public NEXT_ROUND_PRIZE_PERCENTAGE;
    struct RaffleInfo{
        uint256 endTime;
        uint256 interval;
        uint256 round;
        uint256 ticketPrice;
        address lastWinner;
        uint256 prizePool;
        address[] players;
    }
    struct NextRoundInfo{
        uint256 interval;
        uint256 ticketPrice;
    }
    RaffleInfo public raffleInfo;
    NextRoundInfo public nextRoundInfo;

    event TicketPurchase(address indexed player, uint256 amountOfTickets, uint256 totalPrice);
    event RoundFinished(address indexed winner, uint256 prize, uint256 endedAt);
    event RoundStart(uint256 indexed round, uint256 startedAt, uint256 duration, uint256 endsAt);


    constructor(address _token, uint256 _ticketPrice) {
        admin = msg.sender;
        token = IERC20(_token);
        raffleInfo.ticketPrice = _ticketPrice;
        raffleInfo.interval = 6 minutes;
        raffleInfo.endTime = block.timestamp + 6 minutes;
        raffleInfo.round = 1;
        nextRoundInfo.interval = raffleInfo.interval;
        nextRoundInfo.ticketPrice =  _ticketPrice;
        PRIZE_PERCENTAGE=95;
        NEXT_ROUND_PRIZE_PERCENTAGE=95;
        emit RoundStart(1, block.timestamp, raffleInfo.interval, raffleInfo.endTime);
    }
    
    modifier onlyOwner() {
        require(admin == msg.sender, "You are not the owner");
        _;
    }
    modifier isActive(){
        require(block.timestamp<raffleInfo.endTime,"You cannot buy tickets at this time");
        _;
    }

    function setTreasuryAddress(address _address) onlyOwner public {
    treasuryAddress = _address;
    }

    function setTicketPrice(uint256 _price) public onlyOwner{
        nextRoundInfo.ticketPrice = _price;
    }
    //Set interval in seconds
    function setRoundInterval(uint256 _interval) public onlyOwner {
        nextRoundInfo.interval = _interval;
    }
    function setPrizePercentage(uint256 _percentage) public onlyOwner {
        NEXT_ROUND_PRIZE_PERCENTAGE = _percentage;
    }

    function getPlayers() public view returns(address[] memory){
        return raffleInfo.players;
    }

    function getLastWinner() public view returns(address){
        return raffleInfo.lastWinner;
    }

    function checkIntegerETH(uint256 a) pure internal returns (bool) {
        return (a % 1 ether == 0);
    }
  
        function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        upkeepNeeded = (block.timestamp>=raffleInfo.endTime);
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if (block.timestamp >= raffleInfo.endTime) {
            pickWinner();
        }
        // We don't use the performData in this example. The performData is generated by the Automation Node's call to your checkUpkeep function
    }
      
    
    function buyTickets(uint256 _amount) isActive public {
        require(checkIntegerETH(_amount),"Amount must be an integer");
        //Check if transferred amount is enough to buy a ticket    
        require(_amount >= raffleInfo.ticketPrice, "Incorrect token amount!");
        //Make sure admin is not allowed to join the lottery.
        require(msg.sender != admin, "msg.sender is not the owner");

        token.transferFrom(msg.sender,address(this),_amount);
        raffleInfo.prizePool+=_amount*PRIZE_PERCENTAGE/100;
        //Add players to array for each ticket they bought.
        uint256 i;
        uint256 numOfTickets = _amount / raffleInfo.ticketPrice;

        for (i=0; i < numOfTickets; i++) {
             raffleInfo.players.push(msg.sender);
        }
        emit TicketPurchase(msg.sender, numOfTickets, _amount);
       
    }
    
    function getBalance() public view returns(uint256){
        return token.balanceOf(address(this));
    }
    
    function random() internal view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, raffleInfo.players.length)));
    }
    
    function pickWinner() internal {
        require(block.timestamp >= raffleInfo.endTime, "Period has not ended yet");
        // require(players.length >= 2 , "Not enough players in the lottery");
        address winner = address(0);
        if(raffleInfo.players.length>=2){
        //selects the winner with random number
        winner = raffleInfo.players[random() % raffleInfo.players.length];
        //transfers balance to winner

        token.transfer(address(winner), (getBalance() * PRIZE_PERCENTAGE) / 100); 
        token.transfer(address(treasuryAddress), getBalance());
        } else if(raffleInfo.players.length==1){
            token.transfer(address(raffleInfo.players[0]), getBalance());
        }

       resetLottery(winner); 
        
    }

    function resetLottery(address winner) internal {
        emit RoundFinished(winner, raffleInfo.prizePool, block.timestamp);

        raffleInfo = RaffleInfo(block.timestamp + nextRoundInfo.interval,nextRoundInfo.interval,raffleInfo.round+1,nextRoundInfo.ticketPrice,winner,0,new address[](0));
        PRIZE_PERCENTAGE = NEXT_ROUND_PRIZE_PERCENTAGE;
        emit RoundStart(raffleInfo.round, block.timestamp, raffleInfo.interval, raffleInfo.endTime);
    }
    function _emergencyWithdraw() public onlyOwner {
        token.transfer(address(treasuryAddress),getBalance());
    }

}