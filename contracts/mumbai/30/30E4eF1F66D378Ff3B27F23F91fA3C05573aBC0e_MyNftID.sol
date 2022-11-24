/**
 *Submitted for verification at polygonscan.com on 2022-11-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.17;
// Librerias
library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
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

//ERC165
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
//ERC721
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {return msg.data;}
}
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;
    string private _name;
    string private _symbol;
    string private _baseUri;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;
    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    constructor(string memory name_,string memory symbol_,string memory baseUri_) {
        _name = name_;
        _symbol = symbol_;
        _baseUri = baseUri_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721Metadata: ownerOf query for nonexistent token");
        address owner = _owners[tokenId];
        return owner;
    }
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        address owner = _owners[tokenId];
        return owner;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI  = _baseURI();
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }
    function _baseURI() internal view virtual returns (string memory) {
        return _baseUri;
    }
    function _setbaseURI(string memory tokenURI_) internal virtual {
        _baseUri = tokenURI_;
    }
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }
    function _safeMint(address to,uint256 tokenId,bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, data),"ERC721: transfer to non ERC721Receiver implementer");
    }
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _beforeTokenTransfer(address(0), to, tokenId);
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
        _afterTokenTransfer(address(0), to, tokenId);
    }
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        _transfer(owner,address(0), tokenId);
    }
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        _beforeTokenTransfer(from, to, tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
        _afterTokenTransfer(from, to, tokenId);
    }
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}
}

contract MyNftID is ERC721 {
    address private _admin;
    address private _writer;
    address private _owner;
    uint256 private _cost = 0.01 ether;
    address payable BankWALLET;
    uint256 COUNTER;

    struct attribute { 
      string trait_type;
      string value;
    }

    struct Metadata { 
      string name;
      string description;
      string image;
      string external_url;
      attribute DiscordID;
      attribute DiscordAccount;
      attribute TwitterAccount;
      attribute eMailAccount;
    }
   // Mapping from token ID to Metadata Struct
    mapping(uint256 => Metadata) private _MetadataStore;

    Metadata private _EmptyMetadata = Metadata("MyNftID","","https://mydynamicnft.com/static/media/FavIcon.354e0432db1dd9f2f795.png","https://MyNftID.vercel.app",attribute("DiscordID",""),attribute("DiscordAccount",""),attribute("TwitterAccount",""),attribute("eMailAccount",""));

    constructor() ERC721("MyNftID","MyID","https://MyNftID-api.vercel.app/metadata/80001/") {
        _admin = _msgSender();
        _writer = _msgSender();
        BankWALLET = payable(_msgSender());
    }

    // Funciones Matadata
    function _AttributeToString(attribute memory _Attribute) internal pure returns (string memory){
        string memory Salida = string(abi.encodePacked('{"trait_type":"',_Attribute.trait_type,'","value":"',_Attribute.value,'"}'));
        return Salida;
    }
    function _MetadataToString(Metadata storage _Metadata) internal view returns (string memory){
        string memory Cabecera = string(abi.encodePacked('"name":"',_Metadata.name,'","description":"',_Metadata.description,'","image":"',_Metadata.image,'","external_url":"',_Metadata.external_url,'"'));
        string memory attributes = string(abi.encodePacked('"attributes":[',_AttributeToString(_Metadata.DiscordID),',',_AttributeToString(_Metadata.DiscordAccount),',',_AttributeToString(_Metadata.TwitterAccount),',',_AttributeToString(_Metadata.eMailAccount),']'));
        string memory Salida = string(abi.encodePacked('{',Cabecera,',',attributes,'}'));
        return Salida;
    }

    function getMetadata(uint256 _TokenID) public view returns (string memory){
        require(_exists(_TokenID),"getMetadata: Metadata query for nonexistent token");
        return _MetadataToString(_MetadataStore[_TokenID]);
    }

    // NftID#Descripcion#ipfs://cid#www.Web.es#12345#CuentaDiscord#CuentaTwitter#email
    function SetMetadata(uint256 _TokenID,string memory _Data) public onlyWriter {
        require(_exists(_TokenID),"SetMetadata: Set Metadata for nonexistent token");
        string[8] memory finalWordsArray;
        uint256 wordCounter = 0;
        bytes memory stringAsBytesArray = bytes(_Data);
        string memory newWord = '';
        for(uint i = 0; i < stringAsBytesArray.length; i++) {
            if (stringAsBytesArray[i] != "~") {
                newWord = string(abi.encodePacked(newWord,stringAsBytesArray[i]));
            }else {
                finalWordsArray[wordCounter] = newWord;
                wordCounter++;
                newWord = '';
            }
        }
        finalWordsArray[wordCounter] = newWord;
        _MetadataStore[_TokenID] = Metadata(finalWordsArray[0],finalWordsArray[1],finalWordsArray[2],finalWordsArray[3],attribute("DiscordID",finalWordsArray[4]),attribute("DiscordAccount",finalWordsArray[5]),attribute("Twitter",finalWordsArray[6]),attribute("eMail",finalWordsArray[7]));
    }

    function SetWriter(address _Writer) public onlyAdmin {
        _writer = _Writer;
    }
    function GetWriter() public view onlyAdminWriter returns (address){
        return _writer;
    }
    function SetBank(address _Wallet) public onlyAdmin {
        BankWALLET = payable(_Wallet);
    }
    function GetBank() public view onlyAdmin returns (address){
        return BankWALLET;
    }
    function GetCost() public view returns (uint256){
        return _cost;
    }
    function SetCost(uint256 _Coste) public onlyAdmin {
        _cost = _Coste;
    }
    function SafeMint(address to) public onlyAdmin onlyOneNFT {
        _safeMint(to, COUNTER);
        _MetadataStore[COUNTER] = _EmptyMetadata;
        COUNTER++;
    }
    function mint() public payable onlyOneNFT returns (uint256) {
        require(msg.value == _cost,"Mint: Value not Valid");
        _safeMint(msg.sender, COUNTER);
        _MetadataStore[COUNTER] = _EmptyMetadata;
        COUNTER++;
        BankWALLET.transfer(_cost);
        return COUNTER - 1;
    }
    function burn(uint256 tokenId) public onlyOwner(tokenId) {
        _burn(tokenId);
    }
    function SetBaseURI(string memory uri) public onlyAdmin {
        _setbaseURI(uri);
    }
    function walletOfOwner(address _Owner) public view returns (uint256) {
        require(balanceOf(_Owner)>0,"walletOfOwner: caller Does not have any NFT");
        for (uint256 i = 0; i <COUNTER; i++) {
            if (_ownerOf(i) == _Owner) {
                return i;
            }
        }
        return 0;
    }
    function GetNftAmount() public view returns (uint256){
        uint256 Result = 0;
        for (uint256 i = 0; i <COUNTER; i++) {
            if (_ownerOf(i) != address(0)) {
                Result += 1;
            }
        }
        return Result;
    }

    // Ownable
    function getAdmin() public view virtual returns (address) {
        return _admin;
    }
    modifier onlyOwner(uint256 TokenId) {
        require(ownerOf(TokenId) == _msgSender(),"onlyOwner: caller is not the Owner");
        _;
    }

    // Modificadores
    modifier onlyAdmin() {
        require(_admin == _msgSender(),"onlyAdmin: caller is not the Admin");
        _;
    }
    modifier onlyAdminWriter() {
        require((_writer == _msgSender()||_admin == _msgSender()),"onlyAdminWriter: caller is not the Admin or Writer");
        _;
    }
    modifier onlyWriter() {
        require(_writer == _msgSender(),"onlyWriter: caller is not the Writer");
        _;
    }
    modifier onlyOneNFT() {
        require(balanceOf(_msgSender()) < 1,"onlyOneNFT: Only One Nft for Owner");
        _;
    }
}