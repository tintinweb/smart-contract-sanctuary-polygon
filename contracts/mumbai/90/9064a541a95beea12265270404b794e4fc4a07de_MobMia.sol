//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc1155
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract MobMia is ERC1155, Ownable {
    using Strings for uint256;

    string public constant INITIAL_BASEURI =
        "https://ipfs.io/ipfs/QmdSTYvRcAmeA1Tk3H1J1LCLv7uaPwybvvqdbESQwgFDRL/";

    string public name = "Internet of Mobility Mobsters - Miami";
    string public symbol = "MOBMIA";
    string public baseUri;

    constructor()
        ERC1155(string(abi.encodePacked(INITIAL_BASEURI, "{id}.json")))
    {
        baseUri = INITIAL_BASEURI;
    }

    function updateBaseUri(string calldata updatedUri) public onlyOwner {
        baseUri = updatedUri;
    }

    function uri(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(baseUri, Strings.toString(_tokenId), ".json")
            );
    }

    function mint(uint256[] memory _ids, uint256[] memory _amounts)
        public
        onlyOwner
    {
        _mintBatch(msg.sender, _ids, _amounts, "");
    }
}