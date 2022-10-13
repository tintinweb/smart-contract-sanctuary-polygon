// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
// An example of a consumer contract that relies on a subscription for funding.
/*

 
██      ██    ██  ██████ ██   ██ ██    ██ ███    ██ ██    ██ ███    ███ ██████  ███████ ██████      ██████   ██████  
██      ██    ██ ██      ██  ██   ██  ██  ████   ██ ██    ██ ████  ████ ██   ██ ██      ██   ██    ██       ██       
██      ██    ██ ██      █████     ████   ██ ██  ██ ██    ██ ██ ████ ██ ██████  █████   ██████     ██   ███ ██   ███ 
██      ██    ██ ██      ██  ██     ██    ██  ██ ██ ██    ██ ██  ██  ██ ██   ██ ██      ██   ██    ██    ██ ██    ██ 
███████  ██████   ██████ ██   ██    ██    ██   ████  ██████  ██      ██ ██████  ███████ ██   ██ ██  ██████   ██████  
                                                                                                                     
website: https://luckynumber.gg                                                                                                      
discord: https://discord.gg/bPjSKmJXAq
twitter: https://twitter.com/luckynumbergg


*/
import "./Raffle.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

contract Manager is VRFConsumerBaseV2 
{
  using SafeMath for uint256;

  VRFCoordinatorV2Interface COORDINATOR;

 // Your subscription ID.
  uint64 private _subscriptionid;


  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 constant private KEY_HASH = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 2500000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 constant private GAS_LIMIT = 2500000;

  // The default is 3, but you can set this higher.
  uint16 constant private REQUEST_CONFIRMATIONS = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 constant private NUM_WORDS =  1;

  address private _owner;

  //Wallet office that receives the fee rates
  address private _office = 0x71061fBB51c8c243c08D80056B1fE933E5500779;
    
  //Value of fee tax div 20 = 5%
  uint256 private _fee = 20; //5%

  //id generated from the manufacture of the Rifa contract
  uint public raffleId = 0; 

  //total active raffles
  uint public eventCount = 0; 

  //total raffle created
  uint public raffleTotal = 0; 

  //volume 
  uint256 public volume = 0;

  //Mapping token prices
  mapping(string => address) private _aggregator;

  //Mapping contract address with manufactured contract
  mapping(address => Raffle) private raffleItems;

  //Mapping request for the drawn number linked to the Raffle's address
  mapping(uint256 => address) private requests;

  /**
  * @dev Emitted contractAddress address raffle contract
  * @dev Emitted id raffle contract
  * @dev Emitted eventName raffle contract
  * @dev Emitted timestamp date now
  */

  event EventLog(address indexed contractAddress, uint id, string eventName, uint timestamp); 
  
    /**
  * @dev Emitted raffle address raffle contract
  * @dev Emitted id raffle contract
  * @dev Emitted result request
  * @dev Emitted timestamp date now
  */

  event EventRandomResult(address indexed raffle, uint id, uint256 result, uint256 timestamp); 

  /**
  * @dev Emitted office 
  * @dev Emitted fee
  */

  event EventChangeOffice(address office, uint fee);


  modifier onlyOwner() {
    require(msg.sender == _owner);
    _;
  }

  /**
  * @dev build the contract that is raffle factory with VRFConsumer that draws the numbers
  */
  constructor(uint64 subId) VRFConsumerBaseV2(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed) 
  {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    _owner = msg.sender;
    _subscriptionid = subId;

     /*Mumbai*/
    _aggregator["ETH"] = 	0x0715A7794a1dc8e42615F059dD6e406A6594651A;
    _aggregator["MATIC"]  = 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada;
    
     
  }
  function setOffice(address office, uint fee) external onlyOwner
  {
      require(office != address(0), "token address 0x000...");

      _office = office;
      _fee = fee;

      emit EventChangeOffice(_office, _fee);
  }
  /// @dev get address office value fee
  /// @return office fee
  function getOffice() external view returns(address office, uint fee)
  {
      return(_office, _fee);
  }

/// @notice creation init raffle contract 
    /// @param raffleName_ title 
    /// @param quant_ quant 
    /// @param startTime_ start date
    /// @param finishTime_ finish date
    /// @param price_ price number
    /// @param token_ address token
     
  function createRaffle( 
        string memory raffleName_, 
        uint quant_, 
        uint startTime_, 
        uint finishTime_, 
        uint256 price_, 
        address token_) public onlyOwner
  {
       

        //generate the raffle id
        raffleId++;

        //new index
        eventCount++;

        //create the raffle contract with id and index
        Raffle _value = new Raffle(address(this));

        //links the contract address with the contract
        raffleItems[address(_value)] = _value;

        //start the raffle
        raffleItems[address(_value)].init(raffleId, eventCount, raffleName_, quant_, startTime_, finishTime_, price_, token_);
        
  }
  
    function scalePrice(int256 price_, uint8 priceDecimals_, uint8 decimals_)
        internal
        pure
        returns (int256)
    {
        if (priceDecimals_ < decimals_) {
            return price_ * int256(10 ** uint256(decimals_ - priceDecimals_));
        } else if (priceDecimals_ > decimals_) {
            return price_ / int256(10 ** uint256(priceDecimals_ - decimals_));
        }
        return price_;
    }
    

  function getPrice(string memory symbol, uint8 decimals) public view returns (uint) 
  {
       int p = 0;
       
        ( , int256 basePrice, , , ) = AggregatorV3Interface(_aggregator[symbol]).latestRoundData();
        
        uint8 baseDecimals = AggregatorV3Interface(_aggregator[symbol]).decimals();
        p = scalePrice(basePrice, baseDecimals, decimals);

        
       return uint(p);
   }

  function add() external 
  {
    createRaffle( 
        "TESTE1", 
        10, 
        block.timestamp, 
        block.timestamp.add(3600), 
        10000000000000000, 
        0x54d7401d96cDb34D6d2F9226fF7c8Bc7aB26BEDe);
  }   


   /// @notice close the contract
   /// @dev closes the raffle contract that has no purchased numbers
   /// @param raffle address raffle

   function setClose(address raffle) external onlyOwner
   {
      //updates active raffles
      eventCount--;

      //closes the contract in the raffle
      raffleItems[raffle].setClose();

      //delete contract from array
      delete raffleItems[raffle];
   }
    
   // 
   /// @notice Assumes the subscription is funded sufficiently.
   /// @dev run the draw of the number in the raffle
   /// @param raffle address raffle

   function requestRandomWords(address raffle) external onlyOwner
   {
        //validate random
        bool validate = raffleItems[raffle].validateRequest();
      
        if(validate)
        {
            //adds the request id to the drawn raffle contract
            requests[COORDINATOR.requestRandomWords(
                    KEY_HASH,
                    _subscriptionid,
                    REQUEST_CONFIRMATIONS,
                    GAS_LIMIT,
                    NUM_WORDS
                    )] = raffle;
        }
  }
 
   /// @dev receive number drawn after executing the requestRandomWords function
   /// @param requestId requested number drawn
   /// @param randomWords array number drawn
  
  function fulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
  ) internal override {


    resultRandom(requestId, randomWords[0]);
  }

  function resultRandom(uint256 requestId, uint256 randomWord) private
  {
    //load contract drawn
    Raffle _raffle = raffleItems[requests[requestId]];
    
    //check balance of the contract
    uint256 balance =  _raffle.getBalance();

    //token symbol
    string memory symbol = _raffle.tokenSymbol();

    //price token
    uint price = uint(getPrice(symbol, 18));

    //multiplies the balance by the token price
    uint256 total = balance.mul(price).div(1e18);

    //add to volume
    volume = volume.add(total);

    //delete array address 
    delete raffleItems[requests[requestId]];
    
    //add raffle total
    raffleTotal++;

    //delete actives
    eventCount--;

    //emit event
    emit EventRandomResult(address(_raffle), _raffle.id(), randomWord, block.timestamp);

    //updates the random number in the raffle contract
    _raffle.setResult(randomWord);

  }
  
  /// @notice add log
  /// @dev receives the parameters of the raffle contract
  /// @param eventName string
  function addEventLog(string memory eventName) external 
  {
    //sender is the raffle contract
    Raffle _raffle = raffleItems[msg.sender];

    //checks if the operator of the raffle contract is the Contract Manager
    require(_raffle.getOperador() == _owner, "access denied");  

    //emit 
    emit EventLog(msg.sender, _raffle.id(), eventName, block.timestamp);
  }
  /// @dev checks if the contract is activated in the Manager
  /// @param raffle address
  /// @return address contract
  function getRaffleAddress(address raffle) external view returns (address)
  {
    return address(raffleItems[raffle]);
  } 
  /// @dev verify the contract owner
  /// @return owner's wallet address
  function getOwner() external view returns (address)
  {
    return _owner;
  } 
  
}