pragma solidity >=0.7.6 <0.8.6;
// SPDX-License-Identifier: MIT
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

interface AggregatorV3Interface 
{
  function decimals() external view returns (uint8);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

 /// @dev factory contract and random numbers to create raffle contracts
contract Manager is VRFConsumerBaseV2 {
 
  using SafeMath for uint256;
  
  // Your subscription ID.
  VRFCoordinatorV2Interface COORDINATOR;

  // Polygon coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 callbackGasLimit = 100000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 numWords =  1;
  
  //array receive the return of the number drawn
  uint256[] public s_randomWords;

  //id generated from the random number request
  uint256 public s_requestId;

  //VRF Chainlink subscription id
  uint64 public s_subscriptionId;
  
  //id generated from the manufacture of the Rifa contract
  uint public raffleId = 0; 

  //total active raffles
  uint public eventCount = 0; 

  //total raffle created
  uint public raffleTotal = 0; 

  //volume 
  uint256 public volume = 0;

  //array created contracts raffle
  Raffle[] _raffles;

  //Mapping token prices
  mapping(string => address) _aggregator;

  //Mapping contract address with manufactured contract
  mapping(address => Raffle) raffleItems;

  //Mapping request for the drawn number linked to the Raffle's address
  mapping(uint256 => address) requests;

  address s_owner;
  address NULL_ADDRESS = 0x0000000000000000000000000000000000000000;
  /**
  * @dev Emitted contractAddress address raffle contract
  * @dev Emitted id raffle contract
  * @dev Emitted eventName raffle contract
  * @dev Emitted timestamp date now
  */

  event EventLog(address indexed contractAddress, uint id, string eventName, uint timestamp);   

  /**
  * @dev build the contract that is raffle factory with VRFConsumer that draws the numbers
  */
  constructor() VRFConsumerBaseV2() 
  {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    _aggregator["ETH"] = 	0x0715A7794a1dc8e42615F059dD6e406A6594651A;
    _aggregator["MATIC"]  = 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada;

    //Criar uma Subscription na VRF Chainlink e adiciona como consumer
    createNewSubscription();
  }
   
    /// @notice creation init raffle contract 
    /// @param _raffleName title 
    /// @param _quant quant 
    /// @param _startTime start date
    /// @param _finishTime finish date
    /// @param _price price number
    /// @param _token address token
     
  function createRaffle( 
        string memory _raffleName, 
        uint _quant, 
        uint _startTime, 
        uint _finishTime, 
        uint256 _price, 
        address _token) public onlyOwner
  {
        //generate the raffle id
        raffleId++;

        //create the raffle contract with id and index
        Raffle _value = new Raffle(address(this));

        //add to array
        _raffles.push(_value);
        
        //links the contract address with the contract
        raffleItems[address(_value)] = _value;

        //start the raffle
        _value.init(raffleId, eventCount, _raffleName, _quant, _startTime, _finishTime, _price, _token);
        
        //new index
        eventCount++;
  }
  
    function scalePrice(int256 _price, uint8 _priceDecimals, uint8 _decimals)
        internal
        pure
        returns (int256)
    {
        if (_priceDecimals < _decimals) {
            return _price * int256(10 ** uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10 ** uint256(_priceDecimals - _decimals));
        }
        return _price;
    }
    

  function getPrice(string memory symbol, uint8 _decimals) public view returns (uint) 
  {
       int p = 0;
       if(_aggregator[symbol]==NULL_ADDRESS)
       {
          p = 1e18;
       }
       else
       {
        
        ( , int256 basePrice, , , ) = AggregatorV3Interface(_aggregator[symbol]).latestRoundData();
        
        uint8 baseDecimals = AggregatorV3Interface(_aggregator[symbol]).decimals();
        p = scalePrice(basePrice, baseDecimals, _decimals);

       }
       return uint(p);
   }
   /// @notice close the contract
   /// @dev closes the raffle contract that has no purchased numbers
   /// @param raffle address raffle

   function setClose(address raffle) public onlyOwner
   {
      //closes the contract in the raffle
      raffleItems[raffle].setClose();
      
      //delete contract from array
      delete _raffles[raffleItems[raffle].index()];

      //delete contract from array
      delete raffleItems[raffle];

      //updates active raffles
      eventCount--;
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
            //random
            uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
            );

            //adds the request id to the drawn raffle contract
            requests[requestId] = raffle;

            uint256[] memory randomWords = new uint256[](1);
            randomWords[0] = requestId;

            fulfillRandomWords(requestId, randomWords);
            
        }
  }
 
   /// @dev receive number drawn after executing the requestRandomWords function
   /// @param requestId requested number drawn
   /// @param randomWords array number drawn
  function fulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
  ) internal override {

    //array of number drawn only one
    s_randomWords = randomWords;
    
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

    //updates the random number in the raffle contract
    _raffle.setResult(randomWords[0]);
    
    //delete array contract
    delete _raffles[raffleItems[requests[requestId]].index()];

    //delete array address 
    delete raffleItems[requests[requestId]];
    
    //add raffle total
    raffleTotal++;

    //delete actives
    eventCount--;
  }

  // Create a new subscription when the contract is initially deployed.
  function createNewSubscription() private onlyOwner {
    s_subscriptionId = COORDINATOR.createSubscription();
    // Add this contract as a consumer of its own subscription.
    COORDINATOR.addConsumer(s_subscriptionId, address(this));
  }
  /// @notice add log
  /// @dev receives the parameters of the raffle contract
  /// @param eventName string
  function addEventLog(string memory eventName) public 
  {
    //sender is the raffle contract
    Raffle _raffle = raffleItems[msg.sender];

    //checks if the operator of the raffle contract is the Contract Manager
    require(_raffle.getOperador() == s_owner, "access denied");  

    //emit 
    emit EventLog(msg.sender, _raffle.id(), eventName, block.timestamp);
  }
  
  /// @dev checks if the contract is activated in the Manager
  /// @param raffle address
  /// @return address contract
  function getRaffleAddress(address raffle) public view returns (address)
  {
    return address(raffleItems[raffle]);
  } 
  /// @dev verify the contract owner
  /// @return owner's wallet address
  function getOwner() public view returns (address)
  {
    return s_owner;
  } 
  
  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }
}