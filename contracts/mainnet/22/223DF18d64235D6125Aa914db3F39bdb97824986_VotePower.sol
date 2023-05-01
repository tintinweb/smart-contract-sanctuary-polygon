/**
 *Submitted for verification at polygonscan.com on 2023-05-01
*/

//SPDX-License-Identifier: MIT
// File: VOTING/interfaces/IFarmBooster.sol
pragma solidity ^0.8.0;

interface IFarmBooster {
  function proxyContract(address user) external view returns (address);
}
// File: VOTING/interfaces/ISmartChefInitializable.sol

pragma solidity ^0.8.0;

interface ISmartChefInitializable {
  function userInfo(address _user) external view returns (uint256, uint256);
}
// File: VOTING/interfaces/IBarPair.sol

pragma solidity ^0.8.0;

interface IBarPair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}
// File: VOTING/interfaces/IMasterChef.sol

pragma solidity ^0.8.0;

interface IMasterChef {
  function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
}
// File: VOTING/interfaces/IIFOPool.sol

pragma solidity ^0.8.0;

interface IIFOPool {
  function userInfo(address _user) external view returns (uint256, uint256, uint256, uint256);
  function getPricePerFullShare() external view returns (uint256);
}
// File: VOTING/interfaces/IBarFlexiblePool.sol

pragma solidity ^0.8.0;

interface IBarFlexiblePool {
  function userInfo(address _user) external view returns (uint256, uint256, uint256, uint256);
  function getPricePerFullShare() external view returns (uint256);
}
// File: VOTING/interfaces/IBarPool.sol

pragma solidity ^0.8.0;

interface IBarPool {
  function userInfo(address _user) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);
  function getPricePerFullShare() external view returns (uint256);
}
// File: VOTING/interfaces/IERC20.sol

pragma solidity ^0.8.0;

interface IERC20 {
  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);
}
// File: VOTING/contracts/utils/Context.sol


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
// File: VOTING/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// File: VOTING/VotePower.sol

pragma solidity ^0.8.0;

contract VotePower is Ownable {
    uint256 public DURATION_THRESHOLD = 2 weeks; // Default 2 week .
    uint256 public DURATION_BOOST_FACTOR = 1 weeks; // Defaul 1 week .
    address public constant BAR_TOKEN = 0x8EFC01AB566a6F9C7B78a4c82000A1181406a54A; // bar token.
    address public constant BAR_POOL = 0x24D3b138188D4545a3Cf602DC85bE0593AD5D97c; // bar pool.
    address public IFO_POOL = 0x24D3b138188D4545a3Cf602DC85bE0593AD5D97c; // ifo pool.
    address public constant MASTERCHEF = 0xDD55d16037Ec2d91335C41A1B3f8394d7240B538; // masterchef V2.
    address public constant BAR_LP = 0xB16117747642d38E32c8068c987E493D6eaF60f2; // bar lp.
    address public constant BAR_FLEXIBLE_POOL = 0x55c02DC0fb5FB74Cd7Bc932f2Ff927bA32243491; // bar flexible pool.
    address public FARM_BOOSTER;

    event NewIFOPool(address IFO_POOL);
    event NewFarmBooster(address FARM_BOOSTER);
    event NewDurationThreshold(uint256 DURATION_THRESHOLD);
    event NewDurationBoostFactor(uint256 DURATION_BOOST_FACTOR);

    constructor() {}

    /**
     * @notice Set IFO Contract address.
     * @dev Only callable by the contract owner.
     */
    function setIFOPool(address _IFO_POOL) external onlyOwner {
        require(_IFO_POOL != address(0), "Cannot be zero address");
        IFO_POOL = _IFO_POOL;
        emit NewIFOPool(IFO_POOL);
    }

    /**
     * @notice Set Farm Booster Contract address.
     * @dev Only callable by the contract owner.
     */
    function setFarmBooster(address _FARM_BOOSTER) external onlyOwner {
        require(_FARM_BOOSTER != address(0), "Cannot be zero address");
        FARM_BOOSTER = _FARM_BOOSTER;
        emit NewFarmBooster(_FARM_BOOSTER);
    }

    /**
     * @notice Set Duration Threshold.
     * @dev Only callable by the contract owner.
     */
    function setDurationThreshold(uint256 _DURATION_THRESHOLD) external onlyOwner {
        DURATION_THRESHOLD = _DURATION_THRESHOLD;
        emit NewDurationThreshold(_DURATION_THRESHOLD);
    }

    /**
     * @notice Set DURATION BOOST FACTOR.
     * @dev Only callable by the contract owner.
     */
    function setDurationBoostFactor(uint256 _DURATION_BOOST_FACTOR) external onlyOwner {
        require(_DURATION_BOOST_FACTOR > 0, "DURATION_BOOST_FACTOR must be greater than 0");
        DURATION_BOOST_FACTOR = _DURATION_BOOST_FACTOR;
        emit NewDurationBoostFactor(_DURATION_BOOST_FACTOR);
    }

    function getBarBalance(address _user) public view returns (uint256) {
        return IERC20(BAR_TOKEN).balanceOf(_user);
    }

    // Calculate the balance of the bar flexible pool.
    function getBarVaultBalance(address _user) public view returns (uint256) {
        uint256 balance;
        (uint256 shareForFlexiblePool, , , ) = IBarFlexiblePool(BAR_FLEXIBLE_POOL).userInfo(_user);
        uint256 barFlexiblePoolPricePerFullShare = IBarFlexiblePool(BAR_FLEXIBLE_POOL).getPricePerFullShare();
        if (shareForFlexiblePool > 0) {
            balance += (shareForFlexiblePool * barFlexiblePoolPricePerFullShare) / 1e18;
        }

        (uint256 share, , , , , , uint256 userBoostedShare, bool locked, ) = IBarPool(BAR_POOL).userInfo(_user);
        uint256 barPoolPricePerFullShare = IBarPool(BAR_POOL).getPricePerFullShare();
        if (!locked && share > 0) {
            balance += (share * barPoolPricePerFullShare) / 1e18 - userBoostedShare;
        }

        return balance;
    }

    function getIFOPoolBalancee(address _user) public view returns (uint256) {
        (uint256 share, , , ) = IIFOPool(IFO_POOL).userInfo(_user);
        uint256 ifoPoolPricePerFullShare = IIFOPool(IFO_POOL).getPricePerFullShare();
        return (share * ifoPoolPricePerFullShare) / 1e18;
    }

    function getBarPoolBalance(address _user) public view returns (uint256) {
        (
            uint256 share,
            ,
            ,
            ,
            uint256 lockStartTime,
            uint256 lockEndTime,
            uint256 userBoostedShare,
            bool locked,

        ) = IBarPool(BAR_POOL).userInfo(_user);
        uint256 barPoolPricePerFullShare = IBarPool(BAR_POOL).getPricePerFullShare();
        uint256 power;
        if (share > 0 && locked) {
            uint256 barBalance = (share * barPoolPricePerFullShare) / 1e18 - userBoostedShare;
            if (block.timestamp < lockEndTime && block.timestamp >= lockStartTime) {
                uint256 reaminingLockDuration = lockEndTime - block.timestamp;
                if (reaminingLockDuration >= DURATION_THRESHOLD) {
                    power = (barBalance * reaminingLockDuration) / DURATION_BOOST_FACTOR;
                } else {
                    power = barBalance;
                }
            } else {
                power = barBalance;
            }
        }

        return power;
    }

    function getBarMaticLpBalance(address _user) public view returns (uint256) {
        uint256 totalSupplyLP = IBarPair(BAR_LP).totalSupply();
        (uint256 reserve0, , ) = IBarPair(BAR_LP).getReserves();
        (uint256 amount, ) = IMasterChef(MASTERCHEF).userInfo(2, _user);
        uint256 totalAmount = amount;
        // Calculate the amount of the farm booster proxy
        if (FARM_BOOSTER != address(0)) {
            address proxy = IFarmBooster(FARM_BOOSTER).proxyContract(_user);
            if (proxy != address(0)) {
                (uint256 proxyAmount, ) = IMasterChef(MASTERCHEF).userInfo(2, proxy);
                totalAmount += proxyAmount;
            }
        }
        return (totalAmount * reserve0) / totalSupplyLP;
    }

    function getPoolsBalance(address _user, address[] memory _pools) public view returns (uint256) {
        uint256 total;
        for (uint256 i = 0; i < _pools.length; i++) {
            (uint256 amount, ) = ISmartChefInitializable(_pools[i]).userInfo(_user);
            total += amount;
        }
        return total;
    }

    function getVotingPower(address _user, address[] memory _pools) public view returns (uint256) {
        return
            getBarBalance(_user) +
            getBarVaultBalance(_user) +
            getIFOPoolBalancee(_user) +
            getBarPoolBalance(_user) +
            getBarMaticLpBalance(_user) +
            getPoolsBalance(_user, _pools);
    }

    function getVotingPowerWithoutPool(address _user) public view returns (uint256) {
        return
            getBarBalance(_user) +
            getBarVaultBalance(_user) +
            getIFOPoolBalancee(_user) +
            getBarPoolBalance(_user) +
            getBarMaticLpBalance(_user);
    }
}