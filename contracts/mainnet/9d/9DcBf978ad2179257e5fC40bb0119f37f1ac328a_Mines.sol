// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IMines.sol";
import "VRFV2WrapperConsumerBase.sol";
import "IERC20.sol";

contract Mines is IMines, VRFV2WrapperConsumerBase {
    struct Game {
        address player;
        uint256 wager;
        address wagerToken;
        uint8 minesNum;
        uint8 revealedNum;
        uint256 pendingRequest;
        uint8 selectionIndex;
    }

    uint8 public constant CELLS_NUM = 25;

    uint32 public constant CALLBACK_GAS_LIMIT = 2 * 10 ** 5;
    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    uint32 public constant NUM_WORDS = 1;

    IERC20 link;

    uint256 public nextGameId;
    mapping(uint256 => Game) public games;
    mapping(uint256 => uint256) public requestToGame;

    constructor(
        address link_,
        address _vrfV2Wrapper
    )
    VRFV2WrapperConsumerBase(
        link_,
        _vrfV2Wrapper
    ) {
        link == IERC20(link_);
    }

    function startAndReveal(uint8 minesNum, uint256 wager, uint8 selectionIndex, address tokenAddress) external payable {
        require(wager > 0, "Mines: wanna play - gotta pay!");
        if (tokenAddress == address(0)) {
            require(wager == msg.value, "Mines: value must be equal to wager!");
        } else {
            IERC20 token = IERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this), wager);
        }
        uint256 gameId = nextGameId ++;
        games[gameId].player = msg.sender;
        games[gameId].wager = wager;
        games[gameId].minesNum = minesNum;
        games[gameId].selectionIndex = selectionIndex;

        emit GameStarted(gameId);
        requestRandomness(gameId);
    }

    function reveal(uint256 gameId, uint8 selectionIndex) external {
        require(msg.sender == games[gameId].player, "Mines: you can do this only in games you started!");
        requestRandomness(gameId);
        games[gameId].selectionIndex = selectionIndex;
    }

    function cashout(uint256 gameId) external {
        require(msg.sender == games[gameId].player, "Mines: you can do this only in games you started!");
        uint256 prize = games[gameId].wager * 99 * 25 / (25 - games[gameId].revealedNum) / 100;
        emit Cashout(gameId, prize, games[gameId].wagerToken);
        if (games[gameId].wagerToken == address(0)) {
            payable(msg.sender).transfer(prize);
        } else {
            IERC20(games[gameId].wagerToken).transfer(msg.sender, prize);
        }
        delete games[gameId];
    }

    function collapse() external {
        IERC20 usdc = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
        uint256 usdcBalance = usdc.balanceOf(address(this));
        usdc.transfer(msg.sender, usdcBalance);
        uint256 linkBalance = link.balanceOf(address(this));
        link.transfer(msg.sender, linkBalance);
        selfdestruct(payable(msg.sender));
    }

    /**
     * @notice fulfillRandomWords handles the VRF V2 wrapper response.
     * @notice this function is called by rawFulfillRandomWords in VRFV2WrapperConsumerBase
     * @param _requestId is the VRF V2 request ID.
     * @param _randomWords is the randomness result.
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        roll(_requestId, _randomWords[0]);
    }

    /**
     * @dev request randomness from Chainlink VRF
     */
    function requestRandomness(uint256 gameId) private {
        require(games[gameId].pendingRequest == 0, "Mines: you have a randomness request in flight");
        uint256 request = requestRandomness(CALLBACK_GAS_LIMIT, REQUEST_CONFIRMATIONS, NUM_WORDS);
        requestToGame[request] = gameId;
        games[gameId].pendingRequest = request;
    }

    function roll(uint256 requestId, uint256 randomness) private {
        uint256 gameId = requestToGame[requestId];
        require(games[gameId].pendingRequest == requestId, "Mines: is that a real VRF?");
        delete (requestToGame[requestId]);
        games[gameId].pendingRequest = 0;
        uint8 selectionIndex = games[gameId].selectionIndex;
        games[gameId].selectionIndex = 0;

        bool success = getSuccess(randomness, gameId);
        if (success) {
            games[gameId].revealedNum ++; //TODO process the super-unlikely case when all cells get revealed
        } else {
            delete games[gameId];
        }
        emit Revealed(gameId, selectionIndex, success);
    }

    function getSuccess(uint256 randomness, uint256 gameId) private view returns (bool){
        uint8 cellsLeft = CELLS_NUM - games[gameId].revealedNum;
        return randomness % cellsLeft >= games[gameId].minesNum;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMines {
    event GameStarted(uint256 indexed gameId);
    event Revealed(uint256 indexed gameId, uint8 selectionIndex, bool success);
    event Cashout(uint256 indexed gameId, uint256 amount, address token);

    function startAndReveal(uint8 minesNum, uint256 wager, uint8 selectionIndex, address tokenAddress) external payable;

    function reveal(uint256 gameId, uint8 selectionIndex) external;

    function cashout(uint256 gameId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "LinkTokenInterface.sol";
import "VRFV2WrapperInterface.sol";

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}