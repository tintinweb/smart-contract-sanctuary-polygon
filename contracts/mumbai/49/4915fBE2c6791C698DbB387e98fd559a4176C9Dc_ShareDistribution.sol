/**
 *Submitted for verification at polygonscan.com on 2022-11-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract ShareDistribution {

    mapping(address => uint) public partners_shares;
    address [] public partners;
    uint public total_share;
    uint min_balance_to_withdraw;
    string token_symbol_filter;
    
    constructor () {
        min_balance_to_withdraw = 1000;
        token_symbol_filter = "UNI-V2";
        modify_partners(0xF554cccf790B22FB3a49186300A0CF3e15002466,20*1000);
        modify_partners(0x212811209cFA37E9bbE75230eD3c7bB58286b1e5,20*1000);
        modify_partners(0xbBd9f3862f997EC09a4d5515C6bd7D6577F9b834,60*1000);
    }

    function claim_income (address token_address) public {
        //get balance
        IERC20 token = IERC20(token_address);
        uint balance = token.balanceOf(address(this));
        require(balance<=min_balance_to_withdraw,"Less than min balance!");
        string memory token_symbol = token.symbol();
        require(keccak256(bytes(token_symbol)) == keccak256(bytes(token_symbol_filter)),"Just Some tokens allowed for withdraw!");

        for(uint8 i;i<partners.length;i++){
            uint payable_shares = balance * ( partners_shares[partners[i]] / total_share );
            token.transfer(partners[i],payable_shares);
        }
    }

    function modify_partners (address partner, uint share) private {
        require(share >= 1);
        if (partners_shares[partner] > 0)
        {
            total_share -= partners_shares[partner];
            total_share += share;
            partners_shares[partner] = share;
        }else{
            total_share += share;
            partners_shares[partner] = share;
            partners.push(partner);
        }
    }
}

interface IERC20 {
    function symbol() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}