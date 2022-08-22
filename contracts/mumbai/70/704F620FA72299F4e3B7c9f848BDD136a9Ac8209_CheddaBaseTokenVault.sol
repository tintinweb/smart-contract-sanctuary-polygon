//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC721, IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC4626 } from "../tokens/ERC4626.sol";
import { ERC20 } from "../tokens/ERC20.sol";
import { ICheddaAddressRegistry } from "../common/CheddaAddressRegistry.sol";
import { ICheddaDebtToken, CheddaDebtToken } from "../tokens/CheddaDebtToken.sol";
import { IPriceFeed, MultiAssetPriceOracle } from "../oracle/MultiAssetPriceOracle.sol";
import { IGauge } from "../interfaces/IGauge.sol";
import { SafeTransferLib } from "../lib/SafeTransferLib.sol";
import { FixedPointMathLib } from "../lib/FixedPointMathLib.sol";
import { WadRayMathLib } from "../lib/WadRayMathLib.sol";
import { IReserveInterestRateStrategy } from "../interfaces/IReserveInterestRateStrategy.sol";
import { DefaultReserveInterestRateStrategy } from "./DefaultReserveInterestRateStrategy.sol";

/// @title CheddaBaseTokenVault
/// @notice Represents a lending pool on the Chedda platform.
/// @dev maybe break up into separate pool and token contracts.
contract CheddaBaseTokenVault is Ownable, ERC4626, IERC721Receiver {

    struct VaultStats {
        uint256 liquidity;
        uint256 utilization;
        uint256 depositApr;
        uint256 borrowApr;
        uint256 rewardsApr;
    }
    enum CollateralType {
      ERC20,
      ERC721,
      ERC155
    }

    struct Collateral {
      address token;
      CollateralType cType;
      uint256 amount;
      uint256[] tokenIds;
    }

    struct CollateralValue {
        address token;
        uint256 amount;
        int256 value;
    }

    // Events
    event OnTokenWhitelisted(address indexed token, address indexed user);
    event OnCollateralAdded(address indexed token, address indexed account, CollateralType ofType, uint256 amount);
    event OnCollateralRemoved(address indexed token, address indexed account, CollateralType ofType, uint256 amount);
    event OnLoanOpened(address account, uint256 amount);
    event OnLoanRepaid(address account, uint256 amount);

    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;
    using WadRayMathLib for uint256;
    
    // total amount deposited by liquidity providers
    uint256 public deposits;

    uint256 public liquidityRate;
    uint256 public borrowRate;

    uint256 constant public PECISION = 1e18;
    uint256 constant public MAX_LTV = 7 * 1e17; // 70%
    int256 public borrowFee = 3 * 1e15; // 0.3%;

    ICheddaDebtToken public debtToken;
    IReserveInterestRateStrategy public interestRateStrategy;
    ICheddaAddressRegistry public registry;
    IGauge public gauge;
    IPriceFeed public oracle;

    // use mapping to support multi-asset lending pool
    // token address => Debt token
    // mapping(address => address) public debtTokens;

    // list of tokens that can be used as collateral
    address[] public collateralTokenList;

    // token address => is whitelisted
    mapping(address => bool) public collateralTokens;

    // Determines Loan to Value ratio for token
    mapping(address => uint256) public collateralFactor;

    // account => token => amount
    mapping(address => mapping(address => Collateral)) public accountCollateral;
    
    // token address => Collateral amount
    mapping(address => uint256) public tokenCollateral;

    constructor(ERC20 _asset, address _oracle, address[] memory collateral) 
        ERC4626(
        _asset,
        string(abi.encodePacked("CHEDDA Token ", _asset.name())), 
        string(abi.encodePacked("ch", _asset.symbol()))) {
        debtToken = new CheddaDebtToken(asset, address(this));
        oracle = IPriceFeed(_oracle);
        initialize(collateral);
    }

    function initialize(address[] memory _collateralTokens) internal {

        _setCollateralTokenList(_collateralTokens);
        // values express in ray
        uint256 optimalUtilizationRate = 75 * 1e16;
        uint256 baseVariableBorrowRate = 5 * 1e16;
        uint256 variableRateSlope1 = 3 * 1e16;
        uint256 variableRateSlope2 = 9 * 1e16;
        interestRateStrategy = new DefaultReserveInterestRateStrategy(
            optimalUtilizationRate,
            baseVariableBorrowRate,
            variableRateSlope1,
            variableRateSlope2
        );
    }

    function updateRegistry(address registryAddress) external onlyOwner {
        registry = ICheddaAddressRegistry(registryAddress);
    }

    /*///////////////////////////////////////////////////////////////
                           ADMIN - WHITELIST TOKEN
    //////////////////////////////////////////////////////////////*/

    /// @notice Whitelist a token as collateral
    /// @dev Only tokens previously whitelisted can be added as collateral.
    /// @param token token address
    /// @param isWhitelisted If true, allow this token as collateral. If false, this token
    /// can no longer be used as collateral
    /// @param factor The collateral factor for this token
    function whitelistToken(address token, bool isWhitelisted, uint256 factor)
        external
        onlyOwner
    {
        collateralTokens[token] = isWhitelisted;
        collateralFactor[token] = factor;
        _updateCollateralTokenList(token, isWhitelisted);

        emit OnTokenWhitelisted(token, msg.sender);
    }

    /// @notice Total assets deposited as liquidity in this vault - amount borrowed
    /// @dev this represents available liquidity in this vault
    /// @return balance deposits - borrowed
    function assetBalance() public view returns (uint256 balance) {
        balance = deposits - totalBorrowed();
    }

    function getVaultStats() external view returns (VaultStats memory) {
      VaultStats memory stats =  VaultStats({
        liquidity: totalAssets(),
        utilization: utilization(),
        depositApr: depositApr(),
        borrowApr: borrowApr(),
        rewardsApr: rewardsApr()
      });
      return stats;
    }

    /// Vault management
    function beforeWithdraw(uint256 amount, uint256 shares)
        internal
        virtual
        override
    {
        deposits -= amount;
        _calculateIntrestRates(0, amount);
    }

    function afterDeposit(uint256 amount, uint256 shares)
        internal
        virtual
        override
    {
        deposits += amount;
        _calculateIntrestRates(amount, 0);
    }

    function totalAssets() public view override returns (uint256) {
        return deposits;
    }

    // rates
    function utilization() public view returns (uint256 utilized) {
        uint256 assets = totalAssets();
        if (assets == 0) {
            return 0;
        }
        utilized  = totalBorrowed().divWadUp(assets);
    }

    function depositApr() public view returns (uint256) {
        return borrowRate.mulWadDown(utilization());
    }

    function borrowApr() public view returns (uint256) {
      return  borrowRate;
    }

    function rewardsApr() public view returns (uint256) {
        if (address(gauge) == address(0)) {
            return 0;
        }
        return  gauge.rewardRate();
    }

    function interestRateSlope() public view returns (uint256 slope) {
        slope = interestRateStrategy.variableRateSlope();
    }

    function _calculateIntrestRates(uint256 liquidityAdded, uint256 liquidityTaken) internal {
        uint256 totalVariableDebt = totalBorrowed();
        (liquidityRate, borrowRate) = interestRateStrategy.calculateInterestRates(
            address(this),
            address(asset),
            liquidityAdded,
            liquidityTaken,
            totalVariableDebt,
            0
        );
    }

    /*///////////////////////////////////////////////////////////////
                           MANAGE COLLATERAL
    //////////////////////////////////////////////////////////////*/

    function addCollateral(address token, uint256 amount) public {
        // TODO: check if token address is ERC-20
        // Since token already whitelisted it must be one of the supported token types
        require(collateralTokens[token] == true, "CHV: Not whitelisted");
        require(amount > 0, "CHV: 0 amount");
        address account = msg.sender;

        tokenCollateral[token] += amount;

        // add collateral to account
        if (accountHasCollateral(account, token)) {
            accountCollateral[account][token].amount += amount;
        } else {
            Collateral memory collateral = Collateral({
                token: token,
                cType: CollateralType.ERC20,
                amount: amount,
                tokenIds: new uint256[](0)
            });
            accountCollateral[account][token] = collateral;
        }

        ERC20(token).safeTransferFrom(account, address(this), amount);

        emit OnCollateralAdded(token, account, CollateralType.ERC20, amount);
    }

    function removeCollateral(address token, uint256 amount) public {
        address account = msg.sender;
        require(amount > 0, "CHV: 0 amount");
        require(accountCollateralCount(account, token) >= amount, "CHV: INSUF");

        tokenCollateral[token] -= amount;

        if (accountCollateralCount(account, token) == amount) {
            delete accountCollateral[account][token];
        } else {
            accountCollateral[account][token].amount -= amount;
        }

        if (accountPendingAmount(account) > totalAccountCollateralValue(account)) {
            revert("CHV: Not enough collateral");
        }

        ERC20(token).safeTransfer(msg.sender, amount);

        emit OnCollateralRemoved(token, account, CollateralType.ERC20, amount);
    }

    function addCollateral721(address token, uint256[] memory tokenIds) external {
        require(collateralTokens[token] == true, "CHV: Not whitelisted");
        require(tokenIds.length > 0, "CHV: Empty token list");

        address account = msg.sender;

        if (accountHasCollateral(account, token)) {
            Collateral storage collateral = accountCollateral[account][token];
            for (uint256 i = 0; i < tokenIds.length; i++) {
                for (uint256 j = 0; j < collateral.tokenIds.length; j++) {
                    if (tokenIds[i] == collateral.tokenIds[j]) {
                        revert("CHV: Already Added");
                    }
                }
                collateral.tokenIds.push(tokenIds[i]);
            }

            accountCollateral[account][token].amount += tokenIds.length;
            require(collateral.tokenIds.length == collateral.amount, "CHV: Incorrect token amount");
        } else {
            Collateral memory collateral = Collateral({
                token: token,
                cType: CollateralType.ERC721,
                amount: tokenIds.length,
                tokenIds: tokenIds
            });
            accountCollateral[account][token] = collateral;
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(token).safeTransferFrom(account, address(this), tokenIds[i]);
        }

        emit OnCollateralAdded(token, account, CollateralType.ERC721, tokenIds.length);
    }

    function removeCollateral721(address token, uint256[] memory tokenIds) external {
        require(collateralTokens[token] == true, "CHV: Not whitelisted");
        require(tokenIds.length > 0, "CHV: Empty token list");
        address account = msg.sender;
        Collateral storage collateral = accountCollateral[account][token];
        require(collateral.amount >= tokenIds.length, "CHV: Invalid token IDs");
        uint8 matchesFound = 0;

        // make sure account is the owner of all the tokens in `tokenIds`
        // check deposited tokens vs token ids
        for (uint256 i = 0; i < tokenIds.length; i++) {
            for (uint256 j = 0; j < collateral.tokenIds.length; j++) {
               if (tokenIds[i] == collateral.tokenIds[j]) {
                    matchesFound += 1;
                    collateral.tokenIds[j] = collateral.tokenIds[collateral.tokenIds.length -1];
                    collateral.tokenIds.pop();
                    break;
               } 
            }
        }

        // revert if any tokenIds are invalid
        require(matchesFound == tokenIds.length, "CHV: Invalid token ID");
        accountCollateral[account][token].amount -= tokenIds.length;

        if (accountPendingAmount(account) > totalAccountCollateralValue(account)) {
            revert("CHV: Not enough collateral");
        }

        // transfer back collateral
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(token).safeTransferFrom(address(this), account, tokenIds[i]);
        }

        emit OnCollateralRemoved(token, account, CollateralType.ERC721, tokenIds.length);
    } 

    function accountHasCollateral(address account, address collateral) public view returns (bool) {
      return accountCollateral[account][collateral].token != address(0);
    }

    function accountCollateralCount(address account, address collateral) public view returns (uint256) {
        return accountCollateral[account][collateral].amount;
    }

    function collateralAmounts() public view returns (CollateralValue[] memory) {
        CollateralValue[] memory collateralValues = new CollateralValue[](collateralTokenList.length);
        for (uint256 i = 0; i < collateralTokenList.length; i++) {
            address token = collateralTokenList[i];
            uint256 collateralAmount = tokenCollateral[token];
            int256 price = oracle.readPrice(token, 0);
            int256 value = price * int256(collateralAmount);
            CollateralValue memory cValue = CollateralValue({
                token: token,
                amount: collateralAmount,
                value: value
            });
            collateralValues[i] = cValue;
        }
        return collateralValues;
    }

    /// @notice Get the token IDs deposited by this account
    /// @dev `collateral` parameter should be an ERC-721 token.
    /// @param account The account to check for
    /// @param collateral The collateral to check for
    /// @return tokenIds the token ids from the `collateral` NFT deposited by `account`.
    function accountCollateralTokenIds(address account, address collateral) external view returns (uint256[] memory) {
        Collateral memory c = accountCollateral[account][collateral];
        return c.tokenIds;
    }

    /// @notice Get the current value of users collateral.
    /// @param account Account to return collateral value for
    /// @return current collateral value of users account
    function totalAccountCollateralValue(address account)
        public
        view
        returns (uint256)
    {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < collateralTokenList.length; i++) {
            address token = collateralTokenList[i];
            Collateral memory collateral = accountCollateral[account][token];
            if (accountHasCollateral(account, token)) {
                uint256 amount = collateral.amount;
                if (collateral.cType == CollateralType.ERC20) {
                    amount = amount / 10 ** ERC20(token).decimals();
                }
                uint256 collateralValue = _getTokenCollateralValue(token, amount);
                if (collateralValue > 0) {
                    totalValue += uint256(collateralValue);
                }
            }
        }

        return totalValue;
    }

    /// @notice Returns the list of tokens that can be used as collateral
    /// @return list the list of token addresses that can be used as collateral.
    function getCollateralTokens() public view returns (address[] memory list) {
        list = collateralTokenList;
    }

    /// @notice Sets the list of tokens that can be used as collateral in this pool.
    function _setCollateralTokenList(address[] memory list) internal {
        collateralTokenList = list;
        for (uint256 i = 0; i < list.length; i++) {
            collateralTokens[list[i]] = true;
        }
    }

    /// @notice Updates the list of allowable collateral tokens.
    /// @param token address of token to add or remove.
    /// @param add if `true` add the `token` to whitelist, else remove the token.
    /// adding a token which is already in the list has no effect. 
    function _updateCollateralTokenList(address token, bool add) internal {
        if (add) {
            for (uint256 i = 0; i < collateralTokenList.length; i++) {
                if (collateralTokenList[i] == token) {
                    return; // already added
                }
            }
            collateralTokenList.push(token);
        } else {
            for (uint256 i = 0; i < collateralTokenList.length; i++) {
                if (collateralTokenList[i] == token) {
                    collateralTokenList[i] = collateralTokenList[
                        collateralTokenList.length - 1
                    ];
                    collateralTokenList.pop();
                    break;
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        borrow/repay logic
    //////////////////////////////////////////////////////////////*/

    /// borrows a loan
    /// @notice Takes out a loan
    /// @dev The max amount a user can borrow must be less than the value of their collateral weighted
    /// against the loan to value ratio of that colalteral.
    /// @param amount The amount to borrow
    function take(uint256 amount) public {
        address account = msg.sender;
        // check collateral value > ltv (amount)
        _validateBorrow(account, amount);
        _calculateIntrestRates(0, amount);
    
        debtToken.createDebt(amount, account);
        asset.safeTransfer(account, amount);
        emit OnLoanOpened(account, amount);
    }

    // repays a loan
    /// @notice Repays a part or all of a loan.
    /// @param amount amount to repay. Must be > 0 and <= amount borrowed by sender
    function putAmount(uint256 amount) public {
        address account = address(msg.sender);
        require(amount != 0, "CHV: Invalid amount");
        require(amount <= accountPendingAmount(account), "CHV: amount too high");
        _calculateIntrestRates(amount, 0);
        asset.safeTransferFrom(msg.sender, address(this), amount);
        debtToken.repayAmount(amount, account);

        emit OnLoanRepaid(account, amount);
    }

    // repays a loan
    /// @notice Repays a part or all of a loan.
    /// @param shares The share of debt token to repay.
    function putShares(uint256 shares) public {
        address account = address(msg.sender);
        require(shares != 0, "CHV: Invalid amount");
        require(shares <= debtToken.accountShare(account), "CHV: shares too high");
        
        uint256 amount = debtToken.amountForShares(shares);
        asset.safeTransferFrom(msg.sender, address(this), amount);
        debtToken.repayShare(shares, account);

        emit OnLoanRepaid(account, amount);
    }

    function totalBorrowed() public view returns (uint256 amount) {
        amount = debtToken.totalBorrowed();
    }

    function totalBorrowedValue() public view returns (uint256 value) {
        int256 assetPrice = oracle.readPrice(address(asset), 0); 
        require(assetPrice > 0, "Vault: Negative price");
        value = totalBorrowed().mulWadDown(uint256(assetPrice));
    }

    function accountPendingAmount(address account) public view returns (uint256 borrowed) {
        uint256 shares = debtToken.accountShare(account);
        borrowed = debtToken.amountForShares(shares);
    }

    function _getTokenMarketValue(address token, uint256 amount) internal view returns (uint256) {
        int256 price = oracle.readPrice(token, 0);
        require(price > 0, "CHV: Invalid price");
        return uint256(price).mulWadDown(amount);
    }

    function _getTokenCollateralValue(address token, uint256 amount) internal view returns (uint256) {
        int256 price = oracle.readPrice(token, 0);
        require(price > 0, "CHV: Invalid price");
        return (uint256(price) * amount).mulWadDown(collateralFactor[token]);
    }

    /// @notice Checks if account is currently solvent.
    /// @dev TODO: implement LTV rules 
    /// @param account The account to check
    /// @return `true` is account is currently solvent, `false` otherwise.
    function _isSolvent(address account) internal view returns (bool) {
        return accountPendingAmount(account) < accountLiquidity(account);
    }

    function accountLiquidity(address account) public view returns (uint256) {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < collateralTokenList.length; i++) {
            address token = collateralTokenList[i];
            Collateral memory collateral = accountCollateral[account][token];
            if (accountHasCollateral(account, token)) {
                uint256 amount = collateral.amount;
                uint256 collateralValue = _getTokenCollateralValue(token, amount);
                if (collateralValue > 0) {
                    totalValue += collateralValue;
                }
            }
        }

        return totalValue;
    }

    function _validateBorrow(address account, uint256 amount) internal view {
        require (amount != 0, "Invalid amount");
        require (account != address(0), "Invalid address");
        // use collateralFactor in _getColalteralValue()
        // uint256 maxLTV = 75 * 1e16; // fixed 75% ltv
        uint256 collateralValue = totalAccountCollateralValue(account);
        uint256 newTotalBorrow = accountPendingAmount(account) + amount;
        require (newTotalBorrow < collateralValue, "Not enough collateral");
    }

    function setGauge(address gaugeAddress) external onlyOwner {
        gauge = IGauge(gaugeAddress);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        operator;
        from;
        tokenId;
        data;
        return IERC721Receiver.onERC721Received.selector;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { ERC20 } from "./ERC20.sol";
import { SafeTransferLib } from "../lib/SafeTransferLib.sol";
import { FixedPointMathLib } from "../lib/FixedPointMathLib.sol";

/// @notice Minimal ERC4646 tokenized Vault implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol)
/// @dev Do not use in production! ERC-4626 is still in the review stage and is subject to change.
abstract contract ERC4626 is ERC20 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed from, address indexed to, uint256 amount, uint256 shares);

    event Withdraw(address indexed from, address indexed to, uint256 amount, uint256 shares);

    /*///////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;

    uint256 internal immutable ONE;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, _asset.decimals()) {
        asset = _asset;

        // unchecked {
            ONE = 10**decimals; // >77 decimals is unlikely.
        // }
    }

    /*///////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 amount, address to) public virtual returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(amount)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), amount);

        _mint(to, shares);

        emit Deposit(msg.sender, to, amount, shares);

        afterDeposit(amount, shares);
    }

    function mint(uint256 shares, address to) internal virtual returns (uint256 amount) {
        amount = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), amount);

        _mint(to, shares);

        emit Deposit(msg.sender, to, amount, shares);

        afterDeposit(amount, shares);
    }

    function withdraw(
        uint256 amount,
        address to,
        address from
    ) public virtual returns (uint256 shares) {
        shares = previewWithdraw(amount); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != from) {
            uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - shares;
        }

        beforeWithdraw(amount, shares);

        _burn(from, shares);

        emit Withdraw(from, to, amount, shares);

        asset.safeTransfer(to, amount);
    }

    function redeem(
        uint256 shares,
        address to,
        address from
    ) public virtual returns (uint256 amount) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (msg.sender != from && allowed != type(uint256).max) allowance[from][msg.sender] = allowed - shares;

        // Check for rounding error since we round down in previewRedeem.
        require((amount = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(amount, shares);

        _burn(from, shares);

        emit Withdraw(from, to, amount, shares);

        asset.safeTransfer(to, amount);
    }

    /*///////////////////////////////////////////////////////////////
                           ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256);

    function assetsOf(address user) public view virtual returns (uint256) {
        return previewRedeem(balanceOf[user]);
    }

    function assetsPerShare() public view virtual returns (uint256) {
        return previewRedeem(ONE);
    }

    function previewDeposit(uint256 amount) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? amount : amount.mulDivDown(supply, totalAssets());
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 amount) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? amount : amount.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    /*///////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address user) public virtual returns (uint256) {
        return assetsOf(user);
    }

    function maxRedeem(address user) public virtual returns (uint256) {
        return balanceOf[user];
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 amount, uint256 shares) internal virtual {}

    function afterDeposit(uint256 amount, uint256 shares) internal virtual {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

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

interface IRebaseToken {
    function rebase() external;
}

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                            ),
                            owner,
                            spender,
                            value,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ICheddaAddressRegistry {
    function chedda() external view returns (address);
    function xChedda() external view returns (address);
    function veChedda() external view returns (address);
    function gaugeController() external view returns (address);
    function poolFactory() external view returns (address);
    function entropy() external view returns (address);
    function loanManager() external view returns (address);
    function wrappedNativeToken() external view returns (address);
    function priceOracle() external view returns (address);
}

contract CheddaAddressRegistry is Ownable {

    event CheddaUpdated(address indexed newAddress, address indexed caller);
    event XCheddaUpdated(address indexed newAddress, address indexed caller);
    event VECheddaUpdated(address indexed newAddress, address indexed caller);
    event GaugeControllerUpdated(address indexed newAddress, address indexed caller);
    event PoolFactoryUpdated(address indexed newAddress, address indexed caller);
    event LoanManagerUpdated(address indexed newAddress, address indexed caller);
    event WrappedNativeTokenUpdated(address indexed tokenAddress, address indexed caller);
    event PriceOracleUpdated(address indexed consumerAddress, address indexed caller);

    address public chedda;
    address public xChedda;
    address public veChedda;
    address public gaugeController;
    address public poolFactory;
    address public loanManager;
    address public priceOracle;
    address public wrappedNativeToken;

    function setChedda(address _chedda) external onlyOwner() {
        chedda = _chedda;
        emit CheddaUpdated(chedda, _msgSender());
    }

    function setXChedda(address _x) external onlyOwner() {
        xChedda = _x;
        emit XCheddaUpdated(xChedda, _msgSender());
    }

    function setVEChedda(address _ve) external onlyOwner() {
        veChedda = _ve;
        emit VECheddaUpdated(veChedda, _msgSender());
    }

    function setGaugeController(address _controller) external onlyOwner() {
        gaugeController = _controller;
        emit GaugeControllerUpdated(gaugeController, _msgSender());
    }
    function setPoolFactory(address _factory) external onlyOwner() {
        poolFactory = _factory;
        emit PoolFactoryUpdated(poolFactory, _msgSender());
    }
    function setLoanManager(address loanManagerAddress) external onlyOwner() {
        loanManager = loanManagerAddress;
        emit LoanManagerUpdated(loanManagerAddress, _msgSender());
    }

    function setWrappedNativeToken(address tokenAddress) external onlyOwner() {
        wrappedNativeToken = tokenAddress;
        emit WrappedNativeTokenUpdated(tokenAddress, _msgSender());
    }

    function setPriceOracle(address oracleAddress) external onlyOwner() {
        priceOracle = oracleAddress;
        emit PriceOracleUpdated(oracleAddress, _msgSender());
    }
}

//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

import { ERC20 } from "./ERC20.sol";
import { ERC4626 } from "./ERC4626.sol";
import { FixedPointMathLib } from "../lib/FixedPointMathLib.sol";

interface ICheddaDebtToken {
    function createDebt(uint256 amount, address account) external returns (uint256);
    function repayShare(uint256 shares, address account) external returns (uint256);
    function repayAmount(uint256 amount, address account) external returns (uint256);
    function totalBorrowed() external view returns (uint256);
    function amountForShares(uint256 shares) external view returns (uint256);
    function sharesForAmount(uint256 amount) external view returns (uint256);
    function accountShare(address account) external view returns (uint256);
}

/// @title CheddaDebtToken
/// @notice Token representing amount borrowed and pending interest on this debt.
contract CheddaDebtToken is ERC20, ICheddaDebtToken {

    using FixedPointMathLib for uint256;

    event DebtCreated(address indexed account, uint256 amount, uint256 shares);
    event DebtRepaid(address indexed account, uint256 amount, uint256 shares);

    uint256 public constant BASE_RATE = 1e18;
    uint64 public constant STARTING_INTEREST_RATE_PER_SECOND = 317097919; // approx 1% APR
    uint64 public constant ONE_PERCENT = 1e18 / 100;
    uint64 public constant PER_SECOND = ONE_PERCENT / 365 / 86400;
    uint256 internal immutable ONE;

    uint256 private _lastAccrual;
    uint256 private _interestPerSecond;
    uint256 private _variableTotalDebt;
    uint256 private _borrowRate;
    address public vault;
    address public asset;

    modifier onlyVault() {
        require(msg.sender == vault, "CHDebt: Only vault");
        _;
    }

    /// @notice Creates a debt token. 
    /// @param _asset the asset being borrowed.
    /// @param _vault the Chedda vault this asset is being borrowed from.
    constructor(ERC20 _asset, address _vault)
    ERC20(
    string(abi.encodePacked("CHEDDA Debt-", _asset.name())),
    string(abi.encodePacked("cd-", _asset.symbol())),
    _asset.decimals()
    ) {
        ONE = 10**decimals; // >77 decimals is unlikely.
        asset = address(_asset);
        vault = _vault;
    }

    function accountShare(address account) external view returns (uint256) {
        return balanceOf[account];
    }


    /*///////////////////////////////////////////////////////////////
                    ICheddaDebtToken implementation
    //////////////////////////////////////////////////////////////*/

    /// TODO: Change asset references besides underlying `asset` to debt.
    /// e.g totalAssets(), assetsPerShare(), 
    /// @notice Returns the total principal amount of debt tracked.
    /// @dev This does not include any future interest payments.
    /// @return borrowed Total amount of debt (principal) tracked.
    function totalBorrowed() external view returns (uint256 borrowed) {
        borrowed = totalAssets();
    }

    /// @notice records the creation of debt. `account` borrowed `amount` of underlying token.
    /// @dev Explain to a developer any extra details
    /// @param amount The amount borrowed
    /// @param account The account doing the borrowing
    /// @return shares The number of tokens minted to track this debt + future interest payments.
    function createDebt(uint256 amount, address account) external onlyVault returns (uint256 shares) {
        // accrue must be called before anything else.
        _accrue();
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(amount)) != 0, "ZERO_SHARES");

        _variableTotalDebt += amount;

        _mint(account, shares);

        emit DebtCreated(account, amount, shares);

        afterDeposit(amount, shares);
    }

    /// @notice records the repayment of debt. `account` borrowed `shares` portion of outstanding debt.
    /// @dev Explain to a developer any extra details
    /// @param share The portion of debt to repay
    /// @param account The account repaying
    /// @return amount The amount of debt repaid
    function repayShare(uint256 share, address account) external onlyVault returns (uint256 amount) {
        _accrue();

        // Check for rounding error since we round down in previewRedeem.
        require((amount = previewRedeem(share)) != 0, "ZERO_ASSETS");

        beforeWithdraw(amount, share);

        _variableTotalDebt -= amount;
        _burn(account, share);

        emit DebtRepaid(account, amount, share);
    }

    function repayAmount(uint256 amount, address account) external onlyVault returns (uint256 shares) {
       shares = previewWithdraw(amount); // No need to check for rounding error, previewWithdraw rounds up.

        beforeWithdraw(amount, shares);

        _variableTotalDebt -= amount;
        _burn(account, shares);

        emit DebtRepaid(account, amount, shares);
    }

    /// @notice The amount of underlying token covered by this amount of debt token.
    /// @param share the number of shares of debt token.
    /// @return amount the amount of underlying token covered.
    function amountForShares(uint256 share) external view returns (uint256 amount) {
        amount = previewRedeem(share);
    }

    /// @notice The share of debt token representing a given amount of underlying token.
    /// @param amount The amount of underlying token to check.
    /// @return share the amount of debt token that covers this amount of debt.
    function sharesForAmount(uint256 amount) external view returns (uint256 share) {
        share = previewWithdraw(amount);
    }
    
    /*///////////////////////////////////////////////////////////////
                           ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns total owed (amount borrowed + outstanding interest payments).
    /// @return totalDebt Total outstanding debt
    /// todo: change to totalDebt
    function totalAssets() public view returns (uint256 totalDebt) {
        totalDebt = _variableTotalDebt;
    }

    // todo: change to debtOf
    function assetsOf(address user) public view virtual returns (uint256) {
        return previewRedeem(balanceOf[user]);
    }

    // todo: change to debtPerShare
    function assetsPerShare() public view virtual returns (uint256) {
        return previewRedeem(ONE);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 amount) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? amount : amount.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 amount) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? amount : amount.mulDivUp(supply, totalAssets());
    }

    function accrue() external {
        _accrue();
    }

    function beforeWithdraw(uint256 amount, uint256 shares) internal virtual {
        // silence unused variable warnings
        amount;
        shares;
        _accrue();
    }

    function afterDeposit(uint256 amount, uint256 shares) internal virtual {
        // silence unused variable warnings
        amount;
        shares;
        _accrue();
    }

    function _accrue() internal {
        uint256 timestamp =  _timestamp();
         uint256 elapsedTime = timestamp - _lastAccrual;
        if (elapsedTime == 0) {
            return;
        }
        if (_interestPerSecond == 0) {
            _interestPerSecond = STARTING_INTEREST_RATE_PER_SECOND;
        } else {
            _interestPerSecond = _calculateNewBorrowRate();
        }

        _lastAccrual = timestamp;
        uint256 interest = _variableTotalDebt.mulWadUp(_interestPerSecond * elapsedTime);
        _variableTotalDebt += interest;
    }

    // Debt tokens are non-transferrable
    function transfer(address to, uint256 amount) public pure override returns (bool rv) {
        to;
        amount;
        rv = false;
        revert("CHDebt: Non-transferrable");
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public pure override returns (bool rv) {
        from;
        to;
        amount;
        rv = false;
        revert("CHDebt: Non-transferrable");
    }

    function _timestamp() private view returns (uint256) {
        return block.timestamp;
    }

    function setBorrowRate(uint256 rate) external onlyVault {
        _borrowRate = rate;
    }

    function _calculateNewBorrowRate() private pure returns (uint256) {
        return PER_SECOND; // TODO: update based on demand/supply
    }

}

//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import { IPriceFeed } from "./IPriceFeed.sol";

/// @title MultiAssetPriceOracle
/// @notice Explain to an end user what this does
/// @dev Source agnostic oraclel 
contract MultiAssetPriceOracle is Ownable, IPriceFeed {

    // token address to price feed address 
    mapping(address => IPriceFeed) public priceFeed;
    address public token; // Interface conformance; unused

    /// @notice Sets the priceed feed for a token
    /// @param feed The price feed
    /// @param _token The token address
    function setPriceFeed(address feed, address _token) public onlyOwner {
        require(_token != address(0) && feed != address(0), "ERR: Zero address");
        priceFeed[_token] = IPriceFeed(feed);
    }

    /// @dev Explain to a developer any extra details
    /// @return price the latest price
    function readPrice(address _token, uint256 tokenID) public override view returns (int price) {
        IPriceFeed feed = priceFeed[_token];
        require(address(feed) != address(0), "No price feed");
        price = feed.readPrice(_token, tokenID);
    }
}

//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

interface IGauge {
    function claim() external;
    function rollover(uint256 balance, uint256 weight, uint256 rate) external;
    function setRewardRate(uint256 rate) external;
    function recordVote(address account) external;
    function rewardToken() external view returns (address);
    function rewardRate() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed output.
                success := 0
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*///////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z)
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z)
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z)
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z)
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z)
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z)
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

/**
 * @title WadRayMath library
 * @author Aave
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/

library WadRayMathLib {
  uint256 internal constant WAD = 1e18;
  uint256 internal constant halfWAD = WAD / 2;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant halfRAY = RAY / 2;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @return One ray, 1e27
   **/
  function ray() internal pure returns (uint256) {
    return RAY;
  }

  /**
   * @return One wad, 1e18
   **/

  function wad() internal pure returns (uint256) {
    return WAD;
  }

  /**
   * @return Half ray, 1e27/2
   **/
  function halfRay() internal pure returns (uint256) {
    return halfRAY;
  }

  /**
   * @return Half ray, 1e18/2
   **/
  function halfWad() internal pure returns (uint256) {
    return halfWAD;
  }

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a*b, in wad
   **/
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    require(a <= (type(uint256).max - halfWAD) / b, "MATH_MULTIPLICATION_OVERFLOW");

    return (a * b + halfWAD) / WAD;
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "MATH_DIVISION_BY_ZERO");
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / WAD, "MATH_MULTIPLICATION_OVERFLOW");

    return (a * WAD + halfB) / b;
  }

  /**
   * @dev Multiplies two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a*b, in ray
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    require(a <= (type(uint256).max - halfRAY) / b, "MATH_MULTIPLICATION_OVERFLOW");

    return (a * b + halfRAY) / RAY;
  }

  /**
   * @dev Divides two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a/b, in ray
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "MATH_DIVISION_BY_ZERO");
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / RAY, "MATH_MULTIPLICATION_OVERFLOW");

    return (a * RAY + halfB) / b;
  }

  /**
   * @dev Casts ray down to wad
   * @param a Ray
   * @return a casted to wad, rounded half up to the nearest wad
   **/
  function rayToWad(uint256 a) internal pure returns (uint256) {
    uint256 halfRatio = WAD_RAY_RATIO / 2;
    uint256 result = halfRatio + a;
    require(result >= halfRatio, "MATH_ADDITION_OVERFLOW");

    return result / WAD_RAY_RATIO;
  }

  /**
   * @dev Converts wad up to ray
   * @param a Wad
   * @return a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256) {
    uint256 result = a * WAD_RAY_RATIO;
    require(result / WAD_RAY_RATIO == a, "MATH_MULTIPLICATION_OVERFLOW");
    return result;
  }
}

//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

/**
 * @title IReserveInterestRateStrategyInterface interface
 * @dev Interface for the calculation of the interest rates
 * @author Aave
 */
interface IReserveInterestRateStrategy {
  function variableRateSlope() external view returns (uint256);

  function baseVariableBorrowRate() external view returns (uint256);

  function getMaxVariableBorrowRate() external view returns (uint256);

  function calculateInterestRates(
    address reserve,
    uint256 availableLiquidity,
    uint256 totalVariableDebt,
    uint256 reserveFactor
  )
    external
    view
    returns (
      uint256,
      uint256
    );

  function calculateInterestRates(
    address reserve,
    address aToken,
    uint256 liquidityAdded,
    uint256 liquidityTaken,
    uint256 totalVariableDebt,
    uint256 reserveFactor
  )
    external
    view
    returns (
      uint256 liquidityRate,
      uint256 variableBorrowRate
    );
}

//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { WadRayMathLib } from "../lib/WadRayMathLib.sol";
import { FixedPointMathLib } from "../lib/FixedPointMathLib.sol";
import { PercentageMathLib } from "../lib/PercentageMathLib.sol";
import { IReserveInterestRateStrategy } from "../interfaces/IReserveInterestRateStrategy.sol";

// Modified from Aave interest rate strategy
/**
 * @title DefaultReserveInterestRateStrategy contract
 * @notice Implements the calculation of the interest rates depending on the reserve state
 * @dev The model of interest rate is based on 2 slopes, one before the `OPTIMAL_UTILIZATION_RATE`
 * point of utilization and another from that one to 100%
 * - An instance of this same contract, can"t be used across different Aave markets, due to the caching
 *   of the LendingPoolAddressesProvider
 * @author Aave
 **/
contract DefaultReserveInterestRateStrategy is IReserveInterestRateStrategy {
  using WadRayMathLib for uint256;
  using FixedPointMathLib for uint256;
  using PercentageMathLib for uint256;
  using SafeMath for uint256;

  /**
   * @dev this constant represents the utilization rate at which the pool aims to obtain most competitive borrow rates.
   * Expressed in ray
   **/
  uint256 public immutable OPTIMAL_UTILIZATION_RATE;

  /**
   * @dev This constant represents the excess utilization rate above the optimal. It"s always equal to
   * 1-optimal utilization rate. Added as a constant here for gas optimizations.
   * Expressed in ray
   **/

  uint256 public immutable EXCESS_UTILIZATION_RATE;

  // Base variable borrow rate when Utilization rate = 0. Expressed in ray
  uint256 internal immutable _baseVariableBorrowRate;

  // Slope of the variable interest curve when utilization rate > 0 and <= OPTIMAL_UTILIZATION_RATE. Expressed in ray
  uint256 internal immutable _variableRateSlope1;

  // Slope of the variable interest curve when utilization rate > OPTIMAL_UTILIZATION_RATE. Expressed in ray
  uint256 internal immutable _variableRateSlope2;

  constructor(
    uint256 optimalUtilizationRate,
    uint256 baseVariableBorrowRate,
    uint256 variableRateSlope1,
    uint256 variableRateSlope2
  ) public {
    OPTIMAL_UTILIZATION_RATE = optimalUtilizationRate;
    EXCESS_UTILIZATION_RATE = FixedPointMathLib.WAD.sub(optimalUtilizationRate);
    _baseVariableBorrowRate = baseVariableBorrowRate;
    _variableRateSlope1 = variableRateSlope1;
    _variableRateSlope2 = variableRateSlope2;
  }

  function variableRateSlope1() external view returns (uint256) {
    return _variableRateSlope1;
  }

  function variableRateSlope2() external view returns (uint256) {
    return _variableRateSlope2;
  }

  function variableRateSlope() external view returns (uint256) {
    return _variableRateSlope1.add(_variableRateSlope2);
  }

  function baseVariableBorrowRate() external view override returns (uint256) {
    return _baseVariableBorrowRate;
  }

  function getMaxVariableBorrowRate() external view override returns (uint256) {
    return _baseVariableBorrowRate.add(_variableRateSlope1).add(_variableRateSlope2);
  }

  /**
   * @dev Calculates the interest rates depending on the reserve"s state and configurations
   * @param reserve The address of the reserve
   * @param liquidityAdded The liquidity added during the operation
   * @param liquidityTaken The liquidity taken during the operation
   * @param totalVariableDebt The total borrowed from the reserve at a variable rate
   * @param reserveFactor The reserve portion of the interest that goes to the treasury of the market
   * @return The liquidity rate and the variable borrow rate
   **/
  function calculateInterestRates(
    address reserve,
    address aToken,
    uint256 liquidityAdded,
    uint256 liquidityTaken,
    uint256 totalVariableDebt,
    uint256 reserveFactor
  )
    external
    view
    override
    returns (
      uint256,
      uint256
    )
  {
    uint256 availableLiquidity = IERC20(aToken).balanceOf(reserve);
    uint256 totalLiquidity = availableLiquidity.add(liquidityAdded);
    require(totalLiquidity > liquidityTaken, "Interest: Inconsistent state");
    //avoid stack too deep
    availableLiquidity = availableLiquidity.add(liquidityAdded).sub(liquidityTaken);

    return
      calculateInterestRates(
        reserve,
        availableLiquidity,
        totalVariableDebt,
        reserveFactor
      );
  }

  struct CalcInterestRatesLocalVars {
    uint256 totalDebt;
    uint256 currentVariableBorrowRate;
    uint256 currentLiquidityRate;
    uint256 utilizationRate;
  }

  /**
   * @dev Calculates the interest rates depending on the reserve"s state and configurations.
   * NOTE This function is kept for compatibility with the previous DefaultInterestRateStrategy interface.
   * New protocol implementation uses the new calculateInterestRates() interface
   * @param reserve The address of the reserve
   * @param availableLiquidity The liquidity available in the corresponding aToken
   * @param totalVariableDebt The total borrowed from the reserve at a variable rate
   * @param reserveFactor The reserve portion of the interest that goes to the treasury of the market
   * @return The liquidity rate, the stable borrow rate and the variable borrow rate
   **/
  function calculateInterestRates(
    address reserve,
    uint256 availableLiquidity,
    uint256 totalVariableDebt,
    uint256 reserveFactor
  )
    public
    view
    override
    returns (
      uint256,
      uint256
    )
  {
    CalcInterestRatesLocalVars memory vars;

    vars.currentVariableBorrowRate = 0;
    vars.currentLiquidityRate = 0;

    vars.utilizationRate = vars.totalDebt == 0
      ? 0
      : vars.totalDebt.divWadUp(availableLiquidity.add(vars.totalDebt));

    if (vars.utilizationRate > OPTIMAL_UTILIZATION_RATE) {
      uint256 excessUtilizationRateRatio =
        vars.utilizationRate.sub(OPTIMAL_UTILIZATION_RATE).divWadUp(EXCESS_UTILIZATION_RATE);

      vars.currentVariableBorrowRate = _baseVariableBorrowRate.add(_variableRateSlope1).add(
        _variableRateSlope2.mulWadUp(excessUtilizationRateRatio)
      );
    } else {
      vars.currentVariableBorrowRate = _baseVariableBorrowRate.add(
        vars.utilizationRate.mulWadUp(_variableRateSlope1).divWadDown(OPTIMAL_UTILIZATION_RATE)
      );
    }

    vars.currentLiquidityRate = _getOverallBorrowRate(
      totalVariableDebt,
      vars.currentVariableBorrowRate
    )
      .mulWadUp(vars.utilizationRate)
      .percentMul(PercentageMathLib.PERCENTAGE_FACTOR.sub(reserveFactor));

    return (
      vars.currentLiquidityRate,
      vars.currentVariableBorrowRate
    );
  }

  /**
   * @dev Calculates the overall borrow rate as the weighted average between the total variable debt and total stable debt
   * @param totalVariableDebt The total borrowed from the reserve at a variable rate
   * @param currentVariableBorrowRate The current variable borrow rate of the reserve
   * @return The weighted averaged borrow rate
   **/
  function _getOverallBorrowRate(
    uint256 totalVariableDebt,
    uint256 currentVariableBorrowRate
  ) internal pure returns (uint256) {
    uint256 totalDebt = (totalVariableDebt);

    if (totalDebt == 0) return 0;

    uint256 weightedVariableRate = totalVariableDebt.mulWadDown(currentVariableBorrowRate);
    uint256 overallBorrowRate = weightedVariableRate.divWadDown(totalDebt);

    return overallBorrowRate;
  }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

interface IPriceFeed {
    /// @notice The token this feed returns a price for.
    /// @return address token addrss.
    function token() external view returns (address);

    /// @notice Get latest price of asset. For ERC-20 tokens, `tokenID` parameter is unused.
    /// tokenID parameter is for forwards compatibility.
    /// @param token address of the asset's token.
    /// @param amount The number of tokens
    /// @return price the price of the asset
    function readPrice(address token, uint256 amount) external view returns (int price);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

/**
 * @title PercentageMath library
 * @author Aave
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMathLib {
  uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
  uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;

  /**
   * @dev Executes a percentage multiplication
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The percentage of value
   **/
  function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256) {
    if (value == 0 || percentage == 0) {
      return 0;
    }

    require(
      value <= (type(uint256).max - HALF_PERCENT) / percentage,
      "MATH_MULTIPLICATION_OVERFLOW"
    );

    return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
  }

  /**
   * @dev Executes a percentage division
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The value divided the percentage
   **/
  function percentDiv(uint256 value, uint256 percentage) internal pure returns (uint256) {
    require(percentage != 0, "MATH_DIVISION_BY_ZERO");
    uint256 halfPercentage = percentage / 2;

    require(
      value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR,
      "MATH_MULTIPLICATION_OVERFLOW"
    );

    return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
  }
}