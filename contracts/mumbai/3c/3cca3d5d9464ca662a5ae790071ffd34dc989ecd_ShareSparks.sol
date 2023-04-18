// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract ShareSparks is ERC20{

    uint256 private postFee = 1000000000000000 wei; //0.001 SPK

    mapping(address => string[]) private ownerToAddress;
    mapping(string => address) private ipfsAddressToAuthor;
    
    //defining the events
    event SetPostFee(address indexed from, uint256 newFee, uint256 oldFee);
    event GiveReward(address indexed to, uint256 value);

    // function to map the IPFS hash address of the content with the user's address
    function addIpfsHash(string memory _ipfsHash) external {
        require(balanceOf(msg.sender) >= postFee, "Insufficient Token balance to post");
        _transfer(msg.sender,address(this),postFee);
        ownerToAddress[msg.sender].push(_ipfsHash);
        ipfsAddressToAuthor[_ipfsHash] = (msg.sender);
    }

    // only owner functions
    // function to give rewards to the users
    function giveReward(address to, uint value) external onlyOwner {
        require(balanceOf(address(this)) >= value, "Contract's balance is insufficient to give rewards");
        _transfer(address(this), to, value);
        emit GiveReward(to, value);
    }

    // function to update the post fees
    function setPostFee(uint _newFee) external onlyOwner {
        require(_newFee > 0, "Fee not be zero and less than Zero!");
        uint256 oldPostFee = postFee;
        postFee = _newFee;
        emit SetPostFee(getOwner(), _newFee, oldPostFee);
    }

    // call(read) functions
    // function to get the users' content's IPFS hashes
    function getIpfsHashes(address _userAddress) public view returns (string[] memory) {
        return ownerToAddress[_userAddress];
    }

    // function to get the contents' IPFS addresses of an address 
    function getIpfsAuthor(string memory _ipfsAddress) public view returns (address) {
        return ipfsAddressToAuthor[_ipfsAddress];
    }

    // function to read the post fees
    function getPostFee() external view returns (uint256) {
        return postFee;
    }

}