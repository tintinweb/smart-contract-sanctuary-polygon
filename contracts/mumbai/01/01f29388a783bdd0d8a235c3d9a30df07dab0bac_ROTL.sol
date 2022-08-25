// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";
import "./AccessControlEnumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract ROTL is AccessControlEnumerable, Ownable, ERC721A, ERC721ABurnable, ERC721AQueryable {
    using SafeMath for uint256;

    event SetBaseTokenURI(string uri);

    string private _baseTokenURI;

    constructor() ERC721A("ROM0", "ROM1") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function getFaction(uint256 id) external pure returns (uint256) {
        if (id < 5000) {
            return 1;
        } else if (id < 10000) {
            return 2;
        } else if (id < 15000) {
            return 3;
        } else if (id < 25000) {
            return 4;
        } else if (id < 35000) {
            return 5;
        }
        return 0;
    }

    function setBaseTokenURI(string memory uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = uri;
        emit SetBaseTokenURI(uri);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}