/**
 *Submitted for verification at polygonscan.com on 2022-03-11
*/

// File: contracts/interfaces/IUniswapV2Factory.sol


pragma solidity ^0.8.12;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
// File: contracts/interfaces/IManager.sol


pragma solidity ^0.8.12;

interface IManager {
    // Passive fund methods
    function calculatePassiveBrokerage(uint256 amount)
        external
        view
        returns (uint256);

    function calculateTransferPassiveBrokerage(
        uint256 _passiveTransferBrokerage
    ) external view returns (uint256);

    // Active fund methods
    function performanceFeeLimit() external view returns (uint256);

    function platformFeeOnPerformance() external view returns (uint256);

    function calculateActiveBrokerage(uint256 amount)
        external
        view
        returns (uint256);

    function calculatePlatformFeeOnPerformance(uint256 amount)
        external
        view
        returns (uint256);

    function pauser() external view returns (address);

    function terminator() external view returns (address);

    // Path management
    function getPath(address tokenIn, address tokenOut)
        external
        view
        returns (address[] memory);
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: contracts/Manager.sol


pragma solidity ^0.8.12;




interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
function transfer(address to, uint256 amount) external returns (bool);

}

contract Manager is Ownable, IManager {
    uint256 public constant decimalPrecision = 10000;

    // Passive fund configurations:
    uint256 public passiveBrokerage;
    uint256 public passiveTransferBrokerage;

    // Active Fund configurations:
    uint256 public activeBrokerage;
    uint256 _performanceFeeLimit;
    uint256 _platformFeeOnPerformance;
    address public _pauser;
    address public _terminator;

    // quickswap factory address.
    address public factory;

    // Mapping to store paths.
    mapping(address => mapping(address => address[])) paths;

    constructor(
        uint256 _passiveBrokerage,
        uint256 _passiveTransferBrokerage,
        uint256 _activeBrokerage,
        address _factory
    ) {
        passiveBrokerage = _passiveBrokerage;
        passiveTransferBrokerage = _passiveTransferBrokerage;
        _transferOwnership(msg.sender);
        factory = _factory;
        activeBrokerage = _activeBrokerage;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Passive Fund manager.
    ///////////////////////////////////////////////////////////////////////////
    // Passive Brokerage
    function calculatePassiveBrokerage(uint256 amount)
        public
        view
        returns (uint256)
    {
        return (amount * passiveBrokerage) / (100 * decimalPrecision);
    }

    function setPassiveBrokerage(uint256 _passiveBrokerage) external onlyOwner {
        passiveBrokerage = _passiveBrokerage;
    }

    // Passive transfer Brokerage
    function calculateTransferPassiveBrokerage(uint256 amount)
        public
        view
        returns (uint256)
    {
        return (amount * passiveTransferBrokerage) / (100 * decimalPrecision);
    }

    // Method to set transfer fee on passive fund.
    function setPassiveTransferBrokerage(uint256 _passiveTransferBrokerage)
        external
        onlyOwner
    {
        passiveTransferBrokerage = _passiveTransferBrokerage;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Active Fund manager.
    ///////////////////////////////////////////////////////////////////////////

    // Active Brokerage
    function calculateActiveBrokerage(uint256 amount)
        external
        view
        returns (uint256)
    {
        return (amount * activeBrokerage) / (100 * decimalPrecision);
    }

    function setActiveBrokerage(uint256 _activeBrokerage) external onlyOwner {
        activeBrokerage = _activeBrokerage;
    }

    // Performance fee limit
    function performanceFeeLimit() external view returns (uint256) {
        return _performanceFeeLimit;
    }

    function setPerformanceFeeLimit(uint256 _limit) external onlyOwner {
        _performanceFeeLimit = _limit;
    }

    // Platform fee on Performance charges.
    function platformFeeOnPerformance() view external returns (uint) {
        return _platformFeeOnPerformance;
    }

    function calculatePlatformFeeOnPerformance(uint256 amount)
        external
        view
        returns (uint256)
    {
        return (amount * _platformFeeOnPerformance) / (100 * decimalPrecision);
    }

    function setPlatformFeeOnPerformance(uint _fee) external onlyOwner {
        _platformFeeOnPerformance = _fee;
    }

    // Pauser
    function pauser() external view returns(address) {
        return _pauser;
    }

    function setPauser(address pauser_) external onlyOwner {
        _pauser = pauser_;
    }

    // Terminator
    function terminator() view external returns (address) {
        return _terminator;
    }
    function setTerminator(address terminator_) external onlyOwner {
        _terminator = terminator_;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Path Manager
    ///////////////////////////////////////////////////////////////////////////

    // Manage paths
    function getPath(address tokenIn, address tokenOut)
        public
        view
        returns (address[] memory)
    {
        // Check if direct path exists.
        if (paths[tokenIn][tokenOut].length > 0) {
            return paths[tokenIn][tokenOut];
        } else if (paths[tokenIn][tokenOut].length > 0) {
            // Reverse path
            uint256 path_length = paths[tokenIn][tokenOut].length;
            address[] memory path = new address[](path_length);
            for (uint256 i = 0; i < path_length; i++) {
                path[i] = paths[tokenIn][tokenOut][path_length - 1 - i];
            }
            return path;
        } else {
            require(
                IUniswapV2Factory(factory).getPair(tokenIn, tokenOut) !=
                    address(0),
                "Manager: Pair for this exchange doesn't exists. Please contact patform admin."
            );
            address[] memory path = new address[](2);
            path[0] = tokenIn;
            path[1] = tokenOut;
            return path;
        }
    }

    // Method to set path
    function setPath(
        address tokenIn,
        address tokenOut,
        address[] memory path
    ) public onlyOwner {
        require(
            path.length > 2,
            "Manager: Must have atleast 3 address in path."
        );
        require(
            path[0] == tokenIn,
            "Manager: tokenIn must be at starting of path."
        );
        require(
            path[1] == tokenOut,
            "Manager: tokenOut must be at the end of path."
        );
        paths[tokenIn][tokenOut] = path;
    }


    ///////////////////////////////////////////////////////////////////////////
    // finance
    ///////////////////////////////////////////////////////////////////////////
    function withdraw(address _erc20Address, uint amount ) external onlyOwner{
        IERC20 erc20 = IERC20(_erc20Address);

        require(amount <= erc20.balanceOf(address(this)), "Manager: Amount insufficient");
        erc20.transfer(msg.sender, amount);
        
    }
}