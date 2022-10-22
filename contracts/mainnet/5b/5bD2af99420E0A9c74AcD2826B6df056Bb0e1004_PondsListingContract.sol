// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "./IMasterContract.sol";
import "./IPondsNFT.sol";
import "./IPondsLicenseNFT.sol";

contract PondsListingContract{
    

    IMasterContract masterContract;
    IPondsNFT pondsNFT;
    IPondsLicenseNFT pondsLicenseNFT;
    mapping(uint256 => ListingDetails) public listingInfo;
    struct ListingDetails {
        uint256 id;
        string creativeCid;
        string licenseCid;
        uint256 creativeNFTTokenId;
        address owner;
        uint256 price;
        bool isExclusive;
        uint256 quantity;
        uint256 exclusivitySurcharge;
        bool isUnlimitedSupply;
        uint256 minted;
        bool saleClosed;
    }

    
    uint256 totalListing;
    event ListingUpdated(
        ListingDetails listingDetails
    );
    event LicenseIssued(
        uint256 licenseNFTTokenId,
        address licensee,
        string licenseCid
    );
    constructor(address _masterContract, address _pondsNFT, address _licenseNFT){
        masterContract = IMasterContract(_masterContract);
        pondsNFT = IPondsNFT(_pondsNFT);
        pondsLicenseNFT  = IPondsLicenseNFT(_licenseNFT);
    }
    function changeMasterContract(address _newMasterContract) external{
        masterContract = IMasterContract(_newMasterContract);
    }
    function changePondsNFTContract(address _newNFTContract) external{
        pondsNFT = IPondsNFT(_newNFTContract);
    }
    function changeLicenseContract(address _newLicenseContract) external{
        pondsLicenseNFT  = IPondsLicenseNFT(_newLicenseContract);
    }

    function createListing(string memory _listingCID, string memory _licenseCID, uint256 _price, bool _isExclusive, uint256 _quantity, uint256 _exclusivitySurcharge, bool _isUnlimitedSupply) external {
        require(masterContract.isRegistered(msg.sender),"You have to create creator profile first !");
        totalListing++;
        uint256 tokenId = pondsNFT.safeMint(msg.sender,_listingCID);
        ListingDetails memory _listingInfo = ListingDetails(totalListing, _listingCID, _licenseCID, tokenId, msg.sender, _price,  _isExclusive, _quantity, _exclusivitySurcharge, _isUnlimitedSupply, 0, false);
        listingInfo[totalListing] = _listingInfo;
        emit ListingUpdated(listingInfo[totalListing]);
    }
    
    function updateListing(uint256 _listingId, string memory _listingCID, string memory _licenseCID, uint256 _nftTokenId, uint256 _price, bool _isExclusive, uint256 _quantity, uint256 _exclusivitySurcharge, bool _isUnlimitedSupply) external {
        ListingDetails memory listing = listingInfo[_listingId];
        require(msg.sender == listing.owner,"You have to be listing's owner to be able to update listing !");
        require(pondsNFT.ownerOf(listing.creativeNFTTokenId) == listing.owner, "You have to hold the original creative NFT to be able to update listing !");
        
        ListingDetails memory _listingInfo = ListingDetails(totalListing, _listingCID, _licenseCID, _nftTokenId, msg.sender, _price,  _isExclusive, _quantity, _exclusivitySurcharge, _isUnlimitedSupply, 0, false);
        listingInfo[totalListing] = _listingInfo;
        emit ListingUpdated(listingInfo[totalListing]);
    }


    function license(uint256 _listingId) payable external{
        ListingDetails memory listing = listingInfo[_listingId];
        require(!listing.saleClosed, "You cannot license this creative");
        if(listing.isExclusive){
            require(listing.price + listing.exclusivitySurcharge <= msg.value, "Insufficient funds");
            listingInfo[_listingId].saleClosed = true;
        }else{
            require(listing.price <= msg.value, "Insufficient funds");
            if(!listing.isUnlimitedSupply){
                if(listing.minted == listing.quantity){
                    listingInfo[_listingId].saleClosed = true;
                }
            }
           listingInfo[_listingId].minted++;
        }
        require(pondsNFT.ownerOf(listing.creativeNFTTokenId) == listing.owner, "The owner no longer holding this creative's original NFT");
        uint256 licenseNFTTokenId = pondsLicenseNFT.safeMint(msg.sender, listing.licenseCid);
        emit LicenseIssued(licenseNFTTokenId, msg.sender, listing.licenseCid);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IMasterContract {
    function isRegistered(address _address) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IPondsNFT {
    function safeMint(address _to, string memory _tokenUri) external returns(uint256);
    function ownerOf(uint256 tokenId) external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IPondsLicenseNFT {
    function safeMint(address _to, string memory _tokenUri) external returns(uint256);
}