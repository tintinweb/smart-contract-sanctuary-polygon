// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Import this file to use console.log
import "./console.sol";

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import './Strings.sol';
import './ReentrancyGuard.sol';
import './MerkleProof.sol';

contract KhizaTokenVendor is Ownable, ReentrancyGuard {
    // =========== TOKEN VENDOR ===========

    using SafeERC20 for IERC20;

    event BuyTokens(address buyer, uint amountOfAcceptedTokens, uint amountOfTokensSold);

    uint public pricePerToken;
    IERC20 public acceptedToken;
    IERC20 public khizaToken;
    uint public endsAt;

    uint8 private constant SELLED_TOKEN_DECIMALS = 18;

    constructor(
        uint _pricePerToken,
        IERC20 _acceptedToken,
        IERC20 _khizaToken,
        uint _endsAt
    ) {
        acceptedToken = _acceptedToken;
        khizaToken = _khizaToken;
        endsAt = _endsAt;
        setPricePerToken(_pricePerToken);
    }

    function setPricePerToken(uint _pricePerToken) public onlyOwner {
        // Quantos acceptedToken (com todas as casas decimais) para 1 unidade inteira de khizaToken
        pricePerToken = _pricePerToken;
    }

    // error NotEnoughBuyerBalance(uint currentBalance, uint requiredBalance);
    // error NotEnoughContractBalance(uint currentBalance, uint requiredBalance);
    // error NotEnoughAllowance(uint currentAllowance, uint requiredAllowance);

    // *assuma que o usuário já deu approve() na USDC
    function buyTokens(uint amountToBuy) public nonReentrant notPaused whitelistCompliance(amountToBuy) timeCompliance {
        require(amountToBuy > 0);

        uint amountToPay = (amountToBuy * pricePerToken) / (10 ** SELLED_TOKEN_DECIMALS);

        // console.log('amountToPay: %s', amountToPay);

        // check if the Vendor Contract has enough tokens for the transaction
        uint vendorBalance = khizaToken.balanceOf(address(this));
        if (vendorBalance < amountToBuy)
            revert('NotEnoughContractBalance');
            // revert NotEnoughContractBalance(vendorBalance, amountToBuy);

        // check if the msg.sender has allowed enough acceptedToken
        uint currentAllowance = acceptedToken.allowance(_msgSender(), address(this));
        if (currentAllowance < amountToPay)
            revert('NotEnoughAllowance');
            // revert NotEnoughAllowance(currentAllowance, amountToPay);

        // check if the msg.sender has enough acceptedToken
        uint currentBuyerBalance = acceptedToken.balanceOf(_msgSender());
        if (currentBuyerBalance < amountToPay)
            revert('NotEnoughBuyerBalance');
            // revert NotEnoughBuyerBalance(currentBuyerBalance, amountToPay);

        whitelistWithLimits[_msgSender()] -= amountToBuy;

        // Transfer token to the msg.sender
        khizaToken.safeTransfer(_msgSender(), amountToBuy);

        // Transfer token to the owner
        acceptedToken.safeTransferFrom(_msgSender(), owner(), amountToPay);

        // emit the event
        emit BuyTokens(_msgSender(), amountToPay, amountToBuy);
    }

    function amountAvaiableToBuy() public view returns (uint) {
        return khizaToken.balanceOf(address(this));
    }

    function amountAvaiableToWithdraw() public view returns (uint) {
        return acceptedToken.balanceOf(address(this));
    }

    // =========== TIME LOCK ===========

    // error TimeLocked();

    function setEndsAt(uint _endsAt) public onlyOwner {
        endsAt = _endsAt;
    }

    modifier timeCompliance() {
        if (block.timestamp > endsAt)
            revert('TimeLocked');
            // revert TimeLocked();
        _;
    }

    // =========== WHITELIST ===========

    // error Unauthorized();

    mapping(address => uint) public whitelistWithLimits;
    bool public whitelistEnabled = true;

    modifier whitelistCompliance(uint amountToBuy) {
        if (!(whitelistEnabled && whitelistWithLimits[_msgSender()] >= amountToBuy))
            revert('Unauthorized');
            // revert Unauthorized();
        _;
    }

    function setWhitelistEnabled(bool _whitelistEnabled) onlyOwner public {
        whitelistEnabled = _whitelistEnabled;
    }

    function setWhitelistAddress(address _address, uint limit) onlyOwner public {
        whitelistWithLimits[_address] = limit;
    }

    // =========== PAUSABLE ===========

    bool public paused = true;

    // error ContractPaused();

    modifier notPaused() {
        if (paused)
            revert('ContractPaused');
            // revert ContractPaused();
        _;
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    // =========== WITHDRAWABLE ===========

    event Withdrawal(uint amount, uint when);
    event WithdrawalERC20(uint amount, uint when, IERC20 token);

    function withdraw() public onlyOwner nonReentrant {
        emit Withdrawal(address(this).balance, block.timestamp);
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawERC20(IERC20 token) public onlyOwner nonReentrant {
        emit WithdrawalERC20(token.balanceOf(address(this)), block.timestamp, token);
        token.safeTransfer(owner(), token.balanceOf(address(this)));
    }

    receive() external payable {
        // do nothing
    }
}