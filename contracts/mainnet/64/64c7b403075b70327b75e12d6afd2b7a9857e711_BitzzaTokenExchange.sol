/**
 *Submitted for verification at polygonscan.com on 2023-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract BitzzaTokenExchange {
    address private constant BITZZA_TOKEN_ADDRESS = 0x033d1801053f0E337527AFfd6647F846ED996ECf;
    uint256 private constant BITZZA_PRICE = 8817200000000000; // $8.8172 in wei
    uint256 private constant HOLDERS_CASHBACK_PERCENTAGE = 234375; // 2.34375%

    address private constant GOVERNMENT_TAX_ADDRESS = 0xA4908d0cEe99F4f9B3e340eF5A9eBBD1677a7c3d;
    address private constant COMPANY_IMPROVEMENT_ADDRESS = 0x812590cA4593070b77da87d91b905277376c590D;
    address private constant HOLDERS_CASHBACK_ADDRESS = 0x9F0bEaaa78353Af5FB3f9817fDD17abFF3D8bb8F;
    address private constant BITZZA_EARNINGS_ADDRESS = 0x033d1801053f0E337527AFfd6647F846ED996ECf;

    address private owner;

    event TokensExchanged(address indexed sender, uint256 amount);

    constructor() {
        owner = BITZZA_TOKEN_ADDRESS;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function exchangeTokens() external payable {
        require(msg.value > 0, "Invalid amount");

        uint256 bitzzaTokens = (msg.value * 1e18) / BITZZA_PRICE;

        uint256 totalPercentage = 10000000;
        uint256 governmentTaxPercentage = 375000;
        uint256 companyImprovementPercentage = 937500;
        uint256 holdersCashbackPercentage = HOLDERS_CASHBACK_PERCENTAGE;
        uint256 bitzzaEarningsPercentage = totalPercentage - governmentTaxPercentage - companyImprovementPercentage - holdersCashbackPercentage;

        uint256 governmentTax = (bitzzaTokens * governmentTaxPercentage) / totalPercentage;
        uint256 companyImprovement = (bitzzaTokens * companyImprovementPercentage) / totalPercentage;
        uint256 holdersCashback = (bitzzaTokens * holdersCashbackPercentage) / totalPercentage;
        uint256 bitzzaEarnings = (bitzzaTokens * bitzzaEarningsPercentage) / totalPercentage;

        IERC20(BITZZA_TOKEN_ADDRESS).transfer(msg.sender, bitzzaTokens);
        IERC20(BITZZA_TOKEN_ADDRESS).transfer(GOVERNMENT_TAX_ADDRESS, governmentTax);
        IERC20(BITZZA_TOKEN_ADDRESS).transfer(COMPANY_IMPROVEMENT_ADDRESS, companyImprovement);
        IERC20(BITZZA_TOKEN_ADDRESS).transfer(HOLDERS_CASHBACK_ADDRESS, holdersCashback);
        IERC20(BITZZA_TOKEN_ADDRESS).transfer(BITZZA_EARNINGS_ADDRESS, bitzzaEarnings);

        emit TokensExchanged(msg.sender, bitzzaTokens);
    }

    function getBitzzaPrice() external pure returns (uint256) {
        return BITZZA_PRICE;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}