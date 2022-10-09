// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {BaseSlothyVault} from "./BaseSlothyVault.sol";
import {SlothyHelpers} from "./helpers/SlothyHelpers.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";
contract SlothyVaultFactory is Ownable, SlothyHelpers {
    bool public deprecated;

    // address to strategy mapping
    mapping(address => address) userToVault;

    constructor() {
        deprecated = false;
    }

    function newVault(
        address _startingToken,
        uint256 _startingTokenAmount,
        address[] memory _supportedTokens,
        Approval[] memory _approvals,
        Action[] memory _beforeLoop,
        Action[] memory _loop,
        uint256 _waitTime
    ) public {
        require(
            userToVault[msg.sender] == address(0),
            "Vault for this user already exists."
        );

        userToVault[msg.sender] = address(
            new BaseSlothyVault(
                _startingToken,
                _startingTokenAmount,
                _supportedTokens,
                _approvals,
                _beforeLoop,
                _loop,
                _waitTime
            )
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISlothyBlock} from "./interfaces/ISlothyBlock.sol";
import {SlothyHelpers} from "./helpers/SlothyHelpers.sol";

contract BaseSlothyVault is Ownable, SlothyHelpers {
    bool public active;

    address public startingToken;
    uint256 public startingTokenAmount;

    address[] public supportedTokens;

    Action[] public beforeLoop;

    Action[] public loop;

    uint256 public waitTime;

    uint256 public lastRun;

    constructor(
        address _startingToken,
        uint256 _startingTokenAmount,
        address[] memory _supportedTokens,
        Approval[] memory _approvals,
        Action[] memory _beforeLoop,
        Action[] memory _loop,
        uint256 _waitTime
    ) {
        startingToken = _startingToken;
        startingTokenAmount = _startingTokenAmount;
        supportedTokens = _supportedTokens;

        for (uint256 i = 0; i < _approvals.length; i++) {
            IERC20(_approvals[i].token).approve(
                _approvals[i].spender,
                _approvals[i].amount
            );
        }

        for (uint256 i = 0; i < _beforeLoop.length; i++) {
            beforeLoop.push(_beforeLoop[i]);
        }

        for (uint256 i = 0; i < _loop.length; i++) {
            loop.push(_loop[i]);
        }

        waitTime = _waitTime;

        lastRun = block.timestamp;
    }

    function setUp() public {
        require(!active, "Already set up");
        active = true;

        IERC20(startingToken).transferFrom(
            msg.sender,
            address(this),
            startingTokenAmount
        );

        for (uint256 i = 0; i < beforeLoop.length; i++) {
            ISlothyBlock(beforeLoop[i].target).run(beforeLoop[i].data);
        }
    }

    function runLoop() public onlyActiveLoop {
        for (uint256 i = 0; i < loop.length; i++) {
            ISlothyBlock(loop[i].target).run(loop[i].data);
        }

        lastRun = block.timestamp;
    }

    function emergencyWithdrawETH(uint256 _amount) public onlyOwner {
        payable(msg.sender).transfer(_amount);
    }

    function emergencyWithdrawERC20Multiple(address[] memory _tokens)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20(_tokens[i]).transfer(
                msg.sender,
                IERC20(_tokens[i]).balanceOf(address(this))
            );
        }
    }

    function stop() public onlyOwner {
        active = false;
        for (uint256 i = 0; i < supportedTokens.length; i++) {
            IERC20(supportedTokens[i]).transfer(
                msg.sender,
                IERC20(supportedTokens[i]).balanceOf(address(this))
            );
        }
    }

    function toggleActive() external onlyOwner {
        active = !active;
    }

    modifier onlyActiveLoop() {
        require(active, "Vault is not active");
        require(block.timestamp >= lastRun + waitTime, "Cannot run loop yet");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract SlothyHelpers {
    struct Approval {
        address token;
        address spender;
        uint256 amount;
    }

    struct Action {
        address target;
        bytes32[] data;
    }

    function argToAddress(bytes32 _arg)
        external
        pure
        returns (address _address)
    {
        _address = address(uint160(uint256(_arg)));
    }

    function argToUint256(bytes32 _arg)
        external
        pure
        returns (uint256 _uint256)
    {
        _uint256 = uint256(_arg);
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
pragma solidity ^0.8.9;

interface ISlothyBlock {
    function run(bytes32[] memory _args) external returns (bool _success);

    function requestERC20Approval(address _token, uint256 _amount) external;
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