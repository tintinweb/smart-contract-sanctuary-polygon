// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDAI.sol";
import "./interfaces/IERC20OrderRouter.sol";
import "./interfaces/IGelatoPineCore.sol";

/// @title A Proxy for processing meta-transactions for Gelato
/// @author Mikhail Balashov
/// @notice For dev purposes only!
contract RelayProxy is Ownable {
    address public daiAddress;
    address public routerAddress;

    constructor(address _dai, address _router) {
        daiAddress = _dai;
        routerAddress = _router;

        IDAI(daiAddress).approve(routerAddress, type(uint256).max);
    }

    event Approved(
        address holder,
        uint256 expiry,
        bool allowed
    );

    event Deposited(
        address holder,
        uint256 amount,
        address module,
        address witness,
        bytes data,
        bytes32 secret
    );

    /// @dev makes approval of transfering tokens from user to RelayProxy
    /// Here we are using EIP-712 permit method
    function approve(
        address _holder,
        uint256 _nonce,
        uint256 _expiry,
        bool _allowed,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        require(_holder != address(0),
            'fn: deposit(), msg: approving zero address'
        );

        IDAI(daiAddress).permit(
            _holder,
            address(this),
            _nonce,
            _expiry,
            _allowed,
            _v,
            _r,
            _s
        );

        emit Approved(_holder, _expiry, _allowed);
    }

    /// @dev makes deposit from holder to RelayProxy and from RelayProxy to ERC20OrderRouter
    /// We have to make two transfers coz ERC20OrderRouter makes transfer only from msg.sender
    ///
    /// I used onlyOwner but it is the simplest way for Auth
    ///  Here we can improve the roles if needed
    ///
    /// can be implemented nonce's for transaction as "idempotency key"
    ///  to prevent executing transaction twice
    function deposit(
        address payable _holder,
        uint256 _amount,
        address _module,
        address _witness,
        bytes calldata _data,
        bytes32 _secret
    ) external onlyOwner {
        require(_amount > 0,
            'fn: deposit(), msg: amount should be more that zero'
        );
        require(
            IDAI(daiAddress).allowance(_holder, address(this)) >= _amount,
            'fn: deposit(), msg: not enough allowance to transfer money to RelayProxy'
        );
        require(_holder != address(0),
            'fn: deposit(), msg: transfer from zero address'
        );

        IDAI(daiAddress).transferFrom(_holder, address(this), _amount);

        IERC20OrderRouter(routerAddress).depositToken(
            _amount,
            _module,
            daiAddress,
            _holder,
            _witness,
            _data,
            _secret
        );

        emit Deposited(_holder, _amount, _module, _witness, _data, _secret);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IDAI {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function transferFrom(address from, address to, uint256 value) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20OrderRouter {
    function depositToken(
        uint256 _amount,
        address _module,
        address _inputToken,
        address payable _owner,
        address _witness,
        bytes calldata _data,
        bytes32 _secret
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IGelatoPineCore {
    function vaultOfOrder(
        address _module,
        address _inputToken,
        address payable _owner,
        address _witness,
        bytes calldata _data
    ) external view returns (address);

    function keyOf(
        address _module,
        address _inputToken,
        address payable _owner,
        address _witness,
        bytes calldata _data
    ) external pure returns (bytes32);
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