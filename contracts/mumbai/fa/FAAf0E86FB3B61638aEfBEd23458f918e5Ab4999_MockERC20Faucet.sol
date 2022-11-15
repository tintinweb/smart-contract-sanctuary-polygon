/**
 *Submitted for verification at polygonscan.com on 2022-11-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IMockERC20 {
    function decimals() external returns (uint8);
    function mint(address to, uint256 amount) external;
}

contract MockERC20Faucet {
    bytes32 private constant BTC = keccak256(abi.encode("btc"));
    bytes32 private constant ETH = keccak256(abi.encode("eth"));
    bytes32 private constant LINK = keccak256(abi.encode("link"));
    bytes32 private constant MATIC = keccak256(abi.encode("matic"));
    bytes32 private constant USDC = keccak256(abi.encode("usdc"));
    bytes32 private constant USDT = keccak256(abi.encode("usdt"));

    IMockERC20 private constant btc = IMockERC20(0xB0C79Ee335f348973b0c041ff4736e1716C824cE);
    IMockERC20 private constant eth = IMockERC20(0x0A93AAe58941F230551cDE0E0A8310d49C989aC0);
    IMockERC20 private constant link = IMockERC20(0xfD3363A7c824318846E4c06A227Dd0286a2c0E81);
    IMockERC20 private constant matic = IMockERC20(0x252679E8cD8C40b4bF99A50Aba47CB5880182a24);
    IMockERC20 private constant usdc = IMockERC20(0x14AcaC47f89627a8C920CdCA796f9f0a0E3F8243);
    IMockERC20 private constant usdt = IMockERC20(0x1B8a427Cc2AD01d3109F46aaC1DEABB9c45f845b);

    function drip(string calldata token, uint256 amount) external {
        bytes32 tokenHash = keccak256(abi.encode(token));
        IMockERC20 target = BTC == tokenHash
            ? btc
            : ETH == tokenHash
                ? eth
                : LINK == tokenHash
                    ? link
                    : MATIC == tokenHash ? matic : USDC == tokenHash ? usdc : USDT == tokenHash ? usdt : IMockERC20(address(0));
        target.mint(msg.sender, amount * 10 ** target.decimals());
    }

    function dripAll() external {
        btc.mint(msg.sender, 10 * 10 ** btc.decimals());
        eth.mint(msg.sender, 200 * 10 ** eth.decimals());
        link.mint(msg.sender, 30_000 * 10 ** link.decimals());
        matic.mint(msg.sender, 200_000 * 10 ** matic.decimals());
        usdc.mint(msg.sender, 200_000 * 10 ** usdc.decimals());
        usdt.mint(msg.sender, 200_000 * 10 ** usdt.decimals());
    }
}