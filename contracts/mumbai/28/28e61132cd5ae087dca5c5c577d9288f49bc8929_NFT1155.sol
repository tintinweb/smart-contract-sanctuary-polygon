// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SignerRole.sol";
import "./ERC1155Base.sol";

contract NFT1155 is Ownable, SignerRole, ERC1155Base {
    string public name;
    string public symbol;

    constructor(string memory _name, string memory _symbol, address signer, string memory contractURI, string memory tokenURIPrefix) ERC1155Base(contractURI, tokenURIPrefix) {
        name = _name;
        symbol = _symbol;

        _addSigner(signer);
        _registerInterface(bytes4(keccak256('MINT_WITH_ADDRESS')));
    }

    function addSigner(address account) public override onlyOwner {
        _addSigner(account);
    }

    function removeSigner(address account) public onlyOwner {
        _removeSigner(account);
    }

    function mint(uint256 id, uint8 v, bytes32 r, bytes32 s, Fee[] memory fees, uint256 supply, string memory uri) public {
        require(isSigner(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(this, id)))), v, r, s)), "signer should sign tokenId");
        _mint(msg.sender, id, fees, supply, uri);
    }

}