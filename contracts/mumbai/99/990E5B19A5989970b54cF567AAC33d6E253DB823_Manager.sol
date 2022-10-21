// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
/*

┬  ┬ ┬┌─┐┬┌─┬ ┬┌┐┌┬ ┬┌┬┐┌┐ ┌─┐┬─┐ ┌─┐┌─┐
│  │ ││  ├┴┐└┬┘││││ ││││├┴┐├┤ ├┬┘ │ ┬│ ┬
┴─┘└─┘└─┘┴ ┴ ┴ ┘└┘└─┘┴ ┴└─┘└─┘┴└─o└─┘└─┘
                                                                                                                
website: https://luckynumber.gg                                                                                                      
discord: https://discord.gg/bPjSKmJXAq
twitter: https://twitter.com/luckynumbergg

* @author Cesar Maia developer senior solidity, smart contracts, react, c#, 
* nosql, msssql, node.js
* telegram: https://t.me/cesarmaia_dev
*****************************************************************************
* @notice using Manager Factory
******************************************************************************
* @dev PURPOSE
*
* @dev Luckynumber is the betting game of one player against another.
*
* @dev How it works:
* @dev - Players approve the tokens and choose the desired numbers that are available in a raffle, 
* @dev when purchasing the number an NFT is minted and the money transferred to the raffle contract. 
* @dev The draw is made when the total number of numbers are sold or when the end date arrives. 
* @dev Only the winner can claim this prize.
*
* @dev The contract Manager.sol (VRFConsumerBase) uses a ChainLink VRF interface where a random number is provided, 
* @dev this number is extracted from a number that is drawn by the number of numbers sold. 
* @dev After receiving the number, the contract is closed.
*
* @dev The Manager.sol contract is a factory contract that creates the other Raffle contracts, 
* @dev which exist temporarily until the prize amount is withdrawn. 
* @dev Each raffle is created with the amount, token and end date.
*
* @dev The Raffle.sol contract (ERC721) is a contract created by Manager.sol 
* @dev only the MINT and CLAIM functions are used.
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
  bytes32 private _keyhash;

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
  address private _office = 0xC0ad39510aA162d0C10428b705172e331be8F498;
    
  //Value of fee tax div 20 = 5%
  uint256 private _fee = 20; //5%

  //id generated from the manufacture of the Rifa contract
  uint public raffleId = 0; 

  //total active raffles
  uint public eventCount = 0; 

  //total raffle created
  uint public raffleTotal = 0; 

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
  * @dev Emitted quant numbers purchased
  * @dev Emitted requestId chainlink
  * @dev Emitted randomWords chainlink
  * @dev Emitted result request
  * @dev Emitted timestamp date now
  */

   event EventRandomResult(address indexed raffle, uint id, uint quant, uint256 requestId, uint256 randomWord, uint256 result, uint256 timestamp); 

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
  constructor(uint64 subId, address coordinator, bytes32 keyhash) VRFConsumerBaseV2(coordinator) 
  {
    COORDINATOR = VRFCoordinatorV2Interface(coordinator);
    _owner = msg.sender;
    _subscriptionid = subId;
    _keyhash = keyhash;
  }
  
  /// @dev verify the contract owner
  /// @return owner's wallet address
  function getOwner() external view returns (address)
  {
    return _owner;
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
        Raffle _value = new Raffle();

        //links the contract address with the contract
        raffleItems[address(_value)] = _value;

        //start the raffle
        raffleItems[address(_value)].init(raffleId, eventCount, raffleName_, quant_, startTime_, finishTime_, price_, token_);
  }
     
   /// @notice close the contract
   /// @dev closes the raffle contract that has no purchased numbers
   /// @param raffle address raffle

   function setClose(address raffle) external onlyOwner
   {
      
      require(raffleItems[raffle].tokenCount() == 0, "game in progress");

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
        //adds the request id to the drawn raffle contract
        validateRandomNumber(raffle);
  }

  function validateRandomNumber(address raffle) private 
  {
        bool validate = raffleItems[raffle].validateRequest();
      
        if(validate)
        {
            uint256 requestId = COORDINATOR.requestRandomWords(
                    _keyhash,
                    _subscriptionid,
                    REQUEST_CONFIRMATIONS,
                    GAS_LIMIT,
                    NUM_WORDS
                    );

            requests[requestId] = raffle;
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

    //address contract
    address raffle = requests[requestId];
    //
    uint tokenCount = raffleItems[raffle].tokenCount();
    //
    uint result = (randomWord % tokenCount) + 1;

    //add raffle total
    raffleTotal++;

    //delete actives
    eventCount--;

     //emit event
    emit EventRandomResult(
      raffle, 
      raffleItems[raffle].id(), 
      tokenCount, 
      requestId, 
      randomWord, 
      result, 
      block.timestamp); 


    //updates the random number in the raffle contract
    raffleItems[raffle].setResult(result);

     //delete array address 
    delete raffleItems[raffle];

     
  }
  
  /// @notice add log
  /// @dev receives the parameters of the raffle contract
  /// @param eventName string
  function addEventLog(string memory eventName) external 
  {
    //checks if the operator of the raffle contract is the Contract Manager
    require(raffleItems[msg.sender].getOperador() == _owner, "access denied");  

    //checks if the operator of the raffle contract is the Contract Manager
    require(address(raffleItems[msg.sender]) != address(0), "access denied");  

    //emit 
    emit EventLog(msg.sender, raffleItems[msg.sender].id(), eventName, block.timestamp);


    if( keccak256(bytes(eventName)) == keccak256(bytes("EventRafflePurchased")))
    {
        validateRandomNumber(msg.sender);
    }
  }
  /// @dev checks if the contract is activated in the Manager
  /// @param raffle address
  /// @return address contract
  function getRaffleAddress(address raffle) external view returns (address)
  {
    return address(raffleItems[raffle]);
  }
}