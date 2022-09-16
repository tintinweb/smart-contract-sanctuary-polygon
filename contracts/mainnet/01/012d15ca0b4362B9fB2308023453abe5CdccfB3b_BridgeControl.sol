// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IUserProxy.sol";
import "./interfaces/IUserProxyFactory.sol";
import "./interfaces/IVTokenFactory.sol";
import "./interfaces/IVToken.sol";
import "./interfaces/ILendingPool.sol";
import "./libraries/Ownable.sol";
import "./interfaces/IBridgeFeeController.sol";
import "./interfaces/IIncentivesController.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVeDEFE {
    struct LockedBalance {
        int256 amount;
        uint256 end;
    }

    function createLockFor(
        address _beneficiary,
        uint256 _value,
        uint256 _unlockTime
    ) external;

    function increaseAmountFor(address _beneficiary, uint256 _value) external;

    function getLocked(address _addr)
        external
        view
        returns (LockedBalance memory);
}

contract BridgeControl is Ownable {
    using SafeERC20 for IERC20;
    address public proxyFactory;
    address public vTokenFactory;
    address public lendingPool;
    address public virtualDefedToken;
    address public bridgeFeeController;
    address public veDEFE;
    mapping(bytes32 => bool) transactions;

    event TransferToEthereum(
        address indexed fromEthAdr,
        address indexed toEthAdr,
        address indexed toProxyAdr,
        address token,
        address vToken,
        uint256 value,
        uint256 action
    );
    event TransferFromEthereum(
        address indexed fromEthAdr,
        address indexed fromProxyAdr,
        address token,
        address vToken,
        uint256 value,
        bytes32 transactionId
    );
    event TransferFromEthereumForDeposit(
        address indexed fromEthAdr,
        address indexed fromProxyAdr,
        address token,
        address vToken,
        uint256 value,
        bytes32 transactionId
    );
    event TransferFromEthereumForRepay(
        address indexed fromEthAdr,
        address indexed fromProxyAdr,
        address token,
        address vToken,
        uint256 value,
        bytes32 transactionId
    );
    event lockFromEthereumLog(
        address indexed fromEthAdr,
        address indexed fromProxyAdr,
        address virtualDefedToken,
        uint256 value,
        uint256 time,
        bytes32 transactionId
    );
    event BridgeFeeLog(
        address indexed fromUserProxy,
        address token,
        uint256 fee
    );

    constructor(
        address _proxyFactory,
        address _vTokenFactory,
        address _lendingPool,
        address _bridgeFeeController
    ) {
        require(_proxyFactory != address(0));
        require(_vTokenFactory != address(0));
        require(_lendingPool != address(0));
        require(_bridgeFeeController != address(0));
        proxyFactory = _proxyFactory;
        vTokenFactory = _vTokenFactory;
        lendingPool = _lendingPool;
        bridgeFeeController = _bridgeFeeController;
    }

    function setVirtualDefedToken(address _virtualDefedToken, address _veDEFE)
        external
        onlyOwner
    {
        require(_virtualDefedToken != address(0));
        require(_veDEFE != address(0));
        virtualDefedToken = _virtualDefedToken;
        veDEFE = _veDEFE;
    }

    function turnOutToken(address token, uint256 amount) public onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    function transferToEthereum(
        address from,
        address vToken,
        address to,
        uint256 amount,
        uint256 action
    ) external {
        address fromEthAddr = IUserProxy(from).owner();
        address toEthAddr = IUserProxy(to).owner();
        require(fromEthAddr != address(0), "from PROXY_EXISTS");
        require(toEthAddr != address(0), "to PROXY_EXISTS");
        address token = IVToken(vToken).ETHToken();
        require(token != address(0), "unknow token");
        (uint256 fee, address bridgeFeeVault) = IBridgeFeeController(
            bridgeFeeController
        ).getBridgeFee(vToken, amount);
        if (fee > 0) {
            IERC20(vToken).safeTransfer(bridgeFeeVault, fee);
            emit BridgeFeeLog(from, vToken, fee);
        }
        uint256 targetAmount = amount - fee;
        IVToken(vToken).burn(address(this), targetAmount);
        emit TransferToEthereum(
            fromEthAddr,
            toEthAddr,
            to,
            token,
            vToken,
            targetAmount,
            action
        );
    }

    function transferFromEthereumForDeposit(
        bytes32 transactionId,
        address token,
        address to,
        uint256 amount
    ) public onlyOwner {
        require(!transactions[transactionId], "transactionId already exec");
        transactions[transactionId] = true;

        address vToken = IVTokenFactory(vTokenFactory).getVToken(token);
        require(vToken != address(0), "unknow token");
        address proxyAddr = IUserProxyFactory(proxyFactory).getProxy(to);
        if (proxyAddr == address(0)) {
            proxyAddr = IUserProxyFactory(proxyFactory).createProxy(to);
        }
        IVToken(vToken).mint(address(this), amount);
        IERC20(vToken).approve(lendingPool, amount);
        ILendingPool(lendingPool).deposit(vToken, amount, proxyAddr, 0);
        emit TransferFromEthereumForDeposit(
            to,
            proxyAddr,
            token,
            vToken,
            amount,
            transactionId
        );
    }

    function transferFromEthereumForRepay(
        bytes32 transactionId,
        address token,
        address to,
        uint256 amount,
        uint256 rateMode
    ) public onlyOwner {
        require(!transactions[transactionId], "transactionId already exec");
        transactions[transactionId] = true;

        address vToken = IVTokenFactory(vTokenFactory).getVToken(token);
        require(vToken != address(0), "unknow token");
        address proxyAddr = IUserProxyFactory(proxyFactory).getProxy(to);
        if (proxyAddr == address(0)) {
            proxyAddr = IUserProxyFactory(proxyFactory).createProxy(to);
        }
        IVToken(vToken).mint(address(this), amount);
        IERC20(vToken).approve(lendingPool, amount);
        ILendingPool(lendingPool).repay(vToken, amount, rateMode, proxyAddr);
        uint256 balanceAfterRepay = IERC20(vToken).balanceOf(address(this));
        if (balanceAfterRepay > 0) {
            ILendingPool(lendingPool).deposit(
                vToken,
                balanceAfterRepay,
                proxyAddr,
                0
            );
        }
        emit TransferFromEthereumForRepay(
            to,
            proxyAddr,
            token,
            vToken,
            amount,
            transactionId
        );
    }

    function transferFromEthereum(
        bytes32 transactionId,
        address token,
        address to,
        uint256 amount
    ) public onlyOwner {
        require(!transactions[transactionId], "transactionId already exec");
        transactions[transactionId] = true;

        address vToken = IVTokenFactory(vTokenFactory).getVToken(token);
        require(vToken != address(0), "unknow token");
        address proxyAddr = IUserProxyFactory(proxyFactory).getProxy(to);
        if (proxyAddr == address(0)) {
            proxyAddr = IUserProxyFactory(proxyFactory).createProxy(to);
        }
        IVToken(vToken).mint(proxyAddr, amount);
        emit TransferFromEthereum(
            to,
            proxyAddr,
            token,
            vToken,
            amount,
            transactionId
        );
    }

    function lockFromEthereum(
        bytes32 transactionId,
        address user,
        uint256 amount,
        uint256 time
    ) public onlyOwner {
        require(!transactions[transactionId], "transactionId already exec");
        transactions[transactionId] = true;

        address proxyAddr = IUserProxyFactory(proxyFactory).getProxy(user);
        if (proxyAddr == address(0)) {
            proxyAddr = IUserProxyFactory(proxyFactory).createProxy(user);
        }
        lockDefe(proxyAddr, amount, time);
        emit lockFromEthereumLog(
            user,
            proxyAddr,
            virtualDefedToken,
            amount,
            time,
            transactionId
        );
    }

    function lockDefe(
        address proxyAddr,
        uint256 amount,
        uint256 time
    ) internal {
        IVeDEFE.LockedBalance memory locked = IVeDEFE(veDEFE).getLocked(
            proxyAddr
        );
        IERC20(virtualDefedToken).approve(veDEFE, amount);
        if (locked.amount == 0) {
            IVeDEFE(veDEFE).createLockFor(proxyAddr, amount, time);
        } else {
            IVeDEFE(veDEFE).increaseAmountFor(proxyAddr, amount);
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IUserProxy {
    enum Operation {
        Call,
        DelegateCall
    }

    function owner() external view returns (address);

    function initialize(address, bytes32) external;

    function execTransaction(
        address,
        uint256,
        bytes calldata,
        Operation,
        uint256 nonce,
        bytes memory
    ) external;

    function execTransaction(
        address,
        uint256,
        bytes calldata,
        Operation
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IUserProxyFactory {
    event ProxyCreated(address indexed owner, address proxy);

    function getProxy(address owner) external view returns (address proxy);

    function createProxy(address owner) external returns (address proxy);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IVTokenFactory {
    event VTokenCreated(address indexed token, address vToken);

    function bridgeControl() external view returns (address);

    function getVToken(address token) external view returns (address vToken);

    function createVToken(
        address token,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) external returns (address vToken);

    function setBridgeControl(address _bridgeControl) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IVToken {
    function ETHToken() external view returns (address);

    function initialize(
        address _token,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) external;

    function mint(address spender, uint256 amount) external;

    function burn(address spender, uint256 amount) external;

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface ILendingPool {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);

    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    function getReservesList() external view returns (address[] memory);

    function getReserveData(address asset)
        external
        view
        returns (
            uint256,
            uint128,
            uint128,
            uint128,
            uint128,
            uint128,
            uint40,
            address,
            address,
            address,
            address,
            uint8
        );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IBridgeFeeController {
    function getBridgeFee(address asset, uint256 amount)
        external
        view
        returns (uint256, address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IIncentivesController {
    function claimRewards(address[] memory _assets, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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