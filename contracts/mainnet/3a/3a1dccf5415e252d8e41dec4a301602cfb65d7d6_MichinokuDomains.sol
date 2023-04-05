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

contract MichinokuDomains is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public tld;

    // E1 -> SVG
    string svgPartOne =
        '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="url(#a)" d="M0 0h270v270H0z"/><svg width="100" height="100"><path d="M47.9 3.7c18.42-.044 32.453 7.69 42.1 23.2 6.885 12.582 7.951 25.649 3.2 39.2C86.917 81.382 75.75 91.016 59.7 95c-17.4 3.089-32.167-1.745-44.3-14.5-9.544-11.304-13.144-24.304-10.8-39C8.002 25.767 16.968 14.467 31.5 7.6a50.043 50.043 0 0 1 16.4-3.9z" fill="#3D483D" fill-opacity=".957"/><path d="M47.5 6.3c15.745-.276 28.379 5.79 37.9 18.2 8.67 12.765 10.404 26.432 5.2 41-5.87 14.27-16.303 23.236-31.3 26.9-16.208 3.058-30.042-1.309-41.5-13.1C6.554 66.015 3.687 51.082 9.2 34.5c5.89-14.156 16.257-23.19 31.1-27.1a65.265 65.265 0 0 1 7.2-1.1z" fill="#FDFDFD"/>  <path d="M68.3 33.3a531.852 531.852 0 0 1-26 5.7 50.579 50.579 0 0 0 2-5.3c-.23-1.118-.897-1.485-2-1.1l-.5.5a26.914 26.914 0 0 1-1.1 2.8c.013-.088-.02-.154-.1-.2-.89.796-1.923 1.163-3.1 1.1a.794.794 0 0 1-.4-.7 6.824 6.824 0 0 0 .2-2l1.8.4a2.083 2.083 0 0 0 1-.3c1.398-1.427 2.164-3.127 2.3-5.1a8.211 8.211 0 0 0-1.2-1.8 19.416 19.416 0 0 0-1.5-3.4c.242-.809.742-1.409 1.5-1.8a2.889 2.889 0 0 1 .5-1.1 8.536 8.536 0 0 0 3.5-2.1c.836-1.721.936-3.455.3-5.2a11.189 11.189 0 0 0 .5-2c.68-.217 1.313-.083 1.9.4a2.215 2.215 0 0 1 .7-.4 7.919 7.919 0 0 1 1.6 1.4 3.596 3.596 0 0 0-.2 1.8 14.859 14.859 0 0 1 1 3.2c.543.564 1.01.497 1.4-.2.174-.885.64-1.552 1.4-2a75.21 75.21 0 0 0 3.1 2 5.942 5.942 0 0 0 1.2-2.7 1.258 1.258 0 0 0-.2-.6 4.74 4.74 0 0 0 .3-2.7c-.428-.564-.995-.83-1.7-.8.035.734-.299 1.234-1 1.5a26.197 26.197 0 0 1-4 .9 6.492 6.492 0 0 1 .1-1.6 84.666 84.666 0 0 0 1.5-4.7 2.057 2.057 0 0 1 1.6-.2 22.18 22.18 0 0 1 2.8 2.2c1.085.245 2.085.078 3-.5l.2.4a17.494 17.494 0 0 0-.8 4.9 120.166 120.166 0 0 1 .9 7.1 13.95 13.95 0 0 0 1.2 2.4 12.126 12.126 0 0 1 2.8 2.4 72.926 72.926 0 0 1 2.2 4.6 11.663 11.663 0 0 0 1.5 2.1.878.878 0 0 0-.2.7z" fill="#E5E5E6"/>  <path d="M69.3 35.9a67.35 67.35 0 0 0-3.9.8c-.427.357-.593.824-.5 1.4a7.335 7.335 0 0 1 3.8 1.4c2.496 3.037 2.663 6.237.5 9.6a7.866 7.866 0 0 1-3.3 2.2c-1.693-.154-2.026-.92-1-2.3 2.279-.72 3.346-2.288 3.2-4.7-.015-2.65-1.315-3.85-3.9-3.6a269.933 269.933 0 0 0-1.8 7 12.849 12.849 0 0 1-1.5 3.3c-2.81 1.446-4.777.68-5.9-2.3-.506-3.953.86-7.053 4.1-9.3a8.318 8.318 0 0 1 3.2-1.1v-.8a1180.744 1180.744 0 0 0-21 4.6 27.832 27.832 0 0 0-1.6 3.9l.2.3a65.226 65.226 0 0 0 5.8-1.5c4.058-.409 5.958 1.425 5.7 5.5-.4 1.6-1.367 2.7-2.9 3.3a469.885 469.885 0 0 0-8.4 1.8c-.486.14-.952.107-1.4-.1-.815-1.425-.415-2.292 1.2-2.6a121.87 121.87 0 0 0 8-1.7c.727-.406 1.06-1.039 1-1.9-.022-1.243-.655-1.843-1.9-1.8a1748.356 1748.356 0 0 1-7.5 1.8 5.23 5.23 0 0 1-2.4.3c-.658-.482-.892-1.116-.7-1.9a175.509 175.509 0 0 0 1.7-4.4 1.31 1.31 0 0 0-1.2-.1 184.335 184.335 0 0 1-7.4 1.8 720.688 720.688 0 0 0-4.7 12.7c-1.56.84-2.293.374-2.2-1.4l3.9-10.5a39.22 39.22 0 0 0-7.6 1.6 888.127 888.127 0 0 1-5.3 11.5c-.764.514-1.53.481-2.3-.1-2.848-2.358-3.548-5.258-2.1-8.7a8.291 8.291 0 0 1 3.5-3.9 27.149 27.149 0 0 1 4.4-1.3 303.449 303.449 0 0 0 2.8-6.9 89.028 89.028 0 0 0-5.2.8c-.878-.593-1.012-1.326-.4-2.2a37.715 37.715 0 0 1 6.4-1.7c1.699.2 2.332 1.134 1.9 2.8a54.255 54.255 0 0 1-2.5 6.5 67.5 67.5 0 0 0 7.6-1.7 182.426 182.426 0 0 1 2.9-7.8c1.595-.667 2.261-.134 2 1.6a92.31 92.31 0 0 0-1.9 5.6 68.51 68.51 0 0 0 8.6-2 45.012 45.012 0 0 0 1.4-3.8 26.914 26.914 0 0 0 1.1-2.8l.5-.5c1.103-.385 1.77-.018 2 1.1a50.579 50.579 0 0 1-2 5.3 531.852 531.852 0 0 0 26-5.7 229.492 229.492 0 0 1 8.6-1.8 18.307 18.307 0 0 1 3.4-6.1 4.14 4.14 0 0 1 2.4-.2c2.074 1.516 3.174 3.549 3.3 6.1-.188.655-.621 1.021-1.3 1.1a42.975 42.975 0 0 0-5.6 1.4 43.874 43.874 0 0 0-2 5.9c-.022.375.111.675.4.9a237.876 237.876 0 0 1 9.1 7.3c.192 1.457-.441 2.024-1.9 1.7a947.233 947.233 0 0 0-10.3-8.1 4.11 4.11 0 0 1 0-1.8 238.301 238.301 0 0 1 1.5-5.2 57.846 57.846 0 0 0-6.6 1.4z" fill="#3E493E"/>  <path d="M81.5 27.7c1.033.5 1.7 1.3 2 2.4a61.166 61.166 0 0 0-3.4.6 10.282 10.282 0 0 1 1.4-3z" fill="#F1F2F1"/>  <path d="m69.3 35.9-.6 3.6a7.335 7.335 0 0 0-3.8-1.4c-.093-.576.073-1.043.5-1.4a67.35 67.35 0 0 1 3.9-.8z" fill="#E1E2E2"/>  <path d="M65.9 51.3a64.678 64.678 0 0 0-2.7 3.4c-.152.454-.118.887.1 1.3a16.671 16.671 0 0 0-1 3.7c-.059.822.275 1.356 1 1.6a10.566 10.566 0 0 0-1.8.8 3.695 3.695 0 0 0-.4-.7 8.574 8.574 0 0 0-3 .2 36.38 36.38 0 0 0-2.5 3.9 95.756 95.756 0 0 0-.3 5.8 137.603 137.603 0 0 1-2.8-10c-.964-.113-1.864.02-2.7.4a610.301 610.301 0 0 0-4.1 14.8 19.686 19.686 0 0 0 2.8-.1 21.156 21.156 0 0 0 .8-3.1h3.6a43.125 43.125 0 0 0 .8 3.1c.931.1 1.864.133 2.8.1a52.522 52.522 0 0 0-1-4.4 5.134 5.134 0 0 1 1.3 2 60.84 60.84 0 0 0 .9 4.8 33.682 33.682 0 0 0-.9 8.6 1.396 1.396 0 0 1-.5.7 12.627 12.627 0 0 0-2.6 1.5 11.809 11.809 0 0 0-1.8-1 6.29 6.29 0 0 0-1.8 1.7 3.861 3.861 0 0 1-2.2.2 4.816 4.816 0 0 0-1.7-1.9 20.11 20.11 0 0 0-.8-2.6c-2.538-2.11-4.638-1.742-6.3 1.1l-3.6.8c-.7.282-1.233.749-1.6 1.4-.984.149-1.717-.218-2.2-1.1a15.937 15.937 0 0 1 .2-3.3 32.753 32.753 0 0 1-1-1.3 27.847 27.847 0 0 0 .8-2.1 8.295 8.295 0 0 0-.4-1.5.73.73 0 0 1 .2-.3 18.828 18.828 0 0 0 4.6-1.6l.4-1.6a29.01 29.01 0 0 0-3.4-.1V61.3a62.6 62.6 0 0 0 5-.1 4.258 4.258 0 0 0-2.2-1 1.765 1.765 0 0 1-.6-.8 10.96 10.96 0 0 1 3.3-3.7.486.486 0 0 0 .1-.4c.448.207.914.24 1.4.1a469.885 469.885 0 0 1 8.4-1.8c1.533-.6 2.5-1.7 2.9-3.3.258-4.075-1.642-5.909-5.7-5.5a65.226 65.226 0 0 1-5.8 1.5l-.2-.3a27.832 27.832 0 0 1 1.6-3.9 1180.744 1180.744 0 0 1 21-4.6v.8a8.318 8.318 0 0 0-3.2 1.1c-3.24 2.247-4.606 5.347-4.1 9.3 1.123 2.98 3.09 3.746 5.9 2.3a12.849 12.849 0 0 0 1.5-3.3 269.933 269.933 0 0 1 1.8-7c2.585-.25 3.885.95 3.9 3.6.146 2.412-.921 3.98-3.2 4.7-1.026 1.38-.693 2.146 1 2.3z" fill="#E5E5E5"/>  <path d="M60.9 41.1h.6a49.831 49.831 0 0 1-2.3 8c-.824.289-1.424.022-1.8-.8-.275-3.116.891-5.516 3.5-7.2z" fill="#E1E2E2"/>  <path d="M39.9 52.7a11.025 11.025 0 0 0 .4-3.6h-.8a1748.356 1748.356 0 0 0 7.5-1.8c1.245-.043 1.878.557 1.9 1.8.06.861-.273 1.494-1 1.9a121.87 121.87 0 0 1-8 1.7z" fill="#E2E2E3"/>  <path d="M14.9 47.9a.97.97 0 0 1 .8.2 206.254 206.254 0 0 1-3.6 7.8 3.218 3.218 0 0 1-.9-1.4c-.417-3.17.817-5.37 3.7-6.6z" fill="#F9F9F9"/>  <path d="M63.3 61.3c2.392-.304 4.292.496 5.7 2.4.133 3.4.133 6.8 0 10.2-.631 1.43-1.731 2.263-3.3 2.5-2.402.513-4.235-.254-5.5-2.3a65.49 65.49 0 0 1-.2-10c.36-.795.86-1.462 1.5-2a10.566 10.566 0 0 1 1.8-.8z" fill="#3F4A3F"/>  <path d="M33.3 61.5c1.934-.033 3.868 0 5.8.1 1.38.247 2.347 1.014 2.9 2.3.133 3.2.133 6.4 0 9.6-.414 1.615-1.448 2.515-3.1 2.7-1.865.1-3.732.133-5.6.1V61.5z" fill="#3C473C"/>  <path d="M55.3 71.3c-.013.292.053.558.2.8a52.522 52.522 0 0 1 1 4.4 19.686 19.686 0 0 1-2.8-.1 43.125 43.125 0 0 1-.8-3.1h-3.6a21.156 21.156 0 0 1-.8 3.1 19.686 19.686 0 0 1-2.8.1 610.301 610.301 0 0 1 4.1-14.8c.836-.38 1.736-.513 2.7-.4a137.603 137.603 0 0 0 2.8 10z" fill="#3E493E"/>  <path d="M37.7 63.7c.623.011 1.09.278 1.4.8a3.375 3.375 0 0 1-.2 1.6c-.34.173-.573.44-.7.8a6.693 6.693 0 0 1-.8 2.4 8.496 8.496 0 0 0 0 2.6 3.756 3.756 0 0 0 1.1.9 4.432 4.432 0 0 0-.8 1.3h-1.4V63.7h1.4z" fill="#FDFDFD"/>  <path d="M63.7 63.7a8.183 8.183 0 0 1 1.8.1c.367.1.6.333.7.7a96.802 96.802 0 0 1 0 8.8c-.1.367-.333.6-.7.7-.6.133-1.2.133-1.8 0a.937.937 0 0 1-.7-.7c-.133-3-.133-6 0-9a6.047 6.047 0 0 1 .7-.6z" fill="#FBFBFB"/>  <path d="M37.7 63.7h-1.4v10.4h1.4a3.322 3.322 0 0 1-1.6.2V63.5a3.322 3.322 0 0 1 1.6.2z" fill="#ABAFAA"/>  <path d="M39.1 64.5c.232 2.832.265 5.699.1 8.6-.266.701-.766 1.035-1.5 1a4.432 4.432 0 0 1 .8-1.3 3.756 3.756 0 0 1-1.1-.9 8.496 8.496 0 0 1 0-2.6 6.693 6.693 0 0 0 .8-2.4c.127-.36.36-.627.7-.8a3.375 3.375 0 0 0 .2-1.6z" fill="#E0E1E1"/>  <path d="M50.9 66.3c.217.024.35.157.4.4a95.927 95.927 0 0 1 1 4.2 7.375 7.375 0 0 1-2.4.2 61.918 61.918 0 0 0 1-4.8z" fill="#D7D8D8"/></svg>    <defs><linearGradient id="a" x1="0" y1="0" x2="270" y2="270" gradientUnits="userSpaceOnUse"><stop stop-color="#D5E9C9"/><stop offset="1" stop-color="#D5E9C9" stop-opacity=".99"/></linearGradient></defs><text x="50%" y="195" dominant-baseline="middle" text-anchor="middle" font-size="27" fill="#001F5C" filter="url(#b)" font-family="Lucida, sans-serif" font-weight="bold">';
    string svgPartTwo =
        '</text><text x="60" y="240" font-size="27" fill="#001F5C" filter="url(#b)" font-family="Lucida, sans-serif" font-weight="bold">.michinoku</text></svg>';

    mapping(string => address) public domains;
    mapping(string => string) public records;
    mapping(uint256 => string) public names;

    address payable public owner;

    // E2 -> NAME
    constructor(
        string memory _tld
    ) payable ERC721("Michinoku DAO Name Service", "MDNS") {
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
            return 50 * 10 ** 15; // Charge 50 MATIC
        } else if (len == 4) {
            return 20 * 10 ** 15; // Charge 20 MATIC
        } else {
            return 5 * 10 ** 15; // Charge 5 MATIC
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

        (bool sent, ) = payable(0x4C2235d78bC994494FEb777bb683cBf77E375977) // SPLITTER
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