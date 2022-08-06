// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./lib/CurrencyTransferLib.sol";
import "./interfaces/IERC721Collection.sol";

contract PrimarySaleV2 is ReentrancyGuard {

    struct AcceptableERC20 {
        address erc20Token;
        uint tokenInERC20;
    }

    struct TokenPriceDetails {
        address owner;
        AcceptableERC20[] acceptableERC20;
        address nativeTokenWrapper;
        uint tokenPriceInNative;
    }

    struct CreatorBalanceDetails {
        IERC721Collection tokenAddress;
        AcceptableERC20[] acceptableERC20;
        address nativeTokenWrapper;
        uint tokenWrapperBalance;
    }

    // address public nativeTokenWrapper; //wrapped ether 0xc778417E063141139Fce010982780140Aa0cD5Ab
    // address public erc20Token; //metria 0x2605B1574c5644a870A0A6cbb664d7d000D396Ba

    mapping(IERC721Collection => TokenPriceDetails) public tokenPriceDetails;
    mapping(address => mapping(IERC721Collection => CreatorBalanceDetails)) public creatorBalanceDetails;
    
    modifier isOwner(IERC721Collection _tokenAddress) {
        _isOwner(_tokenAddress);
        _;
    }

    function setTokenPrice(IERC721Collection _tokenAddress, AcceptableERC20[] memory _acceptableERC20, address _nativeTokenWrapper, uint _tokenPriceInNative)
        external
        isOwner(_tokenAddress)
    {
        // AcceptableERC20[] memory _newAcceptableERC20 = new AcceptableERC20[](_acceptableERC20.length);
        // for(uint i = 0; i < _acceptableERC20.length; i++){
        //     _newAcceptableERC20[i] = AcceptableERC20({
        //         erc20Token: _acceptableERC20[i].erc20Token,
        //         tokenInERC20: _acceptableERC20[i].tokenInERC20
        //     });
        // }
        TokenPriceDetails storage _tokenPriceDetails = tokenPriceDetails[_tokenAddress];
        for(uint i = 0; i < _acceptableERC20.length; i++){
           _tokenPriceDetails.acceptableERC20[i] =  _acceptableERC20[i];
        }
        _tokenPriceDetails.owner =  msg.sender;
        _tokenPriceDetails.nativeTokenWrapper =  _nativeTokenWrapper;
        _tokenPriceDetails.tokenPriceInNative =  _tokenPriceInNative;

        // tokenPriceDetails[_tokenAddress] = TokenPriceDetails({
        //     owner: msg.sender,
        //     acceptableERC20: _acceptableERC20,
        //     nativeTokenWrapper: _nativeTokenWrapper,
        //     tokenPriceInNative: _tokenPriceInNative
        // });
    }

    function buyNFT(IERC721Collection _tokenAddress, address _receiver, address _erc20Token) external nonReentrant payable {
        TokenPriceDetails memory tokenDetails = tokenPriceDetails[_tokenAddress];
        uint _nftPriceInERC20;
        for(uint i = 0; i < tokenDetails.acceptableERC20.length; i++){
            if(tokenDetails.acceptableERC20[i].erc20Token == _erc20Token) {
               _nftPriceInERC20 = tokenDetails.acceptableERC20[i].tokenInERC20;
               break;
            }
        }
        if (tokenDetails.tokenPriceInNative > 0 || _nftPriceInERC20 > 0) {
            CreatorBalanceDetails storage _creatorBalanceDetails = creatorBalanceDetails[collectionOwner(_tokenAddress)][_tokenAddress];
            // AcceptableERC20[] storage _acceptableERC20 = _creatorBalanceDetails.acceptableERC20;
            if(msg.value > 0){
                require(tokenDetails.tokenPriceInNative == msg.value, "Invalid amount");
            }
            else {
                require(_erc20Token != address(0), "erc20Token required");
                bool isTokenAvailable = false;
                for(uint i = 0; i < _creatorBalanceDetails.acceptableERC20.length; i++){
                    if(_creatorBalanceDetails.acceptableERC20[i].erc20Token == _erc20Token) {
                        _creatorBalanceDetails.acceptableERC20[i].tokenInERC20 = _creatorBalanceDetails.acceptableERC20[i].tokenInERC20 + _nftPriceInERC20;
                        isTokenAvailable = true;
                        break;
                    }
                }
                if(!isTokenAvailable){
                    _creatorBalanceDetails.acceptableERC20[_creatorBalanceDetails.acceptableERC20.length] = AcceptableERC20({
                        erc20Token: _erc20Token,
                        tokenInERC20: _nftPriceInERC20
                    });
                    // _acceptableERC20.push(AcceptableERC20({
                    //     erc20Token: _erc20Token,
                    //     tokenInERC20: _nftPriceInERC20
                    // }));
                }
            }
            _creatorBalanceDetails.tokenAddress = _tokenAddress;
            // _creatorBalanceDetails.tokenAddress = _acceptableERC20;
            _creatorBalanceDetails.nativeTokenWrapper = tokenDetails.nativeTokenWrapper;
            _creatorBalanceDetails.tokenWrapperBalance = msg.value > 0 ? _creatorBalanceDetails.tokenWrapperBalance + msg.value : _creatorBalanceDetails.tokenWrapperBalance;
            // creatorBalanceDetails[collectionOwner(_tokenAddress)][_tokenAddress] = CreatorBalanceDetails({
            //     tokenAddress: _tokenAddress,
            //     acceptableERC20: _acceptableERC20,
            //     nativeTokenWrapper: tokenDetails.nativeTokenWrapper,
            //     tokenWrapperBalance: msg.value > 0 ? _creatorBalanceDetails.tokenWrapperBalance + msg.value : _creatorBalanceDetails.tokenWrapperBalance
            // });
            CurrencyTransferLib.transferAmountWithWrapper(
                _erc20Token,
                msg.sender,
                address(this),
               _nftPriceInERC20,
               tokenDetails.nativeTokenWrapper
            );
        }
        IERC721Collection(_tokenAddress).mintToken(_receiver);
    }

    function assignNFT(IERC721Collection _tokenAddress, address[] calldata destinations) external isOwner(_tokenAddress) {
        IERC721Collection erc721Contract = IERC721Collection(_tokenAddress);
        require(erc721Contract.tokenSupply() + destinations.length > erc721Contract.tokenMinted(), "Limit Reached");
        for(uint256 i = 0; i < destinations.length; i++){
            erc721Contract.mintToken(destinations[i]);
        }
    }

    function withdrawNativeFund(IERC721Collection _tokenAddress, address _destination)
        external
        isOwner(_tokenAddress)
        nonReentrant
        returns (bool)
    {
        uint256 balance = getNativeBalance();
        require(balance > 0, "Zero balance");
        (bool success, ) = _destination.call{value: balance}("");
        return success;
    }

    function withdrawERC20Fund(IERC721Collection _tokenAddress, address _destination, address _erc20Token)
        external
        isOwner(_tokenAddress)
        nonReentrant
    {
        uint balance = getERC20TokenBalance(_tokenAddress, _erc20Token);
        require(balance > 0, "Zero balance");
        CreatorBalanceDetails storage _creatorBalanceDetails = creatorBalanceDetails[collectionOwner(_tokenAddress)][_tokenAddress];
        // AcceptableERC20 storage _erc20Details = getERC20BalanceDetails(_tokenAddress, _erc20Token);
        for(uint i = 0; i < _creatorBalanceDetails.acceptableERC20.length; i++){
            if(_creatorBalanceDetails.acceptableERC20[i].erc20Token == _erc20Token){
                _creatorBalanceDetails.acceptableERC20[i].tokenInERC20 = 0;
                break;
            }
        }
        if(_creatorBalanceDetails.nativeTokenWrapper == _erc20Token) {
            _creatorBalanceDetails.tokenWrapperBalance = 0;
        }
        CurrencyTransferLib.withdrawContractBalance(
            _erc20Token,
            _destination,
            balance
        );
    }

    function getERC20TokenBalance(IERC721Collection _tokenAddress, address _erc20Token) public view returns (uint256 erc20Balance) {
        CreatorBalanceDetails memory _creatorBalanceDetails = creatorBalanceDetails[collectionOwner(_tokenAddress)][_tokenAddress];
        if(_creatorBalanceDetails.nativeTokenWrapper == _erc20Token) {
           erc20Balance = _creatorBalanceDetails.tokenWrapperBalance;
        } 
        else {
            AcceptableERC20 memory _erc20Details = getERC20BalanceDetails(_tokenAddress, _erc20Token);
            erc20Balance = _erc20Details.tokenInERC20;
        }
    }

    function getERC20BalanceDetails(IERC721Collection _tokenAddress, address _erc20Token) public view returns(AcceptableERC20 memory _erc20Details){
        CreatorBalanceDetails memory _creatorBalanceDetails = creatorBalanceDetails[collectionOwner(_tokenAddress)][_tokenAddress];
        AcceptableERC20[] memory _acceptableERC20 = _creatorBalanceDetails.acceptableERC20;
        for(uint i = 0; i < _acceptableERC20.length; i++){
            if(_acceptableERC20[i].erc20Token == _erc20Token){
                _erc20Details = _acceptableERC20[i];
                break;
            }
        }
    }

    function getNativeBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function collectionOwner(IERC721Collection _tokenAddress) private view returns(address _owner) {
        return IERC721Collection(_tokenAddress).owner();
    }

    function _isOwner(IERC721Collection _tokenAddress) private view {
        require(collectionOwner(_tokenAddress) == msg.sender, "Only owner allowed");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Helper interfaces
import {IWETH} from "../interfaces/IWETH.sol";

import "../openzeppelin-presets/SafeERC20.sol";

library CurrencyTransferLib {
    using SafeERC20 for IERC20;

    /// @dev Transfer `amount` of ERC20 token from `from` to `to`.
    function safeTransferERC20(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_from == _to) {
            return;
        }

        if (_from == address(this)) {
            IERC20(_currency).safeTransfer(_to, _amount);
        } else {
            IERC20(_currency).safeTransferFrom(_from, _to, _amount);
        }
    }

    function transferAmountWithWrapper(
        address _currency,
        address _from,
        address _to,
        uint256 _amount,
        address _nativeTokenWrapper
    ) internal {
        if (msg.value > 0) {
            require(_amount == msg.value, "msg.value != amount");
            IWETH(_nativeTokenWrapper).deposit{value: _amount}();
            IERC20(_nativeTokenWrapper).safeTransfer(_to, _amount);
        } else {
            safeTransferERC20(_currency, _from, _to, _amount);
        }
    }

    function withdrawContractBalance(address _erc20Token, address _destination, uint256 _amount)
        internal
    {
        IERC20(_erc20Token).safeTransfer(_destination, _amount);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IERC721Collection {
    function mintToken(address _receiver) external;
    function hasRole(bytes32 role, address account) external returns (bool);
    function owner() external view returns(address);
    function tokenSupply() external view returns (uint);
    function tokenMinted() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../lib/TWAddress.sol";

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
    using TWAddress for address;

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library TWAddress {
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

        (bool success, ) = recipient.call{ value: amount }("");
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

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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