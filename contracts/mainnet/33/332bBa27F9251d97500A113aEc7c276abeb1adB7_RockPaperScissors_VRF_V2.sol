/**
 *Submitted for verification at polygonscan.com on 2023-02-02
*/

// File: @chainlink/contracts/src/v0.8/interfaces/VRFV2WrapperInterface.sol


pragma solidity ^0.8.0;

interface VRFV2WrapperInterface {
  /**
   * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
   * be relied option within the same transaction that the request was made.
   */
  function lastRequestId() external view returns (uint256);

  /**
   * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   */
  function calculateRequestPrice(uint32 _callbackGasLimit) external view returns (uint256);

  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei) external view returns (uint256);
}

// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol


pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// File: @chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol


pragma solidity ^0.8.0;



/** *******************************************************************************
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2 requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2 subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2WrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomness' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2WrapperConsumerBase {
  LinkTokenInterface internal immutable LINK;
  VRFV2WrapperInterface internal immutable VRF_V2_WRAPPER;

  /**
   * @param _link is the address of LinkToken
   * @param _vrfV2Wrapper is the address of the VRFV2Wrapper contract
   */
  constructor(address _link, address _vrfV2Wrapper) {
    LINK = LinkTokenInterface(_link);
    VRF_V2_WRAPPER = VRFV2WrapperInterface(_vrfV2Wrapper);
  }

  /**
   * @dev Requests randomness from the VRF V2 wrapper.
   *
   * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
   *        fulfillRandomWords function.
   * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
   *        request. A higher number of confirmations increases security by reducing the likelihood
   *        that a chain re-org changes a published randomness outcome.
   * @param _numWords is the number of random words to request.
   *
   * @return requestId is the VRF V2 request ID of the newly created randomness request.
   */
  function requestRandomness(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) internal returns (uint256 requestId) {
    LINK.transferAndCall(
      address(VRF_V2_WRAPPER),
      VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit),
      abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
    );
    return VRF_V2_WRAPPER.lastRequestId();
  }

  /**
   * @notice fulfillRandomWords handles the VRF V2 wrapper response. The consuming contract must
   * @notice implement it.
   *
   * @param _requestId is the VRF V2 request ID.
   * @param _randomWords is the randomness result.
   */
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
    require(msg.sender == address(VRF_V2_WRAPPER), "only VRF V2 wrapper can fulfill");
    fulfillRandomWords(_requestId, _randomWords);
  }
}

// File: docs.chain.link/samples/VRF/rps_vrf_v2.sol


pragma solidity 0.8.8;



contract RockPaperScissors_VRF_V2 is VRFV2WrapperConsumerBase {

    enum RPS {ROCK, PAPER, SCISSORS}
    enum ResultGame { DRAW, WIN, LOSE }
    ResultGame result_game;
    address public owner;
    uint256 public stake;


    event Game(
        address indexed players_address,
        uint256 indexed players_choice,
        uint256 indexed contract_choice,
        ResultGame result
    );

    event RPSRequest(uint256 requestId);
    event RPSResult(uint256 requestId, ResultGame didWin);

    struct RPSStatus {
        uint256 fees;
        uint256 randomWord;
        address player;
        ResultGame didWin;
        bool fulfilled;
        RPS choice;
    }

    mapping(uint256 => RPSStatus) public statuses;
    
    // mumbai
    //address constant linkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    //address constant vrfWrapperAddress = 0x99aFAf084eBA697E584501b8Ed2c0B37Dd136693;

    // matic
    address constant linkAddress = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;
    address constant vrfWrapperAddress = 0xAE975071Be8F8eE67addBC1A82488F1C24858067;

    uint32 constant callbackGasLimit = 400000;
    uint32 constant numWords = 1;
    uint16 constant requestConfirmations = 3;

    constructor() 
        payable
        VRFV2WrapperConsumerBase(linkAddress, vrfWrapperAddress)
    { 
        owner = msg.sender;
        // 0,5 ether
        stake = 500000000000000000;
    }

    function play(RPS _number) public payable returns (uint256){
        require(
            uint(RPS.SCISSORS) >= uint(_number), 
            "This symbol is not valide for Rock Paper Scissors !" 
        );
        // only the correct stake per game
        require(
            msg.value == stake,
            "Your stake for the game is not correct !"
        );
        // 
        require(
            getBalance() >= 2*msg.value,
            "No sufficient Deposit on contract !"
        );

        uint256 requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );

        statuses[requestId] = RPSStatus({
            fees: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWord: 0,
            player: msg.sender,
            didWin: ResultGame.DRAW,
            fulfilled: false,
            choice: _number
        });

        emit RPSRequest(requestId);
        return requestId;
    }

  
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        
        require(statuses[requestId].fees > 0, "Request not found");

        statuses[requestId].fulfilled = true;
        //statuses[requestId].randomWord = randomWords[0];

        uint ran_num = randomWords[0] % 3;
        statuses[requestId].randomWord = ran_num;
        RPS _number = statuses[requestId].choice;

        //Same Symbol, no Winner, Try it again
        if (uint(_number) == ran_num){
            //revert('Same Symbol, no Winner, Try it again!');
            result_game = ResultGame.DRAW;
        }
        
        if(_number == RPS.SCISSORS && ran_num == uint(RPS.PAPER)){
            //success = true;
            result_game = ResultGame.WIN;
        }
        if(_number == RPS.SCISSORS && ran_num == uint(RPS.ROCK)){
            //success = false;
            result_game = ResultGame.LOSE;
        }
        if(_number == RPS.ROCK && ran_num == uint(RPS.SCISSORS)){
            //success = true;
            result_game = ResultGame.WIN;
        }
        if(_number == RPS.ROCK && ran_num == uint(RPS.PAPER)){
            //success = false;
            result_game = ResultGame.LOSE;
        }
        if(_number == RPS.PAPER && ran_num == uint(RPS.ROCK)){
            //success = true;
            result_game = ResultGame.WIN;
        }
        if(_number == RPS.PAPER && ran_num == uint(RPS.SCISSORS)){
            //success = false;
            result_game = ResultGame.LOSE;
        }

        // money for the player?
        // WIN
        if (result_game == ResultGame.WIN){
            //address payable receiver = payable(msg.sender);
            //receiver.call{value: 2*stake}("");
            statuses[requestId].didWin = result_game;
            payable(statuses[requestId].player).transfer(stake * 2);
        }
        // DRAW
        if (result_game == ResultGame.DRAW){
            //address payable receiver = payable(msg.sender);
            //receiver.call{value: stake}("");
            statuses[requestId].didWin = result_game;
            payable(statuses[requestId].player).transfer(stake);
        }
       
        //statuses[requestId].didWin = result_game;

        emit Game(msg.sender, uint(_number), ran_num, result_game);
        emit RPSResult(requestId, statuses[requestId].didWin);
    }

    function getBalance() public view returns(uint256 balance){
        return address(this).balance; 
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        //msg.sender.transfer(address(this).balance);
        address payable withdrawer = payable(msg.sender);
            //receiver.transfer(10);
        withdrawer.call{value: address(this).balance}("");
    }

    function setStake(uint256 amount_stake) public onlyOwner {
        stake = amount_stake;
    }

    function fund() public payable {

    }

    function getStatus(uint256 requestId)
        public
        view
        returns (RPSStatus memory)
    {
        return statuses[requestId];
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }


}