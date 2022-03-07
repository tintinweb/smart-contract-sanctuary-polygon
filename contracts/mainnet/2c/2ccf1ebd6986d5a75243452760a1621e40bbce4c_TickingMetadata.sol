/**
 *Submitted for verification at polygonscan.com on 2022-03-07
*/

// File: contracts/DateTime.sol


pragma solidity ^0.8.6;
// source: https://github.com/pipermerriam/ethereum-datetime/blob/master/contracts/DateTime.sol
contract DateTime {
        /*
         *  Date and Time utilities for ethereum contracts
         *
         */
        struct _DateTime {
                uint16 year;
                uint8 month;
                uint8 day;
                uint8 hour;
                uint8 minute;
                uint8 second;
                uint8 weekday;
        }

        uint constant DAY_IN_SECONDS = 86400;
        uint constant YEAR_IN_SECONDS = 31536000;
        uint constant LEAP_YEAR_IN_SECONDS = 31622400;

        uint constant HOUR_IN_SECONDS = 3600;
        uint constant MINUTE_IN_SECONDS = 60;

        uint16 constant ORIGIN_YEAR = 1970;

        function isLeapYear(uint16 year) private pure returns (bool) {
                if (year % 4 != 0) {
                        return false;
                }
                if (year % 100 != 0) {
                        return true;
                }
                if (year % 400 != 0) {
                        return false;
                }
                return true;
        }

        function leapYearsBefore(uint year) private pure returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }

        function getDaysInMonth(uint8 month, uint16 year) private pure returns (uint8) {
                if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                        return 31;
                }
                else if (month == 4 || month == 6 || month == 9 || month == 11) {
                        return 30;
                }
                else if (isLeapYear(year)) {
                        return 29;
                }
                else {
                        return 28;
                }
        }

        function parseTimestamp(uint timestamp) internal pure returns (_DateTime memory dt) {
                uint secondsAccountedFor = 0;
                uint buf;
                uint8 i;

                // Year
                dt.year = getYear(timestamp);
                buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
                secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

                // Month
                uint secondsInMonth;
                for (i = 1; i <= 12; i++) {
                        secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                        if (secondsInMonth + secondsAccountedFor > timestamp) {
                                dt.month = i;
                                break;
                        }
                        secondsAccountedFor += secondsInMonth;
                }

                // Day
                for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                        if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                                dt.day = i;
                                break;
                        }
                        secondsAccountedFor += DAY_IN_SECONDS;
                }

                // Hour
                dt.hour = getHour(timestamp);

                // Minute
                dt.minute = getMinute(timestamp);

                // Second
                dt.second = getSecond(timestamp);

                // Day of week.
                dt.weekday = getWeekday(timestamp);
        }

        function getYear(uint timestamp) private pure returns (uint16) {
                uint secondsAccountedFor = 0;
                uint16 year;
                uint numLeapYears;

                // Year
                year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
                numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
                secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

                while (secondsAccountedFor > timestamp) {
                        if (isLeapYear(uint16(year - 1))) {
                                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                secondsAccountedFor -= YEAR_IN_SECONDS;
                        }
                        year -= 1;
                }
                return year;
        }

        function getMonth(uint timestamp) private pure returns (uint8) {
                return parseTimestamp(timestamp).month;
        }

        function getDay(uint timestamp) private pure returns (uint8) {
                return parseTimestamp(timestamp).day;
        }

        function getHour(uint timestamp) private pure returns (uint8) {
                return uint8((timestamp / 60 / 60) % 24);
        }

        function getMinute(uint timestamp) private pure returns (uint8) {
                return uint8((timestamp / 60) % 60);
        }

        function getSecond(uint timestamp) private pure returns (uint8) {
                return uint8(timestamp % 60);
        }

        function getWeekday(uint timestamp) private pure returns (uint8) {
                return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day) private pure returns (uint timestamp) {
                return toTimestamp(year, month, day, 0, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) private pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) private pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, minute, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) private pure returns (uint timestamp) {
                uint16 i;

                // Year
                for (i = ORIGIN_YEAR; i < year; i++) {
                        if (isLeapYear(i)) {
                                timestamp += LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                timestamp += YEAR_IN_SECONDS;
                        }
                }

                // Month
                uint8[12] memory monthDayCounts;
                monthDayCounts[0] = 31;
                if (isLeapYear(year)) {
                        monthDayCounts[1] = 29;
                }
                else {
                        monthDayCounts[1] = 28;
                }
                monthDayCounts[2] = 31;
                monthDayCounts[3] = 30;
                monthDayCounts[4] = 31;
                monthDayCounts[5] = 30;
                monthDayCounts[6] = 31;
                monthDayCounts[7] = 31;
                monthDayCounts[8] = 30;
                monthDayCounts[9] = 31;
                monthDayCounts[10] = 30;
                monthDayCounts[11] = 31;

                for (i = 1; i < month; i++) {
                        timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
                }

                // Day
                timestamp += DAY_IN_SECONDS * (day - 1);

                // Hour
                timestamp += HOUR_IN_SECONDS * (hour);

                // Minute
                timestamp += MINUTE_IN_SECONDS * (minute);

                // Second
                timestamp += second;

                return timestamp;
        }
}
// File: contracts/Base64.sol



pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

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
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
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
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}
// File: contracts/Strings.sol

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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

}
// File: contracts/TickingMetadata.sol


pragma solidity ^0.8.6;

/*

          _______
         /       \   
        |    |    |
        |    |    |
        |     \   |
        |    sw   |
         \___ ___/
         

*/




interface ITickingMetadata {    
    function tokenMetadata(
        uint256 tokenId,
        uint256 block_time,
        string memory _color1,
        string memory  _color2,
        string memory _color3) external view returns (string memory);
}


contract TickingMetadata is ITickingMetadata, DateTime {
    
    struct ERC721MetadataStructure {
        string name;
        string description;
        string createdBy;
        string image;
    }

    
        
    using Base64 for string;
    using Strings for uint256;    
    
    address public owner;  

    string private _name;
    string[] private _clockParts;


    string constant private COLOR_TAG_1 = '<COLOR_TAG_1>';
    string constant private COLOR_TAG_2 = '<COLOR_TAG_2>';
    string constant private COLOR_TAG_3 = '<COLOR_TAG_3>';
    string constant private DAY = '<DAY>';
    string constant private HOUR = '<HOUR>';
    string constant private MIN = '<MIN>';  
    string constant private SECOND = '<SECOND>';
    string constant private SECOND_SHADOW = '<SECOND_SHADOW>';   
  
    constructor() {
        owner = msg.sender;
        _name = "ticking";
        // Deploy with default SVG clock parts 
        _clockParts.push("<svg version='1.1' class='frozen-clock' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' x='0px' y='0px' width='512px' height='512px'>");
            _clockParts.push("<rect width='512' height='512' fill='");
            _clockParts.push(COLOR_TAG_1);
            _clockParts.push("'/>");
            _clockParts.push("<circle class='background' r='160' pathLength='60'  stroke='");
            _clockParts.push(COLOR_TAG_2);
            _clockParts.push("' stroke-width='3' cx='256' cy='256' fill-opacity='0.2'  fill='none'/>");
            _clockParts.push("<circle class='hour_marker' r='140' pathLength='60' fill='none' stroke='");
            _clockParts.push(COLOR_TAG_2);
            _clockParts.push("' stroke-width='40'  stroke-dasharray= '0.2, 4.8' stroke-dashoffset= '0.1' cx='256' cy='256'/>");
            _clockParts.push("<circle class='min_marker' r='150' pathLength='300' fill='none' stroke='");
            _clockParts.push(COLOR_TAG_2);
            _clockParts.push("' stroke-width='10'  stroke-dasharray= '0.2, 4.8' stroke-dashoffset= '0.1' cx='256' cy='256'/>");
            _clockParts.push("<defs>");
                _clockParts.push("<polygon id='p1' points='252.5,156 252.5,256 252.5,286 259.5,286 259.5,256 259.5,156' fill = '");
                _clockParts.push(COLOR_TAG_2);
                _clockParts.push("'/>");
                _clockParts.push("<polygon id='p2' points='253.5,141 253.5,256 253.5,301 258.5,301 258.5,256 258.5,141' fill = '");
                _clockParts.push(COLOR_TAG_2);
                _clockParts.push("'/>");
                _clockParts.push("<polygon id='p3' points='258,271 257,271 257,256 257,126 255,126 255,256 255,271 254,271 252,321 260,321'  fill = '");
                _clockParts.push(COLOR_TAG_3);
                _clockParts.push("'/>");
            _clockParts.push("</defs>");
            _clockParts.push("<rect width='30' height='25' fill='none' stroke='");
            _clockParts.push(COLOR_TAG_2);
            _clockParts.push("'  fill-opacity='0.7' x='314' y='245' />");
            _clockParts.push("<text id='text' x='242' y='340' fill='");
            _clockParts.push(COLOR_TAG_2);
            _clockParts.push("' font-family='Raleway' font-weight='bold'>SW</text>");
            _clockParts.push("<text id='text' x='321' y='262'  fill='");
            _clockParts.push(COLOR_TAG_2);
            _clockParts.push("' font-weight='bold' >");
            _clockParts.push(DAY);
            _clockParts.push("</text> ");
            _clockParts.push("<g id='Hour'>");
                _clockParts.push("<use xlink:href='#p1'>");
                    _clockParts.push("<animateTransform attributeName='transform' type='rotate' dur='43200s' values='");
                    _clockParts.push(HOUR);
                    _clockParts.push(", 256, 256; 360, 256, 256' repeatCount='indefinite' />");
                _clockParts.push("</use>");
            _clockParts.push("</g>");
            _clockParts.push("<g id='Minute'>");
                _clockParts.push("<use xlink:href='#p2'>");
                    _clockParts.push("<animateTransform attributeName='transform' type='rotate' dur='36000s' values='");
                    _clockParts.push(MIN);
                    _clockParts.push(", 256, 256; 360, 256, 256' repeatCount='indefinite' />");
                _clockParts.push("</use>");
            _clockParts.push("</g>");
            _clockParts.push("<g id='Second'>");
                _clockParts.push("<use xlink:href='#p3'>");
                    _clockParts.push("<animateTransform attributeName='transform' type='rotate' dur='0.6s' values='");
                    _clockParts.push(SECOND);
                    _clockParts.push(", 256, 256;");
                    _clockParts.push(SECOND_SHADOW);
                    _clockParts.push(", 256, 256' repeatCount='indefinite' />");
                _clockParts.push("</use>");
            _clockParts.push("</g>");
            _clockParts.push("<circle fill='");
            _clockParts.push(COLOR_TAG_2);
            _clockParts.push("' stroke='");
            _clockParts.push(COLOR_TAG_3);
            _clockParts.push("' stroke-width='3' cx='256' cy='256' r='7.5' />");
        _clockParts.push("</svg>");
    }        
    
    function setName(string calldata name_) external { 
        _requireOnlyOwner();       
        _name = name_;
    }


    function tokenMetadata(uint256 tokenId, uint256 block_time, string memory _color1, string memory _color2, string memory _color3) external view override returns (string memory) {        
        string memory base64Json = Base64.encode(bytes(string(abi.encodePacked(_getJson(tokenId, block_time, _color1, _color2, _color3)))));
        return string(abi.encodePacked('data:application/json;base64,', base64Json));
    }

    function updateClockParts(string[] memory clockParts_) public {
        _requireOnlyOwner();
        _clockParts = clockParts_;
    }

    function name() public view returns (string memory) {
        return _name;
    }


    function _getJson(uint256 tokenId, uint256 block_time, string memory _color1, string memory _color2, string memory _color3) public view returns (string memory) {        
        string memory imageData = _getSvg(block_time, _color1, _color2, _color3);

        ERC721MetadataStructure memory metadata = ERC721MetadataStructure({
            name: string(abi.encodePacked(name(),"#", tokenId.toString())),
            description: "Ticking of The World Computer",
            createdBy: "SoldierWork",
            image: imageData
        });

        return _generateERC721Metadata(metadata);
    }        
     

    function _getSvg(uint256 block_time, string memory _color1, string memory _color2, string memory _color3) private view returns (string memory) {
        bytes memory byteString;

        for (uint i = 0; i < _clockParts.length; i++) {
          if (_checkTag(_clockParts[i], COLOR_TAG_1)) {
            byteString = abi.encodePacked(byteString, _color1);
          } else if (_checkTag(_clockParts[i], COLOR_TAG_2)) {
            byteString = abi.encodePacked(byteString, _color2);
          } else if (_checkTag(_clockParts[i], COLOR_TAG_3)) {
            byteString = abi.encodePacked(byteString, _color3);
          } else if (_checkTag(_clockParts[i], DAY)) {
            byteString = abi.encodePacked(byteString, _getDay(block_time));
          } else if (_checkTag(_clockParts[i], HOUR)) {
            byteString = abi.encodePacked(byteString, _getHour(block_time));
          } else if (_checkTag(_clockParts[i], MIN)) {
            byteString = abi.encodePacked(byteString, _getMin(block_time));
          } else if (_checkTag(_clockParts[i], SECOND)) {
            byteString = abi.encodePacked(byteString, _getSec(block_time, false));
          } else if (_checkTag(_clockParts[i], SECOND_SHADOW)) {
            byteString = abi.encodePacked(byteString, _getSec(block_time, true));
          } else {
            byteString = abi.encodePacked(byteString, _clockParts[i]);
          }
        }
        return string(byteString); 
    }

    function _getDay(uint256 block_time) private pure returns (string memory){
        uint256 _day1 = uint256(parseTimestamp(block_time).day);
        if (_day1 < 10){
            string memory _day1_s = string(abi.encodePacked("0", _day1.toString()));
            return _day1_s;
        }
        else{
           return _day1.toString(); 
        }
        
    }

    function _getHour(uint256 block_time) private pure returns (string memory){
        uint256 _hour1 = uint256(parseTimestamp(block_time).hour);
        uint256 _min1 = uint256(parseTimestamp(block_time).minute);
        
        return (_min1/2+_hour1*30).toString(); 
        
        
        
    }

    function _getMin(uint256 block_time) private pure returns (string memory){
        uint256 _min1 = uint256(parseTimestamp(block_time).minute);

        return (_min1*6).toString();
        
    }

    function _getSec(uint256 block_time, bool _shadow) private pure returns (string memory){
        uint256 _sec1 = uint256(parseTimestamp(block_time).second);
        if (_shadow){
        return (_sec1*6+4).toString();  
        }
        else {
        return (_sec1*6).toString();
        }
    }
         

    function _generateERC721Metadata(ERC721MetadataStructure memory metadata) private pure returns (string memory) {
      bytes memory byteString;    
    
        byteString = abi.encodePacked(
          byteString,
          _openJsonObject());
    
        byteString = abi.encodePacked(
          byteString,
          _pushJsonPrimitiveStringAttribute("name", metadata.name, true));
    
        byteString = abi.encodePacked(
          byteString,
          _pushJsonPrimitiveStringAttribute("description", metadata.description, true));
    
        byteString = abi.encodePacked(
          byteString,
          _pushJsonPrimitiveStringAttribute("created_by", metadata.createdBy, true));
    

        byteString = abi.encodePacked(
            byteString,
                _pushJsonPrimitiveStringAttribute("image_data", metadata.image, false));
    
        byteString = abi.encodePacked(
          byteString,
          _closeJsonObject());
    
        return string(byteString);
    }

     function _requireOnlyOwner() private view {
        require(msg.sender == owner, "You are not the owner");
    }


    function _checkTag(string storage a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
   
    function _openJsonObject() private pure returns (string memory) {        
        return string(abi.encodePacked("{"));
    }

    function _closeJsonObject() private pure returns (string memory) {
        return string(abi.encodePacked("}"));
    }

    function _openJsonArray() private pure returns (string memory) {        
        return string(abi.encodePacked("["));
    }

    function _closeJsonArray() private pure returns (string memory) {        
        return string(abi.encodePacked("]"));
    }

    function _pushJsonPrimitiveStringAttribute(string memory key, string memory value, bool insertComma) private pure returns (string memory) {
        return string(abi.encodePacked('"', key, '": "', value, '"', insertComma ? ',' : ''));
    }

    function _pushJsonArrayElement(string memory value, bool insertComma) private pure returns (string memory) {
        return string(abi.encodePacked(value, insertComma ? ',' : ''));
    }

}