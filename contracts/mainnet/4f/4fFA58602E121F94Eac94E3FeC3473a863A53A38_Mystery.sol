//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IUniswapV2Router01.sol";

interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract Mystery is OwnableUpgradeable{
    address payable public companyWallet;
    uint256 public minPrice;
    uint256 public feePercentage;
    uint256 private whiteListPrice;
    bool private whiteListSale;
    mapping(address => bool) private whitelistedAddresses;

    uint256 private currencyType;
    address public constant WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address public constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address private constant QUICKSWAP_V2_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;

    event PriceChanged(uint256 indexed price);

    function initialize()
        public
        initializer
    {
        __Ownable_init();
    }

    function setCompanyWallet(address payable _companyWallet)
    external
    onlyOwner
    {
        require(_companyWallet != address(0), "Invalid wallet address");
        companyWallet = _companyWallet;
    }


    /* 
    * @dev Set the mystery box normal price, fee percentage. currency
    * @param _minPrice Mystery Box Price for normal users in any currency
    * @param _feePercentage Fee Percentage to company wallet
    * @param _currency Currency for the mystery box price 
                    1 => WETH
                    2 => USDC
    */
    function setFeeParams(uint256 _minPrice, uint256 _feePercentage, uint256 _currency)
    external
    onlyOwner
    {
        require(_minPrice > 0, "Min Price should be bigger than 0");
        require(_feePercentage < 100, "Fee Percentage should be smaller than 100%");
        
        minPrice = _minPrice;
        feePercentage = _feePercentage;
        currencyType = _currency;
        
        emit PriceChanged(_minPrice);
    }

    function checkWhiteList(address _address) public view returns(bool, bool){
        if(whiteListSale == true) {
            return (whitelistedAddresses[_address], true);
        }
        return (true, false);
    }

    function addWhiteList(address[] memory _address) external onlyOwner{
        for (uint i = 0; i < _address.length; i++) {
            whitelistedAddresses[_address[i]] = true;
        }
    }

    /* 
    * @dev Set the whitelist price for the mystery box
    * @param _wlPrice WhiteList Price in any currency
    * @param _wlType Currency for the mystery box price 
                    1 => WETH
                    2 => USDC
    */
    function setWhiteListPrice(uint256 _wlPrice, uint256 _wlType) external onlyOwner{
        require(currencyType == _wlType, "Currency should be the same");
        require(whiteListPrice <= minPrice, "White-list price should be less than the normal price");
        whiteListPrice = _wlPrice;
    }

    function setWhiteListOption(bool _option) external onlyOwner{
        whiteListSale = _option;
    }

    function getPriceInETH()  public view returns (uint256) { 
        if (currencyType == 1) {
            return minPrice;
        } else {
            address[] memory path = new address[](2);
            path[0] = WETH;
            path[1] = USDC;
            uint256[] memory amounts = IUniswapV2Router01(QUICKSWAP_V2_ROUTER).getAmountsIn(
                minPrice,
                path
            );
            return amounts[0];
        }
    }

    function getPriceInUSD()  public view returns (uint256) { 
        if (currencyType != 1) {
            return minPrice;
        } else {
            address[] memory path = new address[](2);
            path[0] = USDC;
            path[1] = WETH;
            uint256[] memory amounts = IUniswapV2Router01(QUICKSWAP_V2_ROUTER).getAmountsIn(
                minPrice,
                path
            );
            return amounts[0];
        }
    }

    function getWhiteListPriceInETH()  public view returns (uint256) { 
        if (currencyType == 1) {
            return whiteListPrice;
        } else {
            address[] memory path = new address[](2);
            path[0] = WETH;
            path[1] = USDC;
            uint256[] memory amounts = IUniswapV2Router01(QUICKSWAP_V2_ROUTER).getAmountsIn(
                whiteListPrice,
                path
            );
            return amounts[0];
        }
    }

    function getWhiteListPriceInUSD()  public view returns (uint256) { 
        if (currencyType != 1) {
            return whiteListPrice;
        } else {
            address[] memory path = new address[](2);
            path[0] = USDC;
            path[1] = WETH;
            uint256[] memory amounts = IUniswapV2Router01(QUICKSWAP_V2_ROUTER).getAmountsIn(
                whiteListPrice,
                path
            );
            return amounts[0];
        }
    }

    function transferItem(address[] memory _contract, address[] memory from, uint256[] memory id, uint256 quantity, uint256 paymentType) 
    external payable 
    returns (bool) 
    {
        require(quantity > 0, "Quantity should be bigger than zero.");
        if( whiteListSale == true ) {
            require(whitelistedAddresses[_msgSender()] == true, "Only whitelisted users can purchase");
        }

        uint256 itemPrice = 0;
        if(paymentType == 1) {
            itemPrice = whitelistedAddresses[_msgSender()] ? this.getWhiteListPriceInETH() : this.getPriceInETH();
            require(IERC20(WETH).allowance(_msgSender(), address(this)) >= itemPrice * quantity, "Insufficient fund");
        } else {
            itemPrice = whitelistedAddresses[_msgSender()] ? this.getWhiteListPriceInUSD() : this.getPriceInUSD();
            require(IERC20(USDC).allowance(_msgSender(), address(this)) >= itemPrice * quantity, "Insufficient fund");
        }
        uint256 priceTotal = itemPrice * quantity;
    

        uint256 _feeAmount = priceTotal / 100 * feePercentage;
        uint256 _payAmount = priceTotal - _feeAmount;
        if( _feeAmount > 0) {
            bool fee = IERC20(paymentType == 1 ? WETH : USDC).transferFrom(_msgSender(), companyWallet, _feeAmount);
            require(fee, "Fee Transfer failed.");
        }
        
        if(_contract.length == 1) {
            bool success = IERC20(paymentType == 1 ? WETH : USDC).transferFrom(_msgSender(), from[0], _payAmount);
            require(success, "Transfer failed.");
            IERC1155(_contract[0]).safeTransferFrom(from[0], _msgSender(), id[0], quantity, "");
        } else {
            for (uint i = 0; i < quantity; i++) {
                IERC1155(_contract[i]).safeTransferFrom(from[i], _msgSender(), id[i], 1, "");
                bool success = IERC20(paymentType == 1 ? WETH : USDC).transferFrom(_msgSender(), from[i], _payAmount / quantity);
                require(success, "Transfer failed.");
            }
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}