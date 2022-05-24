// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IVoter} from "../interfaces/IVoter.sol";
import {IVotingEscrow} from "../interfaces/IVotingEscrow.sol";
import {IBribe} from "../interfaces/IBribe.sol";
import {IGauge} from "../interfaces/IGauge.sol";
import {IBribeFactory} from "../interfaces/IBribeFactory.sol";
import {IGaugeFactory} from "../interfaces/IGaugeFactory.sol";
import {IUniswapV2Pair} from "../interfaces/IUniswapV2Pair.sol";
import {IEmissionController} from "../interfaces/IEmissionController.sol";

contract BaseV1Voter is Ownable, IVoter {
  address public immutable _ve; // the IVotingEscrow token that governs these contracts
  address internal immutable base;
  address public immutable gaugefactory;
  address public immutable bribefactory;
  uint256 internal constant DURATION = 7 days; // rewards are released over 7 days
  IEmissionController public emissionController;

  uint256 public totalWeight; // total voting weight

  address[] public pools; // all pools viable for incentives
  mapping(address => address) public gauges; // pool => gauge
  mapping(address => address) public poolForGauge; // gauge => pool
  mapping(address => address) public bribes; // gauge => bribe
  mapping(address => int256) public weights; // pool => weight
  mapping(uint256 => mapping(address => int256)) public votes; // nft => pool => votes
  mapping(uint256 => address[]) public poolVote; // nft => pools
  mapping(uint256 => uint256) public usedWeights; // nft => total voting weight of user
  mapping(address => bool) public isGauge;

  constructor(
    address __ve,
    address _gauges,
    address _bribes,
    address _emissionController,
    address _governance
  ) {
    _ve = __ve;
    base = IVotingEscrow(__ve).token();
    gaugefactory = _gauges;
    bribefactory = _bribes;
    emissionController = IEmissionController(_emissionController);

    _transferOwnership(_governance);
  }

  function votingEscrow() external view override returns (address) {
    return _ve;
  }

  // simple re-entrancy check
  uint256 internal _unlocked = 1;
  modifier lock() {
    require(_unlocked == 1, "locked");
    _unlocked = 2;
    _;
    _unlocked = 1;
  }

  function reset(uint256 _tokenId) external {
    require(
      IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, _tokenId),
      "not approved owner"
    );
    _reset(_tokenId);
    IVotingEscrow(_ve).abstain(_tokenId);
  }

  function _reset(uint256 _tokenId) internal {
    address[] storage _poolVote = poolVote[_tokenId];
    uint256 _poolVoteCnt = _poolVote.length;
    int256 _totalWeight = 0;

    for (uint256 i = 0; i < _poolVoteCnt; i++) {
      address _pool = _poolVote[i];
      int256 _votes = votes[_tokenId][_pool];

      if (_votes != 0) {
        _updateFor(gauges[_pool]);
        weights[_pool] -= _votes;
        votes[_tokenId][_pool] -= _votes;
        if (_votes > 0) {
          IBribe(bribes[gauges[_pool]])._withdraw(uint256(_votes), _tokenId);
          _totalWeight += _votes;
        } else {
          _totalWeight -= _votes;
        }
        emit Abstained(_tokenId, _votes);
      }
    }
    totalWeight -= uint256(_totalWeight);
    usedWeights[_tokenId] = 0;
    delete poolVote[_tokenId];
  }

  function poke(uint256 _tokenId) external {
    address[] memory _poolVote = poolVote[_tokenId];
    uint256 _poolCnt = _poolVote.length;
    int256[] memory _weights = new int256[](_poolCnt);

    for (uint256 i = 0; i < _poolCnt; i++) {
      _weights[i] = votes[_tokenId][_poolVote[i]];
    }

    _vote(_tokenId, _poolVote, _weights);
  }

  function _vote(
    uint256 _tokenId,
    address[] memory _poolVote,
    int256[] memory _weights
  ) internal {
    _reset(_tokenId);
    uint256 _poolCnt = _poolVote.length;
    int256 _weight = int256(IVotingEscrow(_ve).balanceOfNFT(_tokenId));
    int256 _totalVoteWeight = 0;
    int256 _totalWeight = 0;
    int256 _usedWeight = 0;

    for (uint256 i = 0; i < _poolCnt; i++) {
      _totalVoteWeight += _weights[i] > 0 ? _weights[i] : -_weights[i];
    }

    for (uint256 i = 0; i < _poolCnt; i++) {
      address _pool = _poolVote[i];
      address _gauge = gauges[_pool];

      if (isGauge[_gauge]) {
        int256 _poolWeight = (_weights[i] * _weight) / _totalVoteWeight;
        require(votes[_tokenId][_pool] == 0, "votes = 0");
        require(_poolWeight != 0, "poolweight = 0");
        _updateFor(_gauge);

        poolVote[_tokenId].push(_pool);

        weights[_pool] += _poolWeight;
        votes[_tokenId][_pool] += _poolWeight;
        if (_poolWeight > 0) {
          IBribe(bribes[_gauge])._deposit(uint256(_poolWeight), _tokenId);
        } else {
          _poolWeight = -_poolWeight;
        }
        _usedWeight += _poolWeight;
        _totalWeight += _poolWeight;
        emit Voted(msg.sender, _tokenId, _poolWeight);
      }
    }
    if (_usedWeight > 0) IVotingEscrow(_ve).voting(_tokenId);
    totalWeight += uint256(_totalWeight);
    usedWeights[_tokenId] = uint256(_usedWeight);
  }

  function vote(
    uint256 tokenId,
    address[] calldata _poolVote,
    int256[] calldata _weights
  ) external {
    require(
      IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, tokenId),
      "not token owner"
    );
    require(_poolVote.length == _weights.length, "invalid weights");
    _vote(tokenId, _poolVote, _weights);
  }

  function createGauge(address _pool) external onlyOwner returns (address) {
    require(gauges[_pool] == address(0x0), "gauge exists");

    address _bribe = IBribeFactory(bribefactory).createBribe();
    address _gauge = IGaugeFactory(gaugefactory).createGauge(
      _pool,
      _bribe,
      _ve
    );

    IERC20(base).approve(_gauge, type(uint256).max);
    bribes[_gauge] = _bribe;
    gauges[_pool] = _gauge;
    poolForGauge[_gauge] = _pool;
    isGauge[_gauge] = true;
    _updateFor(_gauge);
    pools.push(_pool);

    emit GaugeCreated(_gauge, msg.sender, _bribe, _pool);
    return _gauge;
  }

  function attachTokenToGauge(uint256 tokenId, address account)
    external
    override
  {
    require(isGauge[msg.sender], "not gauge");
    if (tokenId > 0) IVotingEscrow(_ve).attach(tokenId);
    emit Attach(account, msg.sender, tokenId);
  }

  function emitDeposit(
    uint256 tokenId,
    address account,
    uint256 amount
  ) external override {
    require(isGauge[msg.sender], "not gauge");
    emit Deposit(account, msg.sender, tokenId, amount);
  }

  function detachTokenFromGauge(uint256 tokenId, address account)
    external
    override
  {
    require(isGauge[msg.sender], "not gauge");
    if (tokenId > 0) IVotingEscrow(_ve).detach(tokenId);
    emit Detach(account, msg.sender, tokenId);
  }

  function emitWithdraw(
    uint256 tokenId,
    address account,
    uint256 amount
  ) external override {
    require(isGauge[msg.sender], "not gauge");
    emit Withdraw(account, msg.sender, tokenId, amount);
  }

  function length() external view returns (uint256) {
    return pools.length;
  }

  uint256 internal index;
  mapping(address => uint256) internal supplyIndex;
  mapping(address => uint256) public claimable;

  function notifyRewardAmount(uint256 amount) external override {
    _safeTransferFrom(base, msg.sender, address(this), amount); // transfer the distro in
    uint256 _ratio = (amount * 1e18) / totalWeight; // 1e18 adjustment is removed during claim
    if (_ratio > 0) {
      index += _ratio;
    }
    emit NotifyReward(msg.sender, base, amount);
  }

  function updateFor(address[] memory _gauges) external {
    for (uint256 i = 0; i < _gauges.length; i++) {
      _updateFor(_gauges[i]);
    }
  }

  function updateForRange(uint256 start, uint256 end) public {
    for (uint256 i = start; i < end; i++) {
      _updateFor(gauges[pools[i]]);
    }
  }

  function updateAll() external {
    updateForRange(0, pools.length);
  }

  function updateGauge(address _gauge) external {
    _updateFor(_gauge);
  }

  function _updateFor(address _gauge) internal {
    address _pool = poolForGauge[_gauge];
    int256 _supplied = weights[_pool];
    if (_supplied > 0) {
      uint256 _supplyIndex = supplyIndex[_gauge];
      uint256 _index = index; // get global index0 for accumulated distro
      supplyIndex[_gauge] = _index; // update _gauge current position to global position
      uint256 _delta = _index - _supplyIndex; // see if there is any difference that need to be accrued
      if (_delta > 0) {
        uint256 _share = (uint256(_supplied) * _delta) / 1e18; // add accrued difference for each supplied token
        claimable[_gauge] += _share;
      }
    } else {
      supplyIndex[_gauge] = index; // new users are set to the default global state
    }
  }

  function claimRewards(address[] memory _gauges, address[][] memory _tokens)
    external
  {
    for (uint256 i = 0; i < _gauges.length; i++) {
      IGauge(_gauges[i]).getReward(msg.sender, _tokens[i]);
    }
  }

  function claimBribes(
    address[] memory _bribes,
    address[][] memory _tokens,
    uint256 _tokenId
  ) external {
    require(
      IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, _tokenId),
      "not approved owner"
    );
    for (uint256 i = 0; i < _bribes.length; i++) {
      IBribe(_bribes[i]).getRewardForOwner(_tokenId, _tokens[i]);
    }
  }

  function _distribute(address _gauge) internal lock {
    if (IEmissionController(emissionController).callable()) IEmissionController(emissionController).allocateEmission();
    _updateFor(_gauge);
    uint256 _claimable = claimable[_gauge];
    if (_claimable > IGauge(_gauge).left(base) && _claimable / DURATION > 0) {
      claimable[_gauge] = 0;
      IGauge(_gauge).notifyRewardAmount(base, _claimable);
      emit DistributeReward(msg.sender, _gauge, _claimable);
    }
  }

  function distribute(address _gauge) external override {
    _distribute(_gauge);
  }

  function distro() external {
    distribute(0, pools.length);
  }

  function distribute() external {
    distribute(0, pools.length);
  }

  function distribute(uint256 start, uint256 finish) public {
    for (uint256 x = start; x < finish; x++) {
      _distribute(gauges[pools[x]]);
    }
  }

  function distribute(address[] memory _gauges) external {
    for (uint256 x = 0; x < _gauges.length; x++) {
      _distribute(_gauges[x]);
    }
  }

  function _safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    require(token.code.length > 0, "invalid token code");
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
    );
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      "transferFrom failed"
    );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVoter {
  function attachTokenToGauge(uint256 _tokenId, address account) external;

  function detachTokenFromGauge(uint256 _tokenId, address account) external;

  function emitDeposit(
    uint256 _tokenId,
    address account,
    uint256 amount
  ) external;

  function emitWithdraw(
    uint256 _tokenId,
    address account,
    uint256 amount
  ) external;

  function distribute(address _gauge) external;

  function votingEscrow() external view returns (address);

  function notifyRewardAmount(uint256 amount) external;

  event GaugeCreated(
    address indexed gauge,
    address creator,
    address indexed bribe,
    address indexed pool
  );
  event Voted(address indexed voter, uint256 tokenId, int256 weight);
  event Abstained(uint256 tokenId, int256 weight);
  event Deposit(
    address indexed lp,
    address indexed gauge,
    uint256 tokenId,
    uint256 amount
  );
  event Withdraw(
    address indexed lp,
    address indexed gauge,
    uint256 tokenId,
    uint256 amount
  );
  event NotifyReward(
    address indexed sender,
    address indexed reward,
    uint256 amount
  );
  event DistributeReward(
    address indexed sender,
    address indexed gauge,
    uint256 amount
  );
  event Attach(address indexed owner, address indexed gauge, uint256 tokenId);
  event Detach(address indexed owner, address indexed gauge, uint256 tokenId);
  event Whitelisted(address indexed whitelister, address indexed token);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";

interface IVotingEscrow is IERC721 {
  function token() external view returns (address);

  function balanceOfNFT(uint256) external view returns (uint256);

  function totalSupplyWithoutDecay() external view returns (uint256);

  function isApprovedOrOwner(address, uint256) external view returns (bool);

  function attach(uint256 tokenId) external;

  function detach(uint256 tokenId) external;

  function voting(uint256 tokenId) external;

  function abstain(uint256 tokenId) external;

  enum DepositType {
    DEPOSIT_FOR_TYPE,
    CREATE_LOCK_TYPE,
    INCREASE_LOCK_AMOUNT,
    INCREASE_UNLOCK_TIME,
    MERGE_TYPE
  }

  struct Point {
    int128 bias;
    int128 slope; // # -dweight / dt
    uint256 ts;
    uint256 blk; // block
  }

  /* We cannot really do block numbers per se b/c slope is per time, not per block
   * and per block could be fairly bad b/c Ethereum changes blocktimes.
   * What we can do is to extrapolate ***At functions */

  struct LockedBalance {
    int128 amount;
    uint256 end;
    uint256 start;
  }

  event Deposit(
    address indexed provider,
    uint256 tokenId,
    uint256 value,
    uint256 indexed locktime,
    DepositType deposit_type,
    uint256 ts
  );

  event Withdraw(
    address indexed provider,
    uint256 tokenId,
    uint256 value,
    uint256 ts
  );

  event Supply(uint256 prevSupply, uint256 supply);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBribe {
  function notifyRewardAmount(address token, uint256 amount) external;

  function left(address token) external view returns (uint256);

  function _deposit(uint256 amount, uint256 tokenId) external;

  function _withdraw(uint256 amount, uint256 tokenId) external;

  function getRewardForOwner(uint256 tokenId, address[] memory tokens) external;

  event Deposit(address indexed from, uint256 tokenId, uint256 amount);
  event Withdraw(address indexed from, uint256 tokenId, uint256 amount);
  event NotifyReward(
    address indexed from,
    address indexed reward,
    uint256 amount
  );
  event ClaimRewards(
    address indexed from,
    address indexed reward,
    uint256 amount
  );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGauge {
  function notifyRewardAmount(address token, uint256 amount) external;

  function getReward(address account, address[] memory tokens) external;

  function left(address token) external view returns (uint256);

  /// @notice A checkpoint for marking balance
  struct Checkpoint {
    uint256 timestamp;
    uint256 balanceOf;
  }

  /// @notice A checkpoint for marking reward rate
  struct RewardPerTokenCheckpoint {
    uint256 timestamp;
    uint256 rewardPerToken;
  }

  /// @notice A checkpoint for marking supply
  struct SupplyCheckpoint {
    uint256 timestamp;
    uint256 supply;
  }

  event Deposit(address indexed from, uint256 tokenId, uint256 amount);
  event Withdraw(address indexed from, uint256 tokenId, uint256 amount);
  event NotifyReward(
    address indexed from,
    address indexed reward,
    uint256 amount
  );
  event ClaimFees(address indexed from, uint256 claimed0, uint256 claimed1);
  event ClaimRewards(
    address indexed from,
    address indexed reward,
    uint256 amount
  );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBribeFactory {
  function createBribe() external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGaugeFactory {
  function createGauge(
    address,
    address,
    address
  ) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Pair {
  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IVoter } from "./IVoter.sol";
import { IEpoch } from "./IEpoch.sol";

interface IEmissionController is IEpoch {
  function allocateEmission() external;

  function setVoter(IVoter _voter) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Receiver.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721Receiver.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEpoch {
  function callable() external view returns (bool);

  function getLastEpoch() external view returns (uint256);

  function getCurrentEpoch() external view returns (uint256);

  function getNextEpoch() external view returns (uint256);

  function nextEpochPoint() external view returns (uint256);

  function getPeriod() external view returns (uint256);

  function getStartTime() external view returns (uint256);
}