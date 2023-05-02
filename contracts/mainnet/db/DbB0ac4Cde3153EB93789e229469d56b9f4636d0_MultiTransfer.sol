pragma solidity ^0.8.0;

interface IERC {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

pragma solidity ^0.8.0;

import "./IERC.sol";

contract MultiTransfer {
    function transferCurrency(
        address[] memory _addresses,
        uint256[] memory _values
    ) external payable {
        for (uint i = 0; i < _addresses.length; i++) {
            payable(_addresses[i]).transfer(_values[i]);
        }
    }

    function transferNfts(
        address[] memory _from,
        address[] memory _to,
        uint256[] memory _tokenId,
        address _contract
    ) external payable {
        for (uint i = 0; i < _from.length; i++) {
            IERC(_contract).transferFrom(_from[i], _to[i], _tokenId[i]);
        }
    }
}