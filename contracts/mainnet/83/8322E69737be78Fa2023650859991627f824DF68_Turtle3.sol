// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

library Turtle3 {
    using Strings for uint256;
    function TurtleString(string memory attack, string memory defense, uint256 kills, bool revived, string memory tokenId, uint256 mintTimestamp) public view returns (string memory) {
        string memory _daysAlive = calculateDaysAlive(mintTimestamp).toString();
        string memory _level = calculatePlayerLevel(mintTimestamp, kills).toString();
        string memory _revived = revivedToString(revived);
        string memory image1 = '<path class="st10" d="M1503.37,766.8c55.23,88.95,106.97,180.22,163.36,268.58c6.39-144.17,17.44-288.35,22.09-432.52 c-32.56,24.42-61.62,53.48-92.43,79.64C1565.58,710.99,1531.86,735.99,1503.37,766.8z"/> <path class="st11" d="M707.51,1111.53c77.9-155.8,158.71-309.86,235.44-466.24c-172.08,41.86-344.74,82.55-516.23,126.73 c79.64,98.83,161.03,196.49,240.68,294.74C680.19,1082.47,691.81,1098.74,707.51,1111.53z"/> <path class="st12" d="M760.41,1033.05c-12.21,24.42-26.16,48.25-35.46,74.41c8.72-3.49,16.86-6.4,25-9.88 c201.15-94.76,402.29-190.1,603.44-286.02c25-12.21,50.58-22.09,74.41-37.21c-27.32-9.88-55.81-16.86-83.71-24.42 c-127.9-35.46-255.79-71.51-383.69-106.97c-14.53,20.93-23.84,44.18-35.46,66.27C870.29,817.37,815.64,925.5,760.41,1033.05z"/> <path class="st13" d="M692.98,1117.35c-91.85-113.36-184.29-226.72-277.88-338.92c-66.85,79.64-130.8,161.61-196.49,242.42 c-23.25,30.81-50.58,59.88-72.09,92.43C328.47,1113.86,511.02,1117.93,692.98,1117.35z"/> <path class="st14" d="M1547.55,1087.7c37.21-11.63,75.57-20.93,112.2-35.46c-30.23-57.55-66.85-111.62-99.41-168.59 c-21.51-33.14-38.95-68.6-62.78-99.41c-17.44,111.62-39.53,222.66-55.81,334.27C1477.79,1111.53,1512.09,1098.16,1547.55,1087.7z" /> <path class="st15" d="M1428.96,1122c16.86-111.04,39.53-220.91,54.07-331.95c-24.42,12.21-44.18,33.72-51.16,59.88 c-23.84,83.71-51.16,166.27-74.99,249.98C1379.55,1111.53,1403.96,1117.35,1428.96,1122z"/> <path class="st16" d="M952.26,1265.01c15.11-9.88,26.16-23.84,38.95-36.62c93.02-92.43,182.54-188.94,276.14-281.37 c46.51-48.83,97.08-93.6,140.69-144.17c-33.14,8.14-62.2,26.16-93.02,40.69c-197.66,93.6-395.31,186.03-592.39,280.79 c62.79,43.6,129.06,83.13,193.59,123.83C927.84,1253.96,938.89,1264.43,952.26,1265.01z"/> <path class="st17" d="M1369.08,862.72c-85.46,84.88-169.75,171.5-254.05,257.54c-43.6,46.51-91.27,88.36-132.55,137.2 c54.07-13.37,105.81-35.46,158.71-52.9c62.79-22.67,126.73-43.02,189.52-66.85c14.53-37.21,24.42-76.16,36.04-113.94 c22.09-73.83,47.09-146.5,64.53-221.49C1408.61,820.28,1389.43,842.37,1369.08,862.72z"/> <path class="st18" d="M1438.84,1134.79c-3.49,42.44-5.81,84.88-7.56,127.31c-2.33,16.28,9.3,28.49,18.02,40.69 c56.97-63.37,111.04-129.06,167.43-192.43c9.88-11.05,19.18-23.25,27.32-36.62c-36.04,6.4-69.76,19.77-104.06,29.65 C1506.28,1114.44,1471.98,1122.58,1438.84,1134.79z"/> <path class="st19" d="M1333.62,1152.23c-30.81,20.35-65.69,35.46-95.34,58.13c51.74,8.72,104.64,6.4,156.96,12.79 c7.56,11.05,15.7,22.09,23.84,33.14c1.16-40.69,6.39-80.81,6.39-121.5c-23.84-8.14-48.25-15.11-73.25-18.02 C1347.57,1128.97,1345.83,1144.67,1333.62,1152.23z"/> <path class="st6" d="M403.47,1359.77c62.2-47.09,121.5-97.67,182.54-145.92c33.72-27.9,69.76-53.48,101.74-83.71 c-93.6-1.74-186.61-1.16-279.63-2.33c-84.3-0.58-169.17-4.07-253.47-0.58c7.56,9.3,15.7,18.02,24.42,26.16 C254.06,1221.99,327.89,1291.75,403.47,1359.77z"/> <path class="st20" d="M688.91,1147c-85.46,70.34-173.82,137.2-258.12,208.7c22.67-1.74,44.76-5.23,67.44-8.72 c144.17-25.58,288.93-47.67,433.1-74.41c-60.46-40.69-123.25-76.74-184.87-116.27c-11.63-7.56-23.25-15.7-36.62-20.93 C701.12,1134.79,695.3,1142.93,688.91,1147z"/> <path class="st21" d="M391.26,1370.23c-8.72-13.95-20.93-24.42-33.14-34.88c-66.85-61.04-132.55-123.24-199.98-183.12 c12.21,37.21,33.14,70.92,49.41,106.39c29.65,60.46,56.97,122.66,89.53,181.38C330.22,1418.48,360.45,1394.07,391.26,1370.23z"/> <path class="st22" d="M1267.93,1175.48c-98.25,28.49-193.59,66.27-290.67,97.67c-27.32,8.72-45.35,31.97-66.27,50 c-22.67,19.77-44.18,41.28-65.69,62.2c-31.39,30.81-68.02,57.55-94.76,93.02c13.37-5.81,26.74-12.79,38.95-20.35 C948.77,1363.84,1109.8,1271.99,1267.93,1175.48z"/> <path class="st47" d="M1376.06,1233.62c-51.74-4.07-102.9-7.56-154.64-9.3c16.86,38.37,33.72,76.16,52.9,113.36 C1309.2,1303.96,1343.5,1269.66,1376.06,1233.62z"/> <path class="st23" d="M1151.66,1433.02c20.35-65.69,32.56-133.13,47.67-199.98c-37.21,18.02-72.09,40.69-108.13,61.04 c-36.62,22.67-74.99,42.44-109.87,66.85c25.58,15.7,54.65,25,81.97,36.62C1092.36,1409.76,1121.43,1423.72,1151.66,1433.02z"/> <path class="st24" d="M1169.1,1424.88c31.97-25,63.37-50.58,94.76-76.74c-14.53-37.79-31.39-74.99-51.74-110.46 C1197.58,1299.89,1180.73,1362.09,1169.1,1424.88z"/> <path class="st25" d="M1456.28,1338.84c-19.77-34.88-43.6-66.85-65.69-100.57c-33.72,34.3-69.18,67.44-100.57,103.48 C1345.25,1342.33,1401.06,1340.58,1456.28,1338.84z"/> <path class="st26" d="M151.74,1313.84c-23.84,27.9-49.41,53.48-70.92,83.13c26.74-1.74,55.23,1.74,80.23-8.72 c13.95-40.11,30.23-80.81,37.79-122.66C179.65,1277.8,166.86,1296.98,151.74,1313.84z"/> <path class="st27" d="M761.58,1446.97c55.23-53.48,113.36-103.48,166.27-159.29c-90.11,13.37-179.64,30.23-269.16,44.76 c-77.32,13.95-155.8,24.42-233.12,40.69c86.62,48.83,173.24,96.5,261.61,141.85C712.74,1493.48,737.16,1470.22,761.58,1446.97z"/> <path class="st28" d="M175,1390c26.16-1.16,51.74-2.91,77.9-6.39c-12.79-31.97-27.9-63.37-45.93-92.43 C195.93,1323.73,184.88,1356.86,175,1390z"/> <path class="st29" d="M1281.88,1355.7c27.32,75.57,54.65,151.73,81.97,227.31c16.28-27.9,25-59.3,38.37-88.36 c18.02-47.67,40.11-93.02,55.81-141.27C1399.31,1351.05,1340.6,1353.96,1281.88,1355.7z"/> <path class="st30" d="M1346.41,1578.94c-9.3-40.11-26.16-77.9-39.53-116.85c-13.95-33.72-22.67-68.6-37.79-101.74 c-34.88,26.16-68.02,54.07-100.57,82.55c29.07,25.58,61.04,47.67,91.27,72.67C1288.86,1535.92,1315.02,1561.5,1346.41,1578.94z"/> <path class="st31" d="M985.39,1378.37c-9.3-2.91-19.18-10.46-28.49-4.65c-33.14,17.44-63.37,38.95-96.5,56.39 c-26.74,17.44-57.55,29.65-81.39,51.74c48.25,23.84,96.5,47.09,145.92,69.18c15.11-34.3,25-70.92,38.37-106.39 C972.02,1423.14,980.16,1401.04,985.39,1378.37z"/> <path class="st32" d="M558.1,1460.34c-38.95-21.51-77.9-41.86-116.27-63.95c-12.21-6.98-25-15.11-38.95-18.02 c-31.39,20.35-61.04,44.18-88.95,69.18c40.11,11.63,81.97,16.28,122.66,24.42c66.85,11.05,133.13,28.49,200.56,34.3 C613.33,1486.5,584.27,1475.46,558.1,1460.34z"/> <path class="st19" d="M1146.43,1445.23c-50-19.18-98.25-43.02-148.24-60.46c-18.6,55.23-41.28,108.71-56.97,163.94 c41.28-5.81,80.81-19.18,121.5-27.9c19.18-5.23,39.53-7.56,57.55-16.86C1133.06,1485.92,1140.61,1465.57,1146.43,1445.23z"/> <path class="st23" d="M1430.12,1458.6c-2.33,6.4-6.39,14.53-0.58,20.35c15.11,20.93,33.72,38.95,52.9,56.39 c-8.72-41.28-20.35-81.39-30.81-122.08C1443.49,1427.79,1435.94,1442.9,1430.12,1458.6z"/> <path class="st33" d="M1310.37,1569.05c-50.58-37.79-98.83-79.06-151.15-115.11c-24.42,50.58-47.67,101.15-70.34,152.89 c85.46-0.58,171.5-4.07,256.95-8.72C1334.78,1587.66,1322.57,1577.77,1310.37,1569.05z"/> <path class="st34" d="M373.82,1472.55c-19.77-4.07-39.53-7.56-59.3-9.88c-40.69,39.53-77.9,82.55-115.11,125.57 c55.81-24.42,109.29-53.48,163.94-80.81C379.63,1502.78,374.4,1484.76,373.82,1472.55z"/> <path class="st35" d="M387.19,1658c35.46-53.48,68.6-108.71,101.74-163.36c-33.72-7.56-67.44-15.11-102.32-17.44 C386.61,1537.08,386.61,1597.54,387.19,1658z"/> <path class="st36" d="M698.79,1525.45c1.74,9.3,4.07,18.6,6.39,27.32c62.2,2.91,124.99,2.91,187.77,0 c-40.69-26.16-86.62-43.02-130.22-64.53C740.65,1499.29,719.14,1512.66,698.79,1525.45z"/> <path class="st37" d="M1478.96,1553.36c-19.18-22.67-37.79-46.51-61.62-64.53c-8.72,21.51-16.86,43.02-25,64.53 C1420.82,1555.68,1449.89,1555.68,1478.96,1553.36z"/> <path class="st38" d="M502.3,1496.97c-22.09,34.3-42.44,69.18-64.53,103.48c-14.53,23.83-31.39,47.09-42.44,73.25 c109.29-11.05,218-23.84,326.72-34.88c-38.37-38.37-80.81-73.25-119.76-111.04C576.71,1500.45,536.01,1504.52,502.3,1496.97z"/> <path class="st39" d="M373.24,1594.05c1.16-25.58,1.16-51.16,0.58-76.74c-57.55,27.9-115.69,55.23-170.92,87.2 C259.87,1603.93,316.27,1598.12,373.24,1594.05z"/> <path class="st40" d="M611.01,1518.48c19.18,21.51,42.44,38.95,62.79,59.3c12.79,12.21,27.32,23.84,42.44,33.72 c-8.72-27.32-20.35-54.07-31.39-80.23C661,1523.71,636.01,1520.22,611.01,1518.48z"/> <path class="st41" d="M1374.31,1604.52c5.23,19.77,16.28,37.79,27.9,54.65c27.9-28.49,54.07-59.3,76.16-92.43 c-30.23-1.74-60.46-1.74-91.27,0.58C1381.87,1578.94,1373.15,1590.56,1374.31,1604.52z"/> <path class="st42" d="M1415.59,1690.55c61.62,2.33,123.25,1.74,184.87,0.58c-32.56-41.86-69.18-80.81-104.64-120.34 c-30.81,33.14-59.3,68.6-87.2,104.06C1410.36,1680.09,1413.26,1685.32,1415.59,1690.55z"/> <path class="st43" d="M375.56,1608.58c-66.85,0-133.13,7.56-199.4,10.46c15.7,30.23,31.39,60.46,51.16,88.36 c46.51-23.84,92.43-48.83,138.36-74.41C376.72,1629.51,373.82,1617.3,375.56,1608.58z"/> <path class="st36" d="M1240.02,1698.69c34.3-29.65,70.92-56.97,104.64-87.2c-54.07,0-108.71,1.74-163.36,4.65 c-30.81,1.74-62.2,0-93.02,5.23c20.93,49.41,40.11,99.99,64.53,147.66C1183.63,1748.11,1210.37,1721.95,1240.02,1698.69z"/> <path class="st44" d="M1169.68,1773.69c91.27,1.16,183.12,2.33,274.4,0c-25.58-53.48-52.9-106.97-81.97-158.71 C1296.99,1666.72,1233.63,1720.2,1169.68,1773.69z"/> <path class="st45" d="M372.66,1644.63c-40.11,19.77-80.23,40.11-118.01,64.53c47.67,2.33,95.34,1.74,143.01,0.58 c-4.65-5.81-9.3-11.05-13.95-16.86C371.49,1680.09,375.56,1660.91,372.66,1644.63z"/> <path class="st6" d="M780.18,1767.29c-14.53-38.95-30.23-77.32-46.51-115.11c-76.74,37.79-153.48,74.99-228.47,114.53 C597.05,1768.46,688.91,1767.87,780.18,1767.29z"/> <path class="st46" d="M690.07,1656.26c-35.46-1.16-70.92,5.81-106.39,8.72c-62.79,8.14-124.99,12.21-187.19,21.51 c25,28.49,51.74,54.65,80.81,79.06c58.72-27.32,115.11-58.13,173.24-86.04C664.49,1673.11,677.86,1665.56,690.07,1656.26z"/> </g> ';
        string memory image2 = string(abi.encodePacked('<text fill="#ffffff" x="-310" y="2180" class="small">Attack: ',attack,' &#9876;</text> <text fill="#ffffff" x="-310" y="2300" class="small">Defense: ',defense,' &#128737;</text> <text fill="#ffffff" x="-310" y="-255" class="small">Alive: ',_daysAlive,' Days &#9200;</text> '));
        string memory image3 = string(abi.encodePacked('<text fill="#ffffff" x="-310" y="-145" class="small">Level: ',_level,' &#127894;</text> <text fill="#ffffff" x="900" y="-300" class="small"># ',tokenId,'</text> <text fill="#ffffff" x="1840" y="-260" class="small">Revived: ',_revived,' </text> <text fill="#ffffff" x="715" y="2300" class="small">Kills Count: ',kills.toString(),' &#128128;</text> <text fill="#ffffff" x="1840" y="2300" class="small">Team Turtle &#129388;</text> </svg>'));
        string memory result = string(abi.encodePacked(image1, image2, image3));
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