// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRoleContract {
    
    function getRoleNumber(address _user) external view returns (uint256);

    function getAmounts(address _user) external view returns (uint256, uint256);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./interfaces/IRoleContract.sol";
import "./TransferHelper.sol";

contract InvestPool is Ownable {

    // =================================
    // Storage
    // =================================

    IRoleContract public immutable rolesContract;
    address public immutable LPtoken;
    address public immutable paymentToken;
    uint8 private immutable paymentTokenDecimals;
    address public immutable fundrisingWallet;

    uint256 public baseFee;
    uint256 public price;

    uint256 public maxAmountToSell;
    uint256 public alreadySold;
    uint256 public totalPaymentTokenSpended;
    uint256 public totalLPDeposited;

    mapping(address => uint256) public alreadyBought;

    struct RoleSettings {
        uint256 startTime;
        uint256 deadline;
        uint256 roleFee;
        uint256 maxAmountToSellForRole;
        uint256 soldAmountForThisRole;
        uint256 totalAmountOfPaymentTokenSpended;
    }

    mapping(uint256 => RoleSettings) public roleSettings;

    struct RoleSettingsSetter {
        uint256 roleNumber;
        uint256 startTime;
        uint256 deadline;
        uint256 roleFee;
        uint256 maxAmountToSellForRole;
    }

    address public manager;

    // =================================
    // Modifier
    // =================================

    modifier onlyManager() {
        require(msg.sender == manager || msg.sender == owner(), "OM");
        _;
    }

    // =================================
    // Events
    // =================================

    event RoleSettingsChanged(uint256 roleNumber, uint256 startTime, uint256 deadline, uint256 roleFee, uint256 maxAmountToSellForRole);
    event Purchase(address user, uint256 amount);

    // =================================
    // Constructor
    // =================================

    constructor(
        address _LPtoken,
        address _rolesContract,
        address _paymentToken,
        address _fundrisingWallet,
        uint256 _baseFee,
        uint256 _price,
        uint256 _maxAmountToSell,
        address _manager,
        RoleSettingsSetter[] memory _roleSettings
    ) {
        require(_baseFee <= 1000, "FTH");

        LPtoken = _LPtoken;
        rolesContract = IRoleContract(_rolesContract);
        paymentToken = _paymentToken;
        paymentTokenDecimals = IERC20Metadata(_paymentToken).decimals();
        fundrisingWallet = _fundrisingWallet;

        baseFee = _baseFee;
        price = _price;
        maxAmountToSell = _maxAmountToSell;
        manager = _manager;

        setRoleSettings(_roleSettings);
    }

    // =================================
    // Functions
    // =================================

    function buy(uint256 paymentTokenAmount) external {

        uint256 userRoleNum = rolesContract.getRoleNumber(msg.sender);
        (uint256 minAmountForRole, uint256 maxAmountForRole) = rolesContract.getAmounts(msg.sender);

        RoleSettings storage userRole = roleSettings[userRoleNum];

        uint256 afterFeesPaymentTokenAmount = paymentTokenAmount * (1000 - 
            (userRole.roleFee == 0 ? baseFee : userRole.roleFee)
            ) / 1000;

        uint256 tokenAmount = afterFeesPaymentTokenAmount * (10 ** (20 - paymentTokenDecimals)) / price;
        
        require(afterFeesPaymentTokenAmount >= minAmountForRole && alreadyBought[msg.sender] + afterFeesPaymentTokenAmount <= maxAmountForRole, "IA");
        require(block.timestamp >= userRole.startTime && block.timestamp <= userRole.deadline, "TE");
        require(userRole.soldAmountForThisRole + tokenAmount <= userRole.maxAmountToSellForRole, "RR");
        require(alreadySold + tokenAmount <= maxAmountToSell, "LT");

        TransferHelper.safeTransferFrom(paymentToken, msg.sender, fundrisingWallet, paymentTokenAmount);

        alreadyBought[msg.sender] += afterFeesPaymentTokenAmount;
        userRole.soldAmountForThisRole += tokenAmount;
        alreadySold += tokenAmount;
        totalPaymentTokenSpended += paymentTokenAmount;
        userRole.totalAmountOfPaymentTokenSpended += paymentTokenAmount;

        TransferHelper.safeTransfer(LPtoken, msg.sender, tokenAmount);

        emit Purchase(msg.sender, tokenAmount);
    }

    // =================================
    // Admin functions
    // =================================

    function setMaxAmountToSell(uint256 _maxAmountToSell) external onlyManager {
        maxAmountToSell = _maxAmountToSell;
    }

    function setRoleSettings(
        RoleSettingsSetter[] memory _roleSettings
    ) public onlyManager {
        for (uint256 i = 0; i < _roleSettings.length; i++) {
            roleSettings[_roleSettings[i].roleNumber].startTime = _roleSettings[i].startTime;
            roleSettings[_roleSettings[i].roleNumber].deadline = _roleSettings[i].deadline;
            roleSettings[_roleSettings[i].roleNumber].roleFee = _roleSettings[i].roleFee;
            roleSettings[_roleSettings[i].roleNumber].maxAmountToSellForRole = _roleSettings[i].maxAmountToSellForRole;
            emit RoleSettingsChanged(
                _roleSettings[i].roleNumber,
                _roleSettings[i].startTime,
                _roleSettings[i].deadline,
                _roleSettings[i].roleFee,
                _roleSettings[i].maxAmountToSellForRole
            );
        }
    }

    function setRoleSetting(
        RoleSettingsSetter memory _rolesSetting
    ) external onlyManager {
        roleSettings[_rolesSetting.roleNumber].startTime = _rolesSetting.startTime;
        roleSettings[_rolesSetting.roleNumber].deadline = _rolesSetting.deadline;
        roleSettings[_rolesSetting.roleNumber].roleFee = _rolesSetting.roleFee;
        roleSettings[_rolesSetting.roleNumber].maxAmountToSellForRole = _rolesSetting.maxAmountToSellForRole;
        emit RoleSettingsChanged(
            _rolesSetting.roleNumber,
            _rolesSetting.startTime, 
            _rolesSetting.deadline,
            _rolesSetting.roleFee,
            _rolesSetting.maxAmountToSellForRole
        );
    }

    function setPrice(uint256 _price) external onlyManager {
        price = _price;
    }

    function setBaseFee(uint256 _baseFee) external onlyManager {
        require(_baseFee <= 1000, "FTH");
        baseFee = _baseFee;
    }

    function updateSettings(
        RoleSettingsSetter[] memory _roleSettings,
        uint256 _price,
        uint256 _baseFee,
        uint256 _maxAmountToSell
    ) external onlyManager {
        setRoleSettings(_roleSettings);
        price = _price;
        baseFee = _baseFee;
        maxAmountToSell = _maxAmountToSell;
    }

    function depositLPtoken(uint256 _amount) external onlyManager {
        TransferHelper.safeTransferFrom(LPtoken, msg.sender, address(this), _amount);
        totalLPDeposited += _amount;
    }

    function withdrawLPtoken(address _to, uint256 _amount) external onlyManager {
        TransferHelper.safeTransfer(LPtoken, _to, _amount);
        if (totalLPDeposited >= _amount) {
            totalLPDeposited -= _amount;
        } else {
            totalLPDeposited = 0;
        }
    }

    function setManager(address _manager) external onlyOwner {
        manager = _manager;
    }

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TransferHelper {

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TF');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }

    function safeGetDecimals(
        address token
    ) internal returns (uint8) {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature("decimals()")
        );
        require(success && data.length != 0, 'TF');
        return abi.decode(data, (uint8));
    }

}