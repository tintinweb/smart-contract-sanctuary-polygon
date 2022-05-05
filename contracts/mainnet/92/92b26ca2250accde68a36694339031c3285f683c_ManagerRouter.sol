/**
 *Submitted for verification at polygonscan.com on 2022-05-05
*/

// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File interfaces/IManagerRouter.sol

pragma solidity >=0.5.0;


interface IManagerRouter {
  function validate(address contractAddress)  external returns (bool);
  function getCommission(address contractAddress) external returns (uint32);
}


// File contracts/ManagerRouter.sol

pragma solidity ^0.8.0;
contract ManagerRouter is IManagerRouter, Ownable {
  struct Game {
    uint256 id;
    string name; // readable game name for dapp
    string icon; // link to the game icon for dapp
    bool isActive;
  }

  struct Router {
    uint256 id;
    string name; // readable server name for dapp
    string icon; // link to the server icon for dapp. If not, then you need to use the game icon 
    address adminAddress;
    address routerAddress;
    address marketplaceAddress;
    uint8 gameId;
    string host;
    bool isActive;
    bool isMarketplaceActive;
    uint32 commission;
    uint32 maxBalance;
    uint32 coefficient;
    bool isDynamicCoefficient;
  }
  
  Game[] private _games;
  Router[] private _routers;

  uint256 public gameCount = 0;
  uint256 public routersCount = 0;

  address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
  IERC20 private immutable _token;
  
  // Function to receive Ether. msg.data must be empty
  receive() external payable {}

  // Fallback function is called when msg.data is not empty
  fallback() external payable {}
  
  modifier onlyOwnerOrServerAdmin(uint32 routerId) {
    require(owner() == _msgSender() || _routers[routerId].adminAddress == _msgSender(), "-_-");
    _;
  }

  constructor(IERC20 token) {
    _token = token;
  }
  
  function addGame(string calldata name, string calldata icon, bool isActive) external onlyOwner {
    _games.push(
      Game(gameCount, name, icon, isActive)
    );
    gameCount += 1;
  }
  
  function setGameName(uint32 gameId, string calldata name) external onlyOwner { 
    _games[gameId].name = name;
  }
  
  function setGameIcon(uint32 gameId, string calldata icon) external onlyOwner {
    _games[gameId].icon = icon;
  }

  function setGameActive(uint32 gameId, bool value) external onlyOwner {
    _games[gameId].isActive = value;
  }

  function addRouter(Router memory router) external onlyOwner {
    _routers.push(
          Router(
            routersCount,
            router.name,
            router.icon,
            router.adminAddress,
            router.routerAddress,
            router.marketplaceAddress,
            router.gameId,
            router.host,
            router.isActive,
            router.isMarketplaceActive,
            router.commission,
            router.maxBalance,
            router.coefficient,
            router.isDynamicCoefficient
          )
      );
    routersCount += 1;
  }

  function setRouterName(uint32 routerId, string calldata name) external onlyOwner { 
    _routers[routerId].name = name;
  }

  function setRouterIcon(uint32 routerId, string calldata icon) external onlyOwner { 
    _routers[routerId].icon = icon;
  }

  function setRouterHost(uint32 routerId, string calldata host) external onlyOwner { 
    _routers[routerId].host = host;
  }

  function setRouterAdminAddress(uint32 routerId, address addr) external onlyOwner { 
    _routers[routerId].adminAddress = addr;
  }

  function setRouterAddress(uint32 routerId, address addr) external onlyOwner { 
    _routers[routerId].routerAddress = addr;
  }

  function setMarketplaceAddress(uint32 routerId, address addr) external onlyOwner { 
    _routers[routerId].marketplaceAddress = addr;
  }

  function setRouterActive(uint32 routerId, bool value) external onlyOwner {
    _routers[routerId].isActive = value;
  }

  function setMarketplaceActive(uint32 routerId, bool value) external onlyOwner {
    _routers[routerId].isMarketplaceActive = value;
  }

  function setRouterCommission(uint32 routerId, uint32 value) external onlyOwner {
    _routers[routerId].commission = value;
  }

  function setRouterMaxBalance(uint32 routerId, uint32 value) external onlyOwnerOrServerAdmin(routerId) {
    _routers[routerId].maxBalance = value;
  }

  function setRouterCoefficient(uint32 routerId, uint32 value) external onlyOwnerOrServerAdmin(routerId) {
    _routers[routerId].coefficient = value;
  }

  function setRouterIsDynamicCoefficient(uint32 routerId, bool value) external onlyOwnerOrServerAdmin(routerId) {
    _routers[routerId].isDynamicCoefficient = value;
  }

  function validate(address routerAddress) external override view returns (bool) {
    bool result = false;
    for(uint i = 0; i < _routers.length; i++) {
        if(_routers[i].routerAddress == routerAddress && _routers[i].isActive == true && _games[_routers[i].gameId].isActive == true) {
            result = true;
            break;
        }
    }
    return result;
  }

  
  function getCommission(address routerAddress) external override view returns (uint32) {
    uint32 result = 0;
    for(uint i = 0; i < _routers.length; i++) {
        if(_routers[i].routerAddress == routerAddress) {
            result = _routers[i].commission;
            break;
        }
    }
    return result;
  }

  function games(uint256 start, uint256 size) external view returns (Game[] memory) {
        Game[] memory arrGames = new Game[](size);

        uint256 end = start + size > gameCount ? gameCount : start + size;
        uint index = 0;
        for (uint256 i = start; i < end; i++) {
            Game storage game = _games[i];
            arrGames[index] = game;
            index++;
        }

        return arrGames;
    }
    

  function routers(uint256 start, uint256 size) external view returns (Router[] memory) {
        Router[] memory arrRouters = new Router[](size);

        uint256 end = start + size > routersCount ? routersCount : start + size;
        uint index = 0;
        for (uint256 i = start; i < end; i++) {
            Router storage router = _routers[i];
            arrRouters[index] = router;
            index++;
        }

        return arrRouters;
    }

}