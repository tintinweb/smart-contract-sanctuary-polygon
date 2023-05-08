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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";


/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 */


contract test001 is VRFV2WrapperConsumerBase {
    using SafeMath for uint256;

    uint8 public currentCritRound = 1;
    uint256 public totalusdtInPot;

    IERC20 public usdt;

    address public owner;

    uint private constant _a = 31;
    uint private constant _c = 7;
    uint private constant _m = 4093;

    struct holder {
        address holderAddress;
        uint256 mintPrice;
    }

    mapping(uint16 => holder) public holderInfo;

    mapping(uint8 => mapping(uint8 => uint16[])) public roundPlayers; //round-drawid-playertokenidlist

    mapping(uint8 => mapping(uint8 => uint16[])) public roundWinners; //round-drawid-winnertokenidlist

    mapping(uint8 => mapping(uint16 => uint256)) public roundPrizesMultiplier; //round-tokenid-multiplier

    event PrizeDraw(
        uint8 indexed critRound,
        uint8 indexed prizeCategory,
        uint16 indexed tokenId,
        uint256 multiplierPercentage
    );

    event PrizeTransferred(
        uint8 indexed critRound,
        uint16 indexed tokenId,
        address indexed winner,     
        uint256 prizeAmount
    );


    uint16[] public LBPWinners; //last big prize: winnertokenidlist

    mapping(uint16 => uint256) public LBPTokenIdsToPrizes; // last big prize: tokenId --->prize

    event LBPPrizeDraw(
        uint16 indexed tokenId,
        uint256 prizeAmount
    );

    event LBPPrizeTransferred(
        address indexed winner,     
        uint256 prizeAmount
    );

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords,
        uint256 payment
    );

    struct RequestStatus {
        uint256 paid; // amount paid in link
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
    public s_requests; /* requestId --> requestStatus */

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    uint32 callbackGasLimit = 300000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFV2Wrapper.getConfig().maxNumWords.
    uint32 numWords = 1;

    // // Address LINK - hardcoded for polygon
    // address linkAddress = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;

    // // address WRAPPER - hardcoded for polygon
    // address wrapperAddress = 0x4e42f0adEB69203ef7AaA4B7c414e5b1331c14dc;

    // Address LINK - hardcoded for MUMBAI
    address linkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;

    // address WRAPPER - hardcoded for MUMBAI
    address wrapperAddress = 0x99aFAf084eBA697E584501b8Ed2c0B37Dd136693;

    uint256 public seed;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor()
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
    {
        usdt = IERC20(0xE097d6B3100777DC31B34dC2c58fB524C2e76921); //mumbai usdc
        // usdt = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
        owner = msg.sender;
    }

    function requestRandomWords() external onlyOwner returns (uint256 requestId)
    {
        // require(!weightsGenerated, "Weights have already been generated");

        requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWords: new uint256[](0),
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].paid > 0, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        seed = _randomWords[0]%1000;

        emit RequestFulfilled(
            _requestId,
            _randomWords,
            s_requests[_requestId].paid
        );
    }

    function getRequestStatus(
        uint256 _requestId
    )
        external
        view
        returns (uint256 paid, bool fulfilled, uint256[] memory randomWords)
    {
        require(s_requests[_requestId].paid > 0, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.paid, request.fulfilled, request.randomWords);
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


    function setHIM(uint16[] memory tokenIds, address[] memory holderAddress, uint256[] memory mintPrices) external onlyOwner {
        require(tokenIds.length == holderAddress.length, "Invalid inputs");
        require(tokenIds.length == mintPrices.length, "Invalid inputs");
     
        for (uint16 i = 0; i < tokenIds.length; i++) {
            holderInfo[tokenIds[i]] = holder(holderAddress[i], mintPrices[i]);
        }
    }

    function sCCR(uint8 _currentCritRound) public onlyOwner{
        currentCritRound=_currentCritRound;
    }

    function dP(uint8 drawId, uint16[] memory tokenIds) external onlyOwner {

        roundPlayers[currentCritRound][drawId] = tokenIds;

        uint256 TPWinnersNum = tokenIds.length.mul(22).div(100); 
        uint256 TPBoundary = TPWinnersNum.mul(3).div(4);

        uint256 MPWinnersNum = tokenIds.length.mul(6).div(100); 
        uint256 MPBoundary = MPWinnersNum.mul(6).div(7);

        uint256 DPWinnersNum = tokenIds.length.mul(3).div(100); 

        uint256 WPWinnersNum = tokenIds.length.mul(1).div(100); 
        uint256 WPBoundary = WPWinnersNum.mul(11).div(12);
        
        uint16 tokenId;
        uint256 multiplierPercentage;


        for (uint256 i = 0; i < TPWinnersNum; i++) {
            if (i < TPBoundary) {
                (tokenId, multiplierPercentage) = getRandomNum(15, 20, drawId);
            } else {
                (tokenId, multiplierPercentage) = getRandomNum(20, 35, drawId);
            }
            roundWinners[currentCritRound][drawId].push(tokenId);
            roundPrizesMultiplier[currentCritRound][tokenId] = multiplierPercentage;

            emit PrizeDraw(currentCritRound, 1, tokenId, multiplierPercentage);
        }


        for (uint256 j = 0; j < MPWinnersNum; j++) {
            if (j < MPBoundary) {
                (tokenId, multiplierPercentage) = getRandomNum(45, 50, drawId);
            } else {
                (tokenId, multiplierPercentage) = getRandomNum(50, 80, drawId);
            }
            roundWinners[currentCritRound][drawId].push(tokenId);
            roundPrizesMultiplier[currentCritRound][tokenId] = multiplierPercentage;

            emit PrizeDraw(currentCritRound, 2, tokenId, multiplierPercentage);
        }


        for (uint256 k = 0; k < DPWinnersNum; k++) {

            tokenId = getRandomTokenID(drawId);
            roundWinners[currentCritRound][drawId].push(tokenId);

            roundPrizesMultiplier[currentCritRound][tokenId] = 100;

            emit PrizeDraw(currentCritRound, 3, tokenId, 100);
        }

        for (uint256 m = 0; m < WPWinnersNum; m++) {
            if (m < WPBoundary) {
                (tokenId, multiplierPercentage) = getRandomNum(200, 250, drawId);
            } else {
                (tokenId, multiplierPercentage) = getRandomNum(250, 800, drawId);
            }
            roundWinners[currentCritRound][drawId].push(tokenId);
            roundPrizesMultiplier[currentCritRound][tokenId] = multiplierPercentage;

            emit PrizeDraw(currentCritRound, 4, tokenId, multiplierPercentage);
        }

    }




    function dLP(uint8 drawId, uint16[] memory tokenIds) external onlyOwner {

        roundPlayers[currentCritRound][drawId] = tokenIds;

        uint256 DPWinnersNum = tokenIds.length.mul(3).div(100); 

        uint256 WPWinnersNum = tokenIds.length.mul(1).div(100); 
        uint256 WPBoundary = WPWinnersNum.mul(11).div(12);
        
        uint16 tokenId;
        uint256 multiplierPercentage;

        for (uint256 k = 0; k < DPWinnersNum; k++) {

            tokenId = getRandomTokenID(drawId);
            roundWinners[currentCritRound][drawId].push(tokenId);

            roundPrizesMultiplier[currentCritRound][tokenId] = 100;

            emit PrizeDraw(currentCritRound, 3, tokenId, 100);
        }

        for (uint256 m = 0; m < WPWinnersNum; m++) {
            if (m < WPBoundary) {
                (tokenId, multiplierPercentage) = getRandomNum(200, 250, drawId);
            } else {
                (tokenId, multiplierPercentage) = getRandomNum(250, 800, drawId);
            }
            roundWinners[currentCritRound][drawId].push(tokenId);
            roundPrizesMultiplier[currentCritRound][tokenId] = multiplierPercentage;

            emit PrizeDraw(currentCritRound, 4, tokenId, multiplierPercentage);
        }

    }

    function tP(uint8 _drawId) external onlyOwner {
        uint16 tokenId;
        address winner;
        uint256 mintPrice;
        uint256 multiplierPercentage;
        uint256 prizeAmount;

        uint256 roundWinnersLength = roundWinners[currentCritRound][_drawId].length;

        for (uint256 i = 0; i < roundWinnersLength; i++) {

            tokenId = roundWinners[currentCritRound][_drawId][i];
            winner = holderInfo[tokenId].holderAddress;

            mintPrice = holderInfo[tokenId].mintPrice;
            multiplierPercentage = roundPrizesMultiplier[currentCritRound][tokenId];
            prizeAmount = mintPrice.mul(multiplierPercentage).div(100);

            usdt.transfer(winner, prizeAmount);
            roundPrizesMultiplier[currentCritRound][tokenId] = 0;

            emit PrizeTransferred(currentCritRound, tokenId, winner, prizeAmount);
            
            totalusdtInPot = totalusdtInPot.sub(prizeAmount);
        }

    }



    function dLBP(uint8 drawIdLength) external onlyOwner {
        uint256 remainingPrizeCount = 5;
        uint256 remainingPrizeAmount = totalusdtInPot;
        uint8 randomDrawID;
        uint16 tokenId;
        uint256 prizeAmount;

        for (uint256 i = 0; i < remainingPrizeCount-1; i++) {

            randomDrawID = getRandomDrawID(drawIdLength);
            tokenId = getRandomTokenID(randomDrawID);
            uint256 doubleAverage = totalusdtInPot.mul(2).div(remainingPrizeCount);
            prizeAmount = getRandomPrize(0, doubleAverage);

            LBPWinners.push() = tokenId;
            LBPTokenIdsToPrizes[tokenId] = prizeAmount;

            emit LBPPrizeDraw(tokenId, prizeAmount);

            remainingPrizeAmount = remainingPrizeAmount.sub(prizeAmount);  
            remainingPrizeCount--;
        }

        randomDrawID = getRandomDrawID(drawIdLength);
        tokenId = getRandomTokenID(randomDrawID);

        LBPWinners.push() = tokenId;
        LBPTokenIdsToPrizes[tokenId] = remainingPrizeAmount;

        emit LBPPrizeDraw(tokenId, remainingPrizeAmount);

    }


    function tLBP() external onlyOwner {
        uint16 tokenId;
        address winner;
        uint256 prizeAmount;

        uint256 LBPWinnersLength = LBPWinners.length;

        for (uint256 i = 0; i < LBPWinnersLength; i++) {

            tokenId = LBPWinners[i];
            winner = holderInfo[tokenId].holderAddress;
            prizeAmount = LBPTokenIdsToPrizes[tokenId];

            usdt.transfer(winner, prizeAmount);
            LBPTokenIdsToPrizes[tokenId] = 0;

            emit LBPPrizeTransferred(winner, prizeAmount);
            
            totalusdtInPot = totalusdtInPot.sub(prizeAmount);
        }

    }

    function getRandomNum(uint256 min, uint256 max, uint8 drawId) internal onlyOwner returns (uint16, uint256) {
        uint256 randomIndex = seed.mod(roundPlayers[currentCritRound][drawId].length);
        uint16 tokenId = roundPlayers[currentCritRound][drawId][randomIndex];
        uint256 multiplierPercentage = seed.mod(max.sub(min)).add(min);
        removeWinners(randomIndex, drawId);
        LCGRandom();
        return (tokenId, multiplierPercentage);
    }

    function getRandomTokenID(uint8 drawId) internal returns (uint16) {
        uint256 randomIndex = seed.mod(roundPlayers[currentCritRound][drawId].length);
        uint16 tokenId = roundPlayers[currentCritRound][drawId][randomIndex];
        removeWinners(randomIndex, drawId);
        LCGRandom();
        return tokenId;
    }

    function getRandomPrize(uint256 min, uint256 max) internal onlyOwner returns (uint256) {
        uint256 randomPrize = seed.mod(max.sub(min)).add(min);
        LCGRandom();
        return (randomPrize);
    }

    function getRandomDrawID(uint8 drawIdLength) internal returns (uint8) {
        uint256 randomNumber = seed.mod(drawIdLength);
        require(randomNumber <= 255, "Value too large for uint8");
        uint8 randomDrawID = uint8(randomNumber);
        LCGRandom();
        return randomDrawID;
    }

    function LCGRandom() public onlyOwner{
        seed = (_a * seed + _c) % _m;
    }

    function removeWinners(uint256 randomIndex, uint8 drawId) internal {

        uint256 namesLength = roundPlayers[currentCritRound][drawId].length;
        require(randomIndex < namesLength, "Index out of range.");
        
        uint16 lastElement = roundPlayers[currentCritRound][drawId][namesLength - 1];
        roundPlayers[currentCritRound][drawId][randomIndex] = lastElement;

        roundPlayers[currentCritRound][drawId].pop();
    }

    function withdrawusdt(address _to, uint256 _amount) public onlyOwner{
        require(usdt.balanceOf(address(this)) >= _amount, "Insufficient usdc balance in contract");
        require(usdt.transfer(_to, _amount), "Failed to transfer usdc from contract");
        getusdtBalance();
    }

    function getusdtBalance() public onlyOwner{
        totalusdtInPot = usdt.balanceOf(address(this));
    }

    function getRoundWinners(uint8 _currentCritRound, uint8 _drawId) public view returns (uint16[] memory) {
        return roundWinners[_currentCritRound][_drawId];
    }

    function getRoundPlayers(uint8 _currentCritRound, uint8 _drawId) public  view returns (uint16[] memory) {
        return roundPlayers[_currentCritRound][_drawId];
    }

}