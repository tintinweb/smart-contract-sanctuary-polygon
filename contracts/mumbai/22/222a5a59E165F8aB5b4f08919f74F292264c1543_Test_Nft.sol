// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.4;

import "./ERC721.sol";

import "./Governance.sol";
import "./RoyaltyFactory.sol";

contract Test_Nft is ERC721, Governance, RoyaltyFactory {
    using SafeMath for uint256;

    uint256 private _lastTokenID = 0;

    constructor() ERC721("Test Nft", "TNFT") {
        _setBaseURI("https://ipfs.io/ipfs/");
    }

    function setURIPrefix(string memory baseURI) public onlyGovernance {
        _setBaseURI(baseURI);
    }

    /**
     * this function assignes the URI to automatically add the id number at the end of the URI
     */
    function assignDataToToken(uint256 id, string memory uri) public {
        require(_msgSender() == ownerOf(id), "invalid token owner");
        _setTokenURI(id, uri);
    }

    /**
     * this function helps with queries to Fetch all the tokens that the address owns by givine address
     */
    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        require(owner != address(0), "invalid owner");
        uint256 length = balanceOf(owner);
        uint256[] memory tokens = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            tokens[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokens;
    }

    /**
     * this function allows to approve more than one token id at once
     */
    function approveMany(address _to, uint256[] memory _tokenIds) public {
        /* Allows bulk-approval of many tokens. This function is useful for
       exchanges where users can make a single tx to enable the call of
       transferFrom for those tokens by an exchange contract. */
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            // approve handles the check for if one who is approving is the owner.
            approve(_to, _tokenIds[i]);
        }
    }

    /**
     * this function allows to approve all the tokens the address owns at once
     */
    function approveAll(address _to) public {
        uint256[] memory tokens = tokensOfOwner(msg.sender);
        for (uint256 t = 0; t < tokens.length; t++) {
            approve(_to, tokens[t]);
        }
    }

    /**
     * this function allows to mint more of your ART
     */
    function mint(string memory metadata, uint256 royaltyFee)
        external
        returns (bool)
    {
        _lastTokenID++;
        // The index of the newest token is at the # totalTokens.
        setOriginalCreator(_lastTokenID, _msgSender());
        setRoyaltyFee(_lastTokenID, royaltyFee);
        _mint(msg.sender, _lastTokenID);
        _setTokenURI(_lastTokenID, metadata);
        return true;
    }

    /**
     * this function allows you burn your NFT
     */
    function burn(uint256 _id) external {
        require(
            _isApprovedOrOwner(_msgSender(), _id),
            "caller is not owner nor approved"
        );
        _burn(_id);
    }
}