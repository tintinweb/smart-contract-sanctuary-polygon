// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.16;

import "./core/AppCoreCell.sol";
import "./core/Vault.sol";

contract BlockVault is AppCoreCell, Vault {
    constructor(address core_) AppCoreCell("BlockAPI_BlockVault_V1", core_) Vault() {}

    function deposit(address depositContract_, uint256 depositAmount_, address target_) external payable {
        Vault._deposit(depositContract_, depositAmount_, target_);
    }
    // function transferFromVault(address target_, address depositContract_ ,uint256 amount_) public view {
    //     AppCoreCell.hasAccess(Role.TREASURY_MANAGER);

    //     if (Vault._deposit[address(this)][depositContract_] <= 0) {
    //         revert ErrDepositAmount(msg.sender, depositContract_, Vault._deposit[address(this)][depositContract_]);
    //     }

    //     if (amount_ <= 0) {
    //         revert ErrTransferAmount(msg.sender, depositContract_, amount_);
    //     }

    //     // IERC20 transferERC20 = IERC20(depositContract_);
    //     // _deposit[msg.sender][depositContract_] -= amount_;

    //     // // function transfer(address to, uint256 amount) external returns (bool);
    //     // require(transferERC20.balanceOf(address(this)) >= amount_);
    //     // require(transferERC20.allowance(address(this)), target_) >= amount_);
    //     // require(transferERC20.transferFrom(address(this), target_, amount_));
    // }
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.16;

import "../interface/Core.sol";
import "../interface/CoreCell.sol";
import "../lib/Role.sol";
import "../lib/Error.sol";

contract AppCoreCell is CoreCell {
    // --- EVENTS --- //
    event Paused(address pausedBy);
    event Unpaused(address unpausedBy);

    // --- ERRORS --- //
    error ContractPaused();
    error ContractNotPaused();

    // --- PROPERTIES --- //
    address immutable public coreAddress;

    string private _name;
    bool internal _paused;

    /**
     * @dev Contract constructor
     * Provide name for contract and address for Core smart contract
     */
    constructor(string memory name_, address core_) {
        coreAddress = core_;
        _paused = false;
        _name = name_;
    }

    modifier isNotPaused() {
        if (_paused == true)
            revert ContractPaused();

        _;
    }

    // --- PUBLIC METHODS --- //

    /**
     * @dev Returns the name of the contract.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns bool if contract is paused
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev pause
     * Can be called only via Core contract by one of owners
     */
    function pause() external override returns (bool) {
        if (msg.sender != coreAddress)
            revert Error.NotAuthorized(msg.sender);

        if (_paused != false)
            revert ContractPaused();

        _paused = true;

        emit Paused(msg.sender);

        return true;
    }

    /**
     * @dev unpause
     * Can be called only via Core contract by one of owners
     */
    function unpause() external override returns (bool) {
        if (msg.sender != coreAddress)
            revert Error.NotAuthorized(msg.sender);

        if (_paused != true)
            revert ContractNotPaused();

        _paused = false;

        emit Unpaused(msg.sender);

        return true;
    }

    // --- PRIVATE/INTERNAL METHODS --- //

    /**
     * @dev hasAccess
     * Checks if {msg.sender} has {role_} registered at Core contract
     * If not, will revert with Error.NotAuthorized(msg.sender);
     */
    function hasAccess(bytes32 role) internal view {
        Core core = Core(coreAddress);

        if (!core.hasAccess(role, msg.sender))
            revert Error.NotAuthorized(msg.sender);
    }
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vault {
    struct Depositor {
        address who;
    }

    struct Deposit {
        address token;
        uint256 amount;
    }

    mapping(address => Depositor) internal _depositors;
    mapping(address => uint256) internal _depositNative;
    mapping(address => mapping(address => uint256)) internal _userDeposit;

    error ErrDepositAmount(address who, address depositContract, uint256 amount);
    error ErrTransferAmount(address who, address depositContract, uint256 amount);

    event NewDepositNativeToken(address who, uint256 depositAmount, uint256 depositTotal, address target);
    event NewDeposit(address who, address depositContract, uint256 depositAmount, uint256 depositTotal, address target);

    function _deposit(address depositContract_, uint256 depositAmount_, address target_) internal {
        if (depositAmount_ <= 0) {
            revert ErrDepositAmount(msg.sender, depositContract_, depositAmount_);  
        }

        address target = msg.sender;
        if (target_ != address(0)) {
            target = target_;
        }

        IERC20 depositERC20 = IERC20(depositContract_);
        
        require(depositERC20.allowance(msg.sender, address(this)) >= depositAmount_, "Not enough allowance");
        require(depositERC20.balanceOf(msg.sender) >= depositAmount_, "Not enough balance");
        require(depositERC20.transferFrom(msg.sender, address(this), depositAmount_), "Unable to transfer");

        _userDeposit[target][depositContract_] += depositAmount_;
        _depositNativeToken(msg.value);

        if (msg.value > 0) {
            emit NewDepositNativeToken(msg.sender, msg.value, _depositNative[msg.sender], target_);
        }

        emit NewDeposit(msg.sender, depositContract_, depositAmount_, _userDeposit[msg.sender][depositContract_], target_);
    }

    function _depositNativeToken(uint256 value_) internal {
        if (value_ > 0) {
            _depositNative[msg.sender] += value_;
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.16;

interface CoreCell {
    function pause() external returns (bool);
    function unpause() external returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.16;

library Role {
    bytes32 public constant NONE = keccak256("");
    bytes32 public constant OWNER = keccak256("OWNER");
    bytes32 public constant TREASURY_MANAGER = keccak256("TREASURY_MANAGER");
    bytes32 public constant DEVELOPER_WALLET = keccak256("DEVELOPER_WALLET");

}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.16;

library Error {
    error NotAuthorized(address who);
    error AddressIsNotContract(address target);

    error ErrorCode(string code);

    string public constant NOT_AUTHORIZED = "NOT_AUTHORIZED";

    // function revert(string memory code_) public pure {
    //     revert ErrorCode(code_);
    // }
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.16;

interface Core {
    function getOwners() external view returns (address[] memory);
    function isOwner(address _address) external view returns (bool);
    function hasAccess(bytes32 role_, address who_) external view returns (bool);
    function grantRole(bytes32 role_, address who_) external;
    function revokeRole(bytes32 role_, address who_) external;
    function pauseContract(address contract_) external;
    function unpauseContract(address contract_) external;
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