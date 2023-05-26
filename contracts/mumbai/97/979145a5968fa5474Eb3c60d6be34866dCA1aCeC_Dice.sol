// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Rewards/Claim.sol";
import "../access/Bound.sol";
import "./priceFeeds/PriceConsumerV3.sol";
import "./Rewards/Reward.sol";

contract Dice is Claim, Bound {
  using SafeERC20 for IERC20;

  PriceConsumerV3 private price;
  Reward private reward;

  uint16 private multiplier; 
  uint256 public currentBetId;

  struct UserBet {
    address bettorAddress;
    uint256 betAmount;
    uint8 sliderValue;
    uint16 multiplier;
    uint8 randomNumber;
    uint256 winningAmount;
    bool isRollOver;
  }

  mapping(uint256 => UserBet) public gameId;
  mapping(uint256 => bool) public isEther;
  mapping(uint256 => address) public tokenAddress;

  event BetPlaced(
    uint256 betId,
    uint256 time,
    address player,
    uint256 betAmount,
    uint8 sliderValue,
    bool isRollOver,
    bool isEther
  );

  event DiceRolled(uint256 indexed betId, uint256 indexed randomNumber, uint256 indexed winningAmount);

  constructor(address _reward, address _priceFeed) {
    reward = Reward(_reward);
    price = new PriceConsumerV3(_priceFeed);
    multiplier = 9850;
  }

  
  /** 
   * @notice calls requestRandomWords function.
   * @dev For placing the bet on dice.
   * @param sliderValue to choose the slider value while placing bet. 
   * @param isRollOver whether the user wants to roll over or roll under the chosen slider value.
   */
  function placeBet(address tokenAddr, uint amount, bool isEth, uint8 sliderValue, bool isRollOver) external nonReentrant betLimit(isEth, amount, tokenAddr) payable {
    ++currentBetId;
    if (isRollOver) {
        require(
          sliderValue > 4 && sliderValue < 100,
          'Invalid Slider Value'
        );
      } else {
        require(sliderValue > 1 && sliderValue < 97, 'Invalid Slider Value');
      }
    UserBet storage b = gameId[currentBetId];
    //when paying with Ether
    if(isEth){
        b.betAmount = msg.value;
        isEther[currentBetId] = true;
        tokenAddress[currentBetId] = address(0);
      }
      //when paying with ERC20 Token
      else {
          IERC20(tokenAddr).safeTransferFrom(msg.sender, address(this), amount);
          b.betAmount = amount;
          isEther[currentBetId] = false;
          tokenAddress[currentBetId] = tokenAddr;
      }
      
      placedBet(sliderValue, isRollOver); 
      _checkWinner(currentBetId);
      emit BetPlaced(currentBetId, block.timestamp, msg.sender, b.betAmount, sliderValue, isRollOver, isEth);
  }

    //private function that will be called by placeBet function. Used for updating UserBet struct.
    function placedBet(uint8 sliderValue, bool isRollOver) private {
          uint16 _multiplier = _calcMultiplier(sliderValue, isRollOver);
          UserBet storage b = gameId[currentBetId];
          b.bettorAddress = msg.sender;
          b.sliderValue = sliderValue;
          b.isRollOver = isRollOver;
          b.multiplier = _multiplier;
      }

  /*
  private function used for calculating multiplier based off the slider value.
  It is called in placeBet function.
  */
  function _calcMultiplier(uint8 sliderValue, bool isRollOver)
    private view
    returns (uint16)
  {
    if (isRollOver) {
      return (multiplier / (100 - sliderValue));
    } else {
      return (multiplier / (sliderValue - 1));
    }
  }

  //set multipier value
  function setMultiplier(uint16 newMultiplier) external onlyAdmin {
    multiplier = newMultiplier;
  }

  /*
   Checks if the user wins the dice based on the _requestId. It is called by the 
   fulfillRandomWords function. When it generates random number, it will check whether 
   the user has won the bet based on the random number generated, and transfers the
   winning amount if user won. Reverts if the contract do not have enough balance.
   */
  function _checkWinner(uint256 betId) private {
    uint256 _winningAmount = 0;
    UserBet storage bet = gameId[betId];
    uint256 _multiplier = bet.multiplier;
    uint256 _randomNum = (uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,betId,block.number,seedWord)))+ 1);
    uint8 _randomNumber = uint8(_randomNum % 100) + 1;
    bet.randomNumber = _randomNumber;
    uint256 sliderValue = bet.sliderValue;
    address _tokenAddress = tokenAddress[betId];

    if (bet.isRollOver && _randomNumber > sliderValue) {
      _winningAmount = (bet.betAmount * _multiplier) / 100;
      gameId[betId].winningAmount = _winningAmount;
    } else if ((!bet.isRollOver) && _randomNumber < sliderValue) {
      _winningAmount = (bet.betAmount * _multiplier) / 100;
      gameId[betId].winningAmount = _winningAmount;
    }

    if(isEther[betId]) {
        withdrawEth(msg.sender, _winningAmount);
    }
    else {
        withdrawToken(msg.sender, _tokenAddress, _winningAmount);
    }
    rewardDistribution(betId);
    emit DiceRolled(betId, _randomNumber, _winningAmount);
  }

    //Add the reward balance
    function rewardDistribution(uint256 betId) private {
        UserBet storage bet = gameId[betId];
        int betValue = int(bet.betAmount);
        int payableReward;
        if(isEther[betId]) {
            int ethPrice = price.getLatestPrice();
            int value = ethPrice * betValue;
            payableReward = value / 10 ** 10;
        } else {
            payableReward = betValue / 100;
        }
        reward.updateReward(msg.sender, payableReward);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../libraries/token/SafeERC20.sol";
import "../../access/Governable.sol";
import "../../libraries/utils/ReentrancyGuard.sol";

contract Claim is Governable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event EthWithdrawn(address indexed player, uint256 indexed amount);
    event TokenWithdrawn(address indexed player, address indexed tokenAddress, uint256 indexed amount);
    event Received(address sender, uint256 indexed message);

    modifier ethBal(uint256 amount) {
        require(reserveInEther() >= amount,'Contract does not have enough balance');
        _;
    }

    modifier tokenBal(address tokenAddress, uint256 amount) {
        require(reserveInToken(tokenAddress) >= amount,'Contract does not have enough balance');
        _;
    }

    //Checks Ether balance of the contract
    function reserveInEther() public view returns (uint256) {
        return address(this).balance;
    }

    //Checks ERC20 Token balance.
    function reserveInToken(address tokenAddress) public view returns(uint) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    //Owner is allowed to withdraw the contract's Ether balance.
    function withdrawEth(address receiver, uint256 amount) internal ethBal(amount) returns(bool) {
        (bool success, ) = receiver.call{value: amount}("");
        require(success, "Transfer failed");
        return true;
    }

    //Owner is allowed to withdraw the contract's token balance.
    function withdrawToken(address receiver, address tokenAddress, uint256 amount) internal tokenBal(tokenAddress, amount) returns(bool){
        IERC20(tokenAddress).safeTransfer(receiver, amount);
        return true;
    }

    //Owner is allowed to withdraw the contract's Ether balance.
    function withdrawEther(address receiver, uint256 amount) external onlyGov nonReentrant ethBal(amount) {
        withdrawEth(receiver, amount);
        emit EthWithdrawn(msg.sender, amount);
    }

    //Owner is allowed to withdraw the contract's token balance.
    function tokenWithdraw(address receiver,address tokenAddress, uint256 amount) external onlyGov nonReentrant tokenBal(tokenAddress, amount) {
        withdrawToken(receiver, tokenAddress, amount);
        emit TokenWithdrawn(msg.sender, tokenAddress, amount);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Governable.sol";

contract Bound is Governable {
    address public rewardToken;
    uint256 internal seedWord;
    uint256 public ethMaxBet;
    uint256 public ethMinBet;
    uint256 public tokenMaxBet;
    uint256 public tokenMinBet;

    mapping(address => bool) public whitelistedToken;

    modifier betLimit(bool isEth, uint256 amount, address tokenAddr) {
        if(isEth) {
            require(msg.value >= ethMinBet && msg.value <= ethMaxBet, 'Invalid amount'); 
        } else {
            require(whitelistedToken[tokenAddr], 'Token not allowed for placing bet');
            require(amount >= tokenMinBet && amount <= tokenMaxBet, 'Invalid amount'); 
        }
        _;
    }

    function setEsBetToken(address rewardTokenAddr) external onlyGov {
        rewardToken = rewardTokenAddr;
    }

    function setSeedWord(uint256 seed) external onlyAdmin {
        seedWord = seed;
    }

    function setEthLimit(uint256 min, uint256 max) external onlyAdmin {
        ethMinBet = min;
        ethMaxBet = max;
    }

    function setTokenLimit(uint256 min, uint256 max) external onlyAdmin {
        tokenMinBet = min;
        tokenMaxBet = max;
    }

    function addWhitelistTokens(address ERC20Address) external onlyAdmin {
        require(!whitelistedToken[ERC20Address], 'Token already whitelisted');
        whitelistedToken[ERC20Address] = true;
    }

    function removeWhitelistTokens(address ERC20Address) external onlyAdmin {
        require(whitelistedToken[ERC20Address], 'Token is not whitelisted');
        whitelistedToken[ERC20Address] = false;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConsumerV3 {
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Sepolia
     * Aggregator: ETH/USD
     * Address: 0x0715A7794a1dc8e42615F059dD6e406A6594651A
     */
    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(
            _priceFeed
        );
    }

    /**
     * Returns the latest price.
     */
    function getLatestPrice() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../access/Governable.sol";

contract Reward is Governable {

    address vester;

    mapping(address => int) public rewards;
    mapping(address => bool) public caller;

    event RewardUpdated(address caller, address recipient, int reward);
    event RewardDeducted(address caller, address recipient, int reward);

    modifier authorisedOnly() {
      require(caller[msg.sender], "Not Authorised");
      _;
    }

    modifier onlyVester() {
        require(msg.sender == vester, "Only vesting contract can call");
        _;
    }

    function setCaller(address contractAddr) external onlyAdmin {
      caller[contractAddr] = true;
    }

    function setVesterAddr(address vesterAddr) external onlyAdmin {
        vester = vesterAddr;
    }

    function updateReward(address recipient, int amount) external authorisedOnly {
        rewards[recipient] += amount;

    emit RewardUpdated(msg.sender, recipient, amount);
    }

    function decreaseRewardBalance(address recipient, int amount) external onlyVester {
        require(msg.sender == vester, "Not Authorised");
        rewards[recipient] -= amount;
        emit RewardDeducted(msg.sender, recipient, amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,          
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Governable {

    address public gov;
    mapping (address => bool) public admins;

    constructor() {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Only Gov can call");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only Admin can call");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function addAdmin(address _account) external onlyGov {
        admins[_account] = true;
    }

    function removeAdmin(address _account) external onlyGov {
        admins[_account] = false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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