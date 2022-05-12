// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Sweepable.sol";
import "./interfaces/IBulkSender.sol";
import "./interfaces/IAssetsGeneric.sol";

error BulkSender_CantAcceptEtherDirectly();
error BulkSender_NotEnoughOrTooMuchEther();

/// @title BulkSender contract.
/// @dev TightlyPacked features are made thanks to the MultiSend contract code:
/// https://etherscan.io/address/0x5fcc77ce412131daeb7654b3d18ee89b13d86cbf#code
/// TightlyPacked is cheaper if amount is less than 12 bytes. Normal is
/// cheaper if you don't need to store input data or if amounts are greater
/// than 12 bytes. 12 bytes allows for sends of up to 2^96-1 units, 79 billion
/// ETH, so tightly packed functions will work for any ETH send but may not 
/// work for token sends when the token has a high number of decimals or a 
/// very large total supply.
contract BulkSender is IBulkSender, Sweepable {
    using SafeERC20 for IERC20;

    /// @dev Default payable function to not allow sending to contract.
    receive() external payable {
        revert BulkSender_CantAcceptEtherDirectly();
    }

    /// @notice Send ETH to multiple addresses using a byte32 array which
    /// includes the addresses and the values.
    /// Addresses and values are stored in a packed bytes32 array
    /// Address is stored in the 20 most significant bytes
    /// The address is retrieved by bitshifting 96 bits to the right
    /// ETH value is stored in the 12 least significant bytes
    /// ETH value is retrieved by taking the 96 least significant bytes
    /// and converting them into an unsigned integer.
    /// @param  _addressesAndValues Bitwise packed array of addresses and amounts.
    function sendEtherTightlyPacked(bytes32[] calldata _addressesAndValues)
        external
        payable
    {
        uint startBalance = address(this).balance;

        address to;
        uint96 value;
        bytes32 data;
        uint len = _addressesAndValues.length;
        for (uint i = 0; i < len; ++i) {
            data = _addressesAndValues[i];
            to = address(uint160(uint256(data >> 96)));
            value = uint96(uint256(data));
            if (!payable(to).send(value)) revert BulkSender_FailedToSendEther();
        }

        if (startBalance - msg.value != address(this).balance)
            revert BulkSender_NotEnoughOrTooMuchEther();
    }

    /// @notice Sends different value of ETH to many addresses.
    /// @param  _accounts The accounts to send ETH to.
    /// @param  _values   The values of ETH to send.
    function sendEther(address payable[] calldata _accounts, uint[] calldata _values)
        external
        payable
    {
        uint startBalance = address(this).balance;

        uint len = _accounts.length;
        for (uint i = 0; i < len; ++i) {
            if (!_accounts[i].send(_values[i])) revert BulkSender_FailedToSendEther();
        }

        if (startBalance - msg.value != address(this).balance)
            revert BulkSender_NotEnoughOrTooMuchEther();
    }

    /// @notice Transfers ERC20 tokens to multiple addresses 
    /// using a byte32 array which includes the address and the amount.
    /// Addresses and amounts are stored in a packed bytes32 array.
    /// Address is stored in the 20 most significant bytes.
    /// The address is retrieved by bitshifting 96 bits to the right
    /// Amount is stored in the 12 least significant bytes.
    /// The amount is retrieved by taking the 96 least significant bytes
    /// and converting them into an unsigned integer.
    /// @param  _token               The token to send.
    /// @param  _addressesAndAmounts Bitwise packed array of addresses and amounts.
    function transferERC20TightlyPacked(IERC20 _token, bytes32[] calldata _addressesAndAmounts)
        external
    {
        address to;
        bytes32 data;
        uint96 amount;
        uint len = _addressesAndAmounts.length;
        for (uint i = 0; i < len; ++i) {
            data = _addressesAndAmounts[i];
            to = address(uint160(uint256(data >> 96)));
            amount = uint96(uint256(data));
            _token.safeTransferFrom(msg.sender, to, amount);
        }
    }

    /// @notice Transfers same amount of tokens to many addresses.
    /// @param  _token    The address of the token contract.
    /// @param  _accounts The accounts to transfer tokens to.
    /// @param  _amount   The amount of tokens to transfer.
    function transferERC20(IERC20 _token, address[] calldata _accounts, uint _amount)
        external
    {
        uint len = _accounts.length;
        for (uint i = 0; i < len; ++i) {
            _token.safeTransferFrom(msg.sender, _accounts[i], _amount);
        }
    }

    /// @notice Transfers different amount of tokens to many addresses.
    /// @param  _token    The address of the token contract.
    /// @param  _accounts The accounts to transfer tokens to.
    /// @param  _amounts  The amounts of tokens to transfer.
    function transferERC20(IERC20 _token, address[] calldata _accounts, uint[] calldata _amounts)
        external
    {
        uint len = _accounts.length;
        for (uint i = 0; i < len; ++i) {
            _token.safeTransferFrom(msg.sender, _accounts[i], _amounts[i]);
        }
    }

    /// @notice Transfers erc721 items to multiple addresses 
    /// using a byte32 array which includes address and item IDs.
    /// Addresses and IDs are stored in a packed bytes32 array.
    /// Address is stored in the 20 most significant bytes.
    /// The address is retrieved by bitshifting 96 bits to the right
    /// ID is stored in the 12 least significant bytes.
    /// The ID is retrieved by taking the 96 least significant bytes
    /// and converting them into an unsigned integer.
    /// @param  _token          The address of the item contract.
    /// @param  _accountsAndIds The accounts to transfer items to.
    function transferERC721TightlyPacked(address _token, bytes32[] calldata _accountsAndIds)
        external
    {
        address to;
        bytes32 data;
        uint96 amount;
        uint len = _accountsAndIds.length;
        for (uint i = 0; i < len; ++i) {
            data = _accountsAndIds[i];
            to = address(uint160(uint256(data >> 96)));
            amount = uint96(uint256(data));
            IAssetsGeneric(_token).safeTransferFrom(msg.sender, to, amount);
        }
    }

    /// @notice Transfers erc721 items to many addresses.
    /// @param  _token    The address of the item contract.
    /// @param  _accounts The accounts to transfer items to.
    /// @param  _ids      The ids of the items to transfer.
    function transferERC721(address _token, address[] calldata _accounts, uint[] calldata _ids)
        external
    {
        uint len = _accounts.length;
        for (uint i = 0; i < len; ++i) {
            IAssetsGeneric(_token).safeTransferFrom(msg.sender, _accounts[i], _ids[i]);
        }
    }

    /// @notice Transfers erc1155 items to multiple addresses 
    /// using a byte32 array which includes addresses and item IDs.
    /// Addresses and IDs are stored in a packed bytes32 array.
    /// Address is stored in the 20 most significant bytes.
    /// The address is retrieved by bitshifting 96 bits to the right
    /// ID is stored in the 12 least significant bytes.
    /// The ID is retrieved by taking the 96 least significant bytes
    /// and converting them into an unsigned integer.
    /// @param  _token           The address of the item contract.
    /// @param  _addressesAndIds The accounts to transfer items to.
    /// @param  _amounts         The amounts of the items to transfer.
    function transferERC1155TightlyPacked(
        address _token,
        bytes32[] calldata _addressesAndIds,
        uint256[] calldata _amounts
    ) external {
        uint96 id;
        address to;
        bytes32 data;
        uint len = _addressesAndIds.length;
        for (uint i = 0; i < len; ++i) {
            data = _addressesAndIds[i];
            to = address(uint160(uint256(data >> 96)));
            id = uint96(uint256(data));
            IAssetsGeneric(_token).safeTransferFrom(
                msg.sender,
                to,
                id,
                _amounts[i],
                ""
            );
        }
    }

    /// @notice Transfers erc1155 items with different `ids` and `amounts` to many addresses.
    /// @param  _token    The address of the item contract.
    /// @param  _accounts The accounts to transfer items to.
    /// @param  _ids      The ids of the items to transfer.
    /// @param  _amounts  The amounts of the items to transfer.
    function transferERC1155(
        address _token,
        address[] calldata _accounts,
        uint[] calldata _ids,
        uint[] calldata _amounts
    ) external {
        uint len = _accounts.length;
        for (uint i = 0; i < len; ++i) {
            IAssetsGeneric(_token).safeTransferFrom(
                msg.sender,
                _accounts[i],
                _ids[i],
                _amounts[i],
                ""
            );
        }
    }

    /// @notice Transfers erc1155 items with different `ids` and same `amount` to many addresses.
    /// @param  _token    The address of the item contract.
    /// @param  _accounts The accounts to transfer items to.
    /// @param  _ids      The ids of the items to transfer.
    /// @param  _amount   The amount of the items to transfer.
    function transferERC1155(
        address _token,
        address[] calldata _accounts,
        uint[] calldata _ids,
        uint _amount
    )
        external
    {
        uint len = _accounts.length;
        for (uint i = 0; i < len; ++i) {
            IAssetsGeneric(_token).safeTransferFrom(
                msg.sender,
                _accounts[i],
                _ids[i],
                _amount,
                ""
            );
        }
    }

    /// @notice Transfers erc1155 items with same `id` and different `amounts` to many addresses.
    /// @param  _token    The address of the item contract.
    /// @param  _accounts The accounts to transfer items to.
    /// @param  _id       The id of the item to transfer.
    /// @param  _amounts  The amounts of the items to transfer.
    function transferERC1155(
        address _token,
        address[] calldata _accounts,
        uint _id,
        uint[] calldata _amounts
    )
        external
    {
        uint len = _accounts.length;
        for (uint i = 0; i < len; ++i) {
            IAssetsGeneric(_token).safeTransferFrom(
                msg.sender,
                _accounts[i],
                _id,
                _amounts[i],
                ""
            );
        }
    }

    /// @notice Transfers erc1155 items with same `id` and `amount` to many addresses.
    /// @param  _token    The address of the item contract.
    /// @param  _accounts The accounts to transfer items to.
    /// @param  _id       The id of the item to transfer.
    /// @param  _amount   The amount of the item to transfer.
    function transferERC1155(
        address _token,
        address[] calldata _accounts,
        uint _id,
        uint _amount
    )
        external
    {
        uint len = _accounts.length;
        for (uint i = 0; i < len; ++i) {
            IAssetsGeneric(_token).safeTransferFrom(
                msg.sender,
                _accounts[i],
                _id,
                _amount,
                ""
            );
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error BulkSender_FailedToSendEther();

/// @title A base contract which supports an administrative sweep function wherein
/// authorized caller may transfer ETH or ERC-20 tokens out of BulkSender contract.
contract Sweepable is Ownable {
    using SafeERC20 for IERC20;

    event Sweep(address indexed sweeper, address indexed token, uint256 amount, address indexed recipient);

    /// Allow the owner to sweep all of ETH or a particular ERC-20 token from 
    /// the contract  and send it to another address. This function exists 
    /// to allow the BulkSender owner to recover tokens or ETH that are
    /// accidentally sent directly to this contract and get stuck.
    /// @param _token The address of the token to transfer, use 0x0 for ETH.
    /// @param _to    The address to send the swept tokens/eth to.
    function sweep(address _token, address _to) external onlyOwner {
        uint256 balance;

        if (_token == address(0)) {
            balance = address(this).balance;
            if (!payable(_to).send(balance)) revert BulkSender_FailedToSendEther();
        } else {
            balance = IERC20(_token).balanceOf(address(this));
            IERC20(_token).safeTransfer(_to, IERC20(_token).balanceOf(address(this)));
        }

        emit Sweep(msg.sender, _token, balance, _to);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice BulkSender contract interface.
interface IBulkSender {
    function sendEtherTightlyPacked(bytes32[] calldata _addressesAndAmounts) external payable;

    function sendEther(address payable[] calldata _accounts, uint[] calldata _values) external payable;

    function transferERC20TightlyPacked(IERC20 _token, bytes32[] calldata _addressesAndAmounts) external;

    function transferERC20(IERC20 _token, address[] calldata _accounts, uint _amount) external;

    function transferERC20(IERC20 _token, address[] calldata _accounts, uint[] calldata _amounts) external;

    function transferERC721(address _token, address[] calldata _accounts, uint[] calldata _ids) external;

    function transferERC1155(
        address _token,
        address[] calldata _accounts,
        uint[] calldata _ids,
        uint[] calldata _amounts
    ) external;

    function transferERC1155(
        address _token,
        address[] calldata _accounts,
        uint[] calldata _ids,
        uint _amount
    ) external;

    function transferERC1155(
        address _token,
        address[] calldata _accounts,
        uint _id,
        uint[] calldata _amount
    ) external;

    function transferERC1155(
        address _token,
        address[] calldata _accounts,
        uint _id,
        uint _amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title A generic interface for ERC721 and ERC1155 used in BulkSender.
interface IAssetsGeneric {    
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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