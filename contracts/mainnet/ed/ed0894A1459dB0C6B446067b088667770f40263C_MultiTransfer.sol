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
    ) external {
        for (uint i = 0; i < _addresses.length; i++) {
            payable(_addresses[i]).transfer(_values[i]);
        }
    }

    function transferNfts(
        address[] memory _to,
        uint256[] memory _tokenId,
        address[] memory _contracts
    ) external {
        for (uint i = 0; i < _contracts.length; i++) {
            IERC(_contracts[i]).transferFrom(msg.sender, _to[i], _tokenId[i]);
        }
    }
}