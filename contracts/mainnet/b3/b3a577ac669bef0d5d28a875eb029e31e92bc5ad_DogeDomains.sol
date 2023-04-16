// SPDX-License-Identifier: MIT
/*
██╗    ██╗██████╗ ██╗   ██╗██████╗     ██████╗  █████╗  ██████╗ 
██║    ██║╚════██╗██║   ██║██╔══██╗    ██╔══██╗██╔══██╗██╔═══██╗
██║ █╗ ██║ █████╔╝██║   ██║██████╔╝    ██║  ██║███████║██║   ██║
██║███╗██║ ╚═══██╗██║   ██║██╔═══╝     ██║  ██║██╔══██║██║   ██║
╚███╔███╔╝██████╔╝╚██████╔╝██║         ██████╔╝██║  ██║╚██████╔╝
 ╚══╝╚══╝ ╚═════╝  ╚═════╝ ╚═╝         ╚═════╝ ╚═╝  ╚═╝ ╚═════╝                                                                                             
*/
pragma solidity ^0.8.10;

import "./ERC721URIStorage.sol";
import "./ERC721.sol";
import "./Counters.sol";
import {Base64} from "./Base64.sol";
import {StringUtils} from "./StringUtils.sol";

contract DogeDomains is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public tld;

    // E1 -> SVG
    string svgPartOne =
        '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="url(#a)" d="M0 0h270v270H0z"/> <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="75px" height="75px" viewBox="0 0 75 75" version="1.1"> <g id="surface1"> <path style=" stroke:none;fill-rule:nonzero;fill:rgb(95.686275%,68.235294%,8.235294%);fill-opacity:1;" d="M 37.5 74.25 C 29.015625 74.25 21.039062 71.046875 15.039062 65.242188 C 9.03125 59.429688 5.722656 51.699219 5.722656 43.46875 C 5.722656 37.695312 7.28125 32.136719 10.230469 27.390625 C 10.605469 26.789062 10.859375 26.113281 11.121094 25.394531 C 11.511719 24.34375 11.925781 23.265625 12.742188 22.378906 C 13.628906 21.425781 14.878906 20.765625 16.101562 20.121094 C 16.859375 19.71875 17.578125 19.34375 18.179688 18.914062 C 19.785156 17.761719 21.523438 16.746094 23.347656 15.90625 C 23.746094 15.433594 23.609375 12.546875 23.519531 10.628906 C 23.332031 6.71875 23.144531 2.683594 24.710938 1.15625 C 24.984375 0.890625 25.328125 0.757812 25.703125 0.757812 C 26.917969 0.757812 28.636719 2.316406 30.800781 5.386719 C 32.378906 7.621094 33.824219 10.175781 34.035156 11.078125 C 34.148438 11.578125 35.09375 12.644531 35.550781 12.773438 C 35.550781 12.773438 35.578125 12.78125 35.671875 12.78125 C 35.804688 12.78125 36 12.765625 36.226562 12.75 C 36.570312 12.726562 37.003906 12.699219 37.515625 12.699219 C 39.308594 12.699219 41.003906 13.132812 42.636719 13.550781 C 44.191406 13.949219 45.660156 14.324219 47.136719 14.324219 C 47.28125 14.324219 47.421875 14.324219 47.566406 14.316406 C 47.78125 14.300781 48.433594 13.996094 48.773438 13.738281 C 49.84375 12.9375 51.464844 11.175781 53.183594 9.308594 C 56.8125 5.371094 59.121094 2.976562 60.652344 2.976562 C 61.09375 2.976562 61.476562 3.171875 61.726562 3.53125 C 62.535156 4.695312 62.863281 5.550781 63.023438 6.921875 C 63.039062 7.074219 63.058594 7.238281 63.082031 7.425781 C 63.367188 9.644531 63.96875 14.25 61.90625 20.378906 C 62.003906 21.171875 62.332031 22.964844 62.886719 23.683594 C 66.78125 28.703125 69.292969 36.480469 69.292969 43.492188 C 69.292969 51.71875 65.984375 59.453125 59.976562 65.265625 C 53.960938 71.046875 45.984375 74.25 37.5 74.25 Z M 25.703125 2.078125 C 25.664062 2.078125 25.65625 2.085938 25.636719 2.101562 C 24.488281 3.210938 24.691406 7.453125 24.839844 10.558594 C 25.027344 14.488281 25.074219 16.566406 23.925781 17.09375 C 22.171875 17.902344 20.488281 18.878906 18.945312 19.988281 C 18.277344 20.46875 17.484375 20.886719 16.710938 21.292969 C 15.59375 21.886719 14.4375 22.492188 13.703125 23.28125 C 13.058594 23.96875 12.710938 24.890625 12.351562 25.859375 C 12.074219 26.601562 11.78125 27.375 11.339844 28.085938 C 8.535156 32.625 7.042969 37.941406 7.042969 43.46875 C 7.042969 59.714844 20.707031 72.921875 37.5 72.921875 C 54.292969 72.921875 67.957031 59.707031 67.957031 43.46875 C 67.957031 36.734375 65.550781 29.28125 61.828125 24.480469 C 60.898438 23.28125 60.59375 20.65625 60.5625 20.363281 L 60.546875 20.210938 L 60.59375 20.070312 C 62.617188 14.160156 62.039062 9.710938 61.761719 7.566406 C 61.738281 7.378906 61.71875 7.207031 61.695312 7.050781 C 61.558594 5.902344 61.3125 5.25 60.636719 4.273438 C 59.574219 4.289062 56.308594 7.828125 54.148438 10.175781 C 52.386719 12.089844 50.722656 13.898438 49.558594 14.773438 C 49.230469 15.023438 48.277344 15.585938 47.625 15.613281 C 47.460938 15.621094 47.296875 15.628906 47.128906 15.628906 C 45.488281 15.628906 43.867188 15.21875 42.300781 14.8125 C 40.738281 14.414062 39.128906 14.003906 37.507812 14.003906 C 37.050781 14.003906 36.636719 14.03125 36.308594 14.054688 C 36.058594 14.070312 35.851562 14.085938 35.664062 14.085938 C 35.460938 14.085938 35.308594 14.070312 35.175781 14.023438 C 34.183594 13.734375 32.949219 12.246094 32.746094 11.347656 C 32.617188 10.785156 31.378906 8.476562 29.722656 6.128906 C 27.449219 2.933594 26.128906 2.078125 25.703125 2.078125 Z M 19.328125 47.339844 C 19.746094 47.199219 21.292969 47.199219 19.15625 44.941406 C 22.058594 48.15625 28.078125 41.0625 20.128906 38.8125 C 17.992188 38.203125 12.050781 38.421875 12.898438 42.269531 C 13.074219 42.667969 14.902344 44.355469 14.953125 44.191406 C 12.585938 43.835938 14.167969 47.316406 16.589844 47.625 C 17.054688 47.691406 18.878906 47.496094 19.328125 47.339844 Z M 19.460938 51.816406 C 15.203125 48.832031 10.921875 52.777344 15.328125 54.40625 C 18.457031 55.558594 18.832031 55.003906 21.667969 55.453125 C 23.566406 55.753906 34.492188 56.339844 34.679688 52.941406 C 34.230469 52.980469 34.628906 53.84375 34.679688 52.941406 C 31.3125 53.25 27.832031 53.960938 26.371094 54.246094 C 25.28125 54.457031 24.148438 53.324219 22.792969 52.859375 Z M 38.65625 29.820312 C 41.617188 29.648438 44.101562 33.425781 44.101562 33.425781 C 44.101562 33.425781 41.617188 37.402344 38.910156 37.320312 C 36.203125 37.238281 36.324219 36.277344 34.425781 35.828125 C 32.535156 35.371094 35.691406 29.984375 38.65625 29.820312 Z M 37.816406 31.710938 C 38.21875 31.183594 39.324219 33.285156 39.480469 31.875 C 39.539062 31.394531 39.367188 31.171875 37.539062 31.199219 C 35.707031 31.230469 34.890625 35.191406 36.046875 35.851562 C 36.9375 36.359375 37.582031 37.230469 37.304688 36.105469 C 37.066406 35.167969 37.222656 32.484375 37.816406 31.710938 Z M 19.613281 26.527344 C 21.871094 26.527344 22.605469 27.996094 22.65625 28.816406 C 22.71875 29.632812 21.246094 32.851562 19.777344 32.851562 C 19.085938 32.851562 17.257812 31.890625 17.070312 30.414062 C 16.867188 28.738281 18.421875 26.527344 19.613281 26.527344 Z M 19.304688 27.515625 C 19.726562 26.910156 17.683594 27.945312 17.828125 29.8125 C 17.96875 31.671875 19.875 32.511719 19.453125 31.941406 C 17.917969 29.851562 19.050781 27.148438 18.636719 27.921875 C 19.050781 28.238281 19.925781 27.5625 18.9375 27.398438 C 18.878906 27.382812 19.265625 27.570312 19.304688 27.515625 Z M 21.691406 28.035156 C 21.464844 28.035156 21.285156 28.230469 21.285156 28.46875 C 21.285156 28.710938 21.464844 28.90625 21.691406 28.90625 C 21.914062 28.90625 22.101562 28.710938 22.101562 28.46875 C 22.09375 28.230469 21.914062 28.035156 21.691406 28.035156 Z M 21.691406 28.035156 "/> </g> </svg> <defs><linearGradient id="a" x1="0" y1="0" x2="270" y2="270" gradientUnits="userSpaceOnUse"><stop stop-color="#000000"/><stop offset="1" stop-color="#000000" stop-opacity=".99"/></linearGradient></defs><text x="50%" y="175" dominant-baseline="middle" text-anchor="middle" font-size="27" fill="#F4AE15" filter="url(#b)" font-family="Lucida, sans-serif" font-weight="bold">';
    string svgPartTwo =
        '</text><text x="62" y="242" font-size="42" fill="#F4AE15" filter="url(#b)" font-family="Lucida, sans-serif" font-weight="bold">.DOGE</text></svg>';

    mapping(string => address) public domains;
    mapping(string => string) public records;
    mapping(uint256 => string) public names;

    address payable public owner;

    // E2 -> NAME
    constructor(
        string memory _tld
    ) payable ERC721("Doge Name Service", "DOGENS") {
        tld = _tld;
        //console.log("%s name service deployed", _tld);
    }

    error Unauthorized();
    error AlreadyRegistered();
    error InvalidName(string name);

    function price(string calldata name) public pure returns (uint256) {
        uint256 len = StringUtils.strlen(name);
        require(len > 0);
        if (len == 3) {
            return 250 * 10 ** 15; // Charge 250 MATIC
        } else if (len == 4) {
            return 100 * 10 ** 15; // Charge 100 MATIC
        } else {
            return 1 * 10 ** 15; // Charge 1 MATIC
        }
    }

    function getAllNames() public view returns (string[] memory) {
        //console.log("Getting all names from contract");
        string[] memory allNames = new string[](_tokenIds.current());
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            allNames[i] = names[i];
            //console.log("Name for token %d is %s", i, allNames[i]);
        }

        return allNames;
    }

    function register(string calldata name) public payable {
        require(domains[name] == address(0));
        if (domains[name] != address(0)) revert AlreadyRegistered();
        if (!valid(name)) revert InvalidName(name);

        uint256 _price = price(name);
        require(msg.value >= _price, "Not enough ETH paid");

        // string memory _name = string(abi.encodePacked(name, ".", tld));
        string memory _name = string(abi.encodePacked(name));
        string memory finalSvg = string(
            abi.encodePacked(svgPartOne, _name, svgPartTwo)
        );
        uint256 newRecordId = _tokenIds.current();
        uint256 length = StringUtils.strlen(name);
        string memory strLen = Strings.toString(length);
        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name": "',
                name,
                ".",
                tld,
                '", "description": "A domain on the W3UP Protocol", "image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(finalSvg)),
                '","length":"',
                strLen,
                '"}'
            )
        );

        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        _safeMint(msg.sender, newRecordId);
        _setTokenURI(newRecordId, finalTokenUri);
        domains[name] = msg.sender;

        (bool sent, ) = payable(0xbFF3eE7d3648Ce6b7DE82dEa427c3A1629aaf671) // SPLITTER
            .call{value: address(this).balance}("");
        require(sent, "Failed to send domain payment to TLD owner");

        names[newRecordId] = name;

        _tokenIds.increment();
    }

    function valid(string calldata name) public pure returns (bool) {
        return StringUtils.strlen(name) >= 3 && StringUtils.strlen(name) <= 15;
    }

    function getAddress(string calldata name) public view returns (address) {
        // Check that the owner is the transaction sender
        return domains[name];
    }

    function setRecord(string calldata name, string calldata record) public {
        // Check that the owner is the transaction sender
        require(domains[name] == msg.sender);
        records[name] = record;
        if (msg.sender != domains[name]) revert Unauthorized();
        records[name] = record;
    }

    function getRecord(
        string calldata name
    ) public view returns (string memory) {
        return records[name];
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }
}