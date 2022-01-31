// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IFeatToken.sol";

/** 
  * @notice The launching staking contract for rewarding $FEAT holders.
  *         Rewards are distributed on a period of 2 years from a fixed supply
  *         corresponding to 8% of the FEAT max supply.
  */
contract FeatStaking is Initializable {
    struct Staker {
        uint stakedAmount;
        uint currentRewards;
    }

    address[] private allStakers;

    /** @notice the $FEAT token */
    address public feat;

    /** 
      * @dev the number used to retrieve the amount of rewards 
      *      corresponding to a gived time window.
      *         prorata = total of rewards to distribute * full time window
      *         rewards = prorata * time window
      */
    uint private prorata;
    /** @notice the beginning of rewards distribution timestamp */
    uint public startTimestamp;
    /** @notice the total of rewards to distribute */
    uint public startRewards;
    /** @dev the total of distributed rewards */
    uint private givenRewards;
    /** @dev the sum of all locked $FEAT by holders */
    uint private totalStaked;
    uint private lastUpdate;
    
    mapping (address => Staker) private StakersIndex;

    event Initialized(uint _startRewards, uint duringTimestamp, uint startTimestamp);
    event EnterStake(address _from, uint _lockAmount, uint timestamp);
    event ExitStake(address _from, uint _receivedFeat, uint timestamp);

    /** 
      * @dev initialize contract by setting up the amount of rewards to distribute,
      *      the window time and the prorata to calculate rewards
     */
    function init(address _feat, uint _startRewards) external initializer {
        feat = _feat;
        startRewards = (_startRewards);
        startTimestamp = block.timestamp;
        lastUpdate = block.timestamp;
        prorata = startRewards / (31556926 * 2);
        emit Initialized(startRewards, (31556926 * 2), startTimestamp);
    }

    /**
      * @notice Deposit FEAT in this contract and start earning rewards
      *
      * @param _amount the amount of FEAT to stake
      */
    function stake(uint _amount) external {
        // can't enter in pool if no more rewards is available
        require(givenRewards < startRewards, "FeatStaking: staking ended");
        updateRewards();
        IFeatToken(feat).transferFrom(msg.sender, address(this), _amount);
        if(StakersIndex[msg.sender].stakedAmount == 0){
            allStakers.push(msg.sender);
        }
        StakersIndex[msg.sender].stakedAmount += _amount;
        totalStaked += _amount;
        emit EnterStake(msg.sender, _amount, block.timestamp);
    }

    /**
      * @notice Withdraw deposited FEAT and new rewards
      *         All rewards are gived even if not all of the staked FEAT are withdrawed.
      *
      * @param _amount the amount of FEAT to unlock */
    function withdraw(uint _amount) external {
        updateRewards();
        StakersIndex[msg.sender].stakedAmount -= _amount;
        totalStaked -= _amount;
        _amount += StakersIndex[msg.sender].currentRewards;
        StakersIndex[msg.sender].currentRewards = 0;
        if(StakersIndex[msg.sender].stakedAmount == 0){
            for(uint i; i < allStakers.length; i++){
                if (allStakers[i] == msg.sender){
                    allStakers[i] = allStakers[allStakers.length - 1];
                    allStakers.pop();
                }
            }
        }
        IFeatToken(feat).transfer(msg.sender, _amount);
        emit ExitStake(msg.sender, _amount, block.timestamp);
    }

    function updateRewards() internal {
        uint toDistribute = getAvailableRewards();
        for(uint i; i < allStakers.length; i++){
            uint rewards = toDistribute * StakersIndex[allStakers[i]].stakedAmount / totalStaked;
            StakersIndex[allStakers[i]].currentRewards += rewards;
            givenRewards += rewards;
        }
    }

    /**
      * @notice Retrieve how many FEAT the caller have deposited,
      *         and how many new rewards he got.
      *
      * @return isStaked the amount that the user have locked 
      * @return waitingRewards the amount of rewards available for the user
      */
    function getActualAmounts() public view returns (uint isStaked, uint waitingRewards) {
        isStaked = StakersIndex[msg.sender].stakedAmount;
        uint additionnalRewards = getAvailableRewards() * StakersIndex[msg.sender].stakedAmount / totalStaked;
        waitingRewards = StakersIndex[msg.sender].currentRewards + additionnalRewards;
    }

    /** 
      * @notice Retrieve the current annual percentage rate (APR)
      * @dev This function basically just simulate a deposit and withdraw 1 year later
      *      to get how many FEAT we obtain after one year.
      *      Percentage calculation should be done on front with a divide on 100.
      *
      * @return the amount of received FEAT after one year (with a unit precision of 0,01)
      *         (i.e returned: 12345 -> 123%)
      */
    function getActualAPR() external view returns (uint){
        uint timeIn1Y = block.timestamp + 31556926;
        uint unlockedIn1Y = prorata * (timeIn1Y - startTimestamp);
        if(unlockedIn1Y > startRewards){
            unlockedIn1Y = startRewards;
        }
        uint toDistribute = unlockedIn1Y - givenRewards;
        return (toDistribute * 1 ether / totalStaked) + 1 ether;
    }

    /** @notice Retrieve the current unlocked rewards */
    function getUnlockedRewards() public view returns (uint) {
        uint timeSinceInit = (block.timestamp - startTimestamp);
        uint unlocked = prorata * timeSinceInit;
        if(unlocked > startRewards){
            return startRewards;
        }
        else return unlocked;
    }

    /** @notice Retrieve the unlocked and non-distributed rewards */
    function getAvailableRewards() public view returns (uint) {
        return getUnlockedRewards() - givenRewards;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IFeatToken {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}