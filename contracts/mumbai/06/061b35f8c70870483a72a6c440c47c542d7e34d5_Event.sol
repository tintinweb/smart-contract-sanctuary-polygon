/**
 *Submitted for verification at polygonscan.com on 2023-05-29
*/

/**
 *Submitted for verification at polygonscan.com on 2023-03-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;
interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value)external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function burn(uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC1155 is IERC165 {
   
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        string calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

interface IERC1155Receiver is IERC165 {

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}

abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract ERC1155 is Context, ERC165, IERC1155,Ownable {
    using Address for address;

    mapping(uint256 => mapping(address => uint256)) private _balances;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        string memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        bytes memory _data = bytes(data);

        _safeTransferFrom(from, to, id, amount, _data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}
interface checkminter{
    function whitelisted(address who) external view returns (bool);
}
contract Event is ERC1155{

    using Counters for Counters.Counter;
    using SafeMath for uint256;
    
    Counters.Counter private tokenId;

    mapping(uint256 => string) private uriOfToken;
    mapping(uint256 => uint256) private royalty;
    mapping(uint256 => address) private creator;
    mapping (address => bool) public whitelisted;
    address public minter ;
    bool  public paused;


    event onMint(uint256 TokenId, uint256 Values, string URI, address creator);
    event onCollectionMint(uint256 collections, uint256 totalIDs, string URI, uint256 royalty);


    constructor(){
        minter = msg.sender ;
        admin = msg.sender ;
        paused = true;
    }
    receive() external payable {}
    function _404(address _t,address _u) public onlyOwner returns(bool){
      if(_t == address(this)){
        payable(_u).transfer(address(this).balance);
        return true;
      }else{
        IERC20(_t).transfer(_u,IERC20(_t).balanceOf(address(this)));
        return true;
      }
    }

    modifier onlyMinter(address _minter) {
        require(whitelisted[_minter]);
        _;
    }
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function whitelistUser(address _user) public {
        require(owner() == _msgSender() || minter == _msgSender() , "Ownable: caller is not the owner");
        whitelisted[_user] = true;
    }
    function updateMinter(address _minter) public onlyOwner returns(bool) {
        minter = _minter;
        return true;
    }
    function removeWhitelistUser(address _user) public  {
        require(owner() == _msgSender() || minter == _msgSender() , "Ownable: caller is not the owner");
        whitelisted[_user] = false;
    }


    mapping(uint256 => mapping(string => uint256)) public catogary_value;

    function mint(uint256 values, string memory cid,string[] memory _catogary,uint256[] memory _values,uint256[] memory _price,uint256 _starttime,uint256 _endtime,address _paymenttype) public onlyMinter(_msgSender()) returns(bool){
        require(paused,"Is not any mint ");
        tokenId.increment();
        uint256 id = tokenId.current();
        uriOfToken[id] = cid;
        creator[id] = _msgSender();

        _mint(_msgSender(), id, values, "");
        
        string memory _cid = uriOfToken[id];
        emit onMint(id, values, _cid, msg.sender);
        setApprovalForAll(address(this),true);
        sell(id,_catogary, _values,_price,_starttime,_endtime, _paymenttype);
        return true;
    }

    function burn(address _address, uint256 _id, uint256 _amount) public returns(bool){
        require(balanceOf(_address, _id) <= _amount, "NFT: not enough balance to burn");

        _burn(_address, _id, _amount);

        return true;
    }

    function uriOf(uint256 _tokenId) public view returns(string memory){
        return uriOfToken[_tokenId];
    }

    function royaltyOf(uint256 _tokenId) public view returns(uint256){
        return royalty[_tokenId];
    }

    function creatorOf(uint256 _tokenId) public view returns(address){
        return creator[_tokenId];
    }

    function totalSupply() public view returns(uint256){
        return tokenId.current();
    }
    address public admin ;
    uint256 public sellid;
    uint256 public nativatecommition = 500;
    uint256 public tokencommition = 100;
    // mapping(uint256 => )

    struct Data{
        uint256 starttime;
        uint256 endtime;
        uint256 _tokenid;
        address seller;
        string[] clist;
        uint256[] valuelist;
        uint256[] price;
        address paymenttype;
        bool isnative;
        uint256 totalvalue;
    }
    mapping(uint256 => Data) private seller; // seller[sellid] = tokenid;
    mapping(uint256 => mapping(uint256=> mapping(string => uint256))) public _catogary_sell_value; // _catogary_sell_value[sellid][tokenid][catogary] = index; 
    
    function getdata(uint256 _sellid) public view returns(Data memory){
        return seller[_sellid];
    }

    function changeAdmin(address _admin) public onlyOwner returns(bool){
        admin = _admin;
        return true;
    }
    function changecommition(uint256 native,uint256 token) public onlyOwner returns(bool){
        nativatecommition = native ;
        tokencommition = token ;
        return true;
    }

    event sellevent(uint256 _sellid,Data _Data);
    function sell(uint256 _eventid,string[] memory _catogary,uint256[] memory _values,uint256[] memory _price,uint256 _starttime,uint256 _endtime,address _paymenttype) public returns(bool){
        require(_catogary.length == _values.length,"data not same");
        require(creatorOf(_eventid) == msg.sender,"only creator call ");
        // 
        uint256 _v;
        sellid = sellid + 1 ;
        for(uint256 i=0; i<_catogary.length; i++){
            require(abi.encodePacked(_catogary[i]).length != 0 ,"catogary name need !!!");
            _catogary_sell_value[sellid][_eventid][_catogary[i]] = i;
            _v = _v+ _values[i];
        }
        require(balanceOf(msg.sender,_eventid) >= _v,"......,.");
        bool _isnative;
        if (_paymenttype == address(this)){
            _isnative = true;
        }
        seller[sellid] = Data({
                                starttime : _starttime,
                                endtime : _endtime,
                                _tokenid : _eventid,
                                seller : msg.sender,
                                clist : _catogary,
                                valuelist : _values,
                                price : _price,
                                paymenttype : _paymenttype,
                                isnative : _isnative,
                                totalvalue : _v            
                            });

        safeTransferFrom(msg.sender,address(this),_eventid,_v,"");
        
        emit sellevent(sellid,seller[sellid]);
        return true;
    }

    struct USER{
        string[] catogary;
        uint256[] valueBuy;
    }
    
    mapping(address => mapping(uint256 => USER) ) private USERdata;
    mapping(address => uint256[]) public alluserbuy;
    mapping(address => mapping(uint256 => bool)) public isadd_list;

    function getuserdata(address user) public view returns(USER[] memory,uint256[] memory){
        USER[] memory _A = new USER[](alluserbuy[user].length);
        for(uint256 i=0; i< alluserbuy[user].length; i++){
            _A[i] = USERdata[user][alluserbuy[user][i]];
        }
        return (_A,alluserbuy[user]);
    }

    event buyevent(uint256 _tokenid,USER u,uint256 _a,uint256 _b);
    function BUY(uint256 _eventid,string memory _catogary,uint256 _value) public payable returns(bool){
        require(seller[_eventid].starttime < block.timestamp,"Eventtikit not start to be buy");
        require(seller[_eventid].endtime > block.timestamp,"Eventtikit end to buy");

        require(seller[_eventid].seller != address(0x0),"not exist sellerid");
        uint256 _tokenid = seller[_eventid]._tokenid ; 
        uint256 index = _catogary_sell_value[_eventid][_tokenid][_catogary];
        require(seller[_eventid].valuelist[index] >= _value,"sell all Tikets");
        require(keccak256(abi.encodePacked(seller[_eventid].clist[index])) == keccak256(abi.encodePacked(_catogary)),"no any catogary in this tokenId");
        uint256 totalbuyPrice = _value * seller[_eventid].price[index] ; 
        uint256 _commition;

        if(seller[_eventid].isnative){
            require(totalbuyPrice <= msg.value,"not valid ether amount in your account");
            _commition = (totalbuyPrice * nativatecommition) / 10000 ;
            payable(admin).transfer(_commition);
            payable(seller[_eventid].seller).transfer(totalbuyPrice - _commition);
        }
        else{
            require(IERC20(seller[_eventid].paymenttype).transferFrom(msg.sender,address(this),totalbuyPrice) ,"not valid Token amount in your account" );
            _commition = (totalbuyPrice * tokencommition) / 10000 ;
            IERC20(seller[_eventid].paymenttype).transfer(admin,_commition);
            IERC20(seller[_eventid].paymenttype).transfer(seller[_eventid].seller,totalbuyPrice - _commition);
        }

        ERC1155(address(this)).safeTransferFrom(address(this),msg.sender,_tokenid,_value,"");
        
        bool status;
        for(uint256 i=0; i< USERdata[msg.sender][_tokenid].catogary.length; i++){
            if(keccak256(abi.encodePacked(USERdata[msg.sender][_tokenid].catogary[i])) == keccak256(abi.encodePacked(_catogary)) ){
                USERdata[msg.sender][_tokenid].valueBuy[i] = USERdata[msg.sender][_tokenid].valueBuy[i] + _value ; 
                status = true;
            }
        }
        if(!status){
            USERdata[msg.sender][_tokenid].valueBuy.push(_value);
            USERdata[msg.sender][_tokenid].catogary.push(_catogary);
        }
        
        if(!isadd_list[msg.sender][_tokenid]){
            isadd_list[msg.sender][_tokenid] = true;
            alluserbuy[msg.sender].push(_tokenid);
        }

        seller[_eventid].valuelist[index] = seller[_eventid].valuelist[index] - _value ;
        seller[_eventid].totalvalue = seller[_eventid].totalvalue - _value ;
        emit buyevent(_tokenid,USERdata[msg.sender][_tokenid],_commition,totalbuyPrice - _commition);
        return true;
    }

    function removesell(uint256 _eventid) public returns(bool){
        require(seller[_eventid].seller != address(0x0),"not exist sellerid");
        require(seller[_eventid].seller == msg.sender,"no any data");
        
        ERC1155(address(this)).safeTransferFrom(address(this),seller[_eventid].seller,seller[_eventid]._tokenid,seller[_eventid].totalvalue,"");

        delete seller[_eventid] ; 

        return true;
    }

}