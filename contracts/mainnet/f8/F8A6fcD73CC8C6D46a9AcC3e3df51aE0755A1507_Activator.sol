/**
 *Submitted for verification at polygonscan.com on 2022-12-08
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract Activator {
    enum activationStatus {
        void,
        pending,
        success,
        fail,
        refunded
    }

    struct ActivationInfo {
        address payer;
        uint256 price;
        string publicKey;
        activationStatus status;
    }

    address public owner;
    address public pendingOwner;
    mapping(string => ActivationInfo) public activationInfoOf; // near account name
    uint256 public price;
    uint256 public accrued;

    event ActivationRequest(string near_account, ActivationInfo activationInfo);
    event ActivationSuccess(string near_account, ActivationInfo activationInfo);
    event ActivationFailed(string near_account, ActivationInfo activationInfo);
    event Refund(string near_account, address to, uint256 amount);
    event Withdrawl(uint256 amount, address to);
    event SetPrice(uint256 price);
    event TransferOwner(address to);
    event AcceptOwner(address owner);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(uint256 price_) {
        owner = msg.sender;
        setPrice(price_);
    }

    function activate(string memory accountName, string memory publicKey)
        external
        payable
    {
        require(
            activationInfoOf[accountName].status != activationStatus.pending,
            "duplicated activation"
        );
        activationInfoOf[accountName] = ActivationInfo(
            msg.sender,
            price,
            publicKey,
            activationStatus.pending
        );
        emit ActivationRequest(accountName, activationInfoOf[accountName]);
    }

    function refund(string memory accountName) external {
        require(
            activationInfoOf[accountName].status == activationStatus.fail,
            "this activation cannot be refunded"
        );
        address to = activationInfoOf[accountName].payer;
        uint256 amount = activationInfoOf[accountName].price;
        (bool success, ) = to.call{value: amount}("");
        require(success, "refund failed");
        activationInfoOf[accountName].status = activationStatus.refunded;
        emit Refund(accountName, to, amount);
    }

    function postResult(string memory accountName, bool success)
        external
        onlyOwner
    {
        if (success) {
            activationInfoOf[accountName].status = activationStatus.success;
            accrued += activationInfoOf[accountName].price;
            emit ActivationSuccess(accountName, activationInfoOf[accountName]);
        } else {
            activationInfoOf[accountName].status = activationStatus.fail;
            emit ActivationFailed(accountName, activationInfoOf[accountName]);
        }
    }

    function withdrawAccrued(address to) external onlyOwner {
        uint256 accrued_ = accrued;
        (bool success, ) = to.call{value: accrued_}("");
        require(success, "withdraw accrued failed");
        accrued = 0;
        emit Withdrawl(accrued_, to);
    }

    function setPrice(uint256 price_) public onlyOwner {
        price = price_;
        emit SetPrice(price);
    }

    function transferOwner(address owner_) external onlyOwner {
        pendingOwner = owner_;
        emit TransferOwner(pendingOwner);
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
        emit AcceptOwner(owner);
    }
}