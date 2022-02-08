//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./Item.sol";

contract Flute is Item {
    constructor(bool _useSeeds) Item("Lute Drop: Flute", "FLUTE", _useSeeds) {}

    function getMaterial(uint256 tokenId)
        public
        view
        override
        requireTokenExists(tokenId)
        returns (string memory)
    {
        return
            ItemLib.getMaterial(
                seedsByTokenId[tokenId],
                [
                    "Wood",
                    "Wood",
                    "Bone",
                    "Bamboo",
                    "Tin",
                    "Tin",
                    "Clay",
                    "Clay",
                    "Brass",
                    "Brass",
                    "Silver",
                    "Gold",
                    "Jade",
                    "Ivory",
                    "Crystal",
                    "Iron"
                ]
            );
    }

    function getType(uint256 tokenId)
        public
        view
        override
        requireTokenExists(tokenId)
        returns (string memory)
    {
        return
            ItemLib.getType(
                seedsByTokenId[tokenId],
                [
                    "Flute",
                    "Flute",
                    "Ocarina",
                    "Panpipes",
                    "Panpipes",
                    "Whistle",
                    "Whistle",
                    "Recorder",
                    "Recorder",
                    "Fife",
                    "Ney",
                    "Piccolo",
                    "Dizi",
                    "Bansuri",
                    "Duduk",
                    "Bombard"
                ]
            );
    }

    function getMajorModifier(uint256 tokenId)
        public
        view
        override
        requireTokenExists(tokenId)
        returns (string memory)
    {
        return
            ItemLib.getMajorModifier(
                seedsByTokenId[tokenId],
                [
                    "One Pipe",
                    "One Pipe",
                    "Two Pipes",
                    "Two Pipes",
                    "Three Pipes",
                    "Three Pipes",
                    "Four Pipes",
                    "Five Pipes",
                    "Six Pipes",
                    "Seven Pipes",
                    "Side Blown",
                    "Cross Blown",
                    "End Blown",
                    "Reed",
                    "Reed",
                    "Double Reed"
                ]
            );
    }

    function getMinorModifier(uint256 tokenId)
        public
        view
        override
        requireTokenExists(tokenId)
        returns (string memory)
    {
        return
            ItemLib.getMinorModifier(
                seedsByTokenId[tokenId],
                [
                    "One Hole",
                    "Two Holes",
                    "Three Holes",
                    "Three Holes",
                    "Four Holes",
                    "Four Holes",
                    "Five Holes",
                    "Five Holes",
                    "Six Holes",
                    "Seven Holes",
                    "Eight Holes",
                    "Nine Holes",
                    "Ten Holes",
                    "Slide",
                    "Slide",
                    "Double Slide"
                ]
            );
    }

    function getRange(uint256 tokenId)
        public
        view
        override
        requireTokenExists(tokenId)
        returns (string memory)
    {
        return
            ItemLib.getRange(
                seedsByTokenId[tokenId],
                [
                    "Piccolo",
                    "Soprano",
                    "Alto",
                    "Piccolo",
                    "Soprano",
                    "Alto",
                    "Piccolo",
                    "Soprano",
                    "Alto",
                    "Piccolo",
                    "Soprano",
                    "Alto",
                    "Piccolo",
                    "Soprano",
                    "Alto",
                    "Piccolo"
                ]
            );
    }

    function getDecoration(uint256 tokenId)
        public
        view
        override
        requireTokenExists(tokenId)
        returns (string memory)
    {
        return
            ItemLib.getDecoration(
                seedsByTokenId[tokenId],
                [
                    "Wooden Mouthpiece",
                    "Wooden Mouthpiece",
                    "Pearl Inlay",
                    "Jade Inlay",
                    "Ivory Inlay",
                    "Brass Keys",
                    "Silver Keys",
                    "Gold Keys",
                    "Brass Mouthpiece",
                    "Silver Mouthpiece",
                    "Gold Mouthpiece",
                    "Decorative Engraving",
                    "Silver Trim",
                    "Gold Trim",
                    "Colorful Ribbon",
                    "Colorful Ribbon"
                ]
            );
    }

    function getName(uint256 tokenId)
        public
        view
        override
        requireTokenExists(tokenId)
        returns (string memory)
    {
        return
            ItemLib.getName(
                getMaterial(tokenId),
                getRange(tokenId),
                getType(tokenId),
                getOrder(tokenId)
            );
    }

    function tokenSVG(uint256 tokenId)
        public
        view
        override
        requireTokenExists(tokenId)
        returns (string memory)
    {
        return
            ItemLib.tokenSVG(
                getName(tokenId),
                getMajorModifier(tokenId),
                getMinorModifier(tokenId),
                getDecoration(tokenId),
                "rgb(153 27 27)",
                '<svg x="25" y="10"><path fill="#ff9811" d="M164.4 202.98c-19.89-7.32-45.63-16.06-55.33-16.06-7.82 0-15.2 2.56-20.77 7.2-5.75 4.8-8.91 11.22-8.91 18.08 0 5.81 2.36 11.48 6.64 15.96a30.53 30.53 0 0 0 14.3 8.21l5.38 14.45c1.25 3.92 4.28 6.45 7.75 6.45 3.47 0 6.51-2.53 7.76-6.46l6.18-16.97c11.93-3.4 26.6-8.58 37-12.42 3.9-1.44 6.43-5.05 6.43-9.22s-2.52-7.78-6.43-9.22z"/><path fill="#bf720d" d="M164.4 202.98c-11.83-4.36-25.73-9.21-37.1-12.43v43.54l.1-.25c11.93-3.4 26.6-8.58 37-12.42 3.9-1.43 6.43-5.05 6.43-9.22s-2.52-7.78-6.43-9.22z"/><g fill="#50412e" transform="translate(79.39 176.38) scale(.1786)"><circle cx="86.17" cy="200.61" r="18.46"/><circle cx="196.95" cy="194.45" r="18.46"/><circle cx="258.5" cy="219.07" r="18.46"/><circle cx="307.74" cy="182.15" r="18.46"/><circle cx="369.28" cy="194.45" r="18.46"/><circle cx="135.4" cy="151.37" r="18.46"/><circle cx="135.4" cy="249.85" r="18.46"/></g><path fill="#ea348b" d="M123.74 111.31a10.4 10.4 0 0 1-10.39-10.39V96.3h6.93v4.62a3.47 3.47 0 0 0 6.93 0h6.93a10.4 10.4 0 0 1-10.4 10.4Z"/><path fill="#b02768" d="M127.2 100.92a3.47 3.47 0 0 1-6.92 0V96.3h-3.46v12.36a10.4 10.4 0 0 0 17.32-7.74h-6.93z"/><path fill="#ccf8f3" d="M128.36 97.46V26.69l-3.3-16.98h-16.49l-3.3 16.98v70.77z"/><path fill="#00d7df" d="M125.06 9.71h-8.24v87.75h11.54V26.69z"/><path fill="#50412e" d="M113.35 35.11h6.93v6.93h-6.93z"/><path fill="#f7b239" d="M92.1 123.17h77.81v12.9h-77.8zm51.88 60.42H131v-4.52h-12.97v-4.51h-12.97v-4.52H92.1v-28.72h77.81v51.32h-12.97v-4.52h-12.96z"/><path fill="#4d4d4d" d="M101.8 123.17h3.27v46.87h-3.27zm12.97 0h3.27v51.39h-3.27zm12.97 0H131v55.9h-3.27zm12.96 0h3.27v60.42h-3.27zm12.97 0h3.27v64.95h-3.27zm12.97 0h3.27v69.47h-3.27z" opacity=".26"/><path fill="#3a88d6" d="M87.66 145.58v-11.85h86.7v11.85H92.1z"/><path fill="#4d4d4d" d="M167.86 145.58v-11.85h6.5v11.85h-6.17z" opacity=".25"/><path fill="#f95428" d="m240.12 170.3.32.47-2.6 19.05h-7.78l-2.6-19.05.31-.47a5.98 5.98 0 0 0 2.3.47h7.74a5.88 5.88 0 0 0 2.3-.47z"/><path fill="#f7b239" d="M256.61 27.42h-45.33a6.34 6.34 0 0 0-6.34 6.34v.38c0 3.2 2.37 5.84 5.45 6.27v.06s13.77 10.88 13.77 26.83v100.65a5.92 5.92 0 0 0 3.61 5.45 5.98 5.98 0 0 0 2.3.47h7.74a5.87 5.87 0 0 0 2.3-.47c2.13-.9 3.62-3 3.62-5.45V67.3c0-15.96 13.78-26.83 13.78-26.83l-.01-.06a6.32 6.32 0 0 0 5.44-6.27v-.38c0-3.5-2.83-6.34-6.33-6.34z"/><path fill="#4d4d4d" d="M256.61 27.42h-23.14c3.5 0 6.33 2.84 6.33 6.34v.38c0 3.2-2.36 5.84-5.44 6.27a5.81 5.81 0 0 1-.9.06h6.28s-4.47 10.88-4.47 26.83v100.65a5.93 5.93 0 0 1-5.52 5.9l.33.02h7.73a5.87 5.87 0 0 0 2.3-.47c2.13-.9 3.62-3 3.62-5.45V67.29c0-15.95 13.78-26.82 13.78-26.82l-.01-.06a6.32 6.32 0 0 0 5.44-6.27v-.38c0-3.5-2.83-6.34-6.33-6.34z" opacity=".25"/><path fill="#4d4d4d" d="M234.95 80.81a2.64 2.64 0 0 0-3.33 3.68c1.16 2.2 4.54 1.6 4.93-.83a2.66 2.66 0 0 0-1.6-2.85zm0 67.42a2.72 2.72 0 0 0-1-.2c-2.3.03-3.5 2.86-1.87 4.5 1.57 1.59 4.36.51 4.5-1.7a2.67 2.67 0 0 0-1.63-2.6zm0-16.85a2.64 2.64 0 1 0-.75 5.06 2.66 2.66 0 0 0 2.34-2.17 2.66 2.66 0 0 0-1.59-2.9zm0-16.86c-1-.4-2.17-.17-2.92.62-.8.83-.95 2.12-.38 3.12 1.2 2.11 4.45 1.54 4.89-.84a2.66 2.66 0 0 0-1.59-2.9zm-1.52-17a2.66 2.66 0 0 0-2.13 2.58c0 1.02.61 1.97 1.53 2.4a2.7 2.7 0 0 0 3.03-.58c.76-.8.94-2.04.43-3.02a2.65 2.65 0 0 0-2.86-1.38c-.17.03.17-.04 0 0z"/><path fill="#bc8b4b" d="M276.18 235.21c0 2.4-1.95 4.34-4.5 4.5h-11.07c-2.4 0-4.34-1.95-4.49-4.5V76.27c0-2.4 1.95-4.34 4.5-4.5h11.07c2.4 0 4.34 1.95 4.49 4.5z"/><path fill="#ce9959" d="M256.12 76.27V235.2c0 2.4 1.95 4.34 4.5 4.5h3.88c2.4 0 4.34-1.95 4.5-4.5V76.27c0-2.4-1.95-4.34-4.5-4.5h-3.89a4.6 4.6 0 0 0-4.49 4.5z"/><g fill="#7a5427" transform="rotate(-45 275.42 -133.2) scale(.26458)"><circle cx="112.8" cy="356.8" r="8.8"/><circle cx="153.6" cy="316" r="8.8"/><circle cx="194.4" cy="275.2" r="8.8"/><path d="M244 234.4c0 4.8-4 8.8-8.8 8.8-4.8 0-8.8-4-8.8-8.8 0-4.8 4-8.8 8.8-8.8 4.8-.8 8.8 3.2 8.8 8.8z"/><circle cx="276" cy="192.8" r="8.8"/><circle cx="316.8" cy="152" r="8.8"/><circle cx="358.4" cy="111.2" r="8.8"/><circle cx="399.2" cy="70.4" r="8.8"/></g><path fill="#a8773d" d="M276.18 215.46h-20.06v19.75c0 2.4 1.95 4.34 4.5 4.5h11.07c2.4 0 4.34-1.95 4.49-4.5z"/><path fill="#bc8b4b" d="M256.12 215.46v19.75c0 2.4 1.95 4.34 4.5 4.5h3.88c2.4 0 4.34-1.95 4.5-4.5v-19.75Z"/><path fill="#593a1c" d="M271.09 239.7v-14.06c0-2.4-1.95-4.34-4.5-4.5l-1.04-.14c-2.4 0-4.34 1.94-4.49 4.49v14.06Z"/><path fill="#382210" d="M266.75 221h-1.2c-2.4 0-4.34 1.94-4.49 4.49v14.06h3.3c2.39 0 4.33-1.94 4.48-4.49V221.6c-.6-.3-1.34-.44-2.1-.6z"/><path fill="#4d4d4d" d="M77.02 200.6H61.21v-10.21l7.97-8.35 7.84 8.35z"/><path fill="#f7b239" d="M79.32 27.13v163.26H58.9v-20.5l.42.01c4.82 0 8.73-3.9 8.73-8.73H58.9V27.13Z"/><path fill="#4d4d4d" d="M72.06 190.39h7.26V27.13h-7.26z" opacity=".25"/><path fill="#4d4d4d" d="M64.23 63.61a2.57 2.57 0 0 0 1.16 2.81 2.55 2.55 0 0 0 3.53-3.44c-1.12-1.98-4.14-1.54-4.7.63zm-.07 24.71a2.56 2.56 0 0 0 4.34 2.07c.9-.9.98-2.37.2-3.37-1.37-1.79-4.3-.92-4.54 1.3zm.02-12.28a2.56 2.56 0 0 0 1.37 2.65c.97.48 2.18.3 2.95-.47.87-.87.99-2.28.28-3.28-1.3-1.84-4.27-1.13-4.6 1.1zm1.9-38.63a2.58 2.58 0 0 0-1.93 2.35c-.12 2.28 2.74 3.54 4.35 1.93.84-.84.98-2.18.35-3.17a2.57 2.57 0 0 0-2.77-1.11zm-1.9 62.95a2.58 2.58 0 0 0 1.37 2.68 2.55 2.55 0 0 0 3.34-3.59c-1.2-2.01-4.34-1.38-4.71.91zm-.03-48.4c-.09 2.27 2.75 3.5 4.35 1.9.87-.87.99-2.27.28-3.27-1.36-1.95-4.54-1.02-4.63 1.37zm0 72.97c-.17 2.3 2.72 3.62 4.35 1.99.89-.89.99-2.32.25-3.32-1.37-1.87-4.42-.97-4.6 1.33zm.02-12.36a2.57 2.57 0 0 0 1.55 2.72c.94.4 2.06.17 2.78-.55.84-.83.98-2.17.35-3.16-1.24-1.98-4.34-1.29-4.68.99z"/><path fill="#f99c38" d="M190.7 256h16.04a3.65 3.65 0 0 0 3.65-3.65V90.51a3.65 3.65 0 0 0-3.65-3.65H190.7a3.65 3.65 0 0 0-3.64 3.65v15.4a6.2 6.2 0 0 1 0 12.38v13.22a6.2 6.2 0 1 1 0 12.38v13.22a6.2 6.2 0 1 1 0 12.38v13.22a6.2 6.2 0 1 1 0 12.39v57.25a3.65 3.65 0 0 0 3.64 3.65z"/><path fill="#d17519" d="M212.2 211.02a3.16 3.16 0 0 1-2.24.93h-22.47a3.18 3.18 0 0 1 0-6.35h22.47a3.18 3.18 0 0 1 3.17 3.17 3.17 3.17 0 0 1-.93 2.25zm0-112.87a3.16 3.16 0 0 1-2.24.93h-22.47a3.18 3.18 0 0 1 0-6.35h22.47a3.18 3.18 0 0 1 3.17 3.18 3.17 3.17 0 0 1-.93 2.24zm0 122.4a3.16 3.16 0 0 1-2.24.92h-22.47a3.18 3.18 0 0 1 0-6.35h22.47a3.18 3.18 0 0 1 3.17 3.18 3.17 3.17 0 0 1-.93 2.24zm0 28.25a3.16 3.16 0 0 1-2.24.93h-22.47a3.18 3.18 0 0 1 0-6.35h22.47a3.18 3.18 0 0 1 3.17 3.17 3.17 3.17 0 0 1-.93 2.25z"/><path fill="#f9e17a" d="m200.01 226.65-1.29 1.29-1.29-1.3a3.18 3.18 0 0 0-4.49 4.5l1.3 1.29-1.3 1.29a3.18 3.18 0 0 0 4.5 4.49l1.28-1.3 1.3 1.3a3.18 3.18 0 0 0 4.48-4.5l-1.29-1.28 1.3-1.3a3.18 3.18 0 0 0-4.5-4.48z"/><g transform="rotate(-45 116.22 -96.96) scale(.26458)"><path fill="#8fa6b4" d="m256.74 7.96 32.3 32.3L42.07 287.22l-32.3-32.3z"/><path fill="#5d7486" d="M281 32.22 34.03 279.2l8.04 8.04L289.04 40.26l-32.3-32.3z"/><path fill="#34495e" d="m285.13 44.17-32.3-32.3 9.76-9.76a7.2 7.2 0 0 1 10.18 0l22.12 22.12a7.2 7.2 0 0 1 0 10.18z"/><path fill="#34495e" d="M294.89 24.23 272.77 2.11a7.2 7.2 0 0 0-7.2-1.8l18.32 18.34a7.2 7.2 0 0 1 0 10.18l-7.05 7.05 8.3 8.3 9.75-9.77a7.2 7.2 0 0 0 0-10.18z" opacity=".3"/><path fill="#34495e" d="M32.3 297A32.3 32.3 0 0 1 0 264.7l14.85-14.85 32.3 32.3L32.3 297z"/><path fill="#34495e" d="m39.6 274.6-12.63 12.63A32.24 32.24 0 0 1 1.7 275.04 32.31 32.31 0 0 0 32.3 297l14.85-14.85a53767.39 53767.39 0 0 0-7.55-7.55z" opacity=".3"/><path fill="#34495e" d="m75.42 189.28 14.85-14.85 24.48 24.48-14.85 14.85z"/><path fill="#293c4c" d="m114.75 198.91 7.82 7.82-14.85 14.85-7.81-7.82z"/><circle cx="243.19" cy="53.81" r="10.5" fill="#2b2b2b"/><circle cx="214.4" cy="82.6" r="10.5" fill="#2b2b2b"/><circle cx="185.62" cy="111.38" r="10.5" fill="#2b2b2b"/><circle cx="156.83" cy="140.17" r="10.5" fill="#2b2b2b"/><path fill="#2b2b2b" d="m40.33 249.53 7.14 7.14a5.45 5.45 0 0 0 7.7 0l8.7-8.7a5.45 5.45 0 0 0 0-7.71l-7.13-7.14a5.45 5.45 0 0 0-7.71 0l-8.7 8.7a5.45 5.45 0 0 0 0 7.71z"/></g><path fill="#a36300" d="M39.99 250.88H28.55a2.31 2.31 0 0 1-2.31-2.31v-21.94a2.31 2.31 0 0 1 2.3-2.31H40a2.31 2.31 0 0 1 2.3 2.3v21.95a2.31 2.31 0 0 1-2.3 2.3z"/><path fill="#c57300" d="M44.07 77.1h-19.6a3.17 3.17 0 0 0-3.18 3.17v119.75h13.13c0 7.25-5.88 13.12-13.13 13.12v12.94a3.17 3.17 0 0 0 3.18 3.18h19.6a3.17 3.17 0 0 0 3.17-3.18V80.27a3.17 3.17 0 0 0-3.17-3.18z"/><path fill="#a36300" d="M44.07 77.1h-9.65v152.16h9.65a3.17 3.17 0 0 0 3.17-3.18V80.27a3.17 3.17 0 0 0-3.17-3.18z"/><g fill="#5e3c16" transform="rotate(-45 164.51 155.15) scale(.26458)"><circle cx="428.52" cy="84.31" r="17.51"/><circle cx="375.07" cy="137.75" r="17.51"/><circle cx="321.62" cy="191.2" r="17.51"/><circle cx="268.17" cy="244.65" r="17.51"/><circle cx="214.73" cy="298.11" r="17.51"/></g><path fill="#844d00" d="M42.3 235.28H26.24v-6.02H42.3z"/></svg>'
            );
    }

    function attributesJSON(uint256 tokenId)
        public
        view
        override
        requireTokenExists(tokenId)
        returns (string memory)
    {
        return
            ItemLib.attributesJSON(
                getType(tokenId),
                getRange(tokenId),
                getMaterial(tokenId),
                getMajorModifier(tokenId),
                getMinorModifier(tokenId),
                getDecoration(tokenId),
                getOrder(tokenId)
            );
    }

    function tokenJSON(uint256 tokenId)
        public
        view
        override
        requireTokenExists(tokenId)
        returns (string memory)
    {
        return
            ItemLib.tokenJSON(
                tokenId,
                "Flute",
                getMaterial(tokenId),
                getType(tokenId),
                getMajorModifier(tokenId),
                getMinorModifier(tokenId),
                getRange(tokenId),
                getDecoration(tokenId),
                getOrder(tokenId),
                tokenSVG(tokenId)
            );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        requireTokenExists(tokenId)
        returns (string memory)
    {
        return
            ItemLib.tokenURI(
                tokenId,
                "Flute",
                getMaterial(tokenId),
                getType(tokenId),
                getMajorModifier(tokenId),
                getMinorModifier(tokenId),
                getRange(tokenId),
                getDecoration(tokenId),
                getOrder(tokenId),
                tokenSVG(tokenId)
            );
    }
}

//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./lib/ItemLib.sol";

abstract contract Item is ERC721Enumerable, AccessControl {
    bytes32 public constant CRAFTER_ROLE = keccak256("CRAFTER_ROLE");

    bool internal immutable useSeeds;
    mapping(uint256 => uint256) internal seedsByTokenId;
    uint256 internal nextId;

    constructor(
        string memory name,
        string memory symbol,
        bool _useSeeds
    ) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        useSeeds = _useSeeds;
    }

    modifier requireTokenExists(uint256 tokenId) {
        require(_exists(tokenId), "Query for nonexistent token");
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function craft(address recipient) public onlyRole(CRAFTER_ROLE) {
        uint256 id = nextId;
        nextId++;
        seedsByTokenId[id] = _getSeed(id);
        _mint(recipient, id);
    }

    function getMaterial(uint256 tokenId)
        public
        view
        virtual
        returns (string memory);

    function getType(uint256 tokenId)
        public
        view
        virtual
        returns (string memory);

    function getMajorModifier(uint256 tokenId)
        public
        view
        virtual
        returns (string memory);

    function getMinorModifier(uint256 tokenId)
        public
        view
        virtual
        returns (string memory);

    function getRange(uint256 tokenId)
        public
        view
        virtual
        returns (string memory);

    function getDecoration(uint256 tokenId)
        public
        view
        virtual
        returns (string memory);

    function getName(uint256 tokenId)
        public
        view
        virtual
        returns (string memory);

    function tokenSVG(uint256 tokenId)
        public
        view
        virtual
        returns (string memory);

    function attributesJSON(uint256 tokenId)
        public
        view
        virtual
        returns (string memory);

    function tokenJSON(uint256 tokenId)
        public
        view
        virtual
        returns (string memory);

    function getOrder(uint256 tokenId)
        public
        view
        requireTokenExists(tokenId)
        returns (string memory)
    {
        return ItemLib.getOrder(seedsByTokenId[tokenId]);
    }

    function _getSeed(uint256 tokenId) internal view returns (uint256) {
        return
            useSeeds
                ? ItemLib.random(
                    abi.encodePacked(
                        tokenId,
                        block.number,
                        block.timestamp,
                        block.difficulty,
                        block.gaslimit,
                        block.basefee,
                        blockhash(block.number - 1),
                        msg.sender,
                        tx.gasprice
                    )
                )
                : tokenId;
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
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./Base64.sol";

library ItemLib {
    using Strings for uint256;

    function getMaterial(uint256 seed, string[16] calldata materials)
        public
        pure
        returns (string memory)
    {
        return pluck(seed, "MATERIAL", materials);
    }

    function getType(uint256 seed, string[16] calldata types)
        public
        pure
        returns (string memory)
    {
        return pluck(seed, "TYPE", types);
    }

    function getMajorModifier(uint256 seed, string[16] calldata majorModifiers)
        public
        pure
        returns (string memory)
    {
        return pluck(seed, "MAJORMOD", majorModifiers);
    }

    function getMinorModifier(uint256 seed, string[16] calldata minorModifiers)
        public
        pure
        returns (string memory)
    {
        return pluck(seed, "MINORMOD", minorModifiers);
    }

    function getRange(uint256 seed, string[16] calldata ranges)
        public
        pure
        returns (string memory)
    {
        return pluck(seed, "RANGE", ranges);
    }

    function getDecoration(uint256 seed, string[16] calldata decorations)
        public
        pure
        returns (string memory)
    {
        return pluck(seed, "DECORATION", decorations);
    }

    function getOrder(uint256 seed) public pure returns (string memory) {
        return
            pluck(
                seed,
                "ORDER",
                [
                    "Power",
                    "Giants",
                    "Titans",
                    "Skill",
                    "Perfection",
                    "Brilliance",
                    "Enlightenment",
                    "Protection",
                    "Anger",
                    "Rage",
                    "Fury",
                    "Vitriol",
                    "the Fox",
                    "Detection",
                    "Reflection",
                    "the Twins"
                ]
            );
    }

    function getName(
        string memory material,
        string memory range,
        string memory itemType,
        string memory order
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    material,
                    " ",
                    range,
                    " ",
                    itemType,
                    " of ",
                    order
                )
            );
    }

    function _textElement(string memory y, string memory text)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<text x="170" y="',
                    y,
                    '" class="base" text-anchor="middle">',
                    text,
                    "</text>"
                )
            );
    }

    function _styleTags(string memory color)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<style>.base { fill: ",
                    color,
                    '; font-family: Luminari, serif; font-size: 16px; }</style><rect width="100%" height="100%" fill="rgb(253 240 221)" />'
                )
            );
    }

    function tokenSVG(
        string memory name,
        string memory majorModifier,
        string memory minorModifier,
        string memory decoration,
        string memory color,
        string memory svg
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 400">',
                    _styleTags(color),
                    svg,
                    _textElement("300", name),
                    _textElement("325", majorModifier),
                    _textElement("350", minorModifier),
                    _textElement("375", decoration),
                    "</svg>"
                )
            );
    }

    function attributesJSON(
        string memory itemType,
        string memory range,
        string memory material,
        string memory majorModifier,
        string memory minorModifier,
        string memory decoration,
        string memory order
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "[",
                    encodeAttribute("Type", itemType),
                    ",",
                    encodeAttribute("Range", range),
                    ",",
                    encodeAttribute("Material", material),
                    ",",
                    encodeAttribute("Major Modifier", majorModifier),
                    ",",
                    encodeAttribute("Minor Modifier", minorModifier),
                    ",",
                    encodeAttribute("Decoration", decoration),
                    ",",
                    encodeAttribute("Order", order),
                    "]"
                )
            );
    }

    function tokenJSON(
        uint256 tokenId,
        string memory name,
        string memory material,
        string memory itemType,
        string memory majorModifier,
        string memory minorModifier,
        string memory range,
        string memory decoration,
        string memory order,
        string memory svg
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"name":"',
                    name,
                    " #",
                    tokenId.toString(),
                    '","description":"I hear that you and your bard have sold your lutes and bought flutes.","image":"data:image/svg+xml;base64,',
                    Base64.encode(bytes(svg)),
                    '","attributes":',
                    attributesJSON(
                        itemType,
                        range,
                        material,
                        majorModifier,
                        minorModifier,
                        decoration,
                        order
                    ),
                    "}"
                )
            );
    }

    function tokenURI(
        uint256 tokenId,
        string memory name,
        string memory material,
        string memory itemType,
        string memory majorModifier,
        string memory minorModifier,
        string memory range,
        string memory decoration,
        string memory order,
        string memory svg
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            tokenJSON(
                                tokenId,
                                name,
                                material,
                                itemType,
                                majorModifier,
                                minorModifier,
                                range,
                                decoration,
                                order,
                                svg
                            )
                        )
                    )
                )
            );
    }

    function random(bytes memory seed) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed)));
    }

    function encodeAttribute(string memory attr, string memory value)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"',
                    attr,
                    '","value":"',
                    value,
                    '"}'
                )
            );
    }

    function pluck(
        uint256 seed,
        string memory keyPrefix,
        string[16] memory sourceArray
    ) internal pure returns (string memory) {
        uint256 rand = random(abi.encodePacked(keyPrefix, seed.toString()));
        string memory output = sourceArray[rand % sourceArray.length];
        return output;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}