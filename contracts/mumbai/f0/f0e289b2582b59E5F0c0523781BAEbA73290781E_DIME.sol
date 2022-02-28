/**
 *Submitted for verification at polygonscan.com on 2022-02-28
*/

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: contracts/DIME.sol

/*
                                                    ,----,                                                                                 ,---,
       ,--.                      ,-.----.         ,/   .`|  ,----..                                                      ,--.           ,`--.' |
   ,--/  /|,-.----.              \    /  \      ,`   .'  : /   /   \            .--.--.                  ,----..     ,--/  /| .--.--.   |   :  :
,---,': / '\    /  \        ,---,|   :    \   ;    ;     //   .     :          /  /    '.          ,--, /   /   \ ,---,': / '/  /    '. '   '  ;
:   : '/ / ;   :    \      /_ ./||   |  .\ :.'___,/    ,'.   /   ;.  \        |  :  /`. /        ,'_ /||   :     ::   : '/ /|  :  /`. / |   |  |
|   '   ,  |   | .\ :,---, |  ' :.   :  |: ||    :     |.   ;   /  ` ;        ;  |  |--`    .--. |  | :.   |  ;. /|   '   , ;  |  |--`  '   :  ;
'   |  /   .   : |: /___/ \.  : ||   |   \ :;    |.';  ;;   |  ; \ ; |        |  :  ;_    ,'_ /| :  . |.   ; /--` '   |  /  |  :  ;_    |   |  '
|   ;  ;   |   |  \ :.  \  \ ,' '|   : .   /`----'  |  ||   :  | ; | '         \  \    `. |  ' | |  . .;   | ;    |   ;  ;   \  \    `. '   :  |
:   '   \  |   : .  / \  ;  `  ,';   | |`-'     '   :  ;.   |  ' ' ' :          `----.   \|  | ' |  | ||   : |    :   '   \   `----.   \;   |  ;
|   |    ' ;   | |  \  \  \    ' |   | ;        |   |  ''   ;  \; /  |          __ \  \  |:  | | :  ' ;.   | '___ |   |    '  __ \  \  |`---'. |
'   : |.  \|   | ;\  \  '  \   | :   ' |        '   :  | \   \  ',  /          /  /`--'  /|  ; ' |  | ''   ; : .'|'   : |.  \/  /`--'  / `--..`;
|   | '_\.':   ' | \.'   \  ;  ; :   : :        ;   |.'   ;   :    /          '--'.     / :  | : ;  ; |'   | '/  :|   | '_\.'--'.     / .--,_
'   : |    :   : :-'      :  \  \|   | :        '---'      \   \ .'             `--'---'  '  :  `--'   \   :    / '   : |     `--'---'  |    |`.
;   |,'    |   |.'         \  ' ;`---'.|                    `---`                         :  ,      .-./\   \ .'  ;   |,'               `-- -`, ;
'---'      `---'            `--`   `---`                                                   `--`----'     `---`    '---'                   '---`"

            ╦╔═╦═╗╦ ╦╔═╗╔╦╗╔═╗╔═╗╦ ╦╔═╗╦╔═╔═╗ ╔═╗╔═╗╔╦╗
            ╠╩╗╠╦╝╚╦╝╠═╝ ║ ║ ║╚═╗║ ║║  ╠╩╗╚═╗ ║  ║ ║║║║
            ╩ ╩╩╚═ ╩ ╩   ╩ ╚═╝╚═╝╚═╝╚═╝╩ ╩╚═╝o╚═╝╚═╝╩ ╩
            v0.3
            @author Krypto Sucks!
            @title DIME

    */

//>>>> Lambda <<<<<
//let msgLimit = 1000000
//If (msgCounter >= msgLimit){
// Create a new contract
// update current contract with new contract address.
// disable current contract from being updated to
//}



//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;


contract DIME {

    // contract admin
    address public admin;

    // Total messages posted
    uint256 public msgCounter;

    // Total allowed tagged accounts
    uint256 public maxTaggedAccounts;

    // Total allowed hashtags
    uint256 public maxHashtags;

    // Item limit returned by mappings
    uint256 public itemLimit;

    // Max length of messages to save (UTF-8 single byte characters only)
    uint256 public maxMessageLength;

    // Cost to post a message
    uint256 public costToPost;

    // Previous contract in chain
    address public prevContract;

    // Next contract in chain
    address public nextContract;

    // Record the first message ID
    uint256 public firstMsgID;

    // Record the last message ID
    uint256 public lastMsgID;

    // The max number of messages that can be returned at once
    uint256 public maxMsgReturnCount;

    // Number of initial free messages
    uint256 public freeMsgCount;

    // Max number of items to store in a bucket in a mapping
    uint256 public maxItemsPerBucket;


    // The Message data struct
    struct MsgData {
        address poster;
        string message;
        uint256 time;
        uint256 tip;
        uint256 paid;
        string posterBucketKey;
    }

    // Map the message ID => Message
    mapping (uint256 => MsgData) public msgMap;

    // Map the poster address to a list of message IDs they own
    // Address is a string for address "buckets" 0x123, 0x123-1, 0x123-2 ...
    mapping (string => uint256[]) public posterMap;

    // Map the tagged address to a list of message IDs they are tagged in
    // Address is a string for address "buckets" 0x123, 0x123-1, 0x123-2 ...
    mapping (string => uint256[]) public taggedMap;

    // Map the hashtags to a list of message IDs they are tagged in
    mapping (string => uint256[]) public hashtagsMap;

    // Set the game availability
    bool gameIsPaused = false;

    constructor() {
        //    constructor(uint256 _costToPost, uint256 _msgCounter, uint256 _maxMessageLength, address _prevContract, uint256 _firstMsgID, uint256 _itemLimit, uint256 _maxMsgReturnCount, uint256 _freeMsgCount, uint256 _maxItemsPerBucket) {
        admin = msg.sender;
        costToPost = 1;
        msgCounter = 0;
        maxMessageLength = 3;
        prevContract = 0x0000000000000000000000000000000000000000;
        firstMsgID = 0;
        itemLimit = 10;
        maxMsgReturnCount = 10;
        freeMsgCount = 100;
        maxItemsPerBucket = 3;
    }

    modifier onlyOwner() {
        require(admin == msg.sender, "You are not the poster");
        _;
    }

    function postMsg(string memory message) public payable{

        // Make sure the game is not paused
        require(gameIsPaused == false , "Game is paused.");

        // Calculate the total cost to post
        uint256 totalCostToPost = costToPost;

        // require the minimal amount being transferred to the contract
        require((msg.value >= totalCostToPost), "Not enough funds sent");

        // Clean the message
        // message = substring(message, 0, maxMessageLength);

        // Get the key for posterMap
        string memory addressStr = addressToString(msg.sender);
        uint256 posterBucketKeyID = getBucketKey(addressStr, "poster", true);
        string memory posterBucketKey = append(addressStr,'-',Strings.toString(posterBucketKeyID),'','');

        // Build the message struct
        uint256 totalTips = (msg.value - costToPost);
        MsgData memory msgData = MsgData(msg.sender, message, block.timestamp, totalTips, msg.value, posterBucketKey);

        // Add the message to the mapping
        msgMap[msgCounter] = msgData;



        // Update the poster Mapping with this message ID
        uint256[] storage posterMsgList = posterMap[posterBucketKey];
        posterMsgList.push(msgCounter);
        posterMap[posterBucketKey] = posterMsgList;


        // Increment the amount of messages we have posted
        msgCounter++;
    }


    function getMsgsByAddress(address poster) public view returns (string memory) {
        return getMsgsByType(addressToString(poster), "poster");
    }

    function getMsgsByType(string memory mapKey, string memory mapType) public view returns (string memory) {
        // Initialize the string as empty;
        string memory msgIDs = "";

        // If they want Messages by Poster
        if (keccak256(abi.encodePacked(mapType)) == keccak256(abi.encodePacked("poster"))){

            // Get the bucket key to read from
            uint256 bucketKeyID = getBucketKey(mapKey, mapType, false);
            string memory bucketKey = append(mapKey,'-',Strings.toString(bucketKeyID),'','');

            for (uint i=posterMap[bucketKey].length; i > 0; i--) {
                if ((i) == posterMap[bucketKey].length){
                    msgIDs = Strings.toString(posterMap[bucketKey][i - 1]);
                } else {
                    msgIDs = append(msgIDs, ',', Strings.toString(posterMap[bucketKey][i - 1]), '', '');
                }
            }
        }

        return msgIDs;
    }

    function testme(string calldata thisBucketKey) public view returns (uint256[] memory){
        return posterMap[thisBucketKey];
    }

    function getPosterBucketKey(address poster) public view returns (uint256 ){
        return getBucketKey(addressToString(poster), "poster", false);
    }

    function getTaggedBucketKey(string calldata tagged) public view returns (uint256 ){
        return getBucketKey(tagged, "tag", false);
    }

    function getHashtagBucketKey(string calldata hashtag) public view returns (uint256 ){
        return getBucketKey(hashtag, "hashtag", false);
    }


    function getBucketKey(string memory mapKey, string memory mapType, bool toInsert) private view returns (uint256){
        //string memory mappingKey = "";
        // string memory prevBucket;
        uint b = 0;
        uint mapID = 99999999999999999999;

        if (keccak256(abi.encodePacked(mapType)) == keccak256(abi.encodePacked("poster"))){
            while (mapID == 99999999999999999999){
                // Get the bucket key to check
                string memory bucketToCheck = append(mapKey,'-',Strings.toString(b),'','');
                if (posterMap[bucketToCheck].length > 0){
                    // exists
                    // prevBucket = bucketToCheck;

                    if (posterMap[bucketToCheck].length >= maxItemsPerBucket && toInsert == true){
                        // We've reached the max items per bucket so return the next key
                        // mappingKey = append(mapKey,'-',Strings.toString(b + 1),'','');
                        mapID = b + 1;
                    }

                    b++;
                } else if (b == 0) {
                    // Doesn't exist at all, so set it to 0
                    // mappingKey = bucketToCheck;
                    mapID = b;
                } else {
                    // It's the previous one
                    // mappingKey = prevBucket;
                    mapID = b - 1;
                }
            }
        } else if (keccak256(abi.encodePacked(mapType)) == keccak256(abi.encodePacked("tag"))){
            while (mapID == 99999999999999999999){
                // Get the bucket key to check
                string memory bucketToCheck = append(mapKey,'-',Strings.toString(b),'','');
                if (taggedMap[bucketToCheck].length > 0){
                    // exists
                    // prevBucket = bucketToCheck;

                    if (taggedMap[bucketToCheck].length >= maxItemsPerBucket && toInsert == true){
                        // We've reached the max items per bucket so return the next key
                        // mappingKey = append(mapKey,'-',Strings.toString(b + 1),'','');
                        mapID = b + 1;
                    }

                    b++;
                } else if (b == 0) {
                    // Doesn't exist at all, so set it to 0
                    // mappingKey = bucketToCheck;
                    mapID = b;
                } else {
                    // It's the previous one
                    // mappingKey = prevBucket;
                    mapID = b - 1;
                }
            }
        } else if (keccak256(abi.encodePacked(mapType)) == keccak256(abi.encodePacked("hashtag"))){
            while (mapID == 99999999999999999999){
                // Get the bucket key to check
                string memory bucketToCheck = append(mapKey,'-',Strings.toString(b),'','');
                if (hashtagsMap[bucketToCheck].length > 0){
                    // exists
                    // prevBucket = bucketToCheck;

                    if (hashtagsMap[bucketToCheck].length >= maxItemsPerBucket && toInsert == true){
                        // We've reached the max items per bucket so return the next key
                        // mappingKey = append(mapKey,'-',Strings.toString(b + 1),'','');
                        mapID = b + 1;
                    }

                    b++;
                } else if (b == 0) {
                    // Doesn't exist at all, so set it to 0
                    // mappingKey = bucketToCheck;
                    mapID = b;
                } else {
                    // It's the previous one
                    // mappingKey = prevBucket;
                    mapID = b - 1;
                }
            }
        }


        //delete prevBucket;
        delete b;
        return mapID;
    }

    function append(string memory a, string memory b, string memory c, string memory d, string memory e) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d, e));
    }


    // THIS RETURNS ADDRESS IN LOWER CASE
    function addressToString(address addr) private pure returns (string memory){
        // Cast Address to byte array
        bytes memory addressBytes = abi.encodePacked(addr);

        // Byte array for the new string
        bytes memory stringBytes = new bytes(42);

        // Assign firs two bytes to '0x'
        stringBytes[0] = '0';
        stringBytes[1] = 'x';

        // Iterate over every byte in the array
        // Each byte contains two hex digits that gets individually converted
        // into their ASCII representation and add to the string
        for (uint256 i = 0; i < 20; i++) {
            // Convert hex to decimal values
            uint8 leftValue = uint8(addressBytes[i]) / 16;
            uint8 rightValue = uint8(addressBytes[i]) - 16 * leftValue;

            // Convert decimals to ASCII Values
            bytes1 leftChar = leftValue < 10 ? bytes1(leftValue + 48) : bytes1(leftValue + 87);
            bytes1 rightChar = rightValue < 10 ? bytes1(rightValue + 48) : bytes1(rightValue + 87);

            // Add ASCII values to the string byte array
            stringBytes[2 * i + 3] = rightChar;
            stringBytes[2 * i + 2] = leftChar;
        }

        // Cast byte array to string and return
        return string(stringBytes);
    }

    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }
}