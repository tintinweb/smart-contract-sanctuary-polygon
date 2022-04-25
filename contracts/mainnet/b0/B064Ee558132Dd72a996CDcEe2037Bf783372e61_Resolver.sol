/**
 *Submitted for verification at polygonscan.com on 2022-04-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20MetadataLookup {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

uint8 constant KIND_IGNORE = 0;
uint8 constant KIND_ERC20 = 1;
uint8 constant KIND_ERC721 = 2;

contract Resolver {
    struct LookupResult {
        string symbol;
        string name;
        uint8 kind;
        uint8 decimals;
    }

    function lookupName(ERC20MetadataLookup token) internal view returns (string memory name, bool success) {
        try token.name() returns (string memory _name) {
            return (_name, true);
        } catch {
            return ('', false);
        }
    }

    function lookupDecimals(ERC20MetadataLookup token) internal view returns (uint8 decimals, bool success) {
        try token.decimals() returns (uint8 _decimals) {
            return (_decimals, true);
        } catch {
            return (0, false);
        }
    }

    function lookupSymbol(ERC20MetadataLookup token) internal view returns (string memory symbol) {
        try token.symbol() returns (string memory _symbol) {
            return _symbol;
        } catch {
            return '';
        }
    }

    function lookup(address[] memory tokens) public view returns (LookupResult[] memory result) {
        result = new LookupResult[](tokens.length);

        for (uint i=0; i<tokens.length; i++) {
            result[i] = lookupSingle(tokens[i]);
        }
    }

    function lookupSingle(address token) public view returns (LookupResult memory result) {
        if (token.code.length == 0) {
            return LookupResult({
                symbol: '',
                name: '',
                decimals: 0,
                kind: KIND_IGNORE
            });
        }

        (string memory name, bool successName) = lookupName(ERC20MetadataLookup(token));

        if (!successName) {
            return LookupResult({
                symbol: '',
                name: '',
                decimals: 0,
                kind: KIND_IGNORE
            });
        }

        string memory symbol = lookupSymbol(ERC20MetadataLookup(token));

        (uint8 decimals, bool successDecimals) = lookupDecimals(ERC20MetadataLookup(token));

        if (successDecimals) {
            return LookupResult({
                symbol: symbol,
                name: name,
                decimals: decimals,
                kind: KIND_ERC20
            });
        }

        return LookupResult({
            symbol: symbol,
            name: name,
            decimals: 0,
            kind: KIND_ERC721
        });
    }
}