// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract MERC1155 is ERC1155, Ownable {
    string public _name;
    string public _symbol;
    string public baseURI;

    mapping(uint => string) public lockUri;
    mapping(address => bool) public minters;
    mapping(uint256 => bool) tokenExist;
    event Minter(address _m,bool _o);
    event SetURI(uint _tokenId,string _ipfs);
    constructor(
        string memory name_, 
        string memory symbol_,
        address minter_,
        string memory base_
    ) ERC1155(base_) {
        _name = name_;
        _symbol = symbol_;
        setMinter(minter_,true);
        setBase(base_);
    }

    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function exist(uint _id) external view returns (bool) {
        return tokenExist[_id];
    }




    function setMinter(address _minter,bool _open) public onlyOwner{
        minters[_minter] = _open;
        emit Minter(_minter,_open);
    }
    function setBase(string memory _uri) public onlyOwner{
        baseURI = _uri;
    }
    function uri(uint256 _id) public view override returns (string memory) {
        if(bytes(lockUri[_id]).length > 0){
            return lockUri[_id];
        }else{
            string memory lastAddress = Strings.toHexString(uint160(address(this)), 20);
            lastAddress = strConcat(lastAddress,"/");
            lastAddress = strConcat(lastAddress,Strings.toString(_id));
            return strConcat(baseURI,lastAddress);
        }
    }
    function strConcat(string memory _a, string memory _b) public pure returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        uint i;
        for (i = 0; i < _ba.length; i++)bret[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
    }

    function setURI(uint _id,string memory _ipfs) public  {
        require(balanceOf(msg.sender,_id) > 0 && bytes(lockUri[_id]).length < 1,"403");
        lockUri[_id] = _ipfs;
        emit SetURI(_id,_ipfs);
    }
    function mint(
        address from,
        address to,
        uint _tokenID,
        uint amount,
        bytes memory data
    ) public virtual returns (uint) {
        require(minters[msg.sender],'Not Minter');
        return _mint(from,to,_tokenID, amount, data);
    }

    function BatchMint(
        address[] memory from,
        address[] memory to,
        uint[] memory _tokenID,
        uint[] memory amount,
        bytes[] memory data
    ) public virtual {
        require(minters[msg.sender],'Not Minter');
        require(from.length == to.length);
        require(to.length == _tokenID.length);
        for(uint i = 0; i < from.length; i++){
            _mint(from[i],to[i],_tokenID[i], amount[i], data[i]);
        }
    }

    function _mint(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual returns (uint) {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(!tokenExist[id],'tokenId exist !');
        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] = amount;
        tokenExist[id] = true;
        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
        return id;
    }

    function BatchTransfer(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        for(uint i = 0;i < ids.length;i++){
            _safeTransferFrom(from, to, ids[i], amounts[i], data);
        }
        
    }
}