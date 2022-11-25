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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract ExtensionWhiteList {
    event WhiteList(address[] account, bool status);
    error NoInWhiteList();

    mapping(address => bool) private _whiteList;

    modifier isWhiteListM(address account) {
        if (!_isWhiteList(msg.sender)) {
            revert NoInWhiteList();
        }
        _;
    }

    function _includeAccountInWL(address account) internal {
        _whiteList[account] = true;
    }

    function _excludeAccountInWL(address account) internal {
        _whiteList[account] = false;
    }

    function _isWhiteList(address account) internal view returns (bool) {
        return (_whiteList[account]);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

abstract contract VestingAbstract {
    struct BasicInfo {
        uint32 tge;
        uint32 epochDuration;
        uint32 numberOfEpochs;
        uint32 epochCliff;
        uint128 TGEPercent;
        uint96 percentageInEpoch;
        address token;
    }

    uint128 public constant PRECISION = 1E24;

    BasicInfo internal _basicInfo;

    constructor(
        uint32 tge,
        uint128 TGEPercent,
        uint32 numberOfEpochs,
        uint32 epochDuration,
        uint32 epochCliff,
        address token
    ) {
        _basicInfo.token = token;
        _basicInfo.tge = tge;
        _basicInfo.TGEPercent = TGEPercent;
        _basicInfo.numberOfEpochs = numberOfEpochs;
        _basicInfo.epochDuration = epochDuration;
        _basicInfo.epochCliff = epochCliff * epochDuration;
        _basicInfo.percentageInEpoch = uint96(
            (100 * PRECISION - TGEPercent) / numberOfEpochs
        );
    }

    function _availableReward(uint256 amount)
        internal
        view
        virtual
        returns (uint256 reward)
    {
        return (_calcAvailablePercent() * amount) / (100 * PRECISION);
    }

    function _calcAvailablePercent()
        internal
        view
        returns (uint256 availablePercent)
    {
        uint256 currentTimestamp = block.timestamp;
        if (currentTimestamp >= _basicInfo.tge) {
            availablePercent += _basicInfo.TGEPercent;
            if (currentTimestamp >= _basicInfo.tge + _basicInfo.epochCliff) {
                uint256 epochs = (currentTimestamp -
                    _basicInfo.tge -
                    _basicInfo.epochCliff) / _basicInfo.epochDuration;
                if (_basicInfo.numberOfEpochs > epochs) {
                    availablePercent += epochs * _basicInfo.percentageInEpoch;
                } else {
                    return 100 * PRECISION;
                }
            }
        }
        return availablePercent;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/extension/VestingAbstract.sol";
import "contracts/extension/ExtensionWhiteList.sol";

contract Vesting is VestingAbstract, ExtensionWhiteList, Ownable {
    event Claim(address account, uint256 availableReward);
    /**
     * @param tokenDistribution - The amount of tokens to be distributed
     * @param amountReceived - The number of tokens that users have already received
     * @param availableReward - Available reward
     * @param availablePercent - vailable reward percentage
     */
    struct InfoVesting {
        uint128 tokenDistribution;
        uint128 amountReceived;
        uint128 availableReward;
        uint128 availablePercent;
    }
    /**
     * @dev - Stores information about the vesting
     */
    InfoVesting private _infoVesting;

    constructor(
        uint128 tokenDistribution,
        uint32 tge,
        uint128 TGEPercent,
        uint32 numberOfEpochs,
        uint32 epochCliff,
        address token,
        uint32 epochDuration
    )
        VestingAbstract(
            tge,
            TGEPercent,
            numberOfEpochs,
            epochDuration,
            epochCliff,
            token
        )
    {
        _infoVesting.tokenDistribution = tokenDistribution;
    }

    /**
     * @notice - Add an array of users to a whitelist
     */
    function includeAccountInWL(address account) external onlyOwner {
        _includeAccountInWL(account);
    }

    /**
     * @notice - Remove users from the whitelist
     */
    function excludeAccountInWL(address account) external onlyOwner {
        _excludeAccountInWL(account);
    }

    /**
     *  @notice - Withdraw liquidity from the contract.
     */
    function removeLiquidity(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    /**
     * @notice - sends the available reward to the user's address.
     */
    function claim() external isWhiteListM(msg.sender) {
        address msgSender = msg.sender;
        uint128 availableReward = _calcAvailableReward(
            _infoVesting.tokenDistribution
        );
        require(availableReward > 0, "ZeroAmount");
        _infoVesting.amountReceived += availableReward;

        IERC20(_basicInfo.token).transfer(msgSender, availableReward);

        emit Claim(msgSender, availableReward);
    }

    /**
     * @notice - Returns the available reward
     */
    function getAvailableReward()
        external
        view
        returns (uint256 availableReward)
    {
        availableReward = _calcAvailableReward(_infoVesting.tokenDistribution);
    }

    /**
     * @notice - Returns the available reward percentage
     */
    function getAvailablePercent()
        external
        view
        returns (uint256 availablePercent)
    {
        return _calcAvailablePercent();
    }

    /**
     * @notice - Returns information about the vesting
     * @return - structure BasicInfo
     */
    function getBasicInfo() external view returns (BasicInfo memory) {
        return _basicInfo;
    }

    /**
     * @notice - Returns information about the vesting
     * @return infoVesting - structure InfoVesting
     */
    function getVestingInfo()
        external
        view
        returns (InfoVesting memory infoVesting)
    {
        infoVesting.amountReceived = _infoVesting.amountReceived;
        infoVesting.tokenDistribution = _infoVesting.tokenDistribution;
        infoVesting.availablePercent = uint128(_calcAvailablePercent());
        infoVesting.availableReward = _calcAvailableReward(
            _infoVesting.tokenDistribution
        );
        return infoVesting;
    }

    /**
     * @dev - calculate the available reward
     */
    function _calcAvailableReward(uint256 amount)
        internal
        view
        returns (uint128 reward)
    {
        reward = uint128(
            _availableReward(amount) - _infoVesting.amountReceived
        );
    }
}