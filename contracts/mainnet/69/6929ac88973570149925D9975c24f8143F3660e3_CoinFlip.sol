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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";

contract CoinFlip is VRFV2WrapperConsumerBase {
    
    event CoinFlipRequest(uint256 requestId);
    event CoinFlipResult(uint256 requestId, bool didWin);

    struct CoinFlipStatus {
        uint256 fees;
        uint256 randomWord;
        uint256 randomNumber;
        uint256 requestId;
        bytes32 hashed;
        address player;
        bool didWin;
        bool fulfilled;
        CoinFlipSelection choice;
    }

    mapping(address => CoinFlipStatus[]) public userGameStatuses;

    enum CoinFlipSelection {
        HEADS,
        TAILS,
        SIDE
    }

    mapping(uint256 => CoinFlipStatus) public statuses;

    address constant linkAddress = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;
    address constant vrfWrapperAddress = 0x4e42f0adEB69203ef7AaA4B7c414e5b1331c14dc;
    
    uint256 public gameCounter = 0;

    uint128 constant entryFees = 0.001 ether;
    uint32 constant callbackGasLimit = 1_000_000;
    uint32 constant numWords = 1;
    uint16 constant requestConfirmations = 3;
    address public owner;

    constructor() payable VRFV2WrapperConsumerBase(linkAddress, vrfWrapperAddress) {
        owner = msg.sender;
    }

    function flip(CoinFlipSelection choice) 
        external 
        payable
        returns (uint256, bytes32)
    {
        require(msg.value == entryFees, "Entry fees not sent.");
        require((choice == CoinFlipSelection.HEADS || choice == CoinFlipSelection.TAILS), "Invalid choice option.");

        uint256 requestId = requestRandomness(
            callbackGasLimit, 
            requestConfirmations, 
            numWords
        );

        statuses[gameCounter] = CoinFlipStatus({
            fees: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWord: 0,
            randomNumber: 0,
            player: msg.sender,
            didWin: false,
            requestId: 0,
            hashed: keccak256(abi.encodePacked(gameCounter, "-", requestId)),
            fulfilled: false,
            choice: choice
        });
        
        emit CoinFlipRequest(requestId);

        return (gameCounter, statuses[gameCounter].hashed);
    }
    
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override
    {
        require(statuses[gameCounter].fees > 0, "Requested not found");

        statuses[gameCounter].fulfilled = true;
        statuses[gameCounter].requestId = requestId;
        statuses[gameCounter].randomWord = randomWords[0];
        statuses[gameCounter].randomNumber = (randomWords[0] % 1000);

        CoinFlipSelection result = CoinFlipSelection.SIDE;
        
        if (statuses[gameCounter].randomNumber < 475) {
            result = CoinFlipSelection.HEADS;
        } else if (statuses[gameCounter].randomNumber < 950) {
            result = CoinFlipSelection.TAILS;
        }
        
        if(statuses[gameCounter].choice == result){
            statuses[gameCounter].didWin = true;
            payable(statuses[gameCounter].player).transfer(entryFees * 2);
        }

        userGameStatuses[statuses[gameCounter].player].push(statuses[gameCounter]);

        emit CoinFlipResult(gameCounter, statuses[gameCounter].didWin);
    }

    function getStatus(uint256 gameCounterFind)
        public
        view
        returns (CoinFlipStatus memory)
    {
        return statuses[gameCounterFind];
    }

    function getUserGameStatuses(address user) external view returns (CoinFlipStatus[] memory) {
        return userGameStatuses[user];
    }

    function withdrawFunds(uint256 amount) external {
        require(msg.sender == owner, "Only CoinFlip owner can withdraw funds.");

        require(address(this).balance >= amount, "Insufficient CoinFlip balance.");

        uint256 communityShare = amount * 20 / 100;
        uint256 daoShare = amount * 10 / 100;
        uint256 houseShare = amount * 70 / 100;

        payable(address(0x4FFB9413fb851B3e6E5F9f442bEb902d7619E371)).transfer(communityShare);
        payable(address(0xe4AfC24B8dba77C4dFBCc9FAB236d0C4701D06fc)).transfer(daoShare);
        payable(address(0x7F19EE3C23F25b4794A25ed25c5418Fb52ff8786)).transfer(houseShare);
    }
}