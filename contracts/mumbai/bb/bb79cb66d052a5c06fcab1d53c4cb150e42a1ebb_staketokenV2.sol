pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract staketokenV2 is ReentrancyGuardUpgradeable {

    // struct details for staking
    struct stake {
        string staketype;
        uint256 typeid;
        address account;
        uint256 stakeid;
        uint256 quantity;
        uint256 timestamp;
    }
    
    // mapping of stake Id with stake details
    mapping(uint256 => stake) public stakeDetails;

    // mapping of user address with stake array
    mapping(address => stake[]) public accountStakeDetails;

    // mapping of stake type with stake array
    mapping(string => stake[]) public objectStakeDetails;

    // mapping of address w.r.t its total stake amount
    mapping(address => uint256) public totalnumberofAccountstakes;

    // mapping of stake type w.r.t its stake amount
    mapping(string => uint256) public totalnumberofObjectstakes;

    // array of stake Id
    uint256[] public stakes;

    // stake Index
    uint256 public stakeindex;

    // total stake amount
    uint256 public totalStakes;

    // FAN Token Interface
    IERC20 internal tokenInterface; 

    // address of escrow account
    address escrow_account; 

    event stakeTokens(address user, uint256 stakeId, uint256 amount, address to);

    event unstakeTokens(address user, uint256 stakeId, uint256 quantity);

    // Initialisation section

    function initialize(address token, address escrowaccount) public initializer {
        __ReentrancyGuard_init();
        tokenInterface = IERC20(token);
        escrow_account = escrowaccount;
        stakeindex = 0;
        totalStakes = 0;
    }

    /**
     * @dev stake FAN tokens on projects/writers etc.
     *
     * @param staketype stake type.
     * @param typeid type id
     * @param to address
     * @param quantity number of tokens
     * 
     * Returns
     * - boolean.
     *
     * Emits a {stakeTokens} event.
    */ 

    function staketokens(
        string memory staketype,
        uint256 typeid,
        address to,
        uint256 quantity
    ) nonReentrant external returns (bool) {
        require(typeid != 0, "Invalid stake type id");
        require(to != msg.sender, "cannot stake on projects by yourself");
        require(quantity > 0, "Amount should be greater then zero");

        stakeindex += 1; //increment stake index
        stake memory createstake = stake(
            staketype,
            typeid,
            msg.sender,
            stakeindex,
            quantity,
            block.timestamp
        );

          //check for balance
        require(
            tokenInterface.balanceOf(msg.sender) >= quantity,
            "Insufficient balance in source account"
        );
        //check for allowance
        require(
            tokenInterface.allowance(msg.sender, address(this)) >= quantity,
            "Source account has not approved stake contract"
        );

        stakes.push(stakeindex);
        stakeDetails[stakeindex] = createstake;

        stake[] storage stakeofaccounts = accountStakeDetails[msg.sender];
        stakeofaccounts.push(createstake);
        totalnumberofAccountstakes[msg.sender] += quantity;

        stake[] storage objectStakes = objectStakeDetails[staketype];
        objectStakes.push(createstake);
        totalnumberofObjectstakes[staketype] = totalnumberofObjectstakes[staketype] + quantity;
        totalStakes += quantity;

        // Transfers tokens to destination account
        tokenInterface.transferFrom(msg.sender, to, quantity);

        emit stakeTokens(msg.sender, stakeindex, quantity, to);

        return true;
    }

    /**
     * @dev unstake FAN tokens on projects/writers etc.
     *
     * @param stakeid stake type.
     * @param quantity number of tokens
     *  
     * 
     * Returns
     * - boolean.
     *
     * Emits a {unstakeTokens} event.
    */ 
    function unstaketokens(uint256 stakeid, uint256 quantity) nonReentrant external returns (bool){
        uint256 index_stakes = stakeid-1;
                        //check if stakeid exists
           require((stakes[index_stakes] == stakeid),"Stakeid not found");
       
        //get details of this stake using stake id
        stake storage stakedetails = stakeDetails[stakeid];
        require(msg.sender == stakedetails.account,"Only staker can unstake");
        require(
            stakedetails.quantity >= quantity,
            "Unstake quantity should be less than or equal to staked quantity"
        );
        require(
            tokenInterface.allowance(escrow_account, address(this)) >= quantity,
            "Escrow account has not approved stake contract"
        );
                require(
            tokenInterface.balanceOf(escrow_account) >= quantity,
            "Insufficient balance in escrow account"
        );
        // Transfers tokens from escrow to staker account
        tokenInterface.transferFrom(escrow_account, address(this), quantity);
        tokenInterface.transfer(msg.sender, quantity);
        
        stake[] storage objectStakes = objectStakeDetails[stakedetails.staketype];
        stake[] storage stakeofaccounts = accountStakeDetails[ stakedetails.account];
        
        if(quantity == stakedetails.quantity){                     //check if all amount is getting unstaked

            if (stakeofaccounts[stakeid - 1].stakeid == stakeid) delete stakeofaccounts[stakeid - 1];

            accountStakeDetails[ stakedetails.account] = stakeofaccounts; //updating orginal record
            
            if (objectStakes[stakeid-1].stakeid == stakeid) delete objectStakes[stakeid-1];

            objectStakeDetails[stakedetails.staketype] = objectStakes;  //updating original record
                delete stakes[index_stakes];                               //delete stake id  
        }
                    
        stake memory currentstake = stakeDetails[stakeid];
        currentstake.quantity = currentstake.quantity - quantity;
        stakeDetails[stakeid] =  currentstake;                              //update the stake record

        if (stakeofaccounts[stakeid - 1].stakeid == stakeid) stakeofaccounts[stakeid - 1].quantity = stakeofaccounts[stakeid - 1].quantity - quantity;
        accountStakeDetails[stakedetails.account] = stakeofaccounts; //updating orginal record

        if (objectStakes[stakeid - 1].stakeid == stakeid) objectStakes[stakeid - 1].quantity = objectStakes[stakeid - 1].quantity - quantity;
        objectStakeDetails[stakedetails.staketype] = objectStakes;  //updating original record

        totalnumberofAccountstakes[stakedetails.account] = totalnumberofAccountstakes[stakedetails.account] - quantity;

        totalnumberofObjectstakes[stakedetails.staketype] = totalnumberofObjectstakes[stakedetails.staketype] - quantity;
        
        totalStakes = totalStakes - quantity;

        emit unstakeTokens(msg.sender, stakeid, quantity);

        return true;
    }
    
    function getListofAllStakesOfAccount(address account)
        public
        view
        returns (stake[] memory)
    {
        return accountStakeDetails[account];
    }

    function getListofAllStakesOfObject(string memory staketype)
        public
        view
        returns (stake[] memory)
    {
        return objectStakeDetails[staketype];
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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