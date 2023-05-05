/**
 *Submitted for verification at polygonscan.com on 2023-05-04
*/

// SPDX-License-Identifier: MIT
// solhint-disable comprehensive-interface
pragma solidity ^0.8.0;

/// @title Test NFT - A Smart Contract for an NFT game based on the proximity of addresses
/// @dev Right now there are no transfer functions and this is just a proof of concept to get people
/// excited about it and put our names out there. Let's see how close we can get!
/// [ ] Change name and symbol and URI and NatSpec and ack address
contract TestNFT {
    int256 private _minDifference;

    address private _currentClosest;

    uint64 private _lastStolen;
    uint16 private _timesStolen;

    /// @notice Transfer event to log NFT transfers
    /// @param from The address from which the NFT is being transferred
    /// @param to The address to which the NFT is being transferred
    /// @param tokenId The ID of the NFT being transferred
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /// @notice Initializes the contract, sending to ACK and emitting a Transfer event
    constructor() {
        // address ack = 0x03ee832367E29a5CD001f65093283eabB5382B62;

        _minDifference = int256(uint256(uint160(0x4200000000000000000000000000000000000000))) - int256(uint256(uint160(address(this))));
        _currentClosest = 0x4200000000000000000000000000000000000000;
        emit Transfer(address(0), 0x4200000000000000000000000000000000000000, 1);
    }

    /// @notice Allows a user to steal the NFT if their address is closer to the contract's address
    function steal() external {
        int256 difference = int256(uint256(uint160(msg.sender))) -
            int256(uint256(uint160(address(this))));
        require(
            (difference < 0 ? -difference : difference) <
                (_minDifference < 0 ? -_minDifference : _minDifference),
            "Address isn't closer!"
        );

        ++_timesStolen;
        _lastStolen = uint64(block.timestamp); // solhint-disable-line not-rely-on-time
        _minDifference = difference;
        emit Transfer(_currentClosest, msg.sender, 1);
        _currentClosest = msg.sender;
    }

    /// @notice Gets the balance of the specified address
    /// @param owner The address to query the balance of
    /// @return The balance of the specified address
    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == _currentClosest) {
            return 1;
        } else {
            return 0;
        }
    }

    /// @notice Gets the owner of the specified token ID
    /// @param tokenId The token ID to query the owner of
    /// @return The owner of the specified token ID
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        require(tokenId == 1, "ERC721: invalid token ID");
        return _currentClosest;
    }

    /// @notice Gets the name of the token
    /// @return The token name
    function name() public view virtual returns (string memory) {
        return "Test";
    }

    /// @notice Gets the symbol of the token
    /// @return The token symbol
    function symbol() public view virtual returns (string memory) {
        return "TST";
    }

    /// @notice Gets the token URI of the specified token ID
    /// @param id The token ID to query the token URI of
    /// @return The token URI of the specified token ID
    function tokenURI(uint256 id) public view returns (string memory) {
        // solhint-disable quotes, max-line-length
        return
            string(
                abi.encodePacked(
                    'data:application/json;utf8,{"name":"Test","description":"Test Test Test Test?","image":"ipfs://QmZsxYajH4Qx9YtAMbS6vm8PdaBnP6SqE4H9y4bV1U4yds","attributes":[{"display_type":"date","trait_type":"Last Stolen","value":',
                    _toString(int64(_lastStolen)),
                    '},{"display_type":"boost_number","trait_type":"Times Stolen","value":',
                    _toString(int16(_timesStolen)),
                    '},{"display_type": "boost_percentage","trait_type":"~Distance Away","value":',
                    _toString((_minDifference * 100) / int256(uint256(uint160(address(this))))),
                    "}]}"
                )
            );
        // solhint-enable quotes, max-line-length
    }

    // solhint-disable-next-line code-complexity
    function _log10(uint256 value) private pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    function _toString(int256 value) private pure returns (string memory) {
        // solhint-disable no-inline-assembly
        unchecked {
            bytes16 symbols = "0123456789abcdef";
            bool negative = value < 0;
            int256 uvalue = negative ? -value : value;
            uint256 length = negative ? _log10(uint256(uvalue)) + 2 : _log10(uint256(uvalue)) + 1;
            string memory buffer = new string(length);
            uint256 ptr;

            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                assembly {
                    mstore8(ptr, byte(mod(uvalue, 10), symbols))
                }
                uvalue /= 10;
                if (uvalue == 0) break;
            }
            if (negative) {
                buffer = string.concat("-", buffer);
            }
            return buffer;
        }
        // solhint-enable no-inline-assembly
    }
}