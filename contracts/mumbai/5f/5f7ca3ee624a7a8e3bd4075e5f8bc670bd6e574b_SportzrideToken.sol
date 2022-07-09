// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

/// @title ERC-20 Token for SZR
contract SportzrideToken is ERC20, Ownable, ReentrancyGuard {
    address public gameContractAddress;

    /// maximum token allowed to be 10 Billion SZR * decimals()
    uint256 public constant maxTokenSupply = 1e10 * 1e18;

    event TransferReceived(address _from, uint256 _amount);
    event WithdrawalOf(address _from, address _destAddr, uint256 _amount);
    event TransferOf(address _from, address _destAddr, uint256 _amount);
    event GameContractChangedTo(address _newGameContractAddress);
    event TokenMinted(uint256 _mintedAmount, address _minterAddress);

    constructor() ERC20("Sportzride Token", "SZR") {}

    function decimals() public pure virtual override returns (uint8) {
        return 18;
    }

    function setGameAddress(address _gameContractAddress) external onlyOwner {
        require(
            _gameContractAddress != address(0),
            "Game Contract cannot be set to zero address"
        );
        gameContractAddress = _gameContractAddress;
        emit GameContractChangedTo(_gameContractAddress);
    }

    receive() external payable {
        emit TransferReceived(msg.sender, msg.value);
    }

    function withdraw(uint256 _withdrawalAmount, address payable destAddr)
        external
        onlyOwner
    {
        require(
            address(this).balance >= _withdrawalAmount,
            "Insufficient funds of Polygon in the contract for withdrawal"
        );
        require(destAddr != address(0), "Cannot withdraw to the zero address");
        (bool success, ) = destAddr.call{value: _withdrawalAmount}("");
        require(success, "Withdraw failed.");
        emit WithdrawalOf(msg.sender, destAddr, _withdrawalAmount);
    }

    function transferERC20(
        IERC20 token,
        address to,
        uint256 amount
    ) external onlyOwner nonReentrant {
        uint256 erc20balance = token.balanceOf(address(this));
        require(
            amount <= erc20balance,
            "Insufficient Balance of ERC20 token in the contract for Transfer"
        );
        require(to != address(0), "Cannot transfer ERC20 to the zero address");
        token.transfer(to, amount);
        emit TransferOf(msg.sender, to, amount);
    }

    function mintTokens(uint256 tokenAmount) external {
        require(
            msg.sender == gameContractAddress,
            "Only Game Contract can mint the tokens"
        );
        require(
            tokenAmount <= maxTokenSupply - totalSupply(),
            "Total supply can be a maximum of 10 Billion SZR tokens"
        );
        _mint(msg.sender, tokenAmount);
        emit TokenMinted(tokenAmount, msg.sender);
    }
}