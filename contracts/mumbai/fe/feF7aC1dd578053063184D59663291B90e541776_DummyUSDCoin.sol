// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.11;

import "./DummyERC20.sol";

contract DummyUSDCoin is DummyERC20("USD Coin (Dummy)", "USDC", 6) {
}