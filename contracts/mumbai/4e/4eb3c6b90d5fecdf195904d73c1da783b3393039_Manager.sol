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
  uint64 private s_subscriptionId;

  // Goerli coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  address private vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 private keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 2500000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 private callbackGasLimit = 2500000;

  // The default is 3, but you can set this higher.
  uint16 private requestConfirmations = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 private numWords =  1;

  uint256[] public s_randomWords;
  uint256 public s_requestId;
  address private s_owner;

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

  //array created contracts raffle
  Raffle[] private _raffles;

  //Mapping token prices
  mapping(string => address) private _aggregator;

  //Mapping contract address with manufactured contract
  mapping(address => Raffle) private raffleItems;

  //Mapping request for the drawn number linked to the Raffle's address
  mapping(uint256 => address) private requests;

  address private NULL_ADDRESS = 0x0000000000000000000000000000000000000000;
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
  * @dev build the contract that is raffle factory with VRFConsumer that draws the numbers
  */
  constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) 
  {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;

     /*Mumbai*/
    _aggregator["ETH"] = 	0x0715A7794a1dc8e42615F059dD6e406A6594651A;
    _aggregator["MATIC"]  = 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada;
    
    //mainnet
    //_aggregator["ETH"] = 	0xF9680D99D6C9589e2a93a78A04A279e509205945;
    //_aggregator["MATIC"]  = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
  }

  function fulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
  ) internal override {

    //array of number drawn only one
    s_randomWords = randomWords;

   // resultRandom(requestId, randomWords[0]);
  }
}