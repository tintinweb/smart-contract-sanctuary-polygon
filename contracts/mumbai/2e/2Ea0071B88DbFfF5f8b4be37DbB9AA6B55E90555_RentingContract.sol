/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Interface of an Lands ERC721 compliant contract.
 */
interface ILandsNftContract {

    function safeTransferFromForRent(address from, address to, uint256 tokenId, bytes memory _data) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(address from, address to, uint256 tokenId) external;
}

/**
 * @dev Interface of an Troopers ERC721 compliant contract.
 */
interface IBotsNftContract {

    function safeTransferFromForRent(address from, address to, uint256 tokenId, bytes memory _data) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IRentingContract {

    // TODO think how it will be expendable in case we will have storage in deifferent contract
    enum Coin {
        XOIL,
        RBLS,
        WETH,
        USDC
    }

    enum RentingType {
        FIXED_PRICE
    }

    struct RentingInfo {
        uint256 landId;
//        uint256[] botsIds;
        uint256 botsId1;
        uint256 botsId2;
        uint256 botsId3;
        uint256 listingTs;
        uint256 rentingTs;
        address landlord;
        address renter;
        RentingType rentingType;
    }

    struct ListingInfo {
        uint256 landId;
//        uint256[] botsIds;
        uint256 botsId1;
        uint256 botsId2;
        uint256 botsId3;
        uint256 listingTs;
        address owner;
        Coin chargeCoin;
        uint256 price;
        address[] whitelistedRenters;
    }

    struct CoinInfo {
        uint decimals;
        IERC20 erc20Contract;
    }
}

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract RentingContract is Context, IRentingContract {

    ILandsNftContract public landsContract;
    IBotsNftContract public botsContract;
    mapping(Coin => address) paymentContracts;

    mapping(uint256 => ListingInfo) private listingInfo;
    mapping(uint256 => RentingInfo) private rentingInfo;

    constructor(address landsContractAddress, address botsContractAddress, address xoilAddress, address rblsAddress) {
        landsContract = ILandsNftContract(landsContractAddress);
        botsContract = IBotsNftContract(botsContractAddress);
        paymentContracts[Coin.XOIL] = xoilAddress;
        paymentContracts[Coin.RBLS] = rblsAddress;
    }


    function listForRent(uint256 _landId, uint256[] memory _botIds, Coin _chargeCoin, uint256 _price) external {
        require(_botIds.length == 3, "Bots number should be 3");
        require(userOwnsRentBundle(_landId, _botIds, _msgSender()), "Sender is not an owner");
        require(listingInfo[_landId].listingTs == 0, "The provided land already listed");
        require(paymentContracts[_chargeCoin] != address(0), "Not supported payment coin");

        listingInfo[_landId] = ListingInfo({
        landId : _landId,
//        botsIds : _botIds,
        botsId1: _botIds[0],
        botsId2 : _botIds[1],
        botsId3: _botIds[2],
        listingTs : block.timestamp,
        owner : _msgSender(),
        chargeCoin : _chargeCoin,
        price : _price,
        whitelistedRenters : new address[](0)
        });
    }

    function cancelListing(uint256 landId) public {
        require(listingInfo[landId].listingTs != 0, "Land is not listed");

        delete listingInfo[landId];
    }


    function rentLand(uint256 landId) public {

    }

    function getListingInfo(uint256 landId) external view returns (ListingInfo memory) {
        ListingInfo memory li =  listingInfo[landId];
        require(li.listingTs != 0, "Listing not found");
        return li;
    }

    function getRentingInfo(uint256 landId) external view returns (RentingInfo memory){
        RentingInfo memory ri = rentingInfo[landId];
        require(ri.listingTs != 0, "Renting info not found");
        return ri;
    }

    //
    //
    //    function endListing(uint256 landId) external {
    //
    //    }
    //
    //    function completeEndedRentals() external {
    //
    //    }

    function userOwnsRentBundle(uint256 landId, uint256[] memory botIds, address owner) private view returns (bool) {
        if (landsContract.ownerOf(landId) != owner) {
            return false;
        }
        for (uint i = 0; i < 3; i++) {
            if (botsContract.ownerOf(botIds[i]) != owner) {
                return false;
            }
        }
        return true;
    }
}