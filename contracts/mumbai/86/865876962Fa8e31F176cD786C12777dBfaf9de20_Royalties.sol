// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./userRoyalties.sol";

contract Royalties is Ownable{
    mapping(uint=>userRoyalties) scAddress;
    mapping(address=>bool) adminList;
    mapping(uint=>userRoyalties[]) scHistory;
    mapping(uint=>uint) royaltiesCreationDate;

    modifier isAdmin() {
        require(adminList[msg.sender],string("Only Admin"));
        _;
    }

    function addAdmin(address _address) public onlyOwner {
        require(!adminList[_address],string("Already in the admin list"));
        adminList[_address]=true;
    }
    function delAdmin(address _address) public onlyOwner {
        require(adminList[_address],string("Address is not in admin list"));
        adminList[_address]=false;
    }
    function createRoyalties(address[] calldata _addresses, uint[] calldata _royalties, uint tokenId) external isAdmin {
        require(_addresses.length==_royalties.length,string("Addresses and Royalties must have the same quantity"));        
        uint _totalRoyalties;
        for (uint i=0; i<_royalties.length; i++) {
            _totalRoyalties=_totalRoyalties+_royalties[i];
        }     
        require(_totalRoyalties<=10,string("Royalties must be <= 10"));
        userRoyalties userroyalties = new userRoyalties(_addresses,_royalties);
        scAddress[tokenId] = userroyalties;
        scHistory[tokenId].push(userroyalties);
        royaltiesCreationDate[tokenId] = block.timestamp;
    }

    function getRoyalties(uint tokenId) external view returns(uint[] memory, address[] memory) {
        uint[] memory _scRoyalties = scAddress[tokenId].showRoyalties();
        address[] memory _scRoyaltiesAddresses = scAddress[tokenId].showRoyaltiesAddress();
        return (_scRoyalties,_scRoyaltiesAddresses);
    }
    
    function getRoyaltiesAddress(uint tokenId) external view returns(userRoyalties) {
        return scAddress[tokenId];
    }

    function getHistory(uint tokenId) external view returns(userRoyalties[] memory) {
        return scHistory[tokenId];
    }

    function getRoyaltiesCreationDate(uint tokenId) external view returns(uint) {
        return royaltiesCreationDate[tokenId];
    }
}