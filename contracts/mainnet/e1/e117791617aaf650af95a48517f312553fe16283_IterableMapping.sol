/**
 *Submitted for verification at polygonscan.com on 2023-01-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

library IterableMapping {
    struct InvestorMap {
        address[] keys;
        mapping(address => uint256) amountInvested;
        mapping(address => uint256) securityTokenAmount;
        mapping(address => uint256) taxFee;
        mapping(address => uint256) indexOf;
    }

    struct holder {
        address[] keys;
        mapping(address => uint256) balance;
        mapping(address => uint256) indexOf;
    }

    function addInvestment(
        InvestorMap storage map,
        address key,
        uint256 amountInvest,
        uint256 securityAmount,
        uint256 taxFee
    ) external {
        if (map.indexOf[key] == 0) {
            if (map.keys.length == 0 || map.keys[0] != key) {
                map.indexOf[key] = map.keys.length;
                map.keys.push(key);
            }
        }
        map.amountInvested[key] += amountInvest;
        map.securityTokenAmount[key] += securityAmount;
        map.taxFee[key] += taxFee;
    }

    function updateBalance(
        holder storage map,
        address key,
        uint256 balance
    ) external {
        if (map.indexOf[key] == 0) {
            if (map.keys.length == 0 || map.keys[0] != key) {
                map.indexOf[key] = map.keys.length;
                map.keys.push(key);
            }
        }
        map.balance[key] = balance;
    }

    function reinitTaxFee(InvestorMap storage map, address key) external {
        map.taxFee[key] = 0;
    }

    function reinitInvestment(InvestorMap storage map, address key) external {
        map.amountInvested[key] = 0;
        map.securityTokenAmount[key] = 0;
        map.taxFee[key] = 0;
    }

    function getTokenAmountFor(InvestorMap storage map, address key)
        external
        view
        returns (uint256)
    {
        return map.amountInvested[key];
    }

    function getSecurityTokenAmountFor(InvestorMap storage map, address key)
        external
        view
        returns (uint256)
    {
        return map.securityTokenAmount[key];
    }

    function getTaxFee(InvestorMap storage map, address key)
        external
        view
        returns (uint256)
    {
        return map.taxFee[key];
    }

    function getKeyAtIndex(InvestorMap storage map, uint256 index)
        external
        view
        returns (address)
    {
        return map.keys[index];
    }

    function investorSize(InvestorMap storage map)
        external
        view
        returns (uint256)
    {
        return map.keys.length;
    }

    function getBalanceOf(holder storage map, address key)
        external
        view
        returns (uint256)
    {
        return map.balance[key];
    }

    function getKeyAddressAtIndex(holder storage map, uint256 index)
        external
        view
        returns (address)
    {
        return map.keys[index];
    }

    function holderSize(holder storage map) external view returns (uint256) {
        return map.keys.length;
    }
}