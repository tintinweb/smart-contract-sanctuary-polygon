// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./ERC721.sol";
import "./Ownable.sol";

contract HERC721 is ERC721, Ownable {
    string public baseURI;
    mapping(uint => string) public lockUri;
    mapping(address => bool) public minters;
    mapping(uint256 => bool) tokenExist;
    event Minter(address _m, bool _o);
    event SetURI(uint _id, string _ipfs);

    constructor(
        string memory name_,
        string memory symbol_,
        address minter_,
        string memory base_
    ) ERC721(name_, symbol_) {
        setMinter(minter_, true);
        setBase(base_);
    }

    function setBase(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function exist(uint _id) external view returns (bool) {
        return tokenExist[_id];
    }

    function setMinter(address _minter, bool _open) public onlyOwner {
        minters[_minter] = _open;
        emit Minter(_minter, _open);
    }

    function setURI(uint _id, string memory _ipfs) public {
        require(
            ownerOf(_id) == msg.sender && bytes(lockUri[_id]).length < 1,
            "403"
        );
        lockUri[_id] = _ipfs;
        emit SetURI(_id, _ipfs);
    }

    function strConcat(
        string memory _a,
        string memory _b
    ) public pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        uint i;
        for (i = 0; i < _ba.length; i++) bret[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (bytes(lockUri[tokenId]).length > 0) {
            return lockUri[tokenId];
        } else {
            string memory lastAddress = Strings.toHexString(
                uint160(address(this)),
                20
            );
            lastAddress = strConcat(lastAddress, "/");
            lastAddress = strConcat(lastAddress, Strings.toString(tokenId));
            return strConcat(baseURI, lastAddress);
        }
    }

    function mint(
        address from,
        address to,
        uint _tokenID,
        bytes memory data
    ) public virtual returns (uint) {
        require(minters[msg.sender], "ERROR 403");
        return _mint(from, to, _tokenID, data);
    }

    function BatchMint(
        address[] memory from,
        address[] memory to,
        uint[] memory _tokenID,
        bytes[] memory data
    ) public virtual {
        require(minters[msg.sender], "Not Minter");
        require(from.length == to.length);
        require(to.length == _tokenID.length);
        for (uint i = 0; i < from.length; i++) {
            _mint(from[i], to[i], _tokenID[i], data[i]);
        }
    }

    function _mint(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual returns (uint) {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        require(data.length > 0, "lenght < 0");
        _beforeTokenTransfer(from, to, tokenId, 1);

        _balances[to] += 1;
        _owners[tokenId] = to;
        tokenExist[tokenId] = true;
        emit Transfer(from, to, tokenId);
        return tokenId;
    }
}