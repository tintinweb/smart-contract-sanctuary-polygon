/**
 *Submitted for verification at polygonscan.com on 2022-04-27
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20MetadataLookup {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20Lookup {
    struct LookupResult {
        string symbol;
        string name;
        uint8 decimals;
    }

    function lookup(address[] memory tokens) public view returns (LookupResult[] memory result) {
        result = new LookupResult[](tokens.length);

        for (uint i=0; i<tokens.length; i++) {
            ERC20MetadataLookup token = ERC20MetadataLookup(tokens[i]);
            result[i] = LookupResult({
                decimals: token.decimals(),
                name: token.name(),
                symbol: token.symbol()
            });
        }
    }
}