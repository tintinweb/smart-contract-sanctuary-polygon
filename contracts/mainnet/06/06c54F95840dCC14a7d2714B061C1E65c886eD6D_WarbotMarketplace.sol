/**
 *Submitted for verification at polygonscan.com on 2022-02-13
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/


pragma solidity ^0.8.4;

// SPDX-License-Identifier: UNLICENSED



interface ERC20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface EngineEcosystemContract{
    function isEngineContract( address _address ) external returns (bool);
    function returnAddress ( string memory _contractName ) external returns ( address );
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
     function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}



/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


interface WarbotManufacturer{
    
     struct Location {
        int256 x;
        int256 y;
        int256 z;
    }
    
    function ownerOf ( uint256 _tokenid ) external returns ( address );
    function setFuturesOnPlant ( uint256 _plant, uint256 _period , bool _switch ) external;
    function getPlantFuturesInfo ( uint256 _plant, uint256 _period ) external view returns ( address, bool, uint256 ) ;
    function manufacture ( uint256 _plant ) external ;
    function returnFuturesTokenID ( uint256 _plant, uint256 _period, uint256 _position ) external returns (uint256);
    function transferFrom ( address _from, address _to, uint256 _tokenId ) external;
    function getManufacturerCertificate ( uint256 _tokenId ) external returns ( uint256, uint256, uint256, Location memory, uint256 );
    function setApprovalForAll ( address _spender, bool _approved ) external;
    function approve ( address _address, uint256 _tokenId ) external;
}




contract WarbotMarketplace is Ownable  {

    bytes4 ERC721_RECEIVED = 0x150b7a02;
    address public WarbotManufacturerAddress;
    WarbotManufacturer public _wm;
    address payable public teamWallet;
    EngineEcosystemContract public _ec;
    uint256 public commissionAmount;  // percentage with 1000 as the denominator
    address payable public commAddress;
    uint256 public totalMaticFromOffers;
    uint256 public totalSales;
    uint256 public ListingCount;
    mapping ( uint256 => Listing ) public Listings;
    mapping ( uint256 => uint256 ) public WarbotListingId;
    
   

    struct Listing {
        address payable _owner;
        uint256  _warbotid;
        uint256  _askingpriceinmatic;
        uint256  _minimumconsideration;
        uint8    _status;  // 0 = open , 1  = canceled, 2 = sold
    }

    uint256 public offerCount;
    mapping ( uint256 => Offer ) public Offers;

    mapping ( address => uint256 ) public userOfferCount;
    mapping ( address => uint256[] ) public userOffers;

    mapping ( address => uint256 ) public userListingCount;
    mapping ( address => uint256[] ) public userListings;
   
    

    struct Offer {
        address payable _offerby;
        uint256 _listingid;
        uint256 _amountinmatic;
        uint256 _expiration;
        uint256 _status;
    }

    event OfferMade ( address indexed _offerer,uint256 indexed _warbotid, uint256 _amount );
    event NewListing ( address indexed _owner, uint256 indexed _warbotid, uint256 _minimumconsideration, uint256 _asking );
    event OfferAccepted ( address indexed _seller, address indexed _buyer, uint256 indexed _warbotid, uint256 _amount );
    event PurchaseAtAsking ( address indexed _seller, address indexed _buyer, uint256 indexed _warbotid, uint256 _amount );


    constructor( address _engineecosystem) {

        _ec = EngineEcosystemContract ( _engineecosystem );
        WarbotManufacturerAddress = _ec.returnAddress("WarbotManufacturer");
        _wm = WarbotManufacturer ( WarbotManufacturerAddress);

        commAddress = payable(msg.sender);
        commissionAmount = 50; // 50 = 5 %
        teamWallet = payable(msg.sender);
    }

    function onERC721Received( address _operator, address _from, uint256 _tokenId, bytes memory _data) public view returns(bytes4){
        _operator; _from; _tokenId; _data;
        return ERC721_RECEIVED;
    }

    function listWarbot ( uint256 _warbotid, uint256 _askingpriceinmatic, uint256 _minimumconsideration ) public {

        require ( msg.sender == _wm.ownerOf( _warbotid) , "Not the owner" );
        require ( _askingpriceinmatic > 0 , "Non zero value only " ) ;
        ListingCount++;
        Listings[ListingCount]._owner = payable(msg.sender);
        Listings[ListingCount]._warbotid = _warbotid;
        Listings[ListingCount]._askingpriceinmatic = _askingpriceinmatic;
        Listings[ListingCount]._minimumconsideration = _minimumconsideration;

        WarbotListingId[_warbotid] = ListingCount;
        userListingCount[msg.sender]++;
        userListings[msg.sender].push(ListingCount);
        emit NewListing ( msg.sender, _warbotid, _minimumconsideration, _askingpriceinmatic );
    }

    function getWarbotListingOwner ( uint256 _warbotid ) public view returns ( address ) {
        return Listings[WarbotListingId[_warbotid]]._owner;
    }


    function cancelWarbotListing ( uint256 _warbotid ) public {
        require ( getWarbotListingOwner(_warbotid ) == msg.sender, "Not Listings owner");
        require (Listings[WarbotListingId[_warbotid]]._status == 0, "Listing Closed" );
        Listings[WarbotListingId[_warbotid]]._status = 1;
    }

    function updateWarbotAskingPrice ( uint256 _warbotid, uint256 _askingpriceinmatic ) public {
        require ( getWarbotListingOwner(_warbotid ) == msg.sender, "Not Listings owner");
        require (Listings[WarbotListingId[_warbotid]]._status == 0, "Listing Closed" );
        Listings[WarbotListingId[_warbotid]]._askingpriceinmatic = _askingpriceinmatic;

    }

    function updateWarbotMinimumConsideration ( uint256 _warbotid, uint256 _minimumconsideration ) public {
        require ( getWarbotListingOwner(_warbotid ) == msg.sender, "Not Listings owner");
        require (Listings[WarbotListingId[_warbotid]]._status == 0, "Listing Closed" );
        Listings[WarbotListingId[_warbotid]]._minimumconsideration = _minimumconsideration;
    }

    function saleTransfers (  address payable _seller, uint256 _amount ) internal {
        uint256 _commAmount = (_amount * commissionAmount )/1000;
        uint256 _nettoSeller = _amount - _commAmount;

        commAddress.transfer( _commAmount );
        _seller.transfer( _nettoSeller );

    }

    function buyAtAsking ( uint256 _warbotid ) public payable {
        uint256 _price =  Listings[WarbotListingId[_warbotid]]._askingpriceinmatic;
        require ( msg.value == _price );
        totalSales += _price;

        Listings[WarbotListingId[_warbotid]]._status = 2;
        _wm.transferFrom ( Listings[WarbotListingId[_warbotid]]._owner, address(this), _warbotid );
        _wm.transferFrom ( address(this), msg.sender,  _warbotid );

        saleTransfers ( Listings[WarbotListingId[_warbotid]]._owner, _price );
        emit PurchaseAtAsking (  Listings[WarbotListingId[_warbotid]]._owner, msg.sender, _warbotid, _price );

    }

    function acceptOffer ( uint256 _offerid ) public  {
        require ( Offers[_offerid]._status == 0 , "Offer not available" );
        require ( block.timestamp  <  Offers[_offerid]._expiration   , "Offer expired" );
        uint256 _price =  Offers[_offerid]._amountinmatic;
        uint256 _listingid = Offers[_offerid]._listingid;
        address _offerer = Offers[_offerid]._offerby;
        Listings[_listingid]._status = 2;
        Offers[_offerid]._status = 2;
        require ( Listings[_listingid]._owner == msg.sender );
        totalMaticFromOffers -= _price;
        totalSales += _price;

        _wm.transferFrom ( msg.sender, address(this), Listings[_listingid]._warbotid );
        _wm.transferFrom ( address(this), _offerer,  Listings[_listingid]._warbotid );

        saleTransfers ( Listings[_listingid]._owner, _price );
        emit OfferAccepted (  msg.sender, _offerer, Listings[_listingid]._warbotid, _price );

    }

    function setCommission ( uint256 _comm ) public onlyOwner {

        commissionAmount = _comm;
    }

    function setCommAddress ( address payable _address ) public onlyOwner {
        commAddress = _address;
    }

    function makeOffer ( uint256 _warbotid, uint256 _offerinmatic, uint256 _days ) public payable {
        require ( msg.value == _offerinmatic, "Please sumbit offer amount");
        offerCount++;
        totalMaticFromOffers += msg.value;
        uint256 _listingid =  WarbotListingId[_warbotid];
        uint256 _minimumconsideration = Listings[_listingid]._minimumconsideration;
        require ( _offerinmatic >= _minimumconsideration , "Offer not high enough" );
        Offers[offerCount]._offerby = payable(msg.sender);
        Offers[offerCount]._listingid = _listingid;
        Offers[offerCount]._amountinmatic = _offerinmatic;
        Offers[offerCount]._expiration = block.timestamp + ( _days * 1 days );
        userOfferCount[msg.sender]++;
        userOffers[msg.sender].push(offerCount);
        emit OfferMade ( msg.sender, _warbotid, _offerinmatic );
    }

    function cancelOffer ( uint256 _offerid ) public {
        require (Offers[_offerid]._offerby == msg.sender, "Not Offer owner");
        require (Offers[_offerid]._status == 0 , "Offer already closed");
        uint256 _offeramount =  Offers[_offerid]._amountinmatic;
        totalMaticFromOffers -=_offeramount;
        Offers[_offerid]._status = 1;
        Offers[_offerid]._offerby.transfer( _offeramount );

    }

    function updateOffer ( uint256 _offerid, uint256 _amountinmatic ) public {
        require (Offers[_offerid]._offerby == msg.sender, "Not Offer owner");
        require (Offers[_offerid]._status == 0, "Offer not active" );
        require (Offers[_offerid]._amountinmatic > _amountinmatic, "Offer can't be greater than previous");

        uint256 _delta = Offers[_offerid]._amountinmatic - _amountinmatic;
        Offers[_offerid]._amountinmatic = _amountinmatic;
        Offers[_offerid]._offerby.transfer( _delta );
        totalMaticFromOffers -=_delta;
    }



    function setEngineEcosystmAddress( address _engineecosystem ) public onlyOwner {
         _ec = EngineEcosystemContract ( _engineecosystem );
        WarbotManufacturerAddress = _ec.returnAddress("WarbotManufacturer");
        _wm = WarbotManufacturer ( WarbotManufacturerAddress);

    }




    function approve ( address _token, address _spender, uint256 _amount ) public onlyOwner {
        ERC20 _erc20 = ERC20 ( _token );
        _erc20.approve ( _spender, _amount );
    }


    function withdrawMatic () public onlyOwner {
        payable(teamWallet).transfer( address(this).balance );
    }



    function setTeamWallet ( address payable _address ) public onlyOwner {
        teamWallet = _address;
    }

    function emergencyWithdrawal ( address _tokenaddress) public onlyOwner {
        ERC20 _erc20 = ERC20 ( _tokenaddress );
        uint256 _balance = _erc20.balanceOf( address(this));
        _erc20.transfer ( teamWallet , _balance );
    }


}