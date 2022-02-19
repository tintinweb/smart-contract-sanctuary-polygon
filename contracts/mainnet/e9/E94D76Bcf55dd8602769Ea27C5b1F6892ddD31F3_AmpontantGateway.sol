// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

contract AmpontantGateway is Ownable, ERC2981, ERC721URIStorage {

    uint256 immutable public maxSupply = 1000;
    uint256 public totalSupply;
    address public contractOwner;
    mapping(uint256 => string) private images;

    string[] private colors = ["black", "blue", "brown", "gray", "green", "orange", "pink", "purple", "red", "white", "yellow"];
    string[] private faces = ["angry", "blue", "closed", "half-opened", "left", "neutral", "right", "sleepy", "sparkling", "spiral", "unique"];    
    string[] private styles = ["animal", "dragon", "origin", "unique"];

    struct Ampontant {
        string color;
        string face;
        string style;
    }

    mapping(uint256 => Ampontant) public ampontants;

    constructor() ERC721 ("Ampontant", "APT") {
        totalSupply = 0;
        address receiver = 0x75f8B316A191cf517972a12473E0df19c1FE3757;
        uint96 feeNumerator = 1000;
        _setDefaultRoyalty(receiver, feeNumerator);    
        contractOwner = owner();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function simpleStorage(uint256 tokenId, string memory _svg) public onlyOwner {
        require(super._exists(tokenId), "ERC721: Strage query for nonexistent token");
        require (msg.sender == super.ownerOf(tokenId), "You have no right to change Metadata");
        images[tokenId] = string(abi.encodePacked(images[tokenId], _svg));
    }

    function refreshStorage(uint256 tokenId) public onlyOwner {
        require(super._exists(tokenId), "ERC721: Strage query for nonexistent token");
        require (msg.sender == super.ownerOf(tokenId), "You have no right to change Metadata");
        images[tokenId] = "";
    }

    function safeMint(address to, uint256 tokenId, uint256 _colorIndex, uint256 _faceIndex, uint256 _styleIndex) public onlyOwner {
        require(!(super._exists(tokenId)), "the tokenId is already exist");
        require(tokenId <= maxSupply, "the tokenId must be from 0 to 999");
        require(totalSupply <= maxSupply, "you can't mint anymore");
        require(_colorIndex < 11, "_colorIndex must be from 0 to 10");
        require(_faceIndex < 11, "_faceIndex must be from 0 to 10");
        require(_styleIndex < 4, "_styleIndex must be from 0 to 3");
        
        string memory _color = colors[_colorIndex];
        string memory _face = faces[_faceIndex];
        string memory _style = styles[_styleIndex];

        ampontants[tokenId] = Ampontant({color: _color, face: _face, style: _style}); 
        _safeMint(to, tokenId);
        totalSupply = totalSupply + 1;
    } 


    function getColor(uint256 tokenId) public view returns (string memory) {
        return ampontants[tokenId].color;
    }

    function getFace(uint256 tokenId) public view returns (string memory) {
        return ampontants[tokenId].face;
    }

    function getStyle(uint256 tokenId) public view returns (string memory) {
        return ampontants[tokenId].style;
    }

    function svgToImageURI(string memory _svg) internal pure returns (string memory){
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(_svg)))
        );
        string memory imageURI = string(abi.encodePacked(baseURL, svgBase64Encoded));
        return imageURI;
    }

    function formatTokenURI(string memory _imageURI, uint256 tokenId) internal view returns (string memory){
        string memory baseURL = "data:application/json;base64,";
        string memory color = getColor(tokenId);
        string memory face = getFace(tokenId);
        string memory style = getStyle(tokenId);

        return string(abi.encodePacked(
            baseURL, 
            Base64.encode(
                bytes(abi.encodePacked(
                    '{"name": "ampontant #', Strings.toString(tokenId),'",', 
                    '"description": "This is an NFT collection of tiny ducks.", ',
                    '"attributes": ',
                    '[{"trait_type": "COLOR", "value": "', color,'"}, ',
                    '{"trait_type": "FACE", "value": "', face,'"}, ',
                    '{"trait_type": "STYLE", "value": "', style,'"}], ',
                    '"image": "',_imageURI,'"}'                                
                )
            ))
        ));
    }

    function tokenURI(uint256 tokenId) public override view returns (string memory output) {
        string memory img0 = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 750 750" xmlns:v="https://vecta.io/nano"><style><![CDATA[.F{fill:#8bd1e5}.G{fill:#1a1a1a}.H{fill:#5b99b4}]]></style><path d="M0 0h750v750H0z" fill="#ffdc00"/><path d="M473.1,617.7c15.4,11,6.6,29.4-8.6,29.6-10.8.1-13.3,17.7-34.3,7.7-14.9-7.1-18.8-18.8-32-30-22.9-19.5-6.2-54.8,23-51,0,0,13.2,23.5,35.1,32.4" class="F"/><path d="M441.8 665.1a32.9 32.9 0 0 1-14.6-3.8c-10.4-5-16.2-11.9-21.9-18.7a108.6 108.6 0 0 0-11.6-12.3c-12.7-10.8-16.6-27.3-10.1-42s21.8-23.4 38.5-21.2l3.5.4 1.7 3.1c.1.2 12.4 21.4 31.6 29.3a7 7 0 1 1-5.3 13c-18.9-7.8-31.7-24.9-36.5-32.2h-.2a22.2 22.2 0 0 0-20.5 13.3c-3.2 7.1-3.2 17.6 6.4 25.7a112.1 112.1 0 0 1 13.3 14c5.3 6.3 9.5 11.3 17.1 15 9.4 4.4 12.3 2 17.1-1.9s7.7-6.4 14.1-6.5a9.8 9.8 0 0 0 9.4-6.5c1.2-3.6-.5-7.3-4.7-10.4a6.9 6.9 0 0 1-1.7-9.7 7.1 7.1 0 0 1 9.8-1.7c9.1 6.6 13 16.5 10 26a23.7 23.7 0 0 1-22.6 16.3c-1.4 0-3 1.2-5.4 3.2s-9.1 7.6-17.4 7.6z" class="G"/><path d="M398.4 602.9c-3-15-8.4-24.6 8-30 6-2 23 0 26 10s4 11 1 26-32 9-35-6z" class="H"/><path d="M361.2,612c1,18,6.6,21.2,28,35,31,20,2.2,24.1,0,29-12,27-32,4-41,14-21.4,23.8-38.4-22.2-48.7-43.9-13-27.2,5.7-47.1,32.5-34.8" class="F"/><path d="M336.2 703.7a14.3 14.3 0 0 1-2.9-.3c-16.6-2.5-27.7-27-36.7-46.7l-3.5-7.6c-7.3-15.5-6.2-31.1 3.1-40.5s23.6-10.6 38.7-3.7l-5.8 12.7c-9.6-4.3-18.1-4-22.9.9s-5.2 14.5-.4 24.6l3.6 7.8c5.9 13 16.9 37.3 26 38.7 2.2.3 4.7-1.1 7.6-4.3 6.2-6.9 14.8-5.1 21-3.7 8.9 1.9 13.8 2.9 18.8-8.4 1.5-3.4 4.7-5.1 8-7 1.6-.8 4.7-2.5 5.6-3.6s-2.3-4.1-11-9.7l-1.5-1c-20.7-13.4-28.5-18.4-29.7-39.5l14-.8c.8 14 3.3 15.7 23.3 28.6l1.5.9c8.3 5.4 17.8 12.7 17.5 22.1s-8.2 12.7-12.9 15.3l-2.5 1.4c-9.6 20.5-24.8 17.3-34 15.4-3.1-.7-6.9-1.5-7.7-.6-5.4 6-11.1 9-17.2 9z" class="G"/><path d="M321.2 619c-3-15-1.2-77.1 12.3-87.8 15.9-12.4 22.7-10.4 36.1 15.7 4.4 8.7-14.4 66.1-17.4 81.1s-28 6-31-9z" class="H"/><path d="M352.2 636a7.1 7.1 0 0 1-4.7-1.8c-8.7-7.8-2.9-26.5 7.3-56.3 3.5-10.3 8.3-24.3 8.2-28.5-2.5-5-9.1-17.5-13.7-18.5-2.1-.5-5.9 1.5-11.5 5.8-1 .8-4.4 4.8-6.6 22.9-1.5 12.5-1.8 27.4-2.1 39.4-.2 8.6-.4 16.1-.9 20.8a7.1 7.1 0 0 1-7.8 6.2 7 7 0 0 1-6.1-7.8c.4-4.1.6-11.2.8-19.5.8-35.7 2.4-63.7 14.1-73 7-5.5 14.6-10.3 23-8.5s16 11.7 23.6 26.5c3 5.9.4 14.8-7.8 38.7-4.3 12.7-12.3 36.2-10.6 41.9a7 7 0 0 1 0 9.4 7.1 7.1 0 0 1-5.2 2.3zm10.8-86.9z" class="G"/><path d="M429.5,457.7c20,12,35.6,20.5,57.2,17,43.3-7,1,57-29.3,54" class="F"/><path d="M459.5 535.8h-2.8a7 7 0 1 1 1.4-14c11.7 1.2 27.9-12.2 35.8-25.5 4.5-7.6 4.8-12.5 3.9-13.8s-3.3-1.9-10-.8c-25.2 4-43.8-7.1-61.9-17.9a7 7 0 1 1 7.1-12c20.2 12 33.8 19.1 52.6 16.1 14.3-2.3 20.8 2.4 23.8 6.7 4.7 7 3.5 17.2-3.5 28.9-9.6 16-28.8 32.3-46.4 32.3z" class="G"/><path d="M268.9 568.6c-27.5-24.4-51.9-87.6-26-121 14-18 51.9 15.8 65 11 86-31 45-76 45-76s-16.3-29.8 23-31 22.5 73.8 42.5 91c55 47 84.5 124 1.5 158-38.5 15.8-107 7-151-32z" class="F"/><path d="M342.5 441a53.7 53.7 0 0 0 12.9-13.1s17-32.5 32-31.3c22.1 1.6 22.1 30.6 27.8 43.4 1.3 27.1-43.6 23.8-72.7 1zm-40.3 148c-79.6-41.5-68-115.6-59.9-127.8-.7 101.4 95.7 149.4 186 129.8-14.1 6.5-62.8 33.5-126.1-2z" class="H"/><path d="M370.9 617.4c-33.8 0-66.7-13.6-102.1-41.9-32.4-26-48.8-82.3-41.3-113.5 3.3-13.8 11.2-22.6 22.3-24.9 9.5-1.9 19.2 2.8 29.3 7.9 12.9 6.4 25.1 12.4 36.7 5.9 22.5-12.6 35.2-25.8 36.7-38.2a21.1 21.1 0 0 0-5.7-16.8l-.8-.8-.5-1a32.4 32.4 0 0 1-3.3-8.9c-1.7-7.1-1-13.7 2-19 4.9-8.5 15-13 30.2-13.5 17-.5 29 7.3 35.9 23.2 5.4 12.5 6.7 28 7.9 41.7.5 6.3 1 12.3 1.9 17.2 1.2 6.6 5.7 10.3 14.3 16.9s22 16.9 31.1 36.3a7 7 0 1 1-12.6 6c-7.7-16.4-18-24.3-27-31.2s-17.4-13.3-19.6-25.6c-.9-5.4-1.5-11.7-2.1-18.4-2.6-30.9-6.3-52.8-29.4-52.1-9.7.3-16.2 2.6-18.4 6.4s-.4 10.6 1 13.6a35.4 35.4 0 0 1 9 27.7c-2.1 17.2-16.8 33.6-43.8 48.7-18 10.1-35.6 1.4-49.7-5.6-7.9-3.9-15.5-7.6-20.3-6.6s-9.5 6-11.5 14.3c-6.4 26.5 9.2 77.5 36.5 99.3 32.8 26.3 62.9 38.9 93.5 38.9a123 123 0 0 0 17.1-1.3c31.8-4.8 54-16.8 66-35.8s11.1-38.9 7.3-51.3a7 7 0 1 1 13.4-4c4.6 15.1 5.1 40.7-8.8 62.7s-39.8 36.8-75.8 42.2a127.7 127.7 0 0 1-19.4 1.5z" class="G"/><path d="M323.2 565c-64.8 25.8-106-38.8-72-45s41.6-36.5 59-37c16.9-3.6 31.8 5.3 35.7 21.2 6.8 27.5-.8 48-22.7 60.8z" class="F"/><path d="M293.8 576.8a81.8 81.8 0 0 1-17.9-1.9c-12.9-2.8-24.6-8.9-32.9-17.2s-13.7-21-10.8-30.4c1.3-4.4 5.4-11.9 17.8-14.2 16.4-3 24.2-10.8 32.5-19.1s14-14.1 25.7-17.7a7 7 0 0 1 4.1 13.4c-8.4 2.5-13.7 7.9-19.9 14.1-9 9.1-19.1 19.3-39.9 23.1q-5.9 1.1-6.9 4.5c-1.1 3.5.7 9.9 7.3 16.4 11.8 11.8 35.9 20.7 68.2 10.5a7.1 7.1 0 0 1 8.8 4.6 7 7 0 0 1-4.6 8.8 105.1 105.1 0 0 1-31.5 5.1z" class="G"/><path d="M468.2 120c19.6 2.1 3 61-9 91-4.8 12.1-10 42-37 34-14.6-4.3-23-20-7-50 11-20.6 34-77 53-75z" class="F"/><path d="M431 258.4a36.6 36.6 0 0 1-10.8-1.7 27.6 27.6 0 0 1-18.3-15.9c-4.8-11.4-2.4-26.2 7.1-44.1 2-3.6 4.3-8.4 7-13.9 17.8-36.6 34-66.7 52.9-64.8h0a15.2 15.2 0 0 1 11.6 7.5c13.4 22.1-13.6 90.2-14.8 93.1s-1.3 3.5-2 5.6c-3.9 11.6-11.4 34.2-32.7 34.2zM467.3 132c-1.5 0-7 1.2-17.5 17.3-7.8 11.9-15.3 27.3-21.3 39.7l-7.1 14.3c-7.2 13.6-9.6 25-6.6 32.1 1.6 3.9 4.8 6.5 9.4 7.9 14.2 4.2 19.8-4.2 26.3-23.5.7-2.3 1.5-4.5 2.2-6.4 15.4-38.4 20.6-72.7 15.9-80.6-.5-.8-.7-.8-1.1-.8z" class="G"/><path d="M264.8 387.8c-20-4-50-24-26-52 11.6-13.5 13.9-12.3 12.1-33.9-3.2-41.1 5.5-101.3 64.9-121.1 24-8 4.6-53.9 31-62s46.8 20.5 60 39c15 21 48 18 70 48 16.4 22.3 27.8 30.2 30 87.4 7 34 26 13.6 31 42.6 3.5 19.9-36.7 60-117.4 72.9-112.6 18.1-99.6-9.7-155.6-20.9z" class="F"/><path d="M287.6,246.7c-13.7,44-4.7,86.6-7.1,89.3-24,28-6.4,45.3,19.6,58.3,0,0-1.5,1.1-5.8.6s-13.6-3-26.1-5.9c-20-4-49-27.5-25-55.5,11.5-13.4,13.8-12.2,12.1-33.9-1.2-15.4-2.1-42.6,6.9-61.6Z" class="H"/><path d="M488.2 228a7 7 0 0 1-6.2-3.7c-14.8-28-34.3-36.1-51.4-43.3-11.4-4.8-22.2-9.3-29.1-18.9l-.6-.9c-12.5-17.5-28.1-39.3-47.3-35.3-8.6 1.7-10.5 8.3-12.7 22.8-1.3 7.9-2.6 16.1-6.7 22.9a7 7 0 1 1-12-7.2c2.7-4.5 3.7-11 4.8-17.9 2.2-13.5 4.8-30.4 23.8-34.4 28.1-5.8 47.4 21.2 61.5 41l.6.8c4.6 6.5 12.8 9.9 23.1 14.2 18.3 7.6 41.2 17.2 58.4 49.6a7.1 7.1 0 0 1-2.9 9.5 8 8 0 0 1-3.3.8zm-128 194.5c-30.6 0-43.1-7.5-54.5-14.3-6.1-3.6-11.2-6.7-19-8.4a7 7 0 0 1 3-13.6c10 2.1 16.7 6.1 23.1 10 15.1 9 32.2 19.2 106.8 5.9 34.7-6.2 65.7-18 87.1-33.2 12.8-9 25.9-22.9 24.6-31.9s-4.1-10.4-9.5-12.9c-7.2-3.4-17.1-7.9-21.5-29.2v-1.2c-1-31-2-37-8.2-49.6a6.9 6.9 0 0 1 3.1-9.4 7.1 7.1 0 0 1 9.4 3.2c7.7 15.5 8.7 23.7 9.6 54.7 3 13.9 7.7 16 13.6 18.8s14.9 6.9 17.4 23.6c2.1 13.5-9.3 30.4-30.3 45.3-16.3 11.6-45.6 27.2-92.8 35.6-26.6 4.7-46.5 6.6-61.9 6.6zm-95-29.5h-1.1c-20.7-3.2-36.3-14.4-40.7-29.1-3.4-11.4.6-23.4 11.1-33 8.7-7.9 8.8-8.7 9.8-28.1l.2-4.4c1.3-25.6 2.6-49.8 10.6-70.8 9.2-24.2 26.5-40.5 52.7-50.1a7.023 7.023 0 1 1 4.8 13.2c-22.5 8.2-36.6 21.5-44.4 41.9s-8.4 42.1-9.7 66.6l-.2 4.3c-1.1 20.5-1.4 26-14.4 37.8-4.5 4.1-9.4 10.7-7.1 18.6s14.4 16.9 29.5 19.3a7 7 0 0 1-1.1 13.9z" class="G"/><path d="M301.3 232.8c-13.6 24.4-33.2 16.2-47.3 2.1-22.2-22.3-47.9-64.2-39.4-73.5 10.5-11.6 59.6 25.9 76.6 37.6s16.6 22 10.1 33.8z" class="F"/><path d="M287.6 246.7c-11.3 5-23.8-2-33.6-11.8-19.1-19.2-40.9-70.1-36.1-63.3 15.4 28.8 69.7 75.1 69.7 75.1z" class="H"/><path d="M258.1 247.9a7 7 0 0 1-5.4-2.6l-7.8-9.6c-24.1-29.4-51.4-62.7-35.8-79.5 9.5-10.2 24.9-3 30-.7 10.4 4.9 22.8 13 37.2 22.4l16.5 10.8a7 7 0 1 1-7.5 11.8l-16.7-10.9c-13.9-9.1-25.9-17-35.3-21.3-7.3-3.4-12.3-4.3-14-2.5s-3.3 5 7.1 22.1c7.7 12.5 19.2 26.5 29.3 38.9l7.9 9.7a7 7 0 0 1-5.5 11.4z" class="G"/><path d="M348.2 410c-14.9-9.5-6.1-29 21-29 24 0 35.3-19.4 67-26 24-5 40 5.8 60 2s19.5 11.9 18 22c-2 14-10 24-47 39-34 13.8-89 11-119-8z" class="F"/><path d="M428.2 426s-40 6-74-10c-20.8-9.8-14-32 5-34 5.1-.5 14-1 14-1-8.9 26.7 27.1 44.1 55 45z" class="H"/><g class="G"><path d="M418.3 432.4c-23.2 0-47-4.1-68.1-12.3-9.9-3.8-16.5-16.2-14.2-27a20 20 0 0 1 9.4-13.2c5.3-3.3 12.4-4.7 21-4.4 20 .8 30.9-6.1 43.6-14 9.9-6.2 20.1-12.6 35-15.9 11.8-2.6 20.7.7 28.5 3.5s12.7 4.6 19.4 2.2 15.8-1.2 21.4 4.3 8.6 15.7 6.1 23.1c-7 21.3-23.7 36.6-49.4 45.5-15.8 5.5-34 8.2-52.7 8.2zm-54.2-45.9c-6.6 0-15.8 1.3-17.4 8.9-1.1 5.5 2.5 12.5 7.5 14.5h0c35.8 13.8 80.2 15.4 113.2 3.9C490 406 504 393.3 510 375.3c1.2-3.6-.3-8.8-3.4-11.8s-6-3.2-10.1-1.8c-10.4 3.7-19 .5-26.7-2.3s-13.8-4.9-22.4-3c-13.1 2.9-22.5 8.7-31.5 14.4-13.1 8.2-26.6 16.6-49.9 15.7z"/><circle cx="486.4" cy="313.8" r="30.8"/></g><circle cx="486.4" cy="313.8" r="21.3" class="F"/><circle cx="486.4" cy="313.8" r="15.7" class="H"/><circle cx="366.9" cy="335.4" r="33.6" class="G"/><circle cx="366.9" cy="335.4" r="23.2" class="F"/><circle cx="366.9" cy="335.4" r="17.1" class="H"/></svg>';
        string memory img1 = images[tokenId];
        string memory imageURI;
        address user1 = super.ownerOf(tokenId);
        if (user1 == contractOwner) {
            imageURI = svgToImageURI(img0);
        } else { 
            imageURI = svgToImageURI(img1);
        }
        output = formatTokenURI(imageURI, tokenId);
        return output;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
        contractOwner = newOwner;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/ERC721Royalty.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../common/ERC2981.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev Extension of ERC721 with the ERC2981 NFT Royalty Standard, a standardized way to retrieve royalty payment
 * information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC721Royalty is ERC2981, ERC721 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";