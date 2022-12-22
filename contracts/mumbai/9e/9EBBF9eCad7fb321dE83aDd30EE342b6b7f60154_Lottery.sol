// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/VRFV2WrapperInterface.sol";

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

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.3;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";

//Now this is the smart contract for the lottery game
contract Lottery is
    VRFV2WrapperConsumerBase,
    ConfirmedOwner{

    //This is the address of the LINK tokens on the  mumbai testnet
    address internal linkAddress=0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    //This is the address of the wrapper contract that is the ConsumerBase smart contract
    address internal wrapperAddress=0x99aFAf084eBA697E584501b8Ed2c0B37Dd136693;

     // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFV2Wrapper.getConfig().maxNumWords.
    uint32 numWords = 2;

    //This is the array that stores the randomwords
    uint randomwords;

    constructor()
        ConfirmedOwner(msg.sender)
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
    {}

    //This is the game id for a particular game
    uint public gameId=0;

    //This is a variable which indicates whether a game has already been started or not
    bool private gamestarted;

    //This is the event that is emitted whenever the game has been started
    event GameStarted(address indexed starter,Game game);

    //This is the event that is emitted whenever the player joins the lottery game
    event PlayerJoined(uint256 gameId, address player);

    //These are the player IDS
    //Each player id is mapped to its account adddress
    uint private playerIds=0;
    mapping(uint=>address) public assignids;
    uint private playersentered=0;

    struct Game{
        //Now each game has the following parameters
        uint gameid;
        string name;
        uint maxplayers;
        uint entryfee;
    }

    //This is also a mapping indicating which game id is assigned to the which game
    mapping(uint=>Game) public gameassigned;

    //This is the function that starts the game
    function start(string memory _name,uint _maxplayers,uint _entryfee) onlyOwner external returns(bool)
    {
        //We first need to check whether the game has started or not
        require(gamestarted!=true,"An exisiting lottery game is running!");

        //Now we create an instance of the game 
        Game memory game;
        game.name=_name;
        game.maxplayers=_maxplayers;
        game.entryfee=_entryfee;
        game.gameid=gameId;

        gameId+=1;

        //Now in the mapping gameassigned
        gameassigned[gameId]=game;

        //Now that the instance of the game has been created we emit an event that the game has been started
        emit GameStarted(msg.sender,game);

        //Now that the game has been started we can make the gamestarted state variable as true
        gamestarted=true;

        return true;
    }

    //This is the function where each player can join a particular game
    //The player can join the game that is currently running on using the game ID.
    function join() external payable
    {
        //Now before joining a game we need to ensure that a game has started
        require(gamestarted,"No lottery game is currently running!");

        //Also we need to check whether the player can still join the game or not
        require(gameassigned[gameId].maxplayers>playersentered,"Sorry the game is already full!");

        //Now for a player to join the lottery game he/she must pay atleast the amount of the entry fee
        //The entry fee is set by the creator of the game
        uint playersent=msg.value;

        if(playersent!=gameassigned[gameId].entryfee)
        {
            //This means that the player has'nt sent the appropriate entry fee
            revert("Please send the appropriate entry fee");
        }

        //Now that the player has entered the game
        playerIds++;
        assignids[playerIds]=msg.sender;
        playersentered++;

        emit PlayerJoined(gameId,msg.sender);

        //In case the max number of players have been allocated then 
        if(playersentered==gameassigned[gameId].maxplayers)
        {
            //Then call the random words function
            requestRandomWords();

        }
    }

    function requestRandomWords()
        private
        returns (uint256 requestId)
    {
        requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );
        // s_requests[requestId] = RequestStatus({
        //     paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
        //     randomWords: new uint256[](0),
        //     fulfilled: false
        // });
        // requestIds.push(requestId);
        // lastRequestId = requestId;
        // emit RequestSent(requestId, numWords);
        return requestId;
    }


    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        // require(s_requests[_requestId].paid > 0, "request not found");
        // s_requests[_requestId].fulfilled = true;
        // s_requests[_requestId].randomWords = _randomWords;
        // emit RequestFulfilled(
        //     _requestId,
        //     _randomWords,
        //     s_requests[_requestId].paid
        // );

        randomwords=(_randomWords[0] % playersentered)+1;
        //Now that we have the random words the next step is to select one player as the winner
        address winner = assignids[randomwords];

        // send the ether in the contract to the winner
        (bool sent,) = winner.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");

        // set the gameStarted variable to false
        gamestarted = false;

        //Now we again set the default values of the variables
        playersentered=0;
        playerIds=0;
        

    }

    function getrandomwords() public view returns(uint)
    {
        return randomwords;
    }


 
}