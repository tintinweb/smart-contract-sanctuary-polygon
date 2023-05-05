pragma solidity ^0.8.19;

interface IERC {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

pragma solidity ^0.8.19;

import "./IERC.sol";

contract MultiTransfer {
    constructor() payable {}

    function transferCurrency(
        address payable[] memory _addresses,
        uint256[] memory _values
    ) public {
        for (uint i = 0; i < _addresses.length; i++) {
            (bool sent, ) = _addresses[i].call{value: _values[i]}("");
            require(sent, "Failed to send matic");
        }
    }

    function transferNfts(
        address[] memory _from,
        address[] memory _to,
        uint256[] memory _tokenId,
        address _contract
    ) public {
        for (uint i = 0; i < _from.length; i++) {
            IERC(_contract).transferFrom(_from[i], _to[i], _tokenId[i]);
        }
    }
}