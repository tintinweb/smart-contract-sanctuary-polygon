// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./impl/Admin.sol";
import "./lib/SafeERC20.sol";

contract Wex is Admin {
    using SafeERC20 for IERC20;

    address[] public lps;

    event DepositedEx(string receiverId, uint256 amount);
    event WithdrewEx(address receiver, uint256 amount, string transactionId);
    event DepositedLP(string receiverId, uint256 amount);
    event WithdrewLP(address receiver, uint256 amount, string transactionId);

    function depositEx(string calldata receiverId, uint256 amount) external notClosed {
        require(amount > 0, "Wrong amount");

        uint256 allowance = IERC20(baseToken).allowance(msg.sender, address(this));
        require(allowance >= amount, "Check allowance");
        IERC20(baseToken).safeTransferFrom(msg.sender, address(this), amount);

        _poolSize += amount;
        emit DepositedEx(receiverId, amount);
    }

    function withdrawEx(
        address receiver,
        uint256 amount,
        string calldata transactionId
    ) external notClosed onlySupervisor {
        require(amount > 0, "Wrong amount");
        require(amount <= _poolSize, "Amount greater than pool size");

        uint256 fee = (amount * feePercentage) / 10000;
        uint256 lpFee = (amount * lpFeePercentage) / 10000;
        IERC20(baseToken).safeTransfer(receiver, amount - fee - lpFee);
        _poolSize = _poolSize - amount - fee + lpFee;

        if (fee > 0) {
            _serviceFee += fee;
            IERC20(baseToken).safeTransfer(feeCollector, fee);
            emit FeeCollected(receiver, feeCollector, fee);
        }

        if (lpFee > 0) {
            for (uint256 i = 0; i < lps.length; i++) {
                _lpBalances[lps[i]] += (lpFee * _lpBalances[lps[i]]) / _poolSize;
            }
            emit LPFeeCollected(receiver, feeCollector, lpFee);
        }

        emit WithdrewEx(receiver, amount, transactionId);
    }

    function depositLP(string calldata receiverId, uint256 amount) external notClosed {
        require(amount > 0, "Wrong amount");
        uint256 allowance = IERC20(baseToken).allowance(msg.sender, address(this));
        require(allowance >= amount, "Check allowance");

        if (_lpBalances[msg.sender] == 0) {
            lps.push(msg.sender);
        }
        _lpBalances[msg.sender] += amount;
        _poolSize += amount;
        IERC20(baseToken).safeTransferFrom(msg.sender, address(this), amount);
        emit DepositedLP(receiverId, amount);
    }

    function withdrawLP(
        address receiver,
        uint256 amount,
        string calldata transactionId
    ) external notClosed {
        require(amount > 0, "Wrong amount");
        require(amount <= _lpBalances[msg.sender], "Amount greater than balance");

        _poolSize -= amount;
        _lpBalances[msg.sender] -= amount;
        if (_lpBalances[msg.sender] == 0) {
            for (uint256 i = 0; i <= lps.length - 1; i++) {
                if (lps[i] == msg.sender) {
                    lps[i] = lps[lps.length - 1];
                    lps.pop();
                    break;
                }
            }
        }
        IERC20(baseToken).safeTransfer(receiver, amount);
        emit WithdrewLP(receiver, amount, transactionId);
    }

    function poolSize() external view returns (uint256) {
        return _poolSize;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _lpBalances[account];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../lib/SafeERC20.sol";
import "../interfaces/IERC20.sol";

contract Admin is Ownable {
    using SafeERC20 for IERC20;
    bool public closed;
    address public baseToken;
    address public feeCollector;
    uint256 public feePercentage;
    uint256 public lpFeePercentage;
    uint256 internal _serviceFee;
    address internal _supervisor;
    uint256 internal _poolSize;
    mapping(address => uint256) internal _lpBalances;

    event SetBaseToken(address newBaseToken);
    event SetSupervisor(address newSupervisor);
    event FeeCollected(address indexed from, address indexed to, uint256 value);
    event LPFeeCollected(address indexed from, address indexed to, uint256 value);
    event Closed();
    event Opened();

    modifier notClosed() {
        require(!closed, "CLOSED");
        _;
    }

    modifier onlySupervisor() {
        require(msg.sender == _supervisor, "NOT_SUPERVISOR");
        _;
    }

    function setSupervisor(address newSupervisor) external onlyOwner {
        _supervisor = newSupervisor;
        emit SetSupervisor(newSupervisor);
    }

    function setbaseToken(address newBaseToken) external onlyOwner {
        baseToken = newBaseToken;
        emit SetBaseToken(newBaseToken);
    }

    function setFeePercentage(uint256 _newFee) external onlyOwner {
        require(_newFee >= 0 && _newFee <= 10000, "Fee is invalid");
        feePercentage = _newFee;
    }

    function setLPFeePercentage(uint256 _newFee) external onlyOwner {
        require(_newFee >= 0 && _newFee <= 10000, "Fee is invalid");
        lpFeePercentage = _newFee;
    }

    function close() external onlyOwner {
        closed = true;
        emit Closed();
    }

    function open() external onlyOwner {
        closed = false;
        emit Opened();
    }

    function claimFees() external onlyOwner {
        IERC20(baseToken).safeTransfer(msg.sender, _serviceFee);
        _poolSize -= _serviceFee;
        _serviceFee = 0;
    }

    function serviceFee() external view onlyOwner returns (uint256) {
        return _serviceFee;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../interfaces/IERC20.sol";

library SafeERC20 {
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
            );
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: did not succeed");
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
pragma solidity 0.8.13;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
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