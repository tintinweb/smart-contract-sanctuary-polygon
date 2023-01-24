//TEMPLATE-TO-DO

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./ERC721URIStorage.sol";
import "./ERC721.sol";
import "./Counters.sol";
import {Base64} from "./Base64.sol";
import {StringUtils} from "./StringUtils.sol";

contract Domains is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public tld;

    string svgPartOne =
        '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="url(#a)" d="M0 0h270v270H0z"/><svg version="1.0" xmlns="http://www.w3.org/2000/svg" width="88" height="88" viewBox="0 0 270 270"><g fill="#03CF9E"><path d="m67.069 116.188 60.148-38.107L51.68 160.87 15 23.979l52.069 92.209Z"/><path d="M117.931 114.637 57.783 76.531l75.537 82.788L170 22.429l-52.069 92.208Z"/></g></svg><defs><linearGradient id="a" x1="0" y1="0" x2="270" y2="270" gradientUnits="userSpaceOnUse"><stop stop-color="#00000"/><stop offset="1" stop-color="#303030" stop-opacity=".99"/></linearGradient></defs><text x="32.5" y="231" font-size="27" fill="#03CF9E" filter="url(#b)" font-family="Arial, Helvetica,Apple Color Emoji,sans-serif" font-weight="bold">';
    string svgPartTwo = "</text></svg>";

    mapping(string => address) public domains;
    mapping(string => string) public records;
    mapping(uint256 => string) public names;

    address payable public owner;

    constructor(string memory _tld) payable ERC721("W3 Name Service", "W3NS") {
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
            return 50 * 10**18; // Charge 50 M
        } else if (len == 4) {
            return 30 * 10**18; // Charge 30 M
        } else {
            return 10 * 10**18; // Charge 10 M
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
        require(msg.value >= _price, "Not enough Matic paid");

        string memory _name = string(abi.encodePacked(name, ".", tld));
        string memory finalSvg = string(
            abi.encodePacked(svgPartOne, _name, svgPartTwo)
        );
        uint256 newRecordId = _tokenIds.current();
        uint256 length = StringUtils.strlen(name);
        string memory strLen = Strings.toString(length);
        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name": "',
                _name,
                '", "description": "A domain on the W3 Name Service", "image": "data:image/svg+xml;base64,',
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

        (bool sent, ) = payable(0xbFF3eE7d3648Ce6b7DE82dEa427c3A1629aaf671)
            .call{value: address(this).balance}("");
        require(sent, "Failed to send domain payment to TLD owner");

        names[newRecordId] = name;

        _tokenIds.increment();
    }

    function valid(string calldata name) public pure returns (bool) {
        return StringUtils.strlen(name) >= 3 && StringUtils.strlen(name) <= 10;
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

    function getRecord(string calldata name)
        public
        view
        returns (string memory)
    {
        return records[name];
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function withdraw() public payable onlyOwner {
        (bool xt, ) = payable(0xbFF3eE7d3648Ce6b7DE82dEa427c3A1629aaf671).call{
            value: (address(this).balance * 25) / 100
        }("");
        require(xt); // Withdraw 25% for Founder

        (bool up, ) = payable(0x5422723dfe547bb1b58a55f7480D1828e47c379a).call{
            value: (address(this).balance * 75) / 100
        }("");
        require(up); // Withdraw 75% for W3UP DAO Treasury
    }
}