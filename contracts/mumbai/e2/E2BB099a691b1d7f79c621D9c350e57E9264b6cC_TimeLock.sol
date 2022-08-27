// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract TimeLock is ERC2771Context, ReentrancyGuard, Ownable {
    uint256 public timelockPeriod;

    struct depositDetails {
        uint256 amount;
        uint256 timelocked;
    }

    struct withdrawVoucher {
        address user;
        address token;
        uint256 amount;
        bytes signature;
    }

    mapping(address => bool) public supportedTokens;
    // User -> Token -> {Amount, Timelock}
    mapping(address => mapping(address => depositDetails)) public depositData;

    event depositStatus(address token, uint256 amount, uint256 timelocked);

    event withdrawStatus(address token, uint256 amount);

    modifier checkTrustedForwarder() {
        require(
            isTrustedForwarder(msg.sender),
            "Timelock: Not a trusted forwarder"
        );
        _;
    }

    modifier checkSupportedTokens(address _token) {
        require(
            supportedTokens[_token],
            "Timelock: Token Address currently not supported"
        );
        _;
    }

    constructor(
        uint256 _timelockPeriod,
        address _tokenAddress,
        address _trustedForwarder
    ) ERC2771Context(_trustedForwarder) {
        require(
            IERC20(_tokenAddress).totalSupply() > 0,
            "Not a valid ERC20 address"
        );
        require(
            _timelockPeriod > 10,
            "Timelock should be greater than 10 seconds"
        );
        timelockPeriod = _timelockPeriod;
        supportedTokens[_tokenAddress] = true;
    }

    /* 
    *****************************
            FUNCTIONALITY                
    *****************************
    */
    function depositERC20(address _token, uint256 _amount)
        public
        checkSupportedTokens(_token)
    {
        require(
            IERC20(_token).balanceOf(_msgSender()) >= _amount,
            "TimeLock -> ERC20: User balance insufficient"
        );
        require(
            IERC20(_token).allowance(_msgSender(), address(this)) >= _amount,
            "TimeLock -> ERC20: Allowance insufficient"
        );

        IERC20(_token).transferFrom(_msgSender(), address(this), _amount);
        depositDetails storage currentDeposit = depositData[_msgSender()][
            _token
        ];
        depositData[_msgSender()][_token] = depositDetails(
            currentDeposit.amount + _amount,
            block.timestamp + timelockPeriod
        );
        emit depositStatus(
            _token,
            depositData[_msgSender()][_token].amount,
            depositData[_msgSender()][_token].timelocked
        );
    }

    function depositEther() public payable {
        depositDetails storage currentDeposit = depositData[_msgSender()][
            address(0)
        ];
        depositData[_msgSender()][address(0)] = depositDetails(
            currentDeposit.amount + msg.value,
            block.timestamp + timelockPeriod
        );
        emit depositStatus(
            address(0),
            depositData[_msgSender()][address(0)].amount,
            depositData[_msgSender()][address(0)].timelocked
        );
    }

    fallback() external payable {
        depositEther();
    }

    receive() external payable {
        depositEther();
    }

    function withdrawERC20Direct(address _token, uint256 _amount)
        public
        checkSupportedTokens(_token)
    {
        require(
            IERC20(_token).balanceOf(address(this)) >= _amount,
            "TimeLock -> ERC20: Contract balance insufficient"
        );

        depositDetails storage currentDeposit = depositData[_msgSender()][
            _token
        ];
        require(
            currentDeposit.amount >= _amount,
            "TimeLock: Withdraw request greater than deposit amount"
        );
        require(
            currentDeposit.timelocked < block.timestamp,
            "TimeLock: Tokens currently under timelock period"
        );

        depositData[_msgSender()][_token] = depositDetails(
            currentDeposit.amount - _amount,
            block.timestamp - 1
        );

        IERC20(_token).transfer(_msgSender(), _amount);
        emit withdrawStatus(
            _token,
            depositData[_msgSender()][address(0)].amount
        );
    }

    function withdrawEtherDirect(uint256 _amount) public {
        require(
            address(this).balance >= _amount,
            "TimeLock: Contract balance insufficient"
        );

        depositDetails storage currentDeposit = depositData[_msgSender()][
            address(0)
        ];
        require(
            currentDeposit.amount >= _amount,
            "TimeLock: Withdraw request greater than deposit amount"
        );
        require(
            currentDeposit.timelocked < block.timestamp,
            "TimeLock: Ether currently under timelock period"
        );

        depositData[_msgSender()][address(0)] = depositDetails(
            currentDeposit.amount - _amount,
            block.timestamp - 1
        );
        (bool sent, bytes memory data) = _msgSender().call{value: _amount}("");
        require(sent, "TimeLock: Ether transfer failed");
        emit withdrawStatus(
            address(0),
            depositData[_msgSender()][address(0)].amount
        );
    }

    function withdrawWithVoucher(withdrawVoucher calldata _voucher) public {
        require(verify(_voucher), "Timelock: Voucher not signed by user");
        if (_voucher.token == address(0)) {
            require(
                address(this).balance >= _voucher.amount,
                "TimeLock: Contract balance insufficient"
            );

            depositDetails storage currentDeposit = depositData[_voucher.user][
                address(0)
            ];
            require(
                currentDeposit.amount >= _voucher.amount,
                "TimeLock: Withdraw request greater than deposit amount"
            );
            require(
                currentDeposit.timelocked < block.timestamp,
                "TimeLock: Ether currently under timelock period"
            );

            depositData[_voucher.user][address(0)] = depositDetails(
                currentDeposit.amount - _voucher.amount,
                block.timestamp - 1
            );
            (bool sent, bytes memory data) = _voucher.user.call{
                value: _voucher.amount
            }("");
            require(sent, "TimeLock: Ether transfer failed");
            emit withdrawStatus(
                address(0),
                depositData[_voucher.user][address(0)].amount
            );
        } else {
            require(
                IERC20(_voucher.token).balanceOf(address(this)) >=
                    _voucher.amount,
                "TimeLock -> ERC20: Contract balance insufficient"
            );

            depositDetails storage currentDeposit = depositData[_voucher.user][
                _voucher.token
            ];
            require(
                currentDeposit.amount >= _voucher.amount,
                "TimeLock: Withdraw request greater than deposit amount"
            );
            require(
                currentDeposit.timelocked < block.timestamp,
                "TimeLock: Tokens currently under timelock period"
            );

            depositData[_voucher.user][_voucher.token] = depositDetails(
                currentDeposit.amount - _voucher.amount,
                block.timestamp - 1
            );

            IERC20(_voucher.token).transfer(_voucher.user, _voucher.amount);
            emit withdrawStatus(
                _voucher.token,
                depositData[_voucher.user][address(0)].amount
            );
        }
    }

    /* 
    ***********************
            GETTERS        
    ***********************
    */

    function getEtherBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getVoucherHash(withdrawVoucher calldata _voucher)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(_voucher.user, _voucher.token, _voucher.amount)
            );
    }

    /* 
    ****************************
            OWNERS ONLY         
    ****************************
    */

    function editTimelockPeriod(uint256 _timelockPeriod) public onlyOwner {
        timelockPeriod = _timelockPeriod;
    }

    function addNewToken(address _tokenAddress) public onlyOwner {
        require(
            IERC20(_tokenAddress).totalSupply() > 0,
            "TimeLock: Not a valid ERC20 address"
        );
        require(
            !supportedTokens[_tokenAddress],
            "TimeLock: Token already supported"
        );
        supportedTokens[_tokenAddress] = true;
    }

    function removeTokenSupport(address _tokenAddress) public onlyOwner {
        require(
            supportedTokens[_tokenAddress],
            "TimeLock: Token was not supported"
        );
        supportedTokens[_tokenAddress] = false;
    }

    /* 
    ********************************
            UTILS & INTERNALS       
    ********************************
    */

    function verify(withdrawVoucher calldata _voucher)
        public
        pure
        returns (bool)
    {
        bytes32 messageHash = getVoucherHash(_voucher);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return
            recoverSigner(ethSignedMessageHash, _voucher.signature) ==
            _voucher.user;
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    /* 
    **********************************
            INTERNAL OVERRIDES                 
    **********************************
    */

    function _msgSender()
        internal
        view
        virtual
        override(Context, ERC2771Context)
        returns (address sender)
    {
        return super._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        return super._msgData();
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
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