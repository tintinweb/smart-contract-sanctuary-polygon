/**
 *Submitted for verification at polygonscan.com on 2022-07-06
*/

// SPDX-License-Identifier: MIT

// File: contracts/Metaverse/tokenamize from real world/Libs.sol
pragma solidity 0.8;

library ADDRESS {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}

library MATH {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function dec(uint256 val) internal pure { // decrement
        require(val > 0, "ERROR: overflow");
        unchecked { val -= 1; }
    }

    function inc(uint256 val) internal pure { // increment
        unchecked { val += 1; }
    }
}

// File: contracts/Metaverse/tokenamize from real world/IERC165.sol
pragma solidity 0.8;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: contracts/Metaverse/tokenamize from real world/ERC165.sol
pragma solidity 0.8;

contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) external virtual override view returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: contracts/Metaverse/tokenamize from real world/IShop.sol
pragma solidity 0.8;

interface IShop is IERC165 {
	event Transfer(uint256 indexed id, address from, address to, bytes16 indexed certification, uint256 indexed time);
	event PriceChange(uint256 indexed id, address caller, uint256 oldPrice, uint256 newPrice, uint256 indexed time);
	event ListItem(uint256 indexed id, address caller, uint256 price, bool isListed, uint256 indexed time);

	function create(uint8 theType, uint8 material, uint256 price, string calldata ipfs) external returns (uint256 itemId); // only by shop or creator
	function changePrice(uint256 id, uint256 newPrice) external payable returns (bool);
	function transfer(uint256 id, address recipient) external payable;
	function list(uint256 id, uint256 price) external returns (bool);
	function unList(uint256 id) external;
	function buy(uint256 id) external payable;

	function verify(bytes16 certification) external view returns (bool success); // validate/verify the certification
}

// File: contracts/Metaverse/tokenamize from real world/IERC20.sol
pragma solidity 0.8;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
}

// File: contracts/Metaverse/tokenamize from real world/Tokenize.sol
pragma solidity 0.8;

contract Jewellery is IShop, ERC165{
    using MATH for uint256;

    // setup ============================================
    address immutable SHOP; 
    uint256 private _id;
    uint256 private _totalItem; // created item {equal _id}
    uint256 private _totalSell; // item sold
    uint256 private _totalValue; // price of all sold item
    uint256 private _shopBalance; // balance now {reset after withdraw}
    enum JEWLLARYTYPE {
        //  0         1       2     3        4
        Necklace, Bracelet, Ring, Emblem, Medallion
    }
    enum MATERIAL { 
        //  0     1      2
        Diamond, Gold, Silver
    }
    struct Product {
        uint8 types;    // 0,4 = 5  -  JEWLLARYTYPE
        uint8 jewells;  // 0,2 = 3  -  MATERIAL
        uint256 id;
        uint256 price;
        bool secondaryMarket;
        string cid; // ipfs or other storage address (full read address) like-> (https://ipfs.io/ipfs/cid)
        address owner;
    }
    Product jewels;
    mapping(uint256 => Product) private _jewels; // developed/final product
    mapping(uint256 => address) private _ownerOf; // owner of item id - using for: identify, verify
    mapping(bytes16 => uint256) private _itemBalance; // can check easily for: certification, identify, verify, checking cargo|warehouse
    mapping(uint256 => bytes16) private _itemCertify; // find certification
    mapping(uint256 => bool) private _isListed; // for listed items to sell

    // events ============================================
    event NewPrice(bytes);


    // validators ============================================
    modifier onlyShop() {
        require(_msgSender() == SHOP, "shop keeper allow only");
        _;
    }

    modifier isTheOwner(uint256 id) {
        require(_msgSender() == _jewels[id].owner && 
        _msgSender() == _ownerOf[id] || 
        _ownerOf[id] == _this() && 
        _msgSender() == SHOP,
        "item owner allow only");
        _;
    }

    // modifier itemExist(uint256 id) {
    //     uint256 max = total();
    //     require(id > 0 && id <= max, "out of range");
    //     _;
    // }

    // init ============================================
    constructor() {
        SHOP = _msgSender();
        _id = 0;
    }

    receive() payable external {}

    // register ============================================
    function supportsInterface(bytes4 interfaceId) 
        external virtual override(ERC165, IERC165) view returns (bool) 
    {
        return interfaceId == type(IERC165).interfaceId || 
        interfaceId == type(IShop).interfaceId;
    }

    // assist ============================================
	function total() external view virtual returns (uint256)
    {
        return _totalItem;
    }
    
	function ownerOf(uint256 id) external view virtual returns (address ownerOfIs)
    {
        _ownerOf[id] != _hole() ?
            ownerOfIs = _ownerOf[id] : 
            ownerOfIs = _hole();
    }
    
	function itemBalance(bytes16 hash) external view virtual returns (uint256 amount)
    {
        _itemBalance[hash] != 0 ?
            amount = _itemBalance[hash] :
            amount = 0;
    }
    
	function itemCertified(uint256 id) external view virtual returns (bytes16)
    {
        if(id > 0 && id <= _totalItem) {
            return _itemCertify[id];
        }
        else {
            revert("not found result");
        }
    }

    // calculation ============================================
	function create(uint8 theType, uint8 material, uint256 price, string calldata ipfs) 
        external onlyShop virtual override returns (uint256 itemId)
    {
        uint256 id = _id;
        (itemId, ) = _create(theType, material, price, ipfs);
        require(itemId > 0 && _id > id); // last security check
    }

    function changePrice(uint256 id, uint256 newPrice) 
        external payable virtual override isTheOwner(id) /*itemExist(id)*/ returns (bool) 
    {
        uint256 oldPrice = _jewels[id].price;
        _changePrice(id, newPrice);
        require(oldPrice != _jewels[id].price, "why spend gas!");
        emit PriceChange(id, _msgSender(), oldPrice, newPrice, block.timestamp);
        return true;
    }

	function burn() external onlyShop virtual returns (uint){
        revert("disabled function");
    }

	function transfer(uint256 id, address recipient) 
        external payable virtual override isTheOwner(id) 
    {
        require(_ownerOf[id] != recipient, "you have this item");
        require(_ownerOf[id] != _hole(), "black hole is denied path");
        require(_isListed[id] == false, "first un-list, then transfer");
        bool success =  _transfer(id, recipient);
        require(success);
        _jewels[id].secondaryMarket = true;
    }

    // buy with native token
	function buy(uint256 id) external payable virtual override 
    {
        require(_msgSender() != _jewels[id].owner, "gas spending is not allow");
        uint256 val = _msgValue();
        address oldOwner_ = _jewels[id].owner;
        require(val >= _jewels[id].price, "not enought fund for buy, check your funds");
        (bool sent, ) = oldOwner_.call{value: val}("");
        bool success = _buy(id);
        require(success && sent);
        if(_jewels[id].secondaryMarket == false){ _jewels[id].secondaryMarket = true; }
        emit Transfer(id, oldOwner_, _msgSender(), _itemCertify[id], block.timestamp);
    }

    // listing for sell
	function list(uint256 id, uint256 price) external isTheOwner(id) virtual override returns (bool)
    {
        require(price > 0, "insane idea");
        require(_isListed[id] == false, "require de-list, or you can change price");
        _list(id, price);
        _isListed[id] = true;
        emit ListItem(id, _msgSender(), price, true, block.timestamp);
        return true;
    }
    
    // de-listing from sell
	function unList(uint256 id) external isTheOwner(id) virtual override 
    {
        require(_isListed[id] == true, "item not listed");
        _isListed[id] = false;
        emit ListItem(id, _msgSender(), _jewels[id].price, false, block.timestamp);
    }

    function verify(bytes16 certification) external virtual override view returns (bool success) 
    {
        require(_itemBalance[certification] != 0, "not valid");
        success = true;
    }

    // tools ============================================
    function _create(uint8 theType, uint8 material, uint256 price, string calldata ipfs) 
        internal onlyShop virtual returns (uint256 id, bytes16 hash)
    {
        require(theType >= 0 && theType < 5, "out of scope");
        require(material >= 0 && material < 3, "out of scope");
        require(bytes(ipfs).length != 0, "view item not accepted");
        hash = bytes16(keccak256(abi.encode(theType,material)));
        _id += 1;
        Product memory newItem = Product(
            theType, // 0,4 = 5
            material, // 0,2 = 3
            _id,
            price,
            false,
            ipfs,
            _this()
        );
        _jewels[_id] = newItem;
        _ownerOf[_id] = _this();
        _itemCertify[_id] = hash;
        _shopBalance += 1;
        _totalItem += 1;
        _itemBalance[hash] += 1;
        // if(_jewels[_id].price > 0) { _isListed[id] = true; }
        if(price > 0) { _list(_jewels[_id].id, price); _isListed[id] = true; }
        id = _id;
        require(_msgData().length > 0);
        emit Transfer(id, _hole(), _this(), hash, block.timestamp);
    }

    function _changePrice(uint256 id, uint256 newPrice) 
        internal virtual 
    {
        _jewels[id].price = newPrice;
    }    

	function _transfer(uint256 id, address recipient) 
        internal virtual returns (bool)
    {
        _ownerOf[id] = recipient;
        _jewels[id].owner = recipient;
        if(_msgSender() == SHOP) { 
            emit Transfer(id, _this(), recipient, _itemCertify[_id], block.timestamp);
        } else {
            emit Transfer(id, _msgSender(), recipient, _itemCertify[_id], block.timestamp);
        }
        return true;
    }

    function _list(uint256 id, uint256 price) internal virtual {
        if(_jewels[id].secondaryMarket != true){ _jewels[id].secondaryMarket = true; }
        _jewels[id].price = price;
    }

	function _buy(uint256 id) internal virtual returns (bool success) {
        success =  _transfer(id, _msgSender());
        require(success);
        address newOwner = _msgSender();
        _jewels[id].owner = newOwner;
        _jewels[id].price = 0;
        _ownerOf[id] = newOwner;
        _isListed[id] = false;
    }

    // helpers ============================================
    function owner() public view virtual returns (address) {
        return SHOP;
    }

    function _this() internal view virtual returns (address) {
        return address(this);
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _msgValue() internal view virtual returns (uint) {
        return msg.value;
    }

    function _hole() internal view virtual returns (address) {
        return address(0);
    }
    

}

/* ==================================================================
                      mosi-sol @ github
=================================================================== */
// how to tokenize real world into blockchain, without erc721/erc1155
//      how to make market/shop based on smart contracts