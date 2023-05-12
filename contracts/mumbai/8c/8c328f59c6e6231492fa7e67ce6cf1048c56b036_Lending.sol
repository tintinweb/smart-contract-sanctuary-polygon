/**
 *Submitted for verification at polygonscan.com on 2023-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Lending {
    address payable ADMIN;
    uint256 ADMIN_FEES;
    IERC20 GCT_TOKEN;
    uint256 ROI30;
    uint256 ROI60;
    uint256 ROI90;
    // Total Amount
    struct borrwer {
        address BorrowerAddress;
        uint256 TokenAmount;
        uint256 ETHPRICE;
        uint256 ReturnTime;
        uint256 Days;
    }
    mapping(address => borrwer) public BorrwerPool;
    error ERROR(string);

    constructor(
        address _ADMIN,
        uint256 _ADMIN_FEES,
        address _GCT_TOKEN,
        uint256 _ROI30,
        uint256 _ROI60,
        uint256 _ROI90
    ) {
        ADMIN = payable(_ADMIN);
        ADMIN_FEES = _ADMIN_FEES;
        GCT_TOKEN = IERC20(_GCT_TOKEN);
        ROI30 = _ROI30;
        ROI60 = _ROI60;
        ROI90 = _ROI90;
    }

    function BorrowToken(
        uint256 _TokenAmount,
        uint256 _ETHPRICE,
        uint8 _Days
    ) public payable {
        if (_Days == 30) {
            BorrwerPool[msg.sender].BorrowerAddress = msg.sender;
            BorrwerPool[msg.sender].TokenAmount = _TokenAmount;
            BorrwerPool[msg.sender].ETHPRICE = _ETHPRICE;
            BorrwerPool[msg.sender].ReturnTime = block.timestamp + 2592000;
            BorrwerPool[msg.sender].Days = 30;
            uint256 TotalETHamount = _TokenAmount * _ETHPRICE;
            ADMIN.transfer(TotalETHamount);
            GCT_TOKEN.transferFrom(ADMIN, msg.sender, _TokenAmount);
        } else if (_Days == 60) {
            BorrwerPool[msg.sender].BorrowerAddress = msg.sender;
            BorrwerPool[msg.sender].TokenAmount = _TokenAmount;
            BorrwerPool[msg.sender].ETHPRICE = _ETHPRICE;
            BorrwerPool[msg.sender].ReturnTime = block.timestamp + 5184000;
            BorrwerPool[msg.sender].Days = 60;
            uint256 TotalETHamount = _TokenAmount * _ETHPRICE;
            ADMIN.transfer(TotalETHamount);
            GCT_TOKEN.transferFrom(ADMIN, msg.sender, _TokenAmount);
        } else if (_Days == 90) {
            BorrwerPool[msg.sender].BorrowerAddress = msg.sender;
            BorrwerPool[msg.sender].TokenAmount = _TokenAmount;
            BorrwerPool[msg.sender].ETHPRICE = _ETHPRICE;
            BorrwerPool[msg.sender].ReturnTime = block.timestamp + 7776000;
            BorrwerPool[msg.sender].Days = 90;
            uint256 TotalETHamount = _TokenAmount * _ETHPRICE;
            ADMIN.transfer(TotalETHamount);
            GCT_TOKEN.transferFrom(ADMIN, msg.sender, _TokenAmount);
        } else if (_Days == 1) {
            BorrwerPool[msg.sender].BorrowerAddress = msg.sender;
            BorrwerPool[msg.sender].TokenAmount = _TokenAmount;
            BorrwerPool[msg.sender].ETHPRICE = _ETHPRICE;
            BorrwerPool[msg.sender].ReturnTime = block.timestamp + 60;
            uint256 TotalETHamount = _TokenAmount * _ETHPRICE;
            ADMIN.transfer(TotalETHamount);
            GCT_TOKEN.transferFrom(ADMIN, msg.sender, _TokenAmount);
        } else revert ERROR("_Invalid Options !");
    }

    function ReturnToken(uint256 _TokenAmount) public payable {
        require(
            BorrwerPool[msg.sender].ReturnTime > block.timestamp,
            "Return Time expired Sorry !"
        );
        require(
            GCT_TOKEN.balanceOf(BorrwerPool[msg.sender].BorrowerAddress) >=
                _TokenAmount,
            "You dont have enough balance !"
        );
        if (BorrwerPool[msg.sender].Days == 30) {
            uint256 interest = (_TokenAmount * ROI30) / 100;
            uint256 Amountredeem = _TokenAmount *
                BorrwerPool[msg.sender].ETHPRICE -
                interest;
            GCT_TOKEN.transferFrom(msg.sender, ADMIN, _TokenAmount);
            payable(msg.sender).transfer(Amountredeem);
            delete BorrwerPool[msg.sender];
        } else if (BorrwerPool[msg.sender].Days == 90) {
            uint256 interest = (_TokenAmount * ROI60) / 100;
            uint256 Amountredeem = _TokenAmount *
                BorrwerPool[msg.sender].ETHPRICE -
                interest;
            GCT_TOKEN.transferFrom(msg.sender, ADMIN, _TokenAmount);
            payable(msg.sender).transfer(Amountredeem);
            delete BorrwerPool[msg.sender];
        } else if (BorrwerPool[msg.sender].Days == 60) {
            uint256 interest = (_TokenAmount * ROI90) / 100;
            uint256 Amountredeem = _TokenAmount *
                BorrwerPool[msg.sender].ETHPRICE -
                interest;
            GCT_TOKEN.transferFrom(msg.sender, ADMIN, _TokenAmount);
            payable(msg.sender).transfer(Amountredeem);
            delete BorrwerPool[msg.sender];
        }
    }
}