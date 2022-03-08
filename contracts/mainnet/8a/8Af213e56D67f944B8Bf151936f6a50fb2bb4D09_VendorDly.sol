// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// token
import "./PriceConsumerV3.sol";
import "./DlyToken.sol";
import "./TetherUSDToken.sol";
import "./USDCoinToken.sol";
import "./WrappedEtherToken.sol";
import "./WrappedBTCToken.sol";

contract VendorDly is
    Context,
    Ownable,
    Pausable,
    PriceConsumerV3,
    DlyToken,
    TetherUSDToken,
    USDCoinToken,
    WrappedEtherToken,
    WrappedBTCToken
{
    constructor(
        address _dlyTokenAddress,
        address _usdtTokenAddress,
        address _usdcTokenAddress,
        address _wethTokenAddress,
        address _wbtcTokenAddress
    )
        DlyToken(_dlyTokenAddress)
        TetherUSDToken(_usdtTokenAddress, _dlyTokenAddress)
        USDCoinToken(_usdcTokenAddress, _dlyTokenAddress)
        WrappedEtherToken(_wethTokenAddress, _dlyTokenAddress)
        WrappedBTCToken(_wbtcTokenAddress, _dlyTokenAddress)
    {}

    // @dev Allow the owner of the contract to withdraw MATIC X
    function withdrawMAtic() public onlyOwner {
        uint256 ownerBalance = address(this).balance;
        require(ownerBalance > 0, "Owner has not balance to withdraw");

        (bool sent, ) = _msgSender().call{value: address(this).balance}("");
        require(sent, "Failed to send user balance back to the owner");
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PriceConsumerV3 is Ownable {
    AggregatorV3Interface internal priceFeedMATICUSD;
    AggregatorV3Interface internal priceFeedWETHUSD;
    AggregatorV3Interface internal priceFeedWBTCUSD;
    AggregatorV3Interface internal priceFeedCOPUSD;

    uint256 public initial_price_fiat_usd = 1000000000000000000;
    uint256 public price_fiat_usd;

    uint256 public initial_price_fiat_cop = 3777000000000000000;
    uint256 public price_fiat_cop;

    uint256 public initial_price_fiat_usd_fixed = 1000000000000000000;
    uint256 public price_fiat_usd_fixed;

    constructor() {
        /**
         * Network: POLYGON MAINNET
         * Aggregator: MATIC / USD
         * Dec: 8
         * Address: 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
         */
        priceFeedMATICUSD = AggregatorV3Interface(
            0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
        );

        /**
         * Network: POLYGON MAINNET
         * Aggregator: WBTC / USD
         * Dec: 8
         * Address: 0xDE31F8bFBD8c84b5360CFACCa3539B938dd78ae6
         */
        priceFeedWBTCUSD = AggregatorV3Interface(
            0xDE31F8bFBD8c84b5360CFACCa3539B938dd78ae6
        );

        /**
         * Network: POLYGON MAINNET
         * Aggregator: ETH / USD
         * Dec: 8
         * Address: 0xF9680D99D6C9589e2a93a78A04A279e509205945
         */
        priceFeedWETHUSD = AggregatorV3Interface(
            0xF9680D99D6C9589e2a93a78A04A279e509205945
        );

        /**
         * Network: POLYGON MAINNET
         * Aggregator: COP / USD
         * Dec: 8
         * Address: 0xDe6302Dfa0ac45B2B1b1a23304469DA630b2F59B
         */
        priceFeedCOPUSD = AggregatorV3Interface(
            0xDe6302Dfa0ac45B2B1b1a23304469DA630b2F59B
        );

        price_fiat_usd = initial_price_fiat_usd;
        price_fiat_cop = initial_price_fiat_cop;
        price_fiat_usd_fixed = initial_price_fiat_usd_fixed;
    }

    // @dev Returns the latest price MATIC / USD
    function getLatestPriceMATICUSD() public view returns (int256) {
        (, int256 price, , , ) = priceFeedMATICUSD.latestRoundData();
        return price * 10**10;
    }

    // @dev Returns the latest price WBTC / USD
    function getLatestPriceWBTCUSD() public view returns (int256) {
        (, int256 price, , , ) = priceFeedWBTCUSD.latestRoundData();
        return price * 10**10;
    }

    // @dev Returns the latest price ETH / USD
    function getLatestPriceWETHUSD() public view returns (int256) {
        (, int256 price, , , ) = priceFeedWETHUSD.latestRoundData();
        return price * 10**10;
    }

    // @dev Returns the latest price COP / USD
    function getLatestPriceCOPUSD() public view returns (int256) {
        (, int256 price, , , ) = priceFeedCOPUSD.latestRoundData();
        return price * 10**10;
    }

    // @dev Returns the latest price   USD/COP
    // value de un dolar en peso colombianos COP
    function getLatestPriceUSDCOP() public view returns (uint256) {
        uint256 valueCOPinUSD = 1000000000000000000 /
            uint256(getLatestPriceCOPUSD());
        return valueCOPinUSD;
    }

    // @dev  get the value in tokens
    function getPriceNowMATICUSD() public view returns (uint256) {
        return
            (price_fiat_usd * 1000000000000000000) /
            uint256(getLatestPriceMATICUSD());
    }

    // @dev Set a different price in case MATIC FIAT USD changes drastically
    function setPriceFiatUsd(uint256 newPrice) public onlyOwner {
        price_fiat_usd = newPrice;
    }

    // @dev Set a different price in case MATIC FIAT COP changes drastically
    function setPriceFiatCOP(uint256 newPrice) public onlyOwner {
        price_fiat_cop = newPrice;
    }

    // @dev Set a different price in case MATIC FIAT COP changes drastically
    function setPriceFiatUSDFi(uint256 newPrice) public onlyOwner {
        price_fiat_usd_fixed = newPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PriceConsumerV3.sol";

contract DlyToken is Context, Ownable, Pausable, PriceConsumerV3 {
    IERC20 private _dlyToken;

    // Event that log buy operation
    event BuyTokensMATICbyDLY(
        address buyer,
        uint256 amountOfMatic,
        uint256 amountOfTokens
    );
    event SellTokensDLYbyMATIC(
        address seller,
        uint256 amountOfTokens,
        uint256 amountOfMatic
    );

    // This is the contract address (DLYTEST)
    constructor(address dlyTokenAddress) {
        _dlyToken = IERC20(dlyTokenAddress);
    }

    // @dev approve function
    function approve(address tokenOwner, uint256 amount) public returns (bool) {
        _dlyToken.approve(tokenOwner, amount);
        return true;
    }

    // @dev approve function
    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _dlyToken.allowance(owner, spender);
    }

    // @dev  Allow users to buy tokens for MATIC by DLY
    function buyDLY() public payable returns (uint256 tokenAmount) {
        require(msg.value > 0, "Send MATIC to buy some tokens");

        // Get the amount of tokens that the user will receive
        // convert cop to usd
        uint256 valueBTCinUSD = (msg.value *
            uint256(getLatestPriceMATICUSD())) / 1000000000000000000;

        // token dly para enviar al sender
        uint256 amountToBuy = (valueBTCinUSD * getLatestPriceUSDCOP()) /
            1000000000000000000;

        // check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 vendorBalance = _dlyToken.balanceOf(address(this));
        require(
            vendorBalance >= amountToBuy,
            "Vendor contract has not enough tokens in its balance"
        );

        // Transfer token to the msg.sender
        bool sent = _dlyToken.transfer(_msgSender(), amountToBuy);
        require(sent, "Failed to transfer token to user");

        // emit the event
        emit BuyTokensMATICbyDLY(_msgSender(), msg.value, amountToBuy);

        return amountToBuy;
    }

    // @dev Allow users to sell tokens for sell DLY by MATIC
    function sellDLY(uint256 tokenAmountToSell)
        public
        returns (uint256 tokenAmount)
    {
        // Check that the requested amount of tokens to sell is more than 0
        require(
            tokenAmountToSell > 0,
            "Specify an amount of token greater than zero"
        );

        // Check that the user's token balance is enough to do the swap
        uint256 userBalance = _dlyToken.balanceOf(_msgSender());
        require(
            userBalance >= tokenAmountToSell,
            "Your balance is lower than the amount of tokens you want to sell"
        );

        // Check that the Vendor's balance is enough to do the swap
        uint256 COPtoUSD = tokenAmountToSell * uint256(getLatestPriceCOPUSD());

        // matic amount to send to sender
        uint256 amountToTransferMATIC = COPtoUSD /
            uint256(getLatestPriceMATICUSD());

        uint256 ownerMATICBalance = address(this).balance;
        require(
            ownerMATICBalance >= amountToTransferMATIC,
            "Vendor has not enough funds to accept the sell request"
        );

        // Transfer token to the msg.sender
        bool sent = _dlyToken.transferFrom(
            _msgSender(),
            address(this),
            tokenAmountToSell
        );
        require(sent, "Failed to transfer tokens from user to vendor");

        (sent, ) = _msgSender().call{value: amountToTransferMATIC}("");
        require(sent, "Failed to send MATIC to the user");

        return tokenAmountToSell;
    }

    // @dev Allow the owner of the contract to withdraw DLY TOKEN
    function withdrawDLY(uint256 tokenAmount) public onlyOwner {
        uint256 dlyBalance = _dlyToken.balanceOf(address(this));
        require(dlyBalance >= tokenAmount, "Owner has not balance to withdraw");

        // Transfer token to the msg.sender
        bool sent = _dlyToken.transfer(_msgSender(), tokenAmount);
        require(sent, "Failed to transfer token to user");
    }

    // @dev balanceOf will return the account balance for the given account
    function balanceOfdly(address _address) public view returns (uint256) {
        return _dlyToken.balanceOf(_address);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PriceConsumerV3.sol";
import "./DlyToken.sol";

contract TetherUSDToken is Context, Ownable, Pausable, PriceConsumerV3 {
    IERC20 private usdtToken;
    IERC20 private dlyTokenUsdt;

    // Event that log buy operation
    event BuyTokensUSDT(
        address buyer,
        uint256 amountOfMatic,
        uint256 amountOfTokens
    );
    event SellTokensUSDT(
        address seller,
        uint256 amountOfTokens,
        uint256 amountOfMatic
    );

    constructor(address usdtTokenAddress, address dlyTokenAddress) {
        usdtToken = IERC20(usdtTokenAddress);
        dlyTokenUsdt = IERC20(dlyTokenAddress);
    }

    // @dev  Allow users to buy tokens for buy  usdt by dly
    function buyUsdt(uint256 tokenAmountToBuy)
        public
        returns (uint256 tokenAmount)
    {
        require(
            tokenAmountToBuy > 0,
            "Specify an amount of token greater than zero"
        );

        // Check that the user's token balance is enough to do the swap
        uint256 userBalance = balanceOfUSDT(_msgSender());
        require(
            userBalance >= tokenAmountToBuy,
            "Your balance is lower than the amount of tokens you want to sell"
        );

        // Get the amount of tokens that the user will receive
        uint256 amountToBuy = tokenAmountToBuy /
            uint256(getLatestPriceCOPUSD());

        // check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 vendorBalance = dlyTokenUsdt.balanceOf(address(this));
        require(
            vendorBalance >= amountToBuy,
            "Vendor contract has not enough tokens in its balance"
        );

        // Transfer token to the msg.sender USDT => WALLET CONTRACT
        bool sent = usdtToken.transferFrom(
            _msgSender(),
            address(this),
            tokenAmountToBuy
        );
        require(sent, "Failed to transfer tokens from user to vendor");

        // Transfer token to the msg.sender DLY => SENDER
        bool sent2 = dlyTokenUsdt.transfer(_msgSender(), amountToBuy);
        require(sent2, "Failed to transfer token to user");

        // emit the event
        emit BuyTokensUSDT(_msgSender(), tokenAmountToBuy, amountToBuy);

        return amountToBuy;
    }

    // @dev Allow users to sell tokens for sell DLY by USDT
    function sellUSDT(uint256 tokenAmountToSell)
        public
        returns (uint256 tokenAmount)
    {
        // Check that the requested amount of tokens to sell is more than 0
        require(
            tokenAmountToSell > 0,
            "Specify an amount of token greater than zero"
        );

        // Check that the user's token balance is enough to do the swap
        uint256 userBalance = dlyTokenUsdt.balanceOf(_msgSender());
        require(
            userBalance >= tokenAmountToSell,
            "Your balance is lower than the amount of tokens you want to sell"
        );

        // Check that the Vendor's balance is enough to do the swap
        uint256 amountToTransfer = tokenAmountToSell *
            uint256(getLatestPriceCOPUSD());

        // check balance usdt of vendor
        uint256 vendorBalance = dlyTokenUsdt.balanceOf(address(this));
        require(
            vendorBalance >= amountToTransfer,
            "Vendor has not enough funds to accept the sell request"
        );

        // Transfer token to the msg.sender DLY TOKEN =>  SMART CONTRACT
        bool sent = dlyTokenUsdt.transferFrom(
            _msgSender(),
            address(this),
            tokenAmountToSell
        );
        require(sent, "Failed to transfer tokens from user to vendor");

        // Transfer token to the msg.sender USDT => sender
        bool sent2 = usdtToken.transfer(_msgSender(), amountToTransfer);
        require(sent2, "Failed to transfer token to user");

        emit SellTokensUSDT(_msgSender(), tokenAmountToSell, amountToTransfer);

        return tokenAmountToSell;
    }

    // @dev approve function
    function allowanceUsdt(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return usdtToken.allowance(owner, spender);
    }

    // @dev approve function
    function approveUsdt(address tokenOwner, uint256 amount)
        public
        returns (bool)
    {
        usdtToken.approve(tokenOwner, amount);
        return true;
    }

    // @dev Allow the owner of the contract to withdraw DLY TOKEN
    function withdrawUsdt(uint256 tokenAmount) public onlyOwner {
        uint256 balanceToken = usdtToken.balanceOf(address(this));
        require(
            balanceToken >= tokenAmount,
            "Owner has not balance to withdraw"
        );

        // @dev Transfer token to the msg.sender
        bool sent = usdtToken.transfer(_msgSender(), tokenAmount);
        require(sent, "Failed to transfer token to user");
    }

    // @dev balanceOf will return the account balance for the given account
    function balanceOfUSDT(address _address) public view returns (uint256) {
        return usdtToken.balanceOf(_address);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PriceConsumerV3.sol";
import "./DlyToken.sol";

contract USDCoinToken is Context, Ownable, Pausable, PriceConsumerV3 {
    IERC20 private _usdCoinToken;
    IERC20 private _dlyTokenUsdc;

    // Event that log buy operation
    event BuyTokensUSDC(
        address buyer,
        uint256 amountOfMatic,
        uint256 amountOfTokens
    );
    event SellTokensUSDC(
        address seller,
        uint256 amountOfTokens,
        uint256 amountOfMatic
    );

    constructor(address usdCoinToken, address _dlyToken) {
        _usdCoinToken = IERC20(usdCoinToken);
        _dlyTokenUsdc = IERC20(_dlyToken);
    }

    // @dev  Allow users to buy tokens for buy  usdt by dly
    function buyUSDC(uint256 tokenAmountToBuy)
        public
        returns (uint256 tokenAmount)
    {
        require(
            tokenAmountToBuy > 0,
            "Specify an amount of token greater than zero"
        );

        // Check that the user's token balance is enough to do the swap
        uint256 userBalance = balanceOfUSDC(_msgSender());
        require(
            userBalance >= tokenAmountToBuy,
            "Your balance is lower than the amount of tokens you want to sell"
        );

        // Get the amount of tokens that the user will receive
        uint256 amountToBuy = tokenAmountToBuy /
            uint256(getLatestPriceCOPUSD());

        // check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 vendorBalance = _dlyTokenUsdc.balanceOf(address(this));
        require(
            vendorBalance >= amountToBuy,
            "Vendor contract has not enough tokens in its balance"
        );

        // Transfer token to the msg.sender USDT => WALLET CONTRACT
        bool sent = _usdCoinToken.transferFrom(
            _msgSender(),
            address(this),
            tokenAmountToBuy
        );
        require(sent, "Failed to transfer tokens from user to vendor");

        // Transfer token to the msg.sender DLY => SENDER
        bool sent2 = _dlyTokenUsdc.transfer(_msgSender(), amountToBuy);
        require(sent2, "Failed to transfer token to user");

        // emit the event
        emit BuyTokensUSDC(_msgSender(), tokenAmountToBuy, amountToBuy);

        return amountToBuy;
    }

    // @dev Allow users to sell tokens for sell DLY by USDT
    function sellUSDC(uint256 tokenAmountToSell)
        public
        returns (uint256 tokenAmount)
    {
        // Check that the requested amount of tokens to sell is more than 0
        require(
            tokenAmountToSell > 0,
            "Specify an amount of token greater than zero"
        );

        // Check that the user's token balance is enough to do the swap
        uint256 userBalance = _dlyTokenUsdc.balanceOf(_msgSender());
        require(
            userBalance >= tokenAmountToSell,
            "Your balance is lower than the amount of tokens you want to sell"
        );

        // Check that the Vendor's balance is enough to do the swap
        uint256 amountToTransfer = tokenAmountToSell *
            uint256(getLatestPriceCOPUSD());

        // check balance usdt of vendor
        uint256 vendorBalance = _dlyTokenUsdc.balanceOf(address(this));
        require(
            vendorBalance >= amountToTransfer,
            "Vendor has not enough funds to accept the sell request"
        );

        // Transfer token to the msg.sender DLY TOKEN =>  SMART CONTRACT
        bool sent = _dlyTokenUsdc.transferFrom(
            _msgSender(),
            address(this),
            tokenAmountToSell
        );
        require(sent, "Failed to transfer tokens from user to vendor");

        // Transfer token to the msg.sender USDT => sender
        bool sent2 = _usdCoinToken.transfer(_msgSender(), amountToTransfer);
        require(sent2, "Failed to transfer token to user");

        emit SellTokensUSDC(_msgSender(), tokenAmountToSell, amountToTransfer);

        return tokenAmountToSell;
    }

    // @dev approve function
    function allowanceUSDC(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _usdCoinToken.allowance(owner, spender);
    }

    // @dev approve function
    function approveUSDC(address tokenOwner, uint256 amount)
        public
        returns (bool)
    {
        _usdCoinToken.approve(tokenOwner, amount);
        return true;
    }

    // @dev Allow the owner of the contract to withdraw DLY TOKEN
    function withdrawUSDC(uint256 tokenAmount) public onlyOwner {
        uint256 balanceToken = _usdCoinToken.balanceOf(address(this));
        require(
            balanceToken >= tokenAmount,
            "Owner has not balance to withdraw"
        );

        // @dev Transfer token to the msg.sender
        bool sent = _usdCoinToken.transfer(_msgSender(), tokenAmount);
        require(sent, "Failed to transfer token to user");
    }

    // @dev balanceOf will return the account balance for the given account
    function balanceOfUSDC(address _address) public view returns (uint256) {
        return _usdCoinToken.balanceOf(_address);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PriceConsumerV3.sol";
import "./DlyToken.sol";

contract WrappedEtherToken is Context, Ownable, Pausable, PriceConsumerV3 {
    IERC20 private wrappedEtherToken;
    IERC20 private dlyTokenETH;

    // Event that log buy operation
    event BuyTokensETH(
        address buyer,
        uint256 amountOfMatic,
        uint256 amountOfTokens
    );
    event SellTokensETH(
        address seller,
        uint256 amountOfTokens,
        uint256 amountOfMatic
    );

    constructor(address wethTokenAddress, address dlyTokenAddress) {
        wrappedEtherToken = IERC20(wethTokenAddress);
        dlyTokenETH = IERC20(dlyTokenAddress);
    }

    // @dev  Allow users to buy tokens for buy  usdt by dly
    function buyETH(uint256 tokenAmountToBuy)
        public
        returns (uint256 tokenAmount)
    {
        require(
            tokenAmountToBuy > 0,
            "Specify an amount of token greater than zero"
        );

        // Check that the user's token balance is enough to do the swap
        uint256 userBalance = balanceOfETH(_msgSender());
        require(
            userBalance >= tokenAmountToBuy,
            "Your balance is lower than the amount of tokens you want to sell"
        );

        // Get the amount of tokens that the user will receive
        // valor de en dolares de los btc enviados
        uint256 valueETHinUSD = (tokenAmountToBuy *
            uint256(getLatestPriceWETHUSD())) / 1000000000000000000;

        // token dly para enviar al sender
        uint256 amountToBuy = (valueETHinUSD * getLatestPriceUSDCOP()) /
            1000000000000000000;

        // check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 vendorBalance = dlyTokenETH.balanceOf(address(this));
        require(
            vendorBalance >= amountToBuy,
            "Vendor contract has not enough tokens in its balance"
        );

        // Transfer token to the msg.sender USDT => WALLET CONTRACT
        bool sent = wrappedEtherToken.transferFrom(
            _msgSender(),
            address(this),
            tokenAmountToBuy
        );
        require(sent, "Failed to transfer tokens from user to vendor");

        // Transfer token to the msg.sender DLY => SENDER
        bool sent2 = dlyTokenETH.transfer(_msgSender(), amountToBuy);
        require(sent2, "Failed to transfer token to user");

        // emit the event
        emit BuyTokensETH(_msgSender(), tokenAmountToBuy, amountToBuy);

        return amountToBuy;
    }

    // @dev Allow users to sell tokens for sell DLY by USDT
    function sellETH(uint256 tokenAmountToSell)
        public
        returns (uint256 tokenAmount)
    {
        // Check that the requested amount of tokens to sell is more than 0
        require(
            tokenAmountToSell > 0,
            "Specify an amount of token greater than zero"
        );

        // Check that the user's token balance is enough to do the swap
        uint256 userBalance = dlyTokenETH.balanceOf(_msgSender());
        require(
            userBalance >= tokenAmountToSell,
            "Your balance is lower than the amount of tokens you want to sell"
        );

        // Check that the Vendor's balance is enough to do the swap
        // pasar de cop a usd
        uint256 COPtoUSD = tokenAmountToSell * uint256(getLatestPriceCOPUSD());

        // monto de wbtc a enviar a sender
        uint256 amountToTransferWETH = COPtoUSD /
            uint256(getLatestPriceWETHUSD());

        // check balance usdt of vendor
        uint256 vendorBalance = dlyTokenETH.balanceOf(address(this));
        require(
            vendorBalance >= amountToTransferWETH,
            "Vendor has not enough funds to accept the sell request"
        );

        // Transfer token to the msg.sender DLY TOKEN =>  SMART CONTRACT
        bool sent = dlyTokenETH.transferFrom(
            _msgSender(),
            address(this),
            tokenAmountToSell
        );
        require(sent, "Failed to transfer tokens from user to vendor");

        // Transfer token to the msg.sender USDT => sender
        bool sent2 = wrappedEtherToken.transfer(
            _msgSender(),
            amountToTransferWETH
        );
        require(sent2, "Failed to transfer token to user");

        emit SellTokensETH(
            _msgSender(),
            tokenAmountToSell,
            amountToTransferWETH
        );

        return tokenAmountToSell;
    }

    // @dev approve function
    function allowanceETH(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return wrappedEtherToken.allowance(owner, spender);
    }

    // @dev approve function
    function approveETH(address tokenOwner, uint256 amount)
        public
        returns (bool)
    {
        wrappedEtherToken.approve(tokenOwner, amount);
        return true;
    }

    // @dev Allow the owner of the contract to withdraw DLY TOKEN
    function withdrawETH(uint256 tokenAmount) public onlyOwner {
        uint256 balanceToken = wrappedEtherToken.balanceOf(address(this));
        require(
            balanceToken >= tokenAmount,
            "Owner has not balance to withdraw"
        );

        // @dev Transfer token to the msg.sender
        bool sent = wrappedEtherToken.transfer(_msgSender(), tokenAmount);
        require(sent, "Failed to transfer token to user");
    }

    // @dev balanceOf will return the account balance for the given account
    function balanceOfETH(address _address) public view returns (uint256) {
        return wrappedEtherToken.balanceOf(_address);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PriceConsumerV3.sol";
import "./DlyToken.sol";

contract WrappedBTCToken is Context, Ownable, Pausable, PriceConsumerV3 {
    IERC20 private _wrappedBTCToken;
    IERC20 private _dlyTokenBTC;

    // Event that log buy operation
    event BuyTokensBTC(
        address buyer,
        uint256 amountOfMatic,
        uint256 amountOfTokens
    );
    event SellTokensBTC(
        address seller,
        uint256 amountOfTokens,
        uint256 amountOfMatic
    );

    constructor(address wbtcTokenAddress, address dlyTokenAddress) {
        _wrappedBTCToken = IERC20(wbtcTokenAddress);
        _dlyTokenBTC = IERC20(dlyTokenAddress);
    }

    // @dev  Allow users to buy tokens for buy  usdt by dly
    function buyBTC(uint256 tokenAmountToBuy)
        public
        returns (uint256 tokenAmount)
    {
        require(
            tokenAmountToBuy > 0,
            "Specify an amount of token greater than zero"
        );

        // Check that the user's token balance is enough to do the swap
        uint256 userBalance = balanceOfBTC(_msgSender());
        require(
            userBalance >= tokenAmountToBuy,
            "Your balance is lower than the amount of tokens you want to sell"
        );

        // Get the amount of tokens that the user will receive
        // valor de en dolares de los btc enviados
        uint256 valueBTCinUSD = (tokenAmountToBuy *
            uint256(getLatestPriceWBTCUSD())) / 1000000000000000000;

        // token dly para enviar al sender
        uint256 amountToBuy = (valueBTCinUSD * getLatestPriceUSDCOP()) /
            1000000000000000000;

        // check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 vendorBalance = _dlyTokenBTC.balanceOf(address(this));
        require(
            vendorBalance >= amountToBuy,
            "Vendor contract has not enough tokens in its balance"
        );

        // Transfer token to the msg.sender USDT => WALLET CONTRACT
        bool sent = _wrappedBTCToken.transferFrom(
            _msgSender(),
            address(this),
            tokenAmountToBuy
        );
        require(sent, "Failed to transfer tokens from user to vendor");

        // Transfer token to the msg.sender DLY => SENDER
        bool sent2 = _dlyTokenBTC.transfer(_msgSender(), amountToBuy);
        require(sent2, "Failed to transfer token to user");

        // emit the event
        emit BuyTokensBTC(_msgSender(), tokenAmountToBuy, amountToBuy);

        return amountToBuy;
    }

    // @dev Allow users to sell tokens for sell DLY by USDT
    function sellBTC(uint256 tokenAmountToSell)
        public
        returns (uint256 tokenAmount)
    {
        // Check that the requested amount of tokens to sell is more than 0
        require(
            tokenAmountToSell > 0,
            "Specify an amount of token greater than zero"
        );

        // Check that the user's token balance is enough to do the swap
        uint256 userBalance = _dlyTokenBTC.balanceOf(_msgSender());
        require(
            userBalance >= tokenAmountToSell,
            "Your balance is lower than the amount of tokens you want to sell"
        );

        // Check that the Vendor's balance is enough to do the swap

        // pasar de cop a usd
        uint256 COPtoUSD = tokenAmountToSell * uint256(getLatestPriceCOPUSD());

        // monto de wbtc a enviar a sender
        uint256 amountToTransferWBTC = COPtoUSD /
            uint256(getLatestPriceWBTCUSD());

        // check balance usdt of vendor
        uint256 vendorBalance = _dlyTokenBTC.balanceOf(address(this));
        require(
            vendorBalance >= amountToTransferWBTC,
            "Vendor has not enough funds to accept the sell request"
        );

        // Transfer token to the msg.sender DLY TOKEN =>  SMART CONTRACT
        bool sent = _dlyTokenBTC.transferFrom(
            _msgSender(),
            address(this),
            tokenAmountToSell
        );
        require(sent, "Failed to transfer tokens from user to vendor");

        // Transfer token to the msg.sender USDT => sender
        bool sent2 = _wrappedBTCToken.transfer(
            _msgSender(),
            amountToTransferWBTC
        );
        require(sent2, "Failed to transfer token to user");

        emit SellTokensBTC(
            _msgSender(),
            tokenAmountToSell,
            amountToTransferWBTC
        );

        return tokenAmountToSell;
    }

    // @dev approve function
    function allowanceBTC(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _wrappedBTCToken.allowance(owner, spender);
    }

    // @dev approve function
    function approveBTC(address tokenOwner, uint256 amount)
        public
        returns (bool)
    {
        _wrappedBTCToken.approve(tokenOwner, amount);
        return true;
    }

    // @dev Allow the owner of the contract to withdraw DLY TOKEN
    function withdrawBTC(uint256 tokenAmount) public onlyOwner {
        uint256 balanceToken = _wrappedBTCToken.balanceOf(address(this));
        require(
            balanceToken >= tokenAmount,
            "Owner has not balance to withdraw"
        );

        // @dev Transfer token to the msg.sender
        bool sent = _wrappedBTCToken.transfer(_msgSender(), tokenAmount);
        require(sent, "Failed to transfer token to user");
    }

    // @dev balanceOf will return the account balance for the given account
    function balanceOfBTC(address _address) public view returns (uint256) {
        return _wrappedBTCToken.balanceOf(_address);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}