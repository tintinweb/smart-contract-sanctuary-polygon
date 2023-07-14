// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "Ownable.sol";
import "IERC20.sol";

contract PayContract is Ownable {

    //  operator contract address
    address public operator;

    mapping(string => IERC20) private _currencies;
    mapping(string => uint256) private _prices;

    event PaymentReceived(string currency, address indexed from, uint256 amount);
    event PriceChanged(string currency, uint256 newPrice);
    event CurrencyAdded(string currency, address newCurrency);
    event ChangeOperator(address oldOperator, address newOperator);

    // Access modifier (Operator)
    modifier onlyOperator() {
        require(operator == _msgSender(), "Subscriber: caller is not the operator");
        _;
    }

    /// @notice Update Operator address
    /// @param newOperator        - Address new operator
    function changeOperator(address newOperator) public onlyOwner {
        address oldOperator = operator;
        operator = newOperator;
        emit ChangeOperator(oldOperator, newOperator);
    }

    function addCurrency(string memory currencyName, address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        require(_currencies[currencyName] == IERC20(address(0)), "Currency already exists");

        _currencies[currencyName] = IERC20(tokenAddress);
        emit CurrencyAdded(currencyName, tokenAddress);
    }

    function getPrice(string memory currencyName) external view returns (uint256) {
        return _prices[currencyName];
    }

    function getCurrencyAddress(string memory currencyName) external view returns (address) {
        return address(_currencies[currencyName]);
    }

    function pay(string memory currencyName) external {
        IERC20 token = _currencies[currencyName];
        uint256 price = _prices[currencyName];

        require(address(token) != address(0), "Currency not supported");
        require(price > 0, "No price set for this currency");

        token.transferFrom(msg.sender, address(this), price);
        emit PaymentReceived(currencyName, msg.sender, price);
    }

    function payOperator(string memory currencyName, address user) external onlyOperator {
        IERC20 token = _currencies[currencyName];
        uint256 price = _prices[currencyName];

        require(address(token) != address(0), "Currency not supported");
        require(price > 0, "No price set for this currency");

        token.transferFrom(user, address(this), price);
        emit PaymentReceived(currencyName, user, price);
    }

    function changePrice(string memory currencyName, uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Price must be greater than 0");

        _prices[currencyName] = newPrice;
        emit PriceChanged(currencyName, newPrice);
    }

    function claim(string memory currencyName, address to) external onlyOwner {
        require(to != address(0), "Invalid address");

        IERC20 token = _currencies[currencyName];
        require(address(token) != address(0), "Currency not supported");

        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to claim");

        token.transfer(to, balance);
    }

    function getContractTokenBalance(string memory currencyName) external view returns (uint256) {
        IERC20 token = _currencies[currencyName];
        require(address(token) != address(0), "Currency not supported");

        return token.balanceOf(address(this));
    }
}