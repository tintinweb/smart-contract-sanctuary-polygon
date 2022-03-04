// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*

MMMXc                                                                                    .oNMMM
MMXc                                                                                      .oNMM
MNo.       ......                ......     ............'..'..                             .xWM
Mk.      .;dOOkxc.             .cxOOkd;   .:xOOOOOOOOOOOOOOOOxc.                            '0M
K;     .;dOOOxol:.           .ck0Okdol;..cxO00000000000000000OOkc.                           cN
d.    .kXNNKxlll:.          ;0NNX0dll:.;OXNNNNNNNNNNNNNNX0000000Od.    .:ccccccccccccc:'     .O
;     ;KMMMXxlll:.          lWMMM0o:'  cNMMMMMMMMMMMMMMMMWXK00Okdl'  .ck000000000000Oxo;.     l
.     ,KMMMXxlll:.          :O00Kkc'...lNMMMWNNNNNXKKK0KWMMWXOdolc''oOKKKKKKKKKKKK0xoll;.     '
      ,KMMMXxlll:.           ..'lkkxxo;oNMMMXxooooc....,OMMMWklllc;xWWWWWWWWWWWWWWKdlll;.     .
      ,KMMMXxlll:.           .;dO0Oxol;oNMMMKdllll;.   .kMMMWklllc:kMMMMMMMMMMMMMMKdlll;.      
      ,KMMMXxlll:.          ,kXXX0dlll;oNMMMKdllll;.   .kMMMWklllc:kMMMWX0000XWMMMKdlll;.      
      ,KMMMXxlll:.          lWMMM0olll;oNMMMKdllll;.   .kMMMWklllc:kMMMWOllllOWMMMKdlll;.      
      ,KMMMXxlllc.          oWMMM0olll;oNMMMKdllll:.   'OMMMWklllc;kMMMWOolllOWMMMKdlll;.     .
      ,KMMMXxllll:;;;;:;::c;oWMMM0olll;oNMMMKdllldxddddxXMMMWkll:'.xMMMWOolodKWMMMKdlll;.     .
.     ,KMMMXxllllllllllodkkcdWMMM0olll;oNMMMKdddkOO0000KNMMMWkc'. .xMMMWOodkOXWMMMKdlll;.     :
c     ,KMMMN0kkkkkkkkkkkO0x;oWMMM0ollc,lNMMMXO000000K00KNMMMKc.   .xMMMWX0KXXNWMMMKdllc,     .x
k.    ;KMMMMMMMMMMMMMWX0kl..oWMMM0oc;. cNMMMMWWWWWWWWWWWMWXd'     .xMMMMMMMMMMMMMMKdl;.      ;K
Nl    ,KWWWWWWWWWWWWWW0l.   lNWWWO:.   cXWWWWWWWWWWWWWWWKo'       .xWWWWWWWWWWWWWW0c.       .xW
MK;   .';;;;;;;;;;;;;,.     .,;;;.     .,;;;;;;;;;;;;;;,.          .;;;;;;;;;;;;;;'         lNM
MWO'                                                                                       :XMM
MMWk.                                                                                     ;KMMM  Made by Lido.

 */

import "./ERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import {IERC2981, IERC165} from "./IERC2981.sol";

contract LidoNFT is ERC721, IERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;
    uint256 constant MAX_SUPPLY = 777;
    uint256 private _currentId;
    string public baseURI;
    bool public isActive = true;
    uint256 public price = 0.1 ether;
    mapping(address => uint256) private _alreadyMinted;
    address public beneficiary;
    address public royalties;

    constructor(
        address _beneficiary,
        address _royalties,
        string memory _initialBaseURI
    ) ERC721("LidoNFT", "LIDO") {
        beneficiary = _beneficiary;
        royalties = _royalties;
        baseURI = _initialBaseURI;
    }

    // Accessors

    function setBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    function setRoyalties(address _royalties) public onlyOwner {
        royalties = _royalties;
    }

    function setActive(bool _isActive) public onlyOwner {
        isActive = _isActive;
    }

    function alreadyMinted(address addr) public view returns (uint256) {
        return _alreadyMinted[addr];
    }

    function totalSupply() public view returns (uint256) {
        return _currentId;
    }

    // Metadata

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // Minting

    function mintListed(uint256 amount) public payable nonReentrant {
        address sender = _msgSender();
        require(isActive, "Sale is closed");
        require(msg.value == price * amount, "Incorrect payable amount");
        _alreadyMinted[sender] += amount;
        _internalMint(sender, amount);
    }

    function ownerMint(address to, uint256 amount) public onlyOwner {
        _internalMint(to, amount);
    }

    function withdraw() public onlyOwner {
        payable(beneficiary).transfer(address(this).balance);
    }

    // Private

    function _internalMint(address to, uint256 amount) private {
        require(
            _currentId + amount <= MAX_SUPPLY,
            "Will exceed maximum supply"
        );

        for (uint256 i = 1; i <= amount; i++) {
            _currentId++;
            _safeMint(to, _currentId);
        }
    }

    // ERC165

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // IERC2981

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256 royaltyAmount)
    {
        _tokenId; // silence solc warning
        royaltyAmount = (_salePrice / 100) * 5;
        return (royalties, royaltyAmount);
    }
}