/**
 *Submitted for verification at polygonscan.com on 2022-12-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20{
    function transferFrom(address sender, address recipient, uint256 amount) external;
}

interface IGNSTradingVaultV5 {
    function maxBalanceDai() external view returns (uint);
    function currentBalanceDai() external view returns(uint);
}

contract OvercollatMigrationRouter {

    address constant gov = 0x80fd0accC8Da81b0852d2Dca17b5DDab68f22253;
    address immutable caller;

    constructor() {
        caller = msg.sender;
    }

    // migrate overcollat from TradingVaultV5
    function swapExactTokensForTokens(
        uint amountIn,
        uint,
        address[] calldata path,
        address,
        uint
    ) external returns (uint[] memory)  {
        require(tx.origin == caller, "Only owner can trigger overcollat migration");

        IGNSTradingVaultV5 vault = IGNSTradingVaultV5(msg.sender);
        // make sure amount being withdrawn does not cause the vault to become under collateralized
        require(vault.currentBalanceDai() - amountIn >= vault.maxBalanceDai(), "AmountIn would cause vault to become undercollateralised");

        // Transfer to gov
        IERC20(path[0]).transferFrom(msg.sender, gov, amountIn);

        // TradingVault calls storageT.handleTokens() with amount stored in amounts[1] meaning 0 tokens are burned
        uint[] memory amounts = new uint256[](2);
        amounts[0] = 0;
        amounts[1] = 0;

        return amounts;
    }
}