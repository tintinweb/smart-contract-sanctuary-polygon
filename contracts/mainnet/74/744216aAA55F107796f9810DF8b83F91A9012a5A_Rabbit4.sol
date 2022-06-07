// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

library Rabbit4 {
    using Strings for uint256;
    function RabbitString(string memory attack, string memory defense, uint256 kills, bool revived, string memory tokenId, uint256 mintTimestamp) public view returns (string memory) {
        string memory _daysAlive = calculateDaysAlive(mintTimestamp).toString();
        string memory _level = calculatePlayerLevel(mintTimestamp, kills).toString();
        string memory _revived = revivedToString(revived);
        string memory image1 = '<path class="st43" d="M376.91,764.58c-10.13-3.99-20.24-7.92-30.26-11.75c9.01,40.97,18.98,82.62,28.63,122.9 c6.44,26.87,13.09,54.65,19.4,81.97c39.73,3.75,80.88,6.8,120.68,9.74l0.13,0.01L492.98,821.1c0-1.62-0.23-3.08-0.66-4.39 c-0.09-0.26-0.18-0.52-0.27-0.77c-0.15-0.38-0.32-0.75-0.5-1.1c-0.12-0.23-0.25-0.46-0.38-0.69c-0.07-0.11-0.14-0.22-0.21-0.33 c-0.21-0.33-0.44-0.65-0.68-0.96c-0.24-0.31-0.49-0.61-0.76-0.9c-0.18-0.19-0.36-0.38-0.55-0.57c-3.54-3.53-8.93-5.59-13.91-7.5 c-1.35-0.52-2.62-1-3.84-1.52c-2.81-1.13-5.64-2.26-8.48-3.4c-4.24-1.7-8.51-3.42-12.75-5.12c-1.44-0.58-2.88-1.16-4.32-1.74 c-2.79-1.12-5.57-2.24-8.32-3.35c-5.6-2.26-11.24-4.53-16.9-6.81c-3.23-1.3-6.47-2.6-9.71-3.9c-3.23-1.3-6.47-2.6-9.72-3.89 c-2.61-1.05-5.22-2.09-7.84-3.13c-0.37-0.15-0.74-0.3-1.12-0.44C387.02,768.57,381.96,766.57,376.91,764.58z"/> <path class="st27" d="M473.49,274.61c-41.29,45.04-85.58,88.58-131.37,129.87c8.26-23.27,15.01-48.05,30.03-67.57 C405.18,314.39,437.45,291.12,473.49,274.61z M473.38,274.69c-10.89,4.99-21.51,10.66-31.9,16.72c-1.89,1.1-3.77,2.22-5.65,3.35 c-17.82,10.72-35.01,22.52-51.86,34.08c-1.45,1-2.92,2-4.4,3.02c-2.46,1.69-4.95,3.39-7.41,5.07 c-12.51,16.25-19.35,36.36-25.97,55.8c-0.82,2.39-1.65,4.84-2.49,7.28c-0.34,0.98-0.68,1.95-1.02,2.92 c-0.17,0.48-0.34,0.97-0.51,1.45C389.25,361.95,433.38,318.31,473.38,274.69z"/> <path class="st13" d="M374.65,1171.44c-3.39,36.02-6.89,73.27-10.73,109.79c22.5-9.76,44.61-21.19,66-32.26 c2.03-23.68,5.49-47.59,8.84-70.72c4.07-28.16,8.28-57.29,9.93-86.15c-5.16-11-10.11-21.46-14.88-31.45 c-0.6-1.25-1.19-2.49-1.78-3.73s-1.18-2.46-1.77-3.68c-0.88-1.83-1.75-3.64-2.61-5.44c-1.15-2.4-2.3-4.77-3.43-7.12 c-2.55-5.29-5.05-10.44-7.52-15.47c0-0.01-0.01-0.01-0.01-0.01c-2.19-4.47-4.35-8.85-6.47-13.16 c-2.67-5.39-5.29-10.65-7.87-15.8c-1.04-2.05-2.06-4.09-3.08-6.12c-0.01-0.01-0.01-0.01-0.01-0.01 c-1.02-2.03-2.05-4.04-3.06-6.03c-0.51-1-1.02-1.99-1.52-2.98C386.59,1044.36,380.52,1108.96,374.65,1171.44z"/> <path class="st30" d="M397.86,761.11c7.64,3.45,15.31,6.87,23.01,10.25c3.26,1.44,6.53,2.86,9.81,4.29 c50.77,22.04,102.57,42.66,152.96,62.72c8.39,3.34,16.86,6.7,25.36,10.1c25.53,10.19,51.43,20.6,76.91,31.15 c3.75-10.12,7.75-20.22,11.63-30c3.87-9.77,7.87-19.88,11.63-30c-42.45-7.69-85.64-16.16-127.41-24.35 C521.58,783.48,459.37,771.29,397.86,761.11z"/> <path class="st31" d="M403.76,967.87c-1.52-0.12-3.03-0.24-4.55-0.35c17.7,37.62,36.01,76.52,54.76,113.27 c21-33.76,40.07-69.61,58.51-104.27c-25.63-2.56-51.81-4.47-77.13-6.31c-7.59-0.55-15.34-1.11-23.13-1.7 C409.4,968.3,406.58,968.09,403.76,967.87z"/> <path class="st28" d="M413.46,350.44c0.75,6,1.71,12.1,2.62,18c0.92,5.89,1.88,11.99,2.62,17.98 c31.46-13.68,58.95-28.89,82.86-45.88c0.7-0.51,1.4-1,2.1-1.5c1.39-1.01,2.77-2.02,4.14-3.04c0.69-0.51,1.37-1.02,2.05-1.53 c0.66-0.5,1.33-1,1.99-1.51c0.01-0.01,0.02-0.02,0.04-0.03c1.34-1.03,2.67-2.07,3.99-3.11c0.91-0.72,1.81-1.44,2.72-2.17 c0.62-0.5,1.24-1,1.85-1.5c0.49-0.41,0.97-0.8,1.46-1.21c0.59-0.49,1.18-0.97,1.76-1.47c0.63-0.54,1.27-1.07,1.9-1.61 c0.62-0.53,1.24-1.06,1.85-1.59c0.01-0.01,0.02-0.02,0.03-0.03c1.75-1.52,3.47-3.05,5.18-4.59c0.12-0.12,0.24-0.23,0.36-0.33 c8.49-7.72,16.4-15.76,23.76-24.15c-1.92,0.68-3.84,1.37-5.75,2.06c-2.87,1.05-5.75,2.11-8.62,3.19 c-25.81,9.73-51.28,20.79-76.05,31.55c-2.48,1.08-4.98,2.16-7.48,3.25c-10.55,4.58-21.28,9.21-32.04,13.71 c-2.22,0.93-4.44,1.86-6.66,2.77C417.9,348.64,415.68,349.54,413.46,350.44z"/> <path class="st32" d="M490.1,273.37c-17.37,16.72-35.33,33.99-50.33,52.99c37.39-11.52,74.08-27.71,109.57-43.36 c10.79-4.76,21.95-9.69,32.97-14.41c13.5-20.54,18.31-45.36,22.95-69.37c1.27-6.56,2.59-13.35,4.05-19.87 c-11.65,9.31-24.53,17.4-36.98,25.24c-9.82,6.17-19.82,12.46-29.36,19.43s-18.64,14.65-26.67,23.59 C507.79,256.36,498.79,265.01,490.1,273.37z"/> <path class="st33" d="M459.25,1091.34c6.35,6.07,12.72,12.19,19.07,18.32c2.66,2.56,5.32,5.13,7.97,7.7 c7.9,7.64,15.75,15.25,23.48,22.75c33.06,32.07,67.24,65.24,101.81,96.81c-2.82-21.31-7.22-42.55-11.47-63.09 c-3.69-17.82-7.51-36.25-10.29-54.7c-0.26-2.34-0.52-4.68-0.77-7.03c-0.71-6.5-1.39-13.03-2.05-19.51 c-1.02-9.88-1.99-19.71-2.95-29.36c-2.76-27.84-5.62-56.63-9.24-85.2c-0.52,0.04-1.04,0.09-1.57,0.12 c-1.05,0.07-2.11,0.1-3.17,0.12c-4.5,0.08-9.12-0.2-13.63-0.47c-11.71-0.71-23.81-1.43-34.14,3.98 c-14.18,21.48-26.64,44.26-38.71,66.29C475.81,1062.27,467.76,1076.97,459.25,1091.34z"/> <path class="st35" d="M500.16,1311.25c-0.37,0.52-0.74,1.03-1.11,1.55c4.35,2.7,8.48,5.96,12.48,9.3 c1.33,1.11,2.64,2.23,3.95,3.34c0.56,0.47,1.12,0.96,1.69,1.44c0.28,0.24,0.56,0.48,0.85,0.72c0.57,0.47,1.13,0.96,1.7,1.43 c0.71,0.59,1.43,1.18,2.16,1.77c0.43,0.35,0.86,0.7,1.3,1.05c0.58,0.46,1.17,0.92,1.76,1.38c6.2,4.76,12.87,8.91,20.63,11.08 c49.44,2.83,99.79,4.2,148.48,5.52c9.12,0.25,18.34,0.51,27.62,0.77c12.75,0.36,25.59,0.74,38.44,1.16 c7.56,0.26,15.11,0.52,22.65,0.8v-29.98c-17.51-3.5-35.32-7.15-52.54-10.68c-34.44-7.05-70.06-14.34-105.08-20.85 c-36.03-3-73.03-3-108.83-3c-3,4.13-5.86,8.32-8.63,12.38c-1.38,2.02-2.79,4.09-4.22,6.15c-0.71,1.04-1.44,2.08-2.17,3.11 C500.9,1310.21,500.54,1310.73,500.16,1311.25z"/> <path class="st29" d="M501.29,815.89c7.38,50.17,15.01,102.04,24.01,152.32c5.16,0,10.4,0.12,15.46,0.24 c12.54,0.3,25.5,0.61,37.81-1c23.28-17.2,45.97-35.79,67.92-53.77c10.64-8.71,21.64-17.73,32.63-26.52 c-22.77-9.51-45.69-18.86-68.59-28.06c-6.38-2.56-12.75-5.12-19.12-7.66c-5.02-2-10.04-3.99-15.04-5.98 c-14.09-5.6-28.13-11.14-42.1-16.63c-7.37-2.9-14.71-5.79-22.03-8.65C508.58,818.75,504.93,817.32,501.29,815.89z"/> <path class="st36" d="M586.86,973.51c-0.91,30.07,2.95,60.65,6.67,90.22c2.41,19.13,4.91,38.91,6.09,58.36 c94.34-21.04,189.89-43.74,282.29-65.7c9.96-2.36,19.93-4.73,29.9-7.1c-86.33-61.91-157.63-111.98-224.39-157.6 c-6.17,5.33-12.42,10.57-18.71,15.75c-1.8,1.49-3.59,2.96-5.4,4.43c0,0.01,0,0.01-0.01,0.01c-6.43,5.24-12.88,10.41-19.29,15.52 c-3.98,3.17-7.93,6.31-11.86,9.43c-2.8,2.23-5.63,4.47-8.45,6.72c-1.89,1.5-3.78,3.01-5.68,4.52 C607.61,956.41,597.1,964.9,586.86,973.51z"/> <path class="st37" d="M604.14,1144.72c3.17,19.32,7.21,38.99,11.12,58c0.33,1.63,0.67,3.27,1.01,4.91 c0.67,3.28,1.35,6.57,2.02,9.88c1.95,9.6,3.86,19.3,5.63,29.05c0.1,0.56,0.21,1.13,0.3,1.69c0.57,3.09,1.11,6.19,1.63,9.3 c0.52,3.09,1.03,6.19,1.51,9.28c0.83,5.31,1.6,10.62,2.28,15.92c23.65,4.13,47.49,9.09,70.56,13.89 c23.04,4.79,46.85,9.74,70.47,13.87c-8.13-8.36-16.36-16.8-24.69-25.3c-3.33-3.4-6.67-6.81-10.03-10.24 c-5.87-5.99-11.79-12-17.75-18.04c-3.07-3.11-6.15-6.22-9.24-9.35C675.16,1213.46,640.06,1178.75,604.14,1144.72z"/> <path class="st38" d="M720.55,1103.64c-38.6,9.13-76.99,18.38-114.89,27.51c47.34,48.53,96.54,97.01,144.12,143.88 c12.04,11.86,24.49,24.12,36.74,36.22c18.39-36.79,37.53-74.04,56.04-110.06c23.76-46.25,48.33-94.08,71.54-141.34 c-7.12,1.51-14.25,3.03-21.39,4.57c-7.5,1.61-14.99,3.25-22.5,4.9c-3.61,0.79-7.23,1.59-10.85,2.39 c-2.16,0.47-4.32,0.96-6.49,1.44c-30.98,6.89-62.02,14-92.99,21.23c-0.19,0.04-0.38,0.09-0.57,0.13 C746.38,1097.53,733.45,1100.58,720.55,1103.64z"/> <path class="st39" d="M681.49,727.37c11.06,28.01,22.5,56.98,36.73,83.96c24.47,14.43,50.86,25.87,76.38,36.92 c4.95,2.15,10.07,4.37,15.08,6.56C771.84,813.46,728.7,770.58,681.49,727.37z"/> <path class="st10" d="M716.72,822.64c-7.37,19.91-15,40.51-22.5,61.51c9.71,6.67,19.43,13.46,29.1,20.29 c11.29,7.96,22.52,15.97,33.62,23.92c4.76,3.41,9.49,6.8,14.2,10.18c8.37,6,16.8,12.05,25.28,18.1 c3.76,2.69,7.54,5.38,11.33,8.06c33.16,23.55,67.12,47.05,101.82,68.78c-10.55-24.05-22.26-48.29-33.57-71.72 c-8.81-18.24-17.92-37.11-26.45-55.81c-1.44-2.7-2.73-5.63-3.98-8.45c-3.98-9.01-8.09-18.32-17.78-22.32 C791.65,857.47,754.27,839.17,716.72,822.64z"/> <path class="st40" d="M923.14,1065.89c-17.17,29.85-33.05,60.88-47.24,92.23c24.13-6.66,46.34-13.47,65.98-20.25 C935.98,1114.28,929.88,1089.89,923.14,1065.89z"/> <path class="st41" d="M930.74,1052.28c0,5.24,0.65,10.5,2.19,15.8c1.31,5.25,2.69,10.55,4.07,15.83 c1.39,5.28,2.8,10.53,4.18,15.7c0.69,2.58,1.39,5.18,2.08,7.79c0.44,1.66,0.88,3.31,1.32,4.98c0.61,2.28,1.21,4.57,1.81,6.86 c1.03,3.96,2.05,7.92,3.03,11.85c12.12-14.32,23.66-29.36,34.83-43.89c4.05-5.28,8.24-10.73,12.42-16.11 c-1.54-2.66-3.06-5.33-4.57-8.02c-1.32-2.33-2.61-4.66-3.9-7c-1.85-3.35-3.68-6.7-5.49-10.05c-2.72-5.02-5.4-10.02-8.04-14.95 c-8.07-15.07-16.41-30.64-25.24-45.49c-1.97,6.88-4.55,13.71-7.28,20.94C936.52,1021.42,930.74,1036.71,930.74,1052.28z"/> <path class="st42" d="M969.62,912.06c-5.93,19.13-12.07,38.91-15.67,59.17c9.46,20.91,20.81,41.6,31.79,61.61 c5.61,10.24,11.42,20.82,16.98,31.43c3.75-4.92,7.61-9.89,11.47-14.82c2.31-2.96,4.62-5.89,6.9-8.8 c1.52-1.94,3.06-3.89,4.6-5.85c4.62-5.89,9.28-11.87,13.79-17.78c-18.66-47.79-38.35-96.25-58.52-144.05 C977.65,886.17,973.57,899.33,969.62,912.06z"/> </g> </g> </g> </g> ';
        string memory image2 = string(abi.encodePacked('<text fill="#ffffff" x="-440" y="1650" class="small">Attack: ',attack,' &#9876;</text> <text fill="#ffffff" x="-440" y="1730" class="small">Defense: ',defense,' &#128737;</text> <text fill="#ffffff" x="-440" y="-70" class="small">Alive: ',_daysAlive,' Days &#9200;</text> <text fill="#ffffff" x="-440" y="6" class="small">Level: ',_level,' &#127894;</text>'));
        string memory image3 = string(abi.encodePacked(' <text fill="#ffffff" x="405" y="-95" class="small"># ',tokenId,'</text> <text fill="#ffffff" x="1065" y="-70" class="small">Revived: ',_revived,'</text> <text fill="#ffffff" x="295" y="1730" class="small">Kills Count: ',kills.toString(),' &#128128;</text> <text fill="#ffffff" x="1060" y="1730" class="small">Team Rabbit &#129365;</text> </svg>'));
        string memory result = string(abi.encodePacked(image1,image2,image3));
        return result;
    }

    function calculateDaysAlive(uint256 timestamp) internal view returns(uint256) {
        return (((block.timestamp - timestamp) / 86400)+1);
    }

    function calculatePlayerLevel(uint256 timestamp, uint256 kills) internal view returns(uint256) {
        return calculateDaysAlive(timestamp)/10 + kills/2;
    }

    function revivedToString(bool revived) internal pure returns(string memory) {
        if (revived) {
            return "Yes &#128519;";
        } else {
            return "No &#128512;";
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}