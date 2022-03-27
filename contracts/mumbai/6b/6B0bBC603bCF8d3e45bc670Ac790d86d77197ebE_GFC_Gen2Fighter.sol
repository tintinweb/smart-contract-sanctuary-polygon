// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Whitelist.sol";

contract GFC_Gen2Fighter is ERC721Enumerable, Ownable, Whitelist {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public _tokenBaseURI;

    //ERC20 basic token contract being held
    IERC20 public immutable GCOIN;

    //In case we need to pause Gen 2 mint
    bool public paused;

    constructor(IERC20 token) ERC721('GFC Gen 2 Fighter', 'GFCGen2') { 
        GCOIN = token;
    }

    function mint(address to) external isWhitelisted returns (uint256) {
        require(!paused, "The mint function have been paused");
        uint256 tokenId = totalSupply();
        _safeMint(to, tokenId);
        return tokenId;
    }

    function tokensOfOwner(address _owner)external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 i; i < tokenCount; i++) {
                result[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return result;
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    /*
     * Only the owner can do these things
     */

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _tokenBaseURI = _newBaseURI;
    }

    function withdrawGCOIN() external onlyOwner {
        IERC20(GCOIN).safeTransfer(msg.sender, IERC20(GCOIN).balanceOf(address(this)));
    }
}