/**
 *Submitted for verification at polygonscan.com on 2023-06-30
*/

// SPDX-License-Identifier: BUSL-1.1
//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>
// - Elijah <[email protected]>
// - Snake <[email protected]>

// File: contracts/interfaces/IElkV2FarmManager.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;

interface IElkV2FarmManager {
    event FarmFactorySet(address factoryAddress);
    event RewardsReceived(address farm);

    function setFarmFactory(address _factoryAddress) external;

    function startEmissionWithCoverage(
        address _farmAddress,
        uint256[] memory _rewards,
        uint256 _coverage,
        uint256 _duration
    ) external;

    function startEmission(
        address _farmAddress,
        uint256[] memory _rewards,
        uint256 _duration
    ) external;

    function stopEmission(address _farmAddress) external;

    function recoverERC20(
        address _farmAddress,
        address _tokenAddress,
        uint256 _amount
    ) external;

    function recoverLeftoverReward(
        address _farmAddress,
        address _tokenAddress
    ) external;

    function addRewardToken(
        address _farmAddress,
        address _tokenAddress
    ) external;

    function recoverLeftoverCoverage(address _farmAddress) external;

    function recoverFees(address _farmAddress) external;

    function multiClaim(address[] memory _farms) external;
}

// File: contracts/interfaces/IElkPair.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.5.0;

interface IElkPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address _owner) external view returns (uint);

    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint);

    function approve(address _spender, uint _value) external returns (bool);

    function transfer(address _to, uint _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint _value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address _owner) external view returns (uint);

    function permit(
        address _owner,
        address _spender,
        uint _value,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address _to) external returns (uint liquidity);

    function burn(address _to) external returns (uint amount0, uint amount1);

    function swap(
        uint _amount0Out,
        uint _amount1Out,
        address _to,
        bytes calldata _data
    ) external;

    function skim(address _to) external;

    function sync() external;

    function initialize(address, address) external;
}

// File: contracts/interfaces/IElkDexOracle.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;

interface IElkDexOracle {
    struct Observation {
        uint timestamp;
        uint price0Cumulative;
        uint price1Cumulative;
    }

    function weth() external view returns (address);

    function factory() external view returns (address);

    function windowSize() external view returns (uint);

    function granularity() external view returns (uint8);

    function periodSize() external view returns (uint);

    function pairObservations(
        address _pair
    ) external view returns (Observation[] memory);

    function observationIndexOf(uint _timestamp) external view returns (uint);

    function update(address _tokenA, address _tokenB) external;

    function updateWeth(address _token) external;

    function consult(
        address _tokenIn,
        uint _amountIn,
        address _tokenOut
    ) external view returns (uint);

    function consultWeth(
        address _tokenIn,
        uint _amountIn
    ) external view returns (uint);
}

// File: @openzeppelin/[email protected]/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// File: @openzeppelin/[email protected]/token/ERC20/extensions/draft-IERC20Permit.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: @openzeppelin/[email protected]/token/ERC20/IERC20.sol


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

// File: contracts/interfaces/IElkV2FarmFactory.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;


interface IElkV2FarmFactory {
    event ContractCreated(address _newContract);
    event ManagerSet(address _farmManager);
    event FeeSet(uint256 _newFee);
    event FeesRecovered(uint256 _balanceRecovered);

    function getFarm(
        address _creator,
        address _lpTokenAddress
    ) external view returns (address);

    function getPermissionedFarm(
        address _creator,
        address _lpTokenAddress
    ) external view returns (address);

    function isFarm(address _farmAddress) external view returns (bool);

    function isPermissionedFarm(address _farmAddress) external view returns (bool);

    function allFarms(uint _index) external view returns (address);

    function allFarmsLength() external view returns (uint256);

    function farmManager() external view returns (address);

    function getCreator(address _farmAddress) external view returns (address);

    function feeToken() external view returns (IERC20);

    function fee() external view returns (uint256);

    function maxFee() external view returns (uint256);

    function createNewRewards(
        address _oracleAddress,
        address _lpTokenAddress,
        address _coverageTokenAddress,
        uint256 _coverageAmount,
        uint32 _coverageVestingDuration,
        address[] memory _rewardTokenAddresses,
        uint256 _rewardsDuration,
        uint16 _depositFeeBps,
        uint16[] memory _withdrawalFeesBps,
        uint32[] memory _withdrawalFeeSchedule
    ) external;

     function createNewPermissonedRewards(
        address _oracleAddress,
        address _lpTokenAddress,
        address _coverageTokenAddress,
        uint256 _coverageAmount,
        uint32 _coverageVestingDuration,
        address[] memory _rewardTokenAddresses,
        uint256 _rewardsDuration,
        uint16 _depositFeeBps,
        uint16[] memory _withdrawalFeesBps,
        uint32[] memory _withdrawalFeeSchedule
    ) external;

    function setManager(address _managerAddress) external;

    function setFee(uint256 _newFee) external;

    function withdrawFees() external;

    function overrideOwnership(address _farmAddress) external;
}

// File: contracts/interfaces/IStaking.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;


interface IStaking {
    /* ========== STATE VARIABLES ========== */
    function stakingToken() external returns (IERC20);

    function totalSupply() external returns (uint256);

    function balances(address _account) external returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */
    function stake(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function exit() external;

    function recoverERC20(
        address _tokenAddress,
        address _recipient,
        uint256 _amount
    ) external;

    /* ========== EVENTS ========== */

    // Emitted on staking
    event Staked(address indexed account, uint256 amount);

    // Emitted on withdrawal (including exit)
    event Withdrawn(address indexed account, uint256 amount);

    // Emitted on token recovery
    event Recovered(
        address indexed token,
        address indexed recipient,
        uint256 amount
    );
}

// File: contracts/interfaces/IStakingFee.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;


interface IStakingFee is IStaking {
    /* ========== STATE VARIABLES ========== */
    function feesUnit() external returns (uint256);

    function maxFee() external returns (uint256);

    function withdrawalFeeSchedule(uint256) external returns (uint256);

    function withdrawalFeesBps(uint256) external returns (uint256);

    function depositFeeBps() external returns (uint256);

    function collectedFees() external returns (uint256);

    function userLastStakedTime(address _user) external view returns (uint32);

    /* ========== VIEWS ========== */

    function depositFee(uint256 _depositAmount) external view returns (uint256);

    function withdrawalFee(
        address _account,
        uint256 _withdrawalAmount
    ) external view returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function recoverFees(address _recipient) external;
    
    /* ========== EVENTS ========== */

    // Emitted when fees are (re)configured
    event FeesSet(
        uint16 _depositFeeBps,
        uint16[] _withdrawalFeesBps,
        uint32[] _feeSchedule
    );

    // Emitted when a deposit fee is collected
    event DepositFeesCollected(address indexed _user, uint256 _amount);

    // Emitted when a withdrawal fee is collected
    event WithdrawalFeesCollected(address indexed _user, uint256 _amount);

    // Emitted when fees are recovered by governance
    event FeesRecovered(uint256 _amount);
}

// File: contracts/interfaces/IStakingRewards.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;


interface IStakingRewards is IStakingFee {
    /* ========== STATE VARIABLES ========== */

    function rewardTokens(uint256) external view returns (IERC20);

    function rewardTokenAddresses(
        address _rewardAddress
    ) external view returns (bool);

    function periodFinish() external view returns (uint256);

    function rewardsDuration() external view returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function rewardRates(
        address _rewardAddress
    ) external view returns (uint256);

    function rewardPerTokenStored(
        address _rewardAddress
    ) external view returns (uint256);

    // wallet address => token address => amount
    function userRewardPerTokenPaid(
        address _walletAddress,
        address _tokenAddress
    ) external view returns (uint256);

    function rewards(
        address _walletAddress,
        address _tokenAddress
    ) external view returns (uint256);

    /* ========== VIEWS ========== */

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken(
        address _tokenAddress
    ) external view returns (uint256);

    function earned(
        address _tokenAddress,
        address _account
    ) external view returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function getReward(address _tokenAddress, address _recipient) external;

    function getRewards(address _recipient) external;

    // Must send reward before calling this!
    function startEmission(
        uint256[] memory _rewards,
        uint256 _duration
    ) external;

    function stopEmission(address _refundAddress) external;

    function recoverLeftoverReward(
        address _tokenAddress,
        address _recipient
    ) external;

    function addRewardToken(address _tokenAddress) external;

    function rewardTokenIndex(
        address _tokenAddress
    ) external view returns (int8);

    /* ========== EVENTS ========== */

    // Emitted when a reward is paid to an account
    event RewardPaid(
        address indexed _token,
        address indexed _account,
        uint256 _reward
    );

    // Emitted when a leftover reward is recovered
    event LeftoverRewardRecovered(address indexed _recipient, uint256 _amount);

    // Emitted when rewards emission is started
    event RewardsEmissionStarted(uint256[] _rewards, uint256 _duration);

    // Emitted when rewards emission ends
    event RewardsEmissionEnded();
}

// File: contracts/interfaces/IElkV2FarmingRewards.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;




interface IElkV2FarmingRewards is IStakingRewards {
    /// @notice Represents a snapshot of an LP position at a given timestamp
    struct Position {
        uint112 amount0;
        uint112 amount1;
        uint32 blockTimestamp;
    }

    /* ========== STATE VARIABLES ========== */

    function oracle() external returns (IElkDexOracle);

    function lpToken() external returns (IElkPair);

    function coverageTokenAddress() external returns (address);

    function coverageAmount() external returns (uint256);

    function coverageVestingDuration() external returns (uint256);

    function coverageRate() external returns (uint256);

    function coveragePerTokenStored() external returns (uint256);

    function userCoveragePerTokenPaid(
        address _tokenPaid
    ) external returns (uint256);

    function coverage(address _token) external returns (uint256);

    function lastStakedPosition(
        address _user
    )
        external
        returns (uint112 amount0, uint112 amount1, uint32 blockTimeStamp);

    /* ========== VIEWS ========== */

    function coveragePerToken() external view returns (uint256);

    function coverageEarned(address _account) external view returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function getCoverage(address _recipient) external;

    function startEmission(
        uint256[] memory _rewards,
        uint256 _coverage,
        uint256 _duration
    ) external;

    function recoverLeftoverCoverage(address _recipient) external;

    /* ========== EVENTS ========== */

    // Emitted when the coverage is paid to an account
    event CoveragePaid(address indexed account, uint256 coverage);

    // Emitted when the leftover coverage is recovered
    event LeftoverCoverageRecovered(address indexed recipient, uint256 amount);
}

// File: contracts/interfaces/IElkV2FarmingRewardsPermissioned.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;


interface IElkV2FarmingRewardsPermissioned is IElkV2FarmingRewards {

    function setAddressPermission(address _walletAddress, bool _permission) external;

}

// File: @openzeppelin/[email protected]/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




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
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

// File: @openzeppelin/[email protected]/utils/Context.sol


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

// File: @openzeppelin/[email protected]/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: contracts/ElkV2FarmManager.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>
// - Elijah <[email protected]>
// - Snake <[email protected]>

pragma solidity >=0.8.0;







/**
 * This contract serves as the main point of contact between any FarmingRewards creators and their farm contract.
 * It contains any function in FarmingRewards that would normally be restricted to the owner and allows access to its functionality as long as the caller is the known owner in the ElkFarmFactory contract.
 */
contract ElkV2FarmManager is IElkV2FarmManager, Ownable {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    /// @notice interface to the farm factory
    IElkV2FarmFactory public farmFactory;

    /// @notice last timestamp the farm was started
    mapping(address => uint256) public lastStarted;

    /// @notice minimum time before a started farm can be stopped
    uint256 public minDelayBeforeStop;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @param _factoryAddress The address of the ElkFarmFactory contract.
     * @param _minDelayBeforeStop The minimum time before a farm can be stopped after having been started.
     */
    constructor(address _factoryAddress, uint256 _minDelayBeforeStop) {
        require(
            _factoryAddress != address(0),
            "ElkV2FarmManager: ZERO_ADDRESS"
        );
        farmFactory = IElkV2FarmFactory(_factoryAddress);
        minDelayBeforeStop = _minDelayBeforeStop;
    }

    /**
     * @notice Utility function for use by Elk in order to change the ElkFarmFactory if needed.
     * @param _factoryAddress The address of the ElkFarmFactory contract.
     */
    function setFarmFactory(address _factoryAddress) external onlyOwner {
        require(
            _factoryAddress != address(0),
            "ElkV2FarmManager: ZERO_ADDRESS"
        );
        farmFactory = IElkV2FarmFactory(_factoryAddress);
        emit FarmFactorySet(_factoryAddress);
    }

    /**
     * @notice Utility function for use by Elk in order to change the minimum delay before a farm can be stopped if needed.
     * @param _delay The minimum delay in seconds.
     */
    function setMinDelayBeforeStop(uint256 _delay) external onlyOwner {
        minDelayBeforeStop = _delay;
    }

    /* ========== MODIFIERS ========== */

    /**
     * @notice The check used by each function that interacts with the FarmingRewards contract. It reads from the owners stored in ElkFarmFactory to determine if the caller is the known owner of the FarmingRewards contract it is trying to interact with.
     * @param _farmAddress The address of the FarmingRewards contract.
     */
    modifier checkOwnership(address _farmAddress) {
        require(
            farmFactory.isFarm(_farmAddress) ||
                farmFactory.isPermissionedFarm(_farmAddress),
            "ElkV2FarmManager: UNKNOWN_FARM"
        );

        IElkV2FarmingRewards rewardsContract = IElkV2FarmingRewards(_farmAddress);
        address lpTokenAddress = address(rewardsContract.stakingToken());

        if (farmFactory.isFarm(_farmAddress)) {
            require(
                farmFactory.getFarm(msg.sender, lpTokenAddress) == _farmAddress,
                "ElkV2FarmManager: NOT_OWNER"
            );
        } else {
            require(
                farmFactory.getPermissionedFarm(msg.sender, lpTokenAddress) ==
                    _farmAddress,
                "ElkV2FarmManager: NOT_OWNER"
            );
        }

        _;
    }

    /* ========== Farm Functions ========== */

    /**
     * @notice Starts the farm emission for the given FarmingRewards contract address. The amount of rewards per rewards token, ILP coverage amount, and duration of the
     * farm emissions must be supplied. Any reward or coverage tokens are sent to the FarmingRewards contract when this function is called.
     * @param _farmAddress The address of the FarmingRewards contract.
     * @param _rewards An array of rewards indexed by reward token number.
     * @param _coverage The amount of coverage for the farm.
     * @param _duration How long the farm will emit rewards and provide coverage.
     */
    function startEmissionWithCoverage(
        address _farmAddress,
        uint256[] memory _rewards,
        uint256 _coverage,
        uint256 _duration
    ) external checkOwnership(_farmAddress) {
        IElkV2FarmingRewards farm = IElkV2FarmingRewards(_farmAddress);
        // Transfer rewards
        for (uint i = 0; i < _rewards.length; ++i) {
            IERC20(farm.rewardTokens(i)).safeTransferFrom(msg.sender, _farmAddress, _rewards[i]);
        }
        // Transfer coverage
        if (_coverage > 0) {
            IERC20(farm.coverageTokenAddress()).safeTransferFrom(msg.sender, _farmAddress, _coverage);
        }
        // Start emissions
        IElkV2FarmingRewards(_farmAddress).startEmission(
            _rewards,
            _coverage,
            _duration
        );
        lastStarted[_farmAddress] = block.timestamp;
    }

    /**
     * @notice Same utility as startEmissionWithCoverage, but coverage does not need to be supplied.
     * @param _farmAddress The address of the FarmingRewards contract.
     * @param _rewards The amount of rewards per rewards token.
     * @param _duration The duration of the farm emissions.
     */
    function startEmission(
        address _farmAddress,
        uint256[] memory _rewards,
        uint256 _duration
    ) external checkOwnership(_farmAddress) {
        IElkV2FarmingRewards farm = IElkV2FarmingRewards(_farmAddress);
        // Transfer rewards
        for (uint i = 0; i < _rewards.length; ++i) {
            IERC20(farm.rewardTokens(i)).safeTransferFrom(msg.sender, _farmAddress, _rewards[i]);
        }
        // Start emissions
        farm.startEmission(_rewards, _duration);
        lastStarted[_farmAddress] = block.timestamp;
    }

    /**
     * @notice Stops the given farm's emissions and refunds any leftover reward token(s) to the msg.sender.
     * @param _farmAddress The address of the FarmingRewards contract.
     */
    function stopEmission(
        address _farmAddress
    ) external checkOwnership(_farmAddress) {
        require(lastStarted[_farmAddress] + minDelayBeforeStop <= block.timestamp, "ElkV2FarmManager: TOO_SHORT_DELAY");
        IElkV2FarmingRewards(_farmAddress).stopEmission(msg.sender);
    }

    /**
     * @notice Recovers an ERC20 token to the owners wallet. The token cannot be the staking token or any of the rewards tokens for the farm.
     * @dev Ensures any unnecessary tokens are not lost if sent to the farm contract.
     * @param _farmAddress The address of the FarmingRewards contract.
     * @param _tokenAddress The address of the token to recover.
     * @param _amount The amount of the token to recover.
     */
    function recoverERC20(
        address _farmAddress,
        address _tokenAddress,
        uint256 _amount
    ) external checkOwnership(_farmAddress) {
        IElkV2FarmingRewards(_farmAddress).recoverERC20(
            _tokenAddress,
            msg.sender,
            _amount
        );
    }

    /**
     * @notice Recovers the given leftover reward token to the msg.sender. Cannot be called while the farm is active or if there are any LP tokens staked in the contract.
     * @param _farmAddress The address of the FarmingRewards contract.
     * @param _tokenAddress The address of the token to recover.
     */
    function recoverLeftoverReward(
        address _farmAddress,
        address _tokenAddress
    ) external checkOwnership(_farmAddress) {
        IElkV2FarmingRewards(_farmAddress).recoverLeftoverReward(
            _tokenAddress,
            msg.sender
        );
    }

    /**
     * @notice Utility function that allows the farm owner to add a new reward token to the contract. Cannot be called while the farm is active.
     * @param _farmAddress The address of the FarmingRewards contract.
     * @param _tokenAddress The address of the token to add.
     */
    function addRewardToken(
        address _farmAddress,
        address _tokenAddress
    ) external checkOwnership(_farmAddress) {
        IElkV2FarmingRewards(_farmAddress).addRewardToken(_tokenAddress);
    }

    /* ========== ILP ========== */

    /**
     * @notice Recovers the given leftover coverage token to the msg.sender. Cannot be called while the farm is active or if there are any LP tokens staked in the contract.
     * @param _farmAddress The address of the FarmingRewards contract.
     */
    function recoverLeftoverCoverage(
        address _farmAddress
    ) external checkOwnership(_farmAddress) {
        IElkV2FarmingRewards(_farmAddress).recoverLeftoverCoverage(msg.sender);
    }

    /* ========== FEES ========== */

    /**
     * @notice Withdraw fees collected from deposits/withdrawals in the FarmingRewards contract to msg.sender.
     * @param _farmAddress The address of the FarmingRewards contract.
     */
    function recoverFees(
        address _farmAddress
    ) external checkOwnership(_farmAddress) {
        IElkV2FarmingRewards(_farmAddress).recoverFees(msg.sender);
    }

    /**
     * @notice Withdraw fees collected from deposits/withdrawals in the FarmingRewards contract to msg.sender.
     * @param _walletAddress The wallet address to permit.
     * @param _permission true to allow, false to revoke permit.
     * @param _permissionedFarmAddress The address of the FarmingRewardsPermissioned contract.
     */
    function setAddressPermission(
        address _walletAddress,
        bool _permission,
        address _permissionedFarmAddress
    ) external checkOwnership(_permissionedFarmAddress) {
        IElkV2FarmingRewardsPermissioned(_permissionedFarmAddress).setAddressPermission(_walletAddress, _permission);
    }

    /* ========== FARMER FUNCTIONS ========== */

    /**
     * @notice Function for farm users to claim rewards from multiple farms at once.
     * @param _farms The addresses of the FarmingRewards contracts.
     */
    function multiClaim(address[] memory _farms) external {
        require(_farms.length < 30, "ElkV2FarmManager: TOO_MANY_FARMS");

        for (uint i = 0; i < _farms.length; i++) {
            address farmAddress = address(_farms[i]);
            IElkV2FarmingRewards(farmAddress).getRewards(msg.sender);

            emit RewardsReceived(_farms[i]);
        }
    }
}