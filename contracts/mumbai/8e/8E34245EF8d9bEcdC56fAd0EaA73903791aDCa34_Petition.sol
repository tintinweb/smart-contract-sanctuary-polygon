pragma solidity ^0.8.0;

import "./IGetterLogic.sol";

contract Petition {
    address humanboundToken;
    string petitionUri;

    mapping(uint256 => bool) signatures;

    constructor(address _humanboundToken, string memory _uri) {
        humanboundToken = _humanboundToken;
        petitionUri = _uri;
    }

    modifier onlyUniqueHuman(uint256 hbtId) {
        require(IGetterLogic(humanboundToken).balanceOf(msg.sender) > 0, "caller is not human");
        require(IGetterLogic(humanboundToken).ownerOf(hbtId) == msg.sender, "caller is not holder of this hbt");
        _;
    }

    modifier onlyUnsigned(uint256 hbtId) {
        require(signatures[hbtId] == false, "this human has already signed this petition");
        _;
    }

    function submitSignature(uint256 hbtId) public 
        onlyUniqueHuman(hbtId)
        onlyUnsigned(hbtId)
    {
        signatures[hbtId] = true;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGetterLogic {
    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) external returns (uint256);

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) external returns (address);

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) external returns (address);

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) external returns (bool);

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     *
     * Requirements:
     *
     * - Must be modified with `public _internal`.
     */
    function _exists(uint256 tokenId) external returns (bool);

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * - Must be modified with `public _internal`.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) external returns (bool);
}