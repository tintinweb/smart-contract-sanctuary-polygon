/*
🇧​​​​​ 🇮​​​​​ 🇱​​​​​ 🇪​​​​​ 🇹​​​​​ 🇸​​​​​

🇨​​​​​ 🇱​​​​​ 🇺​​​​​ 🇧​​​​​

Go to https://bilets.club to see more.

████████████████████████████Bilets-Club████████████████████████████
████████████████████████████Bilets-Club████████████████████████████
█████████████'''''''''''''''''''''''''''''''''''''''''█████████████
█████████████''.....................................''█████████████
█████████████''...........██████████████............''█████████████
█████████████''...........██....██....██............''█████████████
█████████████''...........██....██....██............''█████████████
█████████████''...........██████████████............''█████████████
█████████████''..............█████████..............''█████████████
█████████████''............█████████████............''█████████████
█████████████''.....██████████████████████████......''█████████████
█████████████''.....██████████████████████████......''█████████████
█████████████''............█████████████............''█████████████
█████████████''............█████████████............''█████████████
█████████████''............█████████████............''█████████████
█████████████''............████.....████............''█████████████
█████████████''............████.....████............''█████████████
█████████████''............████.....████............''█████████████
█████████████''............████.....████............''█████████████
█████████████''............████.....████............''█████████████
█████████████''.....................................''█████████████
█████████████'''''''''''''''''''''''''''''''''''''''''█████████████
████████████████████████████Bilets-Club████████████████████████████
████████████████████████████Bilets-Club████████████████████████████
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/** 
@title Bilets Club Forum Contract
@author Bilets
**/

/** @notice Library for encode or decode Base64. **/
library Base64 {
    string internal constant TABLE_ENCODE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes internal constant TABLE_DECODE =
        hex"0000000000000000000000000000000000000000000000000000000000000000"
        hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
        hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
        hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 4 characters
                dataPtr := add(dataPtr, 4)
                let input := mload(dataPtr)

                // write 3 bytes
                let output := add(
                    add(
                        shl(
                            18,
                            and(
                                mload(add(tablePtr, and(shr(24, input), 0xFF))),
                                0xFF
                            )
                        ),
                        shl(
                            12,
                            and(
                                mload(add(tablePtr, and(shr(16, input), 0xFF))),
                                0xFF
                            )
                        )
                    ),
                    add(
                        shl(
                            6,
                            and(
                                mload(add(tablePtr, and(shr(8, input), 0xFF))),
                                0xFF
                            )
                        ),
                        and(mload(add(tablePtr, and(input, 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

contract BiletsClubForum is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    enum PostKind {
        NEW,
        COMMENT
    }

    mapping(uint256 => Item) public attributes;

    struct NFT {
        string name;
        string material;
        uint8 speed;
        uint8 attack;
        uint8 defence;
    }

    struct Item {
        PostKind kind;
        uint256 id;
        uint256 parentId;
        address author;
        uint256 createdAtBlock;
        uint256[] childIds;
        string msgContent;
    }

    struct VoteCount {
        mapping(bytes32 => int8) votes;
        int256 total;
    }

    Counters.Counter private itemIdCounter;
    mapping(uint256 => VoteCount) private itemVotes;
    mapping(address => int256) private authorScore;
    mapping(uint256 => Item) private items;

    event NewItem(
        uint256 indexed id,
        uint256 indexed parentId,
        address indexed author
    );

    constructor() ERC721("Bilets Forum", "BLT-Forum") {}

    /******************** PUBLIC FUNCTIONS ********************/
    /** @notice Create new post. **/
    function addPost(string memory msgContent) public {
        itemIdCounter.increment();
        uint256 id = itemIdCounter.current();
        address author = msg.sender;

        uint256[] memory childIds;
        items[id] = Item(
            PostKind.NEW,
            id,
            0,
            author,
            block.number,
            childIds,
            msgContent
        );
        _safeMint(msg.sender, id);
        attributes[id] = items[id];
        emit NewItem(id, 0, author);
    }

    /** @notice Get post infos. **/
    function getPost(uint256 itemId) public view returns (Item memory) {
        require(items[itemId].id == itemId, "No item found");
        return items[itemId];
    }

    /** @notice Adds a comment to a post or comment. **/
    function addComment(uint256 parentId, string memory msgContent) public {
        require(items[parentId].id == parentId, "Post does not exist.");

        itemIdCounter.increment();
        uint256 id = itemIdCounter.current();
        address author = msg.sender;

        items[parentId].childIds.push(id);

        uint256[] memory childIds;
        items[id] = Item(
            PostKind.COMMENT,
            id,
            parentId,
            author,
            block.number,
            childIds,
            msgContent
        );
        _safeMint(msg.sender, id);
        attributes[id] = items[id];
        emit NewItem(id, parentId, author);
    }

    /** @notice Adds a voto to a post or comment. **/
    function voteForPost(uint256 itemId, int8 voteValue) public {
        require(items[itemId].id == itemId, "Post does not exist.");
        require(
            voteValue >= -1 && voteValue <= 1,
            "Invalid vote value. Must be -1, 0, or 1."
        );

        bytes32 voterId = _voterId(msg.sender);
        int8 oldVote = itemVotes[itemId].votes[voterId];
        if (oldVote != voteValue) {
            itemVotes[itemId].votes[voterId] = voteValue;
            itemVotes[itemId].total =
                itemVotes[itemId].total -
                oldVote +
                voteValue;

            address author = items[itemId].author;
            if (author != msg.sender) {
                authorScore[author] = authorScore[author] - oldVote + voteValue;
            }
        }
    }

    /** @notice Get post score. **/
    function getPostScore(uint256 itemId) public view returns (int256) {
        return itemVotes[itemId].total;
    }

    /** @notice Get author score. **/
    function getAuthorScore(address author) public view returns (int256) {
        return authorScore[author];
    }

    /** @notice SVG image completely on-chain. **/
    function getSvg() private pure returns (string memory) {
        string memory svg;
        svg = "<svg xmlns='http://www.w3.org/2000/svg' version='1.0' width='300.000000pt' height='75.000000pt' viewBox='0 0 300.000000 75.000000' preserveAspectRatio='xMidYMid meet'><metadata>Join https://bilets.club to see more ;)</metadata><g transform='translate(0.000000,75.000000) scale(0.100000,-0.100000)' fill='#000000' stroke='none'><path d='M1082 732 c-18 -12 -28 -13 -41 -5 -23 15 -73 9 -105 -12 -30 -20 -66 -83 -59 -102 7 -21 -5 -15 -61 27 -56 42 -105 63 -173 74 -33 5 -43 3 -43 -7 0 -9 9 -12 30 -9 62 9 234 -99 260 -163 7 -17 9 -16 17 15 6 20 6 39 2 45 -18 19 -8 55 25 89 39 42 82 48 111 16 l18 -20 14 20 c14 20 40 25 80 14 27 -7 43 -55 43 -130 0 -28 3 -72 6 -98 l7 -46 61 0 c35 0 67 -5 74 -12 15 -15 14 -17 1 76 -17 125 12 161 160 196 63 15 133 15 161 0 21 -11 28 -64 10 -75 -6 -4 -1 -18 12 -36 19 -25 20 -33 10 -50 -11 -17 -10 -23 8 -37 11 -9 23 -34 27 -54 9 -58 -21 -87 -119 -115 -44 -13 -102 -33 -128 -44 -62 -26 -88 -22 -110 18 l-17 31 -27 -28 c-25 -27 -32 -29 -124 -32 -135 -5 -142 0 -143 100 -1 42 -5 106 -9 142 -7 50 -8 36 -5 -60 5 -134 2 -142 -47 -174 -28 -18 -51 -13 -77 18 -10 12 -16 11 -37 -11 -24 -24 -30 -25 -101 -20 -41 3 -100 2 -129 -3 -30 -5 -61 -7 -69 -3 -20 7 -31 51 -16 66 14 14 15 97 0 97 -8 0 -9 19 -4 61 6 50 4 63 -11 80 -22 24 -47 25 -42 2 2 -10 12 -17 22 -16 15 1 17 -5 13 -37 -2 -20 -7 -42 -11 -48 -4 -6 1 -28 9 -49 13 -32 14 -45 4 -80 -10 -36 -9 -46 5 -68 19 -29 7 -28 171 -25 85 1 138 6 155 15 17 9 31 10 41 4 19 -12 63 -11 93 2 19 9 32 9 56 -1 43 -18 211 -15 249 5 28 14 31 14 41 -5 9 -17 8 -20 -8 -20 -10 0 -27 -9 -37 -20 l-18 -20 -22 20 c-28 26 -40 23 -88 -20 -45 -40 -66 -76 -69 -117 -3 -42 21 -93 43 -93 18 0 18 1 -1 20 -46 46 -33 117 31 175 53 48 83 45 87 -8 2 -20 7 -35 12 -32 5 3 16 -2 25 -11 15 -16 16 -14 10 19 -9 45 8 77 40 77 32 0 45 -27 45 -94 0 -55 1 -56 29 -56 27 0 29 3 33 50 6 56 31 92 62 88 18 -3 22 -12 26 -70 6 -85 20 -100 20 -21 0 48 4 64 21 79 15 14 24 16 37 8 19 -12 42 -8 42 7 0 13 -57 11 -82 -2 -14 -8 -23 -8 -31 0 -14 14 -40 14 -71 0 -17 -8 -28 -25 -36 -58 -22 -81 -29 -76 -45 34 l-5 40 122 39 c68 21 134 44 148 52 60 31 79 104 44 169 -9 18 -14 40 -11 49 6 16 9 16 33 -3 15 -12 34 -21 43 -21 39 -1 44 -14 42 -119 -2 -100 -2 -102 28 -131 32 -32 45 -35 85 -20 46 17 61 54 66 169 l5 105 32 12 31 13 0 -45 c0 -79 33 -222 56 -248 20 -21 29 -22 102 -19 101 4 139 17 161 54 10 16 21 29 25 29 4 0 5 7 2 15 -4 8 -2 15 3 15 12 0 13 31 1 46 -5 7 -4 22 2 38 10 27 2 34 -17 15 -7 -7 -8 -22 -1 -45 8 -30 5 -42 -16 -78 -31 -53 -68 -70 -136 -64 -28 3 -53 1 -56 -3 -10 -17 -44 -9 -58 14 -16 25 -46 167 -46 218 0 19 5 40 11 46 9 9 9 20 -1 44 l-13 31 -19 -25 c-11 -16 -33 -29 -54 -33 l-34 -6 0 -110 c0 -120 -14 -164 -57 -174 -67 -17 -88 29 -80 172 l7 104 -39 0 c-42 0 -86 27 -96 60 -8 24 28 87 53 94 9 2 87 6 172 8 l155 3 3 -23 4 -24 23 22 c29 28 80 24 151 -11 42 -20 47 -21 56 -6 14 26 55 21 74 -8 13 -19 15 -37 9 -84 -7 -65 1 -114 15 -90 5 7 5 20 1 27 -5 8 -5 31 0 51 12 50 2 95 -27 122 -22 21 -27 21 -62 10 -30 -10 -44 -11 -61 -1 -32 16 -58 22 -121 25 -30 1 -66 7 -81 12 -16 7 -41 8 -70 2 -24 -4 -88 -8 -141 -9 l-98 0 -40 -36 c-22 -20 -40 -31 -40 -25 0 7 -11 23 -25 36 -20 21 -34 25 -82 25 -67 0 -178 -29 -228 -60 -42 -26 -57 -69 -53 -147 l3 -58 -38 -3 c-21 -2 -44 1 -51 7 -7 6 -14 37 -15 68 -7 142 -12 165 -44 186 -37 23 -70 27 -95 9z'/><path d='M565 710 c-4 -6 -4 -14 -1 -17 3 -3 -1 -11 -9 -17 -8 -6 -16 -24 -19 -41 -2 -16 -1 -23 1 -15 3 8 17 29 31 48 17 23 22 36 15 43 -8 8 -13 7 -18 -1z'/><path d='M968 684 c-34 -18 -27 -44 12 -44 58 0 81 28 41 50 -24 12 -20 12 -53 -6z'/><path d='M1097 693 c-4 -3 -6 -31 -5 -62 l1 -56 7 60 c3 37 6 -8 7 -118 1 -98 4 -181 7 -184 3 -3 34 0 69 6 35 6 87 11 115 11 55 0 58 3 42 46 -10 27 -11 27 -84 21 l-74 -5 -4 99 c-2 59 -9 104 -16 111 -7 7 -12 24 -12 39 0 31 -34 51 -53 32z m57 -121 c3 -26 7 -69 8 -95 3 -69 15 -81 83 -82 37 0 60 -5 62 -12 3 -9 -7 -13 -34 -13 -21 0 -56 -5 -78 -10 -59 -14 -63 -4 -65 135 -2 143 -2 138 9 131 5 -4 12 -27 15 -54z'/><path d='M1960 691 c-58 -4 -96 -9 -85 -13 11 -3 -5 -4 -36 -1 -47 5 -57 3 -63 -12 -4 -12 1 -26 15 -42 18 -18 33 -23 72 -23 l50 0 -7 -113 c-8 -125 1 -167 34 -167 13 0 20 7 20 20 0 11 -7 20 -15 20 -12 0 -15 19 -15 115 l0 115 -32 20 c-18 11 -45 22 -61 26 -18 4 -25 10 -20 15 12 12 243 27 250 16 7 -12 -28 -36 -53 -37 -46 0 -56 -30 -55 -151 1 -62 6 -119 11 -128 6 -11 9 29 10 115 0 141 1 144 54 144 33 0 55 21 62 58 6 27 4 32 -12 30 -11 -1 -66 -4 -124 -7z'/><path d='M1515 659 c-60 -16 -115 -35 -122 -42 -13 -13 -11 -37 15 -231 7 -50 34 -83 50 -60 9 13 45 27 37 15 -3 -6 21 1 52 13 32 13 81 29 110 36 28 6 54 17 56 23 3 7 -1 28 -7 47 -10 30 -16 35 -41 34 -45 -2 -206 -68 -177 -72 13 -2 48 6 77 18 72 29 120 32 120 6 0 -10 -7 -22 -15 -26 -12 -6 -164 -54 -206 -65 -31 -8 -34 5 -50 191 l-5 61 52 17 c63 21 74 15 20 -10 -50 -24 -60 -52 -27 -79 24 -20 24 -20 5 -44 -20 -25 -26 -61 -9 -61 6 0 10 9 10 19 0 11 9 23 21 26 15 5 18 9 9 15 -8 5 5 13 34 23 29 10 44 12 40 5 -5 -8 -1 -9 10 -5 10 4 36 10 58 13 22 4 42 13 45 20 8 21 -16 54 -40 54 -19 0 -120 -33 -169 -54 -14 -6 -18 -3 -18 12 0 16 15 24 83 45 45 15 94 29 110 33 29 7 35 22 15 42 -15 15 -14 16 -143 -19z m125 -100 c0 -4 -17 -11 -37 -14 -21 -4 -46 -9 -55 -12 -33 -9 -18 8 24 27 39 17 68 17 68 -1z'/><path d='M2163 679 c-26 -26 -11 -53 87 -154 116 -119 126 -145 55 -145 -55 0 -70 19 -94 117 -13 56 -20 68 -36 68 -14 0 -21 -8 -23 -27 -3 -24 19 -157 34 -210 6 -22 32 -24 40 -3 5 11 11 12 24 5 10 -6 39 -10 64 -10 74 0 103 45 76 115 -16 43 -130 156 -151 150 -18 -6 -59 36 -59 61 0 25 64 16 111 -16 49 -33 81 -41 58 -14 -35 42 -164 86 -186 63z m102 -330 c-2 -3 -21 -3 -42 -1 -21 3 -33 7 -26 9 9 3 9 12 2 29 -17 46 -9 49 30 9 22 -22 38 -43 36 -46z'/><path d='M590 655 c-11 -13 -9 -20 10 -40 20 -22 22 -31 17 -85 -4 -33 -3 -60 2 -60 16 0 18 -104 2 -116 -8 -7 -12 -18 -8 -28 6 -14 14 -16 39 -10 18 4 75 7 127 6 142 -1 160 16 89 85 -50 47 -90 71 -96 55 -2 -7 -12 -6 -33 1 -21 8 -34 9 -47 1 -21 -14 -25 -73 -5 -95 12 -14 12 -17 -2 -23 -29 -11 -31 -7 -32 52 -1 31 -5 78 -9 105 -6 50 3 60 24 27 13 -21 60 -26 97 -10 18 8 18 9 -5 10 -14 1 -37 1 -51 0 -23 -1 -27 3 -32 36 -4 21 -5 40 -3 42 5 4 70 -30 105 -55 23 -17 24 -17 16 7 l-7 24 29 -25 c40 -33 41 -59 2 -59 -16 0 -29 -5 -29 -11 0 -6 17 -9 42 -7 62 4 62 28 -1 89 -88 84 -206 126 -241 84z m93 -12 c4 -3 -3 -17 -14 -30 -21 -21 -23 -21 -35 -5 -21 27 -16 42 14 42 16 0 32 -3 35 -7z m114 -236 c70 -41 96 -67 51 -52 -13 4 -51 10 -85 12 -57 4 -63 7 -63 26 0 12 -3 33 -7 46 -8 30 2 27 104 -32z'/><path d='M2372 658 c-17 -17 -15 -38 3 -38 11 0 15 -12 15 -47 0 -25 -3 -43 -7 -39 -5 4 -8 13 -8 19 0 13 -73 57 -95 56 -11 0 -10 -3 4 -12 46 -29 78 -62 91 -93 25 -61 36 -41 33 63 -3 95 -11 116 -36 91z'/><path d='M959 604 c-10 -13 -14 -44 -12 -116 1 -119 7 -144 34 -159 17 -8 25 -7 41 8 16 15 19 25 13 58 -4 22 -10 81 -14 130 -5 81 -8 90 -27 93 -11 2 -27 -5 -35 -14z m15 -81 c-2 -38 -1 -60 2 -50 8 25 22 21 28 -10 14 -62 15 -79 6 -93 -14 -23 -33 2 -34 45 -1 19 -4 35 -8 35 -9 0 -11 102 -2 124 10 27 12 18 8 -51z'/><path d='M165 550 c-4 -11 -10 -18 -15 -15 -14 9 -38 -6 -43 -27 -4 -12 -10 -17 -18 -13 -9 6 -10 1 -7 -19 3 -14 2 -26 -1 -26 -3 0 -5 -20 -3 -45 2 -25 9 -45 15 -45 6 0 8 -3 4 -6 -17 -17 100 -80 133 -71 11 3 21 -1 24 -9 3 -8 1 -14 -4 -14 -6 0 -10 -5 -10 -12 0 -6 3 -9 6 -5 4 3 13 0 21 -8 15 -15 104 -45 135 -45 10 0 18 4 18 9 0 6 9 8 20 6 11 -2 18 0 15 4 -3 5 2 11 10 15 8 3 15 12 15 21 0 8 7 15 15 15 8 0 15 9 15 20 0 11 -6 20 -12 20 -8 0 -9 3 -3 8 17 12 12 82 -7 93 -10 6 -18 17 -18 24 0 8 -5 15 -11 15 -5 0 -7 5 -4 10 3 6 2 10 -4 10 -5 0 -12 -6 -14 -12 -3 -8 -6 -5 -6 6 -1 14 -7 17 -26 14 -14 -3 -22 -1 -19 4 4 5 -4 8 -17 6 -28 -4 -69 28 -69 53 0 13 -6 17 -21 14 -12 -2 -28 3 -37 11 -12 13 -16 13 -23 2 -7 -10 -9 -10 -9 0 0 20 -38 14 -45 -8z m96 -37 c39 -22 49 -33 49 -54 0 -18 -8 -29 -27 -38 -16 -8 -35 -17 -43 -21 -8 -3 -28 -1 -45 6 -16 7 -23 13 -15 14 13 0 13 1 0 10 -17 11 -17 11 28 15 21 1 32 -2 32 -11 0 -8 7 -14 16 -14 25 0 13 42 -17 59 -22 12 -31 12 -58 2 -28 -12 -31 -18 -31 -55 0 -36 4 -44 30 -59 l29 -18 81 46 c87 51 100 52 158 8 31 -23 33 -28 30 -81 -3 -55 -3 -56 -52 -85 l-49 -28 -46 25 c-55 30 -70 49 -55 73 16 25 34 27 34 4 0 -15 11 -27 35 -38 33 -16 38 -16 63 -1 20 12 28 26 30 51 3 29 -2 38 -27 56 -16 12 -32 21 -35 21 -3 0 -40 -20 -82 -45 -41 -25 -79 -45 -84 -45 -4 0 -28 12 -54 26 l-46 26 0 61 0 62 48 27 c26 15 49 27 51 27 1 1 25 -11 52 -26z m128 -173 c24 0 33 -11 21 -25 -13 -16 -60 -7 -60 11 0 8 -6 14 -12 15 -7 0 -4 4 7 8 11 5 22 4 23 0 2 -5 12 -9 21 -9z'/><path d='M2630 550 c0 -11 -7 -20 -15 -20 -8 0 -16 -6 -17 -12 -5 -45 -20 -78 -35 -78 -10 0 -13 -6 -9 -15 3 -9 -1 -18 -9 -21 -14 -6 -22 -44 -9 -44 18 0 128 185 119 200 -10 17 -25 11 -25 -10z'/><path d='M2681 477 l-1 -58 -45 -20 c-54 -24 -72 -45 -29 -35 16 4 36 14 45 22 9 8 19 11 22 7 10 -10 8 -93 -2 -93 -5 0 -30 12 -55 26 -68 38 -68 22 -1 -21 51 -33 60 -36 81 -25 21 12 22 14 8 36 -16 24 -15 70 1 68 6 -1 21 -5 35 -8 17 -5 13 0 -13 14 -34 19 -37 24 -32 53 3 18 1 46 -4 62 -8 27 -9 23 -10 -28z'/><path d='M878 465 c-16 -22 -16 -23 8 -46 l25 -23 -7 44 c-4 25 -7 46 -8 47 -1 0 -9 -9 -18 -22z'/><path d='M2740 470 c0 -11 6 -20 13 -20 7 0 13 9 14 20 1 11 -4 20 -13 20 -8 0 -14 -9 -14 -20z'/><path d='M2240 454 c0 -17 37 -60 45 -53 3 4 -5 20 -19 35 -14 16 -26 24 -26 18z'/><path d='M1213 323 c20 -2 54 -2 75 0 20 2 3 4 -38 4 -41 0 -58 -2 -37 -4z'/><path d='M2553 313 c3 -13 1 -23 -4 -23 -6 0 -4 -6 3 -14 7 -8 15 -12 18 -11 4 2 12 -5 19 -17 8 -13 9 -18 1 -13 -7 5 -7 0 1 -14 8 -12 16 -16 20 -10 3 6 9 1 12 -10 3 -12 0 -21 -6 -21 -6 0 -8 -2 -5 -5 3 -3 15 -2 26 2 21 8 20 10 -19 68 -23 33 -48 67 -56 75 -14 13 -15 13 -10 -7z'/><path d='M2727 243 c-4 -3 -7 -12 -7 -20 0 -17 26 -17 33 1 8 21 -11 35 -26 19z'/><path d='M1777 201 c29 -17 56 -39 62 -48 6 -10 11 -13 11 -6 0 7 -11 23 -25 37 -14 14 -25 22 -25 18 0 -4 -4 -2 -8 5 -4 6 -21 14 -37 18 -24 5 -19 0 22 -24z'/><path d='M1368 183 c-3 -21 -3 -65 0 -98 l4 -61 66 4 c57 4 64 3 59 -12 -5 -11 -1 -16 13 -16 13 0 18 5 14 15 -4 8 -10 15 -14 15 -5 0 -12 9 -15 21 -6 17 -13 20 -46 17 l-38 -3 -6 45 c-11 89 -16 110 -24 110 -5 0 -11 -17 -13 -37z'/><path d='M1222 194 c-27 -19 -52 -65 -52 -97 0 -38 36 -77 71 -77 44 0 66 15 78 53 13 38 6 67 -15 67 -10 0 -14 -13 -14 -40 0 -33 -4 -42 -22 -49 -27 -10 -53 1 -69 30 -13 25 2 67 32 95 18 17 19 16 19 -34 0 -28 5 -54 10 -57 6 -4 10 18 10 59 0 71 -7 79 -48 50z'/><path d='M1516 194 c-3 -9 -6 -37 -6 -64 0 -86 70 -140 116 -89 14 15 20 40 22 96 4 69 3 75 -14 71 -16 -3 -20 -15 -24 -73 -4 -54 -9 -71 -22 -73 -22 -4 -42 58 -35 109 4 33 2 39 -13 39 -10 0 -21 -7 -24 -16z'/><path d='M1680 196 c0 -8 5 -18 11 -22 6 -3 9 -20 6 -38 -2 -17 0 -44 4 -60 5 -18 5 -34 -1 -41 -15 -18 -7 -20 74 -17 88 4 96 15 41 59 l-35 28 31 5 31 5 -22 28 c-39 50 -140 88 -140 53z m81 -33 c37 -22 37 -33 -1 -33 -16 0 -30 4 -30 9 0 5 -3 16 -6 25 -8 20 1 20 37 -1z m44 -107 c19 -14 18 -15 -22 -13 -26 1 -43 6 -43 13 0 7 -3 20 -6 29 -6 16 -5 16 22 2 16 -9 38 -22 49 -31z'/><path d='M1844 105 c-10 -20 -8 -27 8 -42 19 -17 20 -17 13 22 -4 22 -8 41 -9 42 -1 1 -6 -9 -12 -22z'/><path d='M1656 65 c-4 -14 -15 -34 -26 -45 -20 -20 -20 -20 10 -20 26 0 30 4 36 36 8 43 -10 69 -20 29z'/><path d='M1313 35 l-22 -35 27 0 c26 0 28 2 24 35 -2 19 -5 35 -6 35 0 -1 -11 -16 -23 -35z'/></g></svg>";
        return svg;
    }

    /** @notice Token URI completely on-chain. **/
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Post #',
                        uint2str(attributes[tokenId].id),
                        '",',
                        '"image_data": "',
                        getSvg(),
                        '",',
                        '"attributes": [{"trait_type": "Created At Block", "value": ',
                        uint2str(items[tokenId].createdAtBlock),
                        "},",
                        // '{"trait_type": "Attack", "value": ', uint2str(attributes[tokenId].attack), '},',
                        // '{"trait_type": "Defence", "value": ', uint2str(attributes[tokenId].defence), '},',
                        // '{"trait_type": "Material", "value": "', attributes[tokenId].material, '"}',
                        "]}"
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /******************** INTERNAL FUNCTIONS ********************/
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function _voterId(address voter) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(voter));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

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

        _afterTokenTransfer(address(0), to, tokenId);
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

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}