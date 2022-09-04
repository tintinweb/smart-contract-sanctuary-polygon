// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/ILoadPriceHandler.sol";

contract LoadPriceHandler is Ownable, ILoadPriceHandler {
    event TokenPriceUpdated(address indexed sender, address indexed token, uint256 newPrice);
    event HealingDollarsPerHPUpdated(address indexed sender, uint256 indexed newPrice);
    event ResurrectionDollarsUpdated(address indexed sender, uint256 indexed newPrice);
    event BardSongDollarsUpdated(address indexed sender, uint256 indexed newPrice);
    event InnRestDollarsUpdated(address indexed sender, uint256 indexed newPrice);
    event TokenDollarsRewardPerLevelUpdated(address indexed sender, uint256 indexed newPrice);
    event InnRestLevelMultiplierDollarsUpdated(address indexed sender, uint256 indexed newPrice);
    event DCARBondPriceUpdated(address indexed sender, uint256 indexed newPrice);
    event UpdatePriceOracle(address indexed newPriceOracle);

    address public PRICE_ORACLE;

    uint256 public constant DOLLAR_PRECISION = 1e18;

    uint256 public HEALING_DOLLARS_PER_HP = 25;

    uint256 public RESURRECTION_DOLLARS_PER_LEVEL = 2500;

    uint256 public BARD_SONG_DOLLARS = 1 * DOLLAR_PRECISION;

    uint256 public INN_REST_DOLLARS = 3 * DOLLAR_PRECISION;

    uint256 public INN_REST_LEVEL_MULTIPLIER_DOLLARS = 25;

    uint256 public TOKEN_DOLLARS_REWARD_PER_LEVEL = 20;

    uint256 public DCAR_BOND_PRICE = 100 * DOLLAR_PRECISION;

    address public immutable DCAR_CONTRACT_ADDRESS;
    address public immutable DCAU_CONTRACT_ADDRESS;

    mapping(address => uint256) public TokensPerDollar;

    constructor(
        address priceOracle,
        address dcauContract,
        address dcarContract
    ) {
        require(priceOracle != address(0), "must be valid address");
        require(dcauContract != address(0), "must be valid address");
        require(dcarContract != address(0), "must be valid address");

        PRICE_ORACLE = priceOracle;
        DCAU_CONTRACT_ADDRESS = dcauContract;
        DCAR_CONTRACT_ADDRESS = dcarContract;
    }

    function setHealingPrice(uint256 amount) external onlyOwner {
        require(amount > 0, "CANNOT_BE_ZERO");

        HEALING_DOLLARS_PER_HP = amount;

        emit HealingDollarsPerHPUpdated(msg.sender, amount);
    }

    function setResurrectionPricePerLevel(uint256 amount) external onlyOwner {
        require(amount > 0, "CANNOT_BE_ZERO");

        RESURRECTION_DOLLARS_PER_LEVEL = amount;

        emit ResurrectionDollarsUpdated(msg.sender, amount);
    }

    function setBardSongPrice(uint256 amount) external onlyOwner {
        require(amount > 0, "CANNOT_BE_ZERO");

        BARD_SONG_DOLLARS = amount;

        emit BardSongDollarsUpdated(msg.sender, amount);
    }

    function setInnRestPrice(uint256 amount) external onlyOwner {
        require(amount > 0, "CANNOT_BE_ZERO");

        INN_REST_DOLLARS = amount;

        emit InnRestDollarsUpdated(msg.sender, amount);
    }

    function setRewardPerLevelPrice(uint256 amount) external onlyOwner {
        require(amount > 0, "CANNOT_BE_ZERO");

        TOKEN_DOLLARS_REWARD_PER_LEVEL = amount;

        emit TokenDollarsRewardPerLevelUpdated(msg.sender, amount);
    }

    function setInnRestLevelMultiplierDollars(uint256 amount) external onlyOwner {
        require(amount > 0, "CANNOT_BE_ZERO");

        INN_REST_LEVEL_MULTIPLIER_DOLLARS = amount;

        emit InnRestLevelMultiplierDollarsUpdated(msg.sender, amount);
    }

    function setTokenPricePerDollar(address tokenAddress, uint256 amountPerDollar) external {
        require(tokenAddress != address(0), "INVALID_TOKEN_ADDRESS");
        require(msg.sender == PRICE_ORACLE, "ORACLE_ONLY");

        TokensPerDollar[tokenAddress] = amountPerDollar;

        emit TokenPriceUpdated(msg.sender, tokenAddress, amountPerDollar);
    }

    function setDCARBondPrice(uint256 priceInDollars) external {
        require(msg.sender == PRICE_ORACLE, "ORACLE_ONLY");

        DCAR_BOND_PRICE = priceInDollars;

        emit DCARBondPriceUpdated(msg.sender, priceInDollars);
    }

    function tokensPerDollar(address tokenAddress) public view returns (uint256) {
        require(tokenAddress != address(0), "INVALID_TOKEN_ADDRESS");
        require(TokensPerDollar[tokenAddress] > 0, "PRICE_NOT_SET");
        return TokensPerDollar[tokenAddress];
    }

    function tokenCostDCARBond(address tokenAddress, uint256 discount) external view returns (uint256) {
        uint256 totalTokenCost = tokensPerDollar(tokenAddress) * DCAR_BOND_PRICE;
        uint256 discountInTokens = (totalTokenCost * discount) / 1000;
        uint256 discountedTokenPrice = totalTokenCost - discountInTokens;

        return discountedTokenPrice;
    }

    function totalCostHeal(uint256 amount) external view returns (uint256) {
        uint256 costInDollars = HEALING_DOLLARS_PER_HP * amount;
        return (costInDollars * tokensPerDollar(DCAU_CONTRACT_ADDRESS)) / DOLLAR_PRECISION;
    }

    function costToResurrect(uint256 level) external view returns (uint256) {
        uint256 costInDollars = RESURRECTION_DOLLARS_PER_LEVEL * level;
        return (costInDollars * tokensPerDollar(DCAU_CONTRACT_ADDRESS)) / DOLLAR_PRECISION;
    }

    function bardSongCost() external view returns (uint256) {
        return (BARD_SONG_DOLLARS * tokensPerDollar(DCAU_CONTRACT_ADDRESS)) / DOLLAR_PRECISION;
    }

    function innRestCost(uint256 level) external view returns (uint256) {
        uint256 levelCostDollars = INN_REST_LEVEL_MULTIPLIER_DOLLARS * level;
        return ((INN_REST_DOLLARS + levelCostDollars) * tokensPerDollar(DCAU_CONTRACT_ADDRESS)) / DOLLAR_PRECISION;
    }

    function costFromStableCost(address tokenAddress, uint256 amountInDollars) external view returns (uint256) {
        require(tokenAddress != address(0), "INVALID_TOKEN_ADDRESS");
        require(TokensPerDollar[tokenAddress] > 0, "PRICE_NOT_SET");

        return (amountInDollars * tokensPerDollar(tokenAddress)) / DOLLAR_PRECISION;
    }

    function setPriceOracle(address _priceOracle) external onlyOwner {
        require(_priceOracle != address(0), "must be valid address");
        PRICE_ORACLE = _priceOracle;
        emit UpdatePriceOracle(_priceOracle);
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
// DragonCryptoGaming - Legend of Aurum Draconis Contract Libaries

pragma solidity ^0.8.14;

/**
 * @dev Interfact 
 */
interface ILoadPriceHandler {
    function tokenCostDCARBond(
        address tokenAddress,
        uint256 discount
    ) external view
    returns (uint256);

    function totalCostHeal( uint256 amount ) external view returns (uint256);

    function costToResurrect( uint256 level ) external view returns (uint256);

    function bardSongCost( ) external view returns (uint256);

    function innRestCost( uint256 level ) external view returns (uint256);
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