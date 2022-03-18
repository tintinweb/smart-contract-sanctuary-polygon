// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// token
import "./Withdraw.sol";
import "./DlyToken.sol";
import "./TetherUSDToken.sol";
import "./USDCoinToken.sol";
import "./WrappedEtherToken.sol";
import "./WrappedBTCToken.sol";
import "./PriceConsumerV3.sol";
import "./TransferHistory.sol";
import "./TransactionFee.sol";

contract VendorDLY is
    Context,
    Ownable,
    PriceConsumerV3,
    Withdraw,
    TransferHistory,
    TransactionFee,
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
        Withdraw(
            _dlyTokenAddress,
            _usdtTokenAddress,
            _usdcTokenAddress,
            _wethTokenAddress,
            _wbtcTokenAddress
        )
        DlyToken(_dlyTokenAddress)
        TetherUSDToken(_usdtTokenAddress, _dlyTokenAddress)
        USDCoinToken(_usdcTokenAddress, _dlyTokenAddress)
        WrappedEtherToken(_wethTokenAddress, _dlyTokenAddress)
        WrappedBTCToken(_wbtcTokenAddress, _dlyTokenAddress)
    {}

    // This fallback/receive function
    // will keep all the Ether
    fallback() external payable {
        // Do nothing
    }

    receive() external payable {
        // Do nothing
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
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ReEntrancyGuard.sol";

contract Withdraw is Context, Ownable, ReEntrancyGuard {
    IERC20 private wdlyToken;
    IERC20 private wusdtToken;
    IERC20 private wusdcToken;
    IERC20 private wwethToken;
    IERC20 private wwbtcToken;

    // event
    event WithdrawEvent(
        uint256 indexed _type,
        address indexed owner,
        uint256 amount
    );

    constructor(
        address _dlyTokenAddress,
        address _usdtTokenAddress,
        address _usdcTokenAddress,
        address _wethTokenAddress,
        address _wbtcTokenAddress
    ) {
        wdlyToken = IERC20(_dlyTokenAddress);
        wusdtToken = IERC20(_usdtTokenAddress);
        wusdcToken = IERC20(_usdcTokenAddress);
        wwethToken = IERC20(_wethTokenAddress);
        wwbtcToken = IERC20(_wbtcTokenAddress);
    }

    // @dev Withdrawal $MATIC ONLY ONWER
    // @dev Allow the owner of the contract to withdraw MATIC Owner
    function withdrawMaticOwner(uint256 amount)
        external
        payable
        onlyOwner
        noReentrant
    {
        require(
            payable(address(_msgSender())).send(amount),
            "Failed to transfer token to fee contract"
        );

        emit WithdrawEvent(0, _msgSender(), amount);
    }

    // @dev Withdrawal TOKEN $USDT, $USDC, $DLY, $WETH, $WBTC  ONLY ONWER
    // @dev Allow the owner of the contract to withdraw MATIC Owner
    function withdrawTokenOnwer(uint256 amount, uint256 _type)
        external
        onlyOwner
        noReentrant
    {
        if (_type == 1) {
            // @dev Withdraw $DLY
            // Transfer token to the msg.sender
            bool sent1 = wdlyToken.transfer(_msgSender(), amount);
            require(sent1, "Failed to transfer token to Onwer");
        } else if (_type == 2) {
            // @dev Withdraw $USDT
            // Transfer token to the msg.sender
            bool sent1 = wusdtToken.transfer(_msgSender(), amount);
            require(sent1, "Failed to transfer token to Onwer");
        } else if (_type == 3) {
            // @dev Withdraw $USDC
            // Transfer token to the msg.sender
            bool sent1 = wusdcToken.transfer(_msgSender(), amount);
            require(sent1, "Failed to transfer token to Onwer");
        } else if (_type == 4) {
            // @dev Withdraw $WETH
            // Transfer token to the msg.sender
            bool sent1 = wwethToken.transfer(_msgSender(), amount);
            require(sent1, "Failed to transfer token to Onwer");
        } else if (_type == 5) {
            // @dev Withdraw $WBTC
            // @dev Transfer token to the msg.sender
            bool sent1 = wwbtcToken.transfer(_msgSender(), amount);
            require(sent1, "Failed to transfer token to Onwer");
        }

        emit WithdrawEvent(_type, _msgSender(), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PriceConsumerV3.sol";
import "./ReEntrancyGuard.sol";
import "./TransferHistory.sol";
import "./TransactionFee.sol";

contract DlyToken is
    Context,
    Ownable,
    PriceConsumerV3,
    ReEntrancyGuard,
    TransferHistory,
    TransactionFee
{
    IERC20 private _dlyToken;

    // Event that log buy operation
    event BuyTokensMATICbyDLY(
        address buyer,
        uint256 amountOfMatic,
        uint256 amountOfTokens,
        uint256 amountfee
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

    // @dev  Allow users to buy tokens for MATIC by DLY
    function buyDLY()
        external
        payable
        limitBuy(maticSentBuy())
        noReentrant
        returns (uint256 tokenAmount)
    {
        require(msg.value > 0, "Send MATIC to buy some tokens");

        // @dev token dly para enviar al sender
        uint256 amountToBuy = maticSentBuy();

        // @dev check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 vendorBalance = _dlyToken.balanceOf(address(this));
        require(
            vendorBalance >= amountToBuy,
            "Vendor contract has not enough tokens in its balance"
        );

        // @dev Transfer token to the msg.sender
        bool sent = _dlyToken.transfer(_msgSender(), amountToBuy);
        require(sent, "Failed to transfer token to user");

        // @dev send fee
        uint256 _amountfee = calculateFee(msg.value);
        require(
            payable(address(ownerFee)).send(_amountfee),
            "Failed to transfer token to fee contract"
        );

        // @dev log the buy operation
        bool history = historyPerBuy(amountToBuy);
        require(history, "failed to save record");

        // @dev emit the event
        emit BuyTokensMATICbyDLY(
            _msgSender(),
            msg.value,
            amountToBuy,
            _amountfee
        );

        return amountToBuy;
    }

    // @dev calculate the tokens to send to the sender
    function maticSentBuy() internal view returns (uint256) {
        // Get the amount of tokens that the user will receive
        // convert cop to usd
        uint256 valueMATICinUSD = (msg.value *
            uint256(getLatestPriceMATICUSD())) / 1000000000000000000;

        // token dly para enviar al sender
        uint256 amountToBuy = (valueMATICinUSD * 1000000000000000000) /
            uint256(getLatestPriceCOPUSD());

        return amountToBuy;
    }

    // @dev Allow users to sell tokens for sell DLY by MATIC
    function sellDLY(uint256 tokenAmountToSell)
        external
        limitSell(tokenAmountToSell)
        noReentrant
        returns (uint256 tokenAmount)
    {
        // @dev Check that the requested amount of tokens to sell is more than 0
        require(
            tokenAmountToSell > 0,
            "Specify an amount of token greater than zero"
        );

        // @dev Check that the user's token balance is enough to do the swap
        uint256 userBalance = _dlyToken.balanceOf(_msgSender());
        require(
            userBalance >= tokenAmountToSell,
            "Your balance is lower than the amount of tokens you want to sell"
        );

        // @dev Check that the Vendor's balance is enough to do the swap
        uint256 COPtoUSD = tokenAmountToSell * uint256(getLatestPriceCOPUSD());

        // @dev matic amount to send to sender
        uint256 amountToTransferMATIC = COPtoUSD /
            uint256(getLatestPriceMATICUSD());

        // @dev verificar balance de matic en el vendor
        uint256 ownerMATICBalance = address(this).balance;
        require(
            ownerMATICBalance >= amountToTransferMATIC,
            "Vendor has not enough funds to accept the sell request"
        );

        // @dev Transfer token to the msg.sender
        bool sent = _dlyToken.transferFrom(
            _msgSender(),
            address(this),
            tokenAmountToSell
        );
        require(sent, "Failed to transfer tokens from user to vendor");

        // @dev  we send matic to the sender
        (sent, ) = _msgSender().call{value: amountToTransferMATIC}("");
        require(sent, "Failed to send MATIC to the user");

        // @dev send fee
        uint256 _amountfee = calculateFee(amountToTransferMATIC);
        require(
            payable(address(ownerFee)).send(_amountfee),
            "Failed to transfer token to fee contract"
        );

        // @dev log the  operation
        bool history = historyPerSell(tokenAmountToSell);
        require(history, "failed to save record");

        return tokenAmountToSell;
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
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PriceConsumerV3.sol";
import "./DlyToken.sol";
import "./ReEntrancyGuard.sol";
import "./TransferHistory.sol";
import "./TransactionFee.sol";

contract TetherUSDToken is
    Context,
    Ownable,
    PriceConsumerV3,
    ReEntrancyGuard,
    TransferHistory,
    TransactionFee
{
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
    function buyUSDT(uint256 tokenAmountToBuy)
        external
        noReentrant
        limitBuy(usdtSentBuy(tokenAmountToBuy))
        returns (uint256 tokenAmount)
    {
        require(
            tokenAmountToBuy > 0,
            "Specify an amount of token greater than zero"
        );

        //  @dev  Check that the user's token balance is enough to do the swap
        uint256 userBalance = balanceOfUSDT(_msgSender());
        require(
            userBalance >= tokenAmountToBuy,
            "Your balance is lower than the amount of tokens you want to sell"
        );

        //  @dev  Get the amount of tokens that the user will receive
        uint256 amountToBuy = usdtSentBuy(tokenAmountToBuy);

        //  @dev  check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 vendorBalance = dlyTokenUsdt.balanceOf(address(this));
        require(
            vendorBalance >= amountToBuy,
            "Vendor contract has not enough tokens in its balance"
        );

        //  @dev  Transfer token to the msg.sender USDT => WALLET CONTRACT
        bool sent = usdtToken.transferFrom(
            _msgSender(),
            address(this),
            tokenAmountToBuy
        );
        require(sent, "Failed to transfer tokens from user to vendor");

        //  @dev  Transfer token to the msg.sender DLY => SENDER
        bool sent2 = dlyTokenUsdt.transfer(_msgSender(), amountToBuy);
        require(sent2, "Failed to transfer token to user");

        // @dev send fee
        uint256 _amountfee = calculateFee(tokenAmountToBuy);
        bool sent3 = usdtToken.transfer(ownerFee, _amountfee);
        require(sent3, "Failed to transfer token to fee");

        // @dev log the buy operation
        bool history = historyPerBuy(amountToBuy);
        require(history, "failed to save record");

        // emit the event
        emit BuyTokensUSDT(_msgSender(), tokenAmountToBuy, amountToBuy);

        return amountToBuy;
    }

    // @dev calculate the tokens to send to the sender
    function usdtSentBuy(uint256 tokenAmountToBuy)
        internal
        view
        returns (uint256)
    {
        // los token usdt se reciben en 6 decimales y se le agrega las 12 decimales restante para quedar en 18
        uint256 tokenAmountToBuyTo18Decimals = tokenAmountToBuy * 10**12;

        // Get the amount of tokens that the user will receive
        uint256 amountToBuy = tokenAmountToBuyTo18Decimals *
            uint256(getLatestPriceUSDCOP());

        return amountToBuy;
    }

    // @dev Allow users to sell tokens for sell DLY by USDT
    function sellUSDT(uint256 tokenAmountToSell)
        external
        noReentrant
        limitSell(tokenAmountToSell)
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
        // hacemos la conversion de dly(COP) a usdt (USD)
        uint256 amountToTransfer = tokenAmountToSell /
            uint256(getLatestPriceUSDCOP());

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
        // llevamos el calculo de dly de 18 decimales a 6 decimales
        uint256 amountToTransferTo6Decimal = amountToTransfer / 10**12;
        bool sent2 = usdtToken.transfer(
            _msgSender(),
            amountToTransferTo6Decimal
        );
        require(sent2, "Failed to transfer token to user");

        // @dev send fee
        uint256 _amountfee = calculateFee(amountToTransferTo6Decimal);
        bool sent3 = usdtToken.transfer(ownerFee, _amountfee);
        require(sent3, "Failed to transfer token to user");

        // @dev log the  operation
        bool history = historyPerSell(tokenAmountToSell);
        require(history, "failed to save record");

        emit SellTokensUSDT(_msgSender(), tokenAmountToSell, amountToTransfer);

        return tokenAmountToSell;
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
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PriceConsumerV3.sol";
import "./DlyToken.sol";
import "./ReEntrancyGuard.sol";
import "./TransferHistory.sol";
import "./TransactionFee.sol";

contract USDCoinToken is
    Context,
    Ownable,
    PriceConsumerV3,
    ReEntrancyGuard,
    TransferHistory,
    TransactionFee
{
    IERC20 private usdCoinToken;
    IERC20 private dlyTokenUsdc;

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

    constructor(address _usdCoinToken, address _dlyToken) {
        usdCoinToken = IERC20(_usdCoinToken);
        dlyTokenUsdc = IERC20(_dlyToken);
    }

    // @dev  Allow users to buy tokens for buy  usdt by dly
    function buyUSDC(uint256 tokenAmountToBuy)
        external
        noReentrant
        limitBuy(usdcSentBuy(tokenAmountToBuy))
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
        uint256 amountToBuy = usdcSentBuy(tokenAmountToBuy);

        // check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 vendorBalance = dlyTokenUsdc.balanceOf(address(this));
        require(
            vendorBalance >= amountToBuy,
            "Vendor contract has not enough tokens in its balance"
        );

        // Transfer token to the msg.sender USDT => WALLET CONTRACT
        bool sent = usdCoinToken.transferFrom(
            _msgSender(),
            address(this),
            tokenAmountToBuy
        );
        require(sent, "Failed to transfer tokens from user to vendor");

        // Transfer token to the msg.sender DLY => SENDER
        bool sent2 = dlyTokenUsdc.transfer(_msgSender(), amountToBuy);
        require(sent2, "Failed to transfer token to user");

        // @dev send fee
        uint256 _amountfee = calculateFee(tokenAmountToBuy);
        bool sent3 = usdCoinToken.transfer(ownerFee, _amountfee);
        require(sent3, "Failed to transfer token to fee");

        // @dev log the operation
        bool history = historyPerBuy(amountToBuy);
        require(history, "failed to save record");

        // emit the event
        emit BuyTokensUSDC(_msgSender(), tokenAmountToBuy, amountToBuy);

        return amountToBuy;
    }

    // @dev calculate the tokens to send to the sender
    function usdcSentBuy(uint256 tokenAmountToBuy)
        internal
        view
        returns (uint256)
    {
        // los token usdt se reciben en 6 decim ales y se le agrega las 12 decimales restante para quedar en 18
        uint256 tokenAmountToBuyTo18Decimals = tokenAmountToBuy * 10**12;

        // Get the amount of tokens that the user will receive
        uint256 amountToBuy = tokenAmountToBuyTo18Decimals *
            uint256(getLatestPriceUSDCOP());

        return amountToBuy;
    }

    // @dev Allow users to sell tokens for sell DLY by USDT
    function sellUSDC(uint256 tokenAmountToSell)
        external
        noReentrant
        limitSell(tokenAmountToSell)
        returns (uint256 tokenAmount)
    {
        // Check that the requested amount of tokens to sell is more than 0
        require(
            tokenAmountToSell > 0,
            "Specify an amount of token greater than zero"
        );

        // Check that the user's token balance is enough to do the swap
        uint256 userBalance = dlyTokenUsdc.balanceOf(_msgSender());
        require(
            userBalance >= tokenAmountToSell,
            "Your balance is lower than the amount of tokens you want to sell"
        );

        // Check that the Vendor's balance is enough to do the swap
        // hacemos la conversion de dly(COP) a usdt (USD)
        uint256 amountToTransfer = tokenAmountToSell /
            uint256(getLatestPriceUSDCOP());

        // check balance usdt of vendor
        uint256 vendorBalance = dlyTokenUsdc.balanceOf(address(this));
        require(
            vendorBalance >= amountToTransfer,
            "Vendor has not enough funds to accept the sell request"
        );

        // Transfer token to the msg.sender DLY TOKEN =>  SMART CONTRACT
        bool sent = dlyTokenUsdc.transferFrom(
            _msgSender(),
            address(this),
            tokenAmountToSell
        );
        require(sent, "Failed to transfer tokens from user to vendor");

        // Transfer token to the msg.sender USDT => sender
        // llevamos el calculo de dly de 18 decimales a 6 decimales
        uint256 amountToTransferTo6Decimal = amountToTransfer / 10**12;
        bool sent2 = usdCoinToken.transfer(
            _msgSender(),
            amountToTransferTo6Decimal
        );
        require(sent2, "Failed to transfer token to user");

        // @dev send fee
        uint256 _amountfee = calculateFee(amountToTransferTo6Decimal);
        bool sent3 = usdCoinToken.transfer(ownerFee, _amountfee);
        require(sent3, "Failed to transfer token to fee");

        // @dev log the  operation
        bool history = historyPerSell(tokenAmountToSell);
        require(history, "failed to save record");

        emit SellTokensUSDC(_msgSender(), tokenAmountToSell, amountToTransfer);

        return tokenAmountToSell;
    }

    // @dev balanceOf will return the account balance for the given account
    function balanceOfUSDC(address _address) public view returns (uint256) {
        return usdCoinToken.balanceOf(_address);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PriceConsumerV3.sol";
import "./DlyToken.sol";
import "./ReEntrancyGuard.sol";
import "./TransferHistory.sol";
import "./TransactionFee.sol";

contract WrappedEtherToken is
    Context,
    Ownable,
    PriceConsumerV3,
    ReEntrancyGuard,
    TransferHistory,
    TransactionFee
{
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
    function buyWETH(uint256 tokenAmountToBuy)
        external
        noReentrant
        limitBuy(wethSentBuy(tokenAmountToBuy))
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

        // token dly para enviar al sender
        uint256 amountToBuyDLY = wethSentBuy(tokenAmountToBuy);

        // check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 vendorBalance = dlyTokenETH.balanceOf(address(this));
        require(
            vendorBalance >= amountToBuyDLY,
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
        bool sent2 = dlyTokenETH.transfer(_msgSender(), amountToBuyDLY);
        require(sent2, "Failed to transfer token to user");

        // @dev send fee
        uint256 _amountfee = calculateFee(tokenAmountToBuy);
        bool sent3 = wrappedEtherToken.transfer(ownerFee, _amountfee);
        require(sent3, "Failed to transfer token to fee");

        // @dev log the operation
        bool history = historyPerBuy(amountToBuyDLY);
        require(history, "failed to save record");

        // emit the event
        emit BuyTokensETH(_msgSender(), tokenAmountToBuy, amountToBuyDLY);

        return amountToBuyDLY;
    }

    // @dev calculate the tokens to send to the sender
    function wethSentBuy(uint256 tokenAmountToBuy)
        internal
        view
        returns (uint256)
    {
        // Get the amount of tokens that the user will receive
        // valor de en dolares de los btc enviados
        uint256 valueETHinUSD = tokenAmountToBuy *
            uint256(getLatestPriceWETHUSD());

        // token dly para enviar al sender
        uint256 amountToBuyDLY = (valueETHinUSD /
            uint256(getLatestPriceCOPUSD()));
        return amountToBuyDLY;
    }

    // @dev Allow users to sell tokens for sell DLY by USDT
    function sellWETH(uint256 tokenAmountToSell)
        external
        noReentrant
        limitSell(tokenAmountToSell)
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

        // @dev send fee
        uint256 _amountfee = calculateFee(amountToTransferWETH);
        bool sent3 = wrappedEtherToken.transfer(ownerFee, _amountfee);
        require(sent3, "Failed to transfer token to fee");

        // @dev log the operation
        bool history = historyPerBuy(tokenAmountToSell);
        require(history, "failed to save record");

        emit SellTokensETH(
            _msgSender(),
            tokenAmountToSell,
            amountToTransferWETH
        );

        return tokenAmountToSell;
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
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PriceConsumerV3.sol";
import "./DlyToken.sol";
import "./ReEntrancyGuard.sol";
import "./TransferHistory.sol";
import "./TransactionFee.sol";

contract WrappedBTCToken is
    Context,
    Ownable,
    PriceConsumerV3,
    ReEntrancyGuard,
    TransferHistory,
    TransactionFee
{
    IERC20 private wrappedBTCToken;
    IERC20 private dlyTokenBTC;

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

    constructor(address _wbtcTokenAddress, address _dlyTokenAddress) {
        wrappedBTCToken = IERC20(_wbtcTokenAddress);
        dlyTokenBTC = IERC20(_dlyTokenAddress);
    }

    // @dev  Allow users to buy tokens for buy  usdt by dly
    function buyWBTC(uint256 tokenAmountToBuy)
        external
        noReentrant
        limitBuy(wbtcSentBuy(tokenAmountToBuy))
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

        // Get the amount of tokens that the user will receiv

        // token dly para enviar al sender
        uint256 amountToBuy = wbtcSentBuy(tokenAmountToBuy);

        // check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 vendorBalance = dlyTokenBTC.balanceOf(address(this));
        require(
            vendorBalance >= amountToBuy,
            "Vendor contract has not enough tokens in its balance"
        );

        // Transfer token to the msg.sender USDT => WALLET CONTRACT
        bool sent = wrappedBTCToken.transferFrom(
            _msgSender(),
            address(this),
            tokenAmountToBuy
        );
        require(sent, "Failed to transfer tokens from user to vendor");

        // Transfer token to the msg.sender DLY => SENDER
        bool sent2 = dlyTokenBTC.transfer(_msgSender(), amountToBuy);
        require(sent2, "Failed to transfer token to user");

        // @dev send fee
        uint256 _amountfee = calculateFee(tokenAmountToBuy);
        bool sent3 = wrappedBTCToken.transfer(ownerFee, _amountfee);
        require(sent3, "Failed to transfer token to fee");

        // @dev log the operation
        bool history = historyPerBuy(amountToBuy);
        require(history, "failed to save record");

        // emit the event
        emit BuyTokensBTC(_msgSender(), tokenAmountToBuy, amountToBuy);

        return amountToBuy;
    }

    // @dev calculate the tokens to send to the sender
    function wbtcSentBuy(uint256 tokenAmountToBuy)
        internal
        view
        returns (uint256)
    {
        // los token usdt se reciben en 8 decimales y se le agrega las 12 decimales restante para quedar en 18
        uint256 tokenAmountToBuyTo18Decimals = tokenAmountToBuy * 10**10;

        uint256 valueBTCinUSD = (tokenAmountToBuyTo18Decimals *
            uint256(getLatestPriceWBTCUSD()));

        // token dly para enviar al sender
        uint256 amountToBuy = valueBTCinUSD / uint256(getLatestPriceCOPUSD());
        return amountToBuy;
    }

    // @dev To Solve: CompilerError: Stack too deep, try removing local variables.
    struct SlotInfo {
        uint256 userBalance;
        uint256 COPtoUSD;
        uint256 amountToTransferWBTC;
        uint256 vendorBalance;
        bool sent;
        bool sent2;
        uint256 fee;
        bool _fee;
        bool history;
    }

    // @dev Allow users to sell tokens for sell DLY by USDT
    function sellWBTC(uint256 tokenAmountToSell)
        external
        noReentrant
        limitSell(tokenAmountToSell)
        returns (uint256 tokenAmount)
    {
        SlotInfo memory slot;
        // Check that the requested amount of tokens to sell is more than 0
        require(
            tokenAmountToSell > 0,
            "Specify an amount of token greater than zero"
        );

        // Check that the user's token balance is enough to do the swap
        slot.userBalance = dlyTokenBTC.balanceOf(_msgSender());
        require(
            slot.userBalance >= tokenAmountToSell,
            "Your balance is lower than the amount of tokens you want to sell"
        );

        // monto de wbtc a enviar a sender
        slot.COPtoUSD = tokenAmountToSell * uint256(getLatestPriceCOPUSD());
        uint256 amountToTransferWBTC = slot.COPtoUSD /
            uint256(getLatestPriceWBTCUSD());

        // check balance usdt of vendor
        slot.vendorBalance = dlyTokenBTC.balanceOf(address(this));
        require(
            slot.vendorBalance >= amountToTransferWBTC,
            "Vendor has not enough funds to accept the sell request"
        );

        // Transfer token to the msg.sender DLY TOKEN =>  SMART CONTRACT
        slot.sent = dlyTokenBTC.transferFrom(
            _msgSender(),
            address(this),
            tokenAmountToSell
        );
        require(slot.sent, "Failed to transfer tokens from user to vendor");

        // Transfer token to the msg.sender USDT => sender
        uint256 amountToTransferTo8Decimal = amountToTransferWBTC / 10**10;
        slot.sent2 = wrappedBTCToken.transfer(
            _msgSender(),
            amountToTransferTo8Decimal
        );
        require(slot.sent2, "Failed to transfer token to user");

        // @dev send fee
        uint256 _amountfee = calculateFee(amountToTransferTo8Decimal);
        bool sent3 = wrappedBTCToken.transfer(ownerFee, _amountfee);
        require(sent3, "Failed to transfer token to fee");

        // @dev log the operation
        slot.history = historyPerBuy(tokenAmountToSell);
        require(slot.history, "failed to save record");

        emit SellTokensBTC(
            _msgSender(),
            tokenAmountToSell,
            amountToTransferWBTC
        );
        return tokenAmountToSell;
    }

    // @dev balanceOf will return the account balance for the given account
    function balanceOfBTC(address _address) public view returns (uint256) {
        return wrappedBTCToken.balanceOf(_address);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PriceConsumerV3 is Ownable {
    // @dev oracle
    AggregatorV3Interface internal priceFeedMATICUSD;
    AggregatorV3Interface internal priceFeedWETHUSD;
    AggregatorV3Interface internal priceFeedWBTCUSD;
    AggregatorV3Interface internal priceFeedCOPUSD;

    // @dev  trm enabled/disabled
    bool public trmCopUsdManual = false;
    bool public trmUsdCopManual = false;
    bool public trmMaticUsdManual = false;
    bool public trmWbtcUsdManual = false;
    bool public trmWethUsdManual = false;

    // @dev  value trm
    int256 public valueTrmCopUsdManual = 0;
    int256 public valueTrmUsdCopManual = 0;
    int256 public valueTrmMaticUsdManual = 0;
    int256 public valueTrmWbtcUsdManual = 0;
    int256 public valueTrmWethUsdManual = 0;

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
    }

    // @dev Returns the latest price MATIC / USD
    function getLatestPriceMATICUSD() public view returns (int256) {
        if (trmMaticUsdManual) {
            return valueTrmMaticUsdManual * 10**10;
        } else {
            (, int256 price, , , ) = priceFeedMATICUSD.latestRoundData();
            return price * 10**10;
        }
    }

    // @dev Returns the latest price WBTC / USD
    function getLatestPriceWBTCUSD() public view returns (int256) {
        if (trmWbtcUsdManual) {
            return valueTrmWbtcUsdManual * 10**10;
        } else {
            (, int256 price, , , ) = priceFeedWBTCUSD.latestRoundData();
            return price * 10**10;
        }
    }

    // @dev Returns the latest price ETH / USD
    function getLatestPriceWETHUSD() public view returns (int256) {
        if (trmWethUsdManual) {
            return valueTrmWethUsdManual * 10**10;
        } else {
            (, int256 price, , , ) = priceFeedWETHUSD.latestRoundData();
            return price * 10**10;
        }
    }

    // @dev Returns the latest price COP / USD
    function getLatestPriceCOPUSD() public view returns (int256) {
        if (trmCopUsdManual) {
            return valueTrmCopUsdManual * 10**10;
        } else {
            (, int256 price, , , ) = priceFeedCOPUSD.latestRoundData();
            return price * 10**10;
        }
    }

    // @dev Returns the latest price   USD/COP
    // value de un dolar en peso colombianos COP
    function getLatestPriceUSDCOP() public view returns (uint256) {
        if (trmUsdCopManual) {
            return uint256(valueTrmUsdCopManual);
        } else {
            uint256 valueCOPinUSD = 1000000000000000000 /
                uint256(getLatestPriceCOPUSD());
            return valueCOPinUSD;
        }
    }

    // @dev change the manual or automatic price value of the trm
    function setTypeTrm(int256 typeTrm, bool valueTrm) public onlyOwner {
        if (typeTrm == 1) {
            trmCopUsdManual = valueTrm;
        } else if (typeTrm == 2) {
            trmUsdCopManual = valueTrm;
        } else if (typeTrm == 3) {
            trmMaticUsdManual = valueTrm;
        } else if (typeTrm == 4) {
            trmWbtcUsdManual = valueTrm;
        } else if (typeTrm == 5) {
            trmWethUsdManual = valueTrm;
        }
    }

    // @dev change the manual or automatic price value of the trm
    function setValueTrm(int256 typeTrm, int256 valueTrm) public onlyOwner {
        if (typeTrm == 1) {
            valueTrmCopUsdManual = valueTrm;
        } else if (typeTrm == 2) {
            valueTrmUsdCopManual = valueTrm;
        } else if (typeTrm == 3) {
            valueTrmMaticUsdManual = valueTrm;
        } else if (typeTrm == 4) {
            valueTrmWbtcUsdManual = valueTrm;
        } else if (typeTrm == 5) {
            valueTrmWethUsdManual = valueTrm;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./DateTime.sol";

contract TransferHistory is Context, Ownable, DateTime {
    struct StructTransferHistory {
        uint256 transferTime;
        uint8 day;
        uint256 amount;
    }

    uint256 public sellLimit = 1000000000000000000000;
    uint256 public buyLimit = 1000000000000000000000;

    mapping(address => StructTransferHistory) internal transferHistoryPerBuy;
    mapping(address => StructTransferHistory) internal transferHistoryPerSell;

    constructor() {
        uint256 _time = getBlockTime();
        uint8 _day = getDay(_time);

        //  initialize variables
        transferHistoryPerBuy[_msgSender()].transferTime = _time;
        transferHistoryPerBuy[_msgSender()].day = _day;
        transferHistoryPerBuy[_msgSender()].amount = 0;

        transferHistoryPerSell[_msgSender()].transferTime = _time;
        transferHistoryPerSell[_msgSender()].day = _day;
        transferHistoryPerSell[_msgSender()].amount = 0;
    }

    /**
     * @dev Throws if you exceed the Buy limit
     */
    modifier limitBuy(uint256 tokenAmount) {
        uint256 _time = getBlockTime();
        uint8 _day = getDay(_time);

        // @dev Check if the day is the same
        if (transferHistoryPerBuy[_msgSender()].day == _day) {
            require(
                tokenAmount + transferHistoryPerBuy[_msgSender()].amount <=
                    buyLimit,
                "Buy: Exceeded DLY token buy limit"
            );
        } else {
            // @dev reset the counter and change the day
            transferHistoryPerBuy[_msgSender()].day = _day;
            transferHistoryPerBuy[_msgSender()].amount = 0;
        }

        _;
    }

    /**
     * @dev Throws if you exceed the Sell limit
     */
    modifier limitSell(uint256 tokenAmount) {
        uint256 _time = getBlockTime();
        uint8 _day = getDay(_time);

        // @dev Check if the day is the same
        if (transferHistoryPerSell[_msgSender()].day == _day) {
            require(
                tokenAmount + transferHistoryPerSell[_msgSender()].amount <=
                    sellLimit,
                "SELL: Exceeded DLY token sell limit"
            );
        } else {
            // @dev reset the counter and change the day
            transferHistoryPerSell[_msgSender()].day = _day;
            transferHistoryPerSell[_msgSender()].amount = 0;
        }

        _;
    }

    // @dev save purchase record
    function historyPerBuy(uint256 tokenAmount) internal returns (bool) {
        uint256 _time = getBlockTime();
        uint8 _day = getDay(_time);
        transferHistoryPerBuy[_msgSender()].transferTime = _time;
        transferHistoryPerBuy[_msgSender()].day = _day;
        transferHistoryPerBuy[_msgSender()].amount =
            transferHistoryPerBuy[_msgSender()].amount +
            tokenAmount;

        return true;
    }

    // @dev save sales record
    function historyPerSell(uint256 tokenAmount) internal returns (bool) {
        uint256 _time = getBlockTime();
        uint8 _day = getDay(_time);
        transferHistoryPerSell[_msgSender()].transferTime = _time;
        transferHistoryPerSell[_msgSender()].day = _day;
        transferHistoryPerSell[_msgSender()].amount =
            transferHistoryPerSell[_msgSender()].amount +
            tokenAmount;

        return true;
    }

    // @dev we get last purchase record
    function getLastBuy(address _a)
        public
        view
        returns (
            uint256,
            uint8,
            uint256
        )
    {
        return (
            transferHistoryPerBuy[_a].transferTime,
            transferHistoryPerBuy[_a].day,
            transferHistoryPerBuy[_a].amount
        );
    }

    // @dev get last sale record
    function getLastSell(address _a)
        public
        view
        returns (
            uint256,
            uint8,
            uint256
        )
    {
        return (
            transferHistoryPerSell[_a].transferTime,
            transferHistoryPerSell[_a].day,
            transferHistoryPerSell[_a].amount
        );
    }

    // @dev changes to the token sale limit
    function setSellLimit(uint256 newLimit) external onlyOwner returns (bool) {
        sellLimit = newLimit;
        return true;
    }

    // @dev Token purchase limit changes
    function setBuyLimit(uint256 newLimit) external onlyOwner returns (bool) {
        buyLimit = newLimit;
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";

contract TransactionFee is Context {
    event OwnershipTransferredFee(
        address indexed previousOwner,
        address indexed newOwner
    );

    address public ownerFee = address(0);

    constructor() {
        ownerFee = _msgSender();
    }

    // @dev onwe of this section fee
    modifier onlyOwnerFee() {
        require(_msgSender() == ownerFee);
        _;
    }

    // @dev Withdrawal $MATIC ONLY ONWER FEE
    // @dev Allow the owner of the contract to withdraw MATIC Owner
    uint256 public fee_fixed = 250; // 0,025 %;

    function calculateFee(uint256 amount) public view returns (uint256 fee) {
        return (amount * fee_fixed) / 10000;
    }

    // @dev get the current fee
    function getFee() public view returns (uint256) {
        return fee_fixed;
    }

    // @dev Transfers ownership of the contract to a new account (`newOwner`).
    function transferOwnershipFee(address newOwner)
        public
        onlyOwnerFee
        returns (bool)
    {
        require(
            newOwner != address(0),
            "Ownable Fee: new owner is the zero address"
        );

        address oldOwner = ownerFee;
        ownerFee = newOwner;
        emit OwnershipTransferredFee(oldOwner, newOwner);
        return true;
    }
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract ReEntrancyGuard {
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
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
pragma solidity 0.8.9;

contract DateTime {
    /*
     *  Date and Time utilities for ethereum contracts
     *
     */
    struct _DateTime {
        uint16 year;
        uint8 month;
        uint8 day;
        uint8 hour;
        uint8 minute;
        uint8 second;
        uint8 weekday;
    }

    uint256 constant DAY_IN_SECONDS = 86400;
    uint256 constant YEAR_IN_SECONDS = 31536000;
    uint256 constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint256 constant HOUR_IN_SECONDS = 3600;
    uint256 constant MINUTE_IN_SECONDS = 60;

    uint16 constant ORIGIN_YEAR = 1970;

    function isLeapYear(uint16 year) public pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }

    function leapYearsBefore(uint256 year) public pure returns (uint256) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function getDaysInMonth(uint8 month, uint16 year)
        public
        pure
        returns (uint8)
    {
        if (
            month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12
        ) {
            return 31;
        } else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        } else if (isLeapYear(year)) {
            return 29;
        } else {
            return 28;
        }
    }

    function parseTimestamp(uint256 timestamp)
        internal
        pure
        returns (_DateTime memory dt)
    {
        uint256 secondsAccountedFor = 0;
        uint256 buf;
        uint8 i;

        // Year
        dt.year = getYear(timestamp);
        buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

        // Month
        uint256 secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                dt.month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }

        // Day
        for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
            if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                dt.day = i;
                break;
            }
            secondsAccountedFor += DAY_IN_SECONDS;
        }

        // Hour
        dt.hour = getHour(timestamp);

        // Minute
        dt.minute = getMinute(timestamp);

        // Second
        dt.second = getSecond(timestamp);

        // Day of week.
        dt.weekday = getWeekday(timestamp);
    }

    function getYear(uint256 timestamp) public pure returns (uint16) {
        uint256 secondsAccountedFor = 0;
        uint16 year;
        uint256 numLeapYears;

        // Year
        year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor +=
            YEAR_IN_SECONDS *
            (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > timestamp) {
            if (isLeapYear(uint16(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            } else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }

    function getMonth(uint256 timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).month;
    }

    function getDay(uint256 timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).day;
    }

    function getHour(uint256 timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint256 timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60) % 60);
    }

    function getSecond(uint256 timestamp) public pure returns (uint8) {
        return uint8(timestamp % 60);
    }

    function getWeekday(uint256 timestamp) public pure returns (uint8) {
        return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day
    ) public pure returns (uint256 timestamp) {
        return toTimestamp(year, month, day, 0, 0, 0);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour
    ) public pure returns (uint256 timestamp) {
        return toTimestamp(year, month, day, hour, 0, 0);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 minute
    ) public pure returns (uint256 timestamp) {
        return toTimestamp(year, month, day, hour, minute, 0);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 minute,
        uint8 second
    ) public pure returns (uint256 timestamp) {
        uint16 i;

        // Year
        for (i = ORIGIN_YEAR; i < year; i++) {
            if (isLeapYear(i)) {
                timestamp += LEAP_YEAR_IN_SECONDS;
            } else {
                timestamp += YEAR_IN_SECONDS;
            }
        }

        // Month
        uint8[12] memory monthDayCounts;
        monthDayCounts[0] = 31;
        if (isLeapYear(year)) {
            monthDayCounts[1] = 29;
        } else {
            monthDayCounts[1] = 28;
        }
        monthDayCounts[2] = 31;
        monthDayCounts[3] = 30;
        monthDayCounts[4] = 31;
        monthDayCounts[5] = 30;
        monthDayCounts[6] = 31;
        monthDayCounts[7] = 31;
        monthDayCounts[8] = 30;
        monthDayCounts[9] = 31;
        monthDayCounts[10] = 30;
        monthDayCounts[11] = 31;

        for (i = 1; i < month; i++) {
            timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
        }

        // Day
        timestamp += DAY_IN_SECONDS * (day - 1);

        // Hour
        timestamp += HOUR_IN_SECONDS * (hour);

        // Minute
        timestamp += MINUTE_IN_SECONDS * (minute);

        // Second
        timestamp += second;

        return timestamp;
    }

    function getBlockTime() public view returns (uint256 timestamp) {
        return block.timestamp;
    }
}