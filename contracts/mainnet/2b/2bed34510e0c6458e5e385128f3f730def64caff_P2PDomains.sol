// SPDX-License-Identifier: UNLICENSED
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

contract P2PDomains is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public tld;

    // E1 -> SVG
    string svgPartOne =
        '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="url(#a)" d="M0 0h270v270H0z"/><svg xmlns="http://www.w3.org/2000/svg" width="100" height="100"><circle cx="50" cy="50" r="40" fill="white" stroke="green" stroke-width="4" filter="url(#soft-border)" />  <text x="50" y="57" font-size="35" font-weight="bold" text-anchor="middle" fill="green">P2P</text><path d="M25,70C40,80,60,80,75,70" stroke="green" stroke-width="4" fill="none" /><circle cx="27" cy="70" r="4" fill="green" /></svg><defs><linearGradient id="a" x1="0" y1="0" x2="270" y2="270" gradientUnits="userSpaceOnUse"><stop stop-color="#7BB038"/><stop offset="1" stop-color="#7BB038" stop-opacity=".99"/></linearGradient></defs><text x="50%" y="180" dominant-baseline="middle" text-anchor="middle" font-size="27" fill="#fff" filter="url(#b)" font-family="Lucida, sans-serif" font-weight="bold">';
    string svgPartTwo =
        '</text><text x="88" y="240" font-size="42" fill="#fff" filter="url(#b)" font-family="Lucida, sans-serif" font-weight="bold">.p2p</text></svg>';

    mapping(string => address) public domains;
    mapping(string => string) public records;
    mapping(uint256 => string) public names;

    address payable public owner;

    // E2 -> NAME
    constructor(
        string memory _tld
    ) payable ERC721("P2P Name Service", "P2PNS") {
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
            return 1 * 10 ** 15; // Charge 1 MATIC
        } else if (len == 4) {
            return 0.5 * 10 ** 15; // Charge 0.5 MATIC
        } else {
            return 0.3 * 10 ** 15; // Charge 0.3 MATIC
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

        (bool sent, ) = payable(0x10DE99f47F3E0D43F8d3EfA1BbF82a8D64dF8671) // SPLITTER
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