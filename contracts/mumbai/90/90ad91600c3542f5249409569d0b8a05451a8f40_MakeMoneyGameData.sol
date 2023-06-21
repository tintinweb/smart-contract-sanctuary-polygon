/**
 *Submitted for verification at polygonscan.com on 2023-06-20
*/

// Sources flattened with hardhat v2.15.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/IGameData.sol

pragma solidity >=0.4.22 <0.9.0;

struct PlayerData {
    // 玩家数据
    uint256 gameCount; // 游戏次数
    uint256 gameLevel; // 游戏等级
    uint256 casinoCount; // 赌场次数
    uint256 dataVersion; // 数据版本
}

interface GameDataInterface {
    // 游戏玩家数据接口
    function incrGameCount(address player, uint256 dataVersion) external;

    function incrGameLevel(address player, uint256 dataVersion) external;

    function incrCasinoCount(address player, uint256 dataVersion) external;

    function transferCoin(address to, uint256 amount) external;

    function getPlayerData(
        address player
    ) external view returns (PlayerData memory);
}


// File contracts/MakeMoneyGameData.sol

pragma solidity >=0.4.22 <0.9.0;



/**
 * 这是一个游戏数据合约，用于记录玩家的游戏数据
 */
contract MakeMoneyGameData is Ownable {

    mapping(address => PlayerData) private playerData; // 玩家数据
    address public gameContract; // 游戏合约地址
    address public tokenContract; // 游戏代币合约地址

    modifier onlyGameContract() {
        // 限制只能游戏合约调用
        require(
            msg.sender == gameContract,
            "MakeMoneyGameData: caller is not the game contract"
        );
        _;
    }

    function setGameContract(address _gameContract) public onlyOwner {
        // 更新游戏合约地址 只有合约所有者可以调用
        gameContract = _gameContract;
    }

    function setTokenContract(address _tokenAddress) public onlyOwner {
        // 更新游戏代币合约地址 只有合约所有者可以调用
        tokenContract = _tokenAddress;
    }

    function getPlayerData(address player) public view returns (PlayerData memory) {
        // 获取玩家数据
        PlayerData memory data = playerData[player];
        return data;
    }

    function incrGameCount(address player, uint256 dataVersion) public onlyGameContract {
        // 增加玩家游戏次数
        require(
            playerData[player].dataVersion == dataVersion,
            "MakeMoneyGameData: data version error"
        );
        playerData[player].gameCount++;
        playerData[player].dataVersion++;
    }

    function incrGameLevel(
        address player,
        uint256 dataVersion
    ) public onlyGameContract {
        // 增加玩家游戏等级
        require(
            playerData[player].dataVersion == dataVersion,
            "MakeMoneyGameData: data version error"
        );
        playerData[player].gameLevel++;
        playerData[player].dataVersion++;
    }

    function incrCasinoCount(
        address player,
        uint256 dataVersion
    ) public onlyGameContract {
        // 增加玩家赌场次数
        require(
            playerData[player].dataVersion == dataVersion,
            "MakeMoneyGameData: data version error"
        );
        playerData[player].casinoCount++;
        playerData[player].dataVersion++;
    }

    function transferCoin(address to, uint256 amount) public onlyGameContract {
        // 转账
        IERC20(tokenContract).transfer(to, amount);
    }
}