/**
 *Submitted for verification at polygonscan.com on 2022-12-23
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721Holder is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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


abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
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
        bytes calldata data
    ) external;
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);  
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


contract CosmicTreasury is ERC721Holder,ERC1155Holder {

    IERC20 public GameToken;
    IERC1155 public GameNft1155;
    IERC721 public GameNft721;

    bool public paused;

    mapping(address => bool) public _authorized; 
    address public owner;

    event transferOwnership(
        address from,
        address to
    );

    modifier onlyOwner() {
        require(msg.sender == owner,"Caller must Be Owner!");
        _;
    }

    modifier onlyAuthorized() {
        require(_authorized[msg.sender],"Caller must be Authorized!!");
        _;
    }

    constructor()  {
        _authorized[msg.sender] = true;
        owner = msg.sender;
    }

    function withdraw(address recipient,uint _value) external onlyAuthorized() {
        require(!paused,"Error: Withdraw is currently Unavailable!!");
        GameToken.transfer(recipient,_value);
    }

    function withdraw1155(address _recipient,uint256 _id,uint256 _amount) external onlyAuthorized() {
        require(!paused,"Error: Withdraw is currently Unavailable!!");
        GameNft1155.safeTransferFrom(address(this),_recipient,_id,_amount,"");
    }

    function withdraw721(address _recipient,uint256 _id) external onlyAuthorized() {
        require(!paused,"Error: Withdraw is currently Unavailable!!");
        GameNft721.safeTransferFrom(address(this),_recipient,_id);
    }

    //  ==============     Owner    ======================

    function rescueFunds() external onlyOwner() {
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(os);
    }

    function rescueToken(address _token,uint _value) external onlyOwner() {
        IERC20(_token).transfer(msg.sender,_value);
    }

    function rescueNftE721(address _collection,address _recipient,uint256 _id) external onlyOwner() {
        IERC721(_collection).safeTransferFrom(address(this),_recipient,_id);
    }

    function rescueNftE1155(address _collection,address _recipient,uint256 _id,uint256 _amount) external onlyOwner() {
        IERC1155(_collection).safeTransferFrom(address(this),_recipient,_id,_amount,"");
    }

    function setPauser(bool _status) external onlyOwner() {
        paused = _status;
    }
	
	function setToken(address _token) external onlyOwner() {
        GameToken = IERC20(_token);
    }

    function setNft1155(address _token) external onlyOwner() {
        GameNft1155 = IERC1155(_token);
    }

    function setNft721(address _token) external onlyOwner() {
        GameNft721 = IERC721(_token);
    }

    function setAuthorized(address _user, bool _status) external onlyOwner {
        require(_authorized[_user] != _status,"Error: Status must be changed!");
        _authorized[_user] = _status;
    }

    function transferControl(address _newOwner) external onlyOwner() {
        require(owner != _newOwner,"Error: Owner must be different!");
        address previous = owner;
        owner = _newOwner;
        emit transferOwnership(previous,owner);
    }

    receive() external payable {}

}