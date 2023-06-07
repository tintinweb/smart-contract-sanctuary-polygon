// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

/**
 * @title IOwnable:
 *
 * @author Farasat Ali
 *
 * @notice This is an interface which will be implemented to provide  contract
 * ownership to the deployer with the facility to transfer ownership.
 */
interface IOwnable {
    /**
     * @notice implement to get the address of the owner.
     *
     * @return owner returns owner of the contract.
     */
    function getOwner() external returns (address owner);

    /**
     * @notice implement to transfer the ownership of the contract.
     *
     * @param newOwner address of the new owner.
     */
    function transferOwnership(address newOwner) external;

    /**
     * @notice implement to give up the ownership of the contract.
     */
    function renounceOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

//interface
import "./interfaces/IOwnable.sol";
// library
import "../utils/NotAvailableForOperationLib.sol";

/**
 * @title Ownable:
 *
 * @author Farasat Ali.
 *
 * @notice this implementation is to make give contract ownership to the
 * deployer with the facility to transfer and revoke ownership.
 */

contract Ownable is IOwnable {
    // ============================================================= //
    //                          VARIABLES                            //
    // ============================================================= //

    // it is the address which is stored when the contract is deployed
    address internal _owner;

    // ============================================================= //
    //                          EVENTS                               //
    // ============================================================= //

    /**
     * @notice emitted when a contract ownership is transferred from an
     * old address to new address.
     *
     * @param oldOwner previous owner of the contract.
     * @param newOwner new owner of the contract.
     * @param when when transfer is happend.
     */
    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner,
        uint256 indexed when
    );

    // ============================================================= //
    //                          MODIFIERS                            //
    // ============================================================= //

    /**
     * @notice to check if the function is being called by owner if `true`
     * then allow the function to continue else raise exception. compares the
     * stored owner address with the address of sender and raise exception if
     * both are not equal contract.
     *
     * Requirements:
     *       ‼ caller should be the owner.
     *
     */
    modifier onlyOwner() {
        if (_owner != msg.sender)
            revert NotAvailableForOperationLib.NotAvailableForOperation(20);
        _;
    }

    /**
     * @notice to check for the address passed. It compares the incoming
     * address (msg.sender) with the 0x0000000000000000000000000000000000000000
     * and if matched then the transaction is reverted with error containing
     * the passed string.
     *
     * Requirements:
     *       ‼ provided address should not be invalid.
     *
     */
    modifier checkForInvalidAddress(address newOwner) {
        if (newOwner == address(0))
            revert NotAvailableForOperationLib.NotAvailableForOperation(21);
        _;
    }

    // ============================================================= //
    //                          CONSTRUCTOR                          //
    // ============================================================= //

    /**
     * @notice calls the _transferOwnership function and sets the
     * deployer (msg.sender) which sets the private variable private
     * owner with the deployer's address.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    // ============================================================= //
    //                          METHODS                              //
    // ============================================================= //

    /**
     * @notice updates or changes the address of old owner within the
     * contract with the incoming address (msg.sender).
     *
     * emit the `OwnershipTransferred` event when successful.
     *
     * @param newOwner address to which ownership of this contract will be transferred.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, _owner, block.timestamp);
    }

    /**
     * @notice returns the address of the owner stored in the private
     * owner variable.
     *
     * @return owner address of owner stored
     */
    function getOwner() external view override returns (address) {
        return _owner;
    }

    /**
     * @notice changes the address of old owner within the contract and
     * with the incoming address (msg.sender) by calling the internal
     * transferOwnership.
     *
     * emit the `OwnershipTransferred` event when successful.
     *
     * Requirements:
     *       ‼ caller of the function should be the current owner.
     *       ‼ the address to which ownership is being transferred should be a valid address or a non-zero address.
     *
     * @param newOwner address to which ownership of this contract will be transferred.
     *
     */
    function transferOwnership(
        address newOwner
    ) external override onlyOwner checkForInvalidAddress(newOwner) {
        _transferOwnership(newOwner);
    }

    /**
     * @notice it lets owner give up their ownership and leave contract without
     * by calling internal _transferOwnership with a 0 address.
     *
     * emit the `OwnershipTransferred` event when successful.
     *
     * Requirements:
     *       ‼ caller of the function should be the current owner of the contract.
     */
    function renounceOwnership() external override onlyOwner {
        _transferOwnership(address(0));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

// interfaces
import "./interfaces/IERC1155Dao.sol";
// contracts
import "../access/Ownable.sol";
import "../security/Pausable.sol";
import "../extensions/Auction.sol";
// library
import "../utils/NotAvailableForOperationLib.sol";

/**
 * @title ERC1155Dao:
 *
 * @author Farasat Ali
 *
 * @notice Inherits the ERC1155 contract and provide functionality for lending/borrowing,
 * transfering, minting, bidding.
 */
contract ERC1155Dao is IERC1155Dao, Ownable, Pausable, Auction {
    // ============================================================= //
    //                          VARIABLES                            //
    // ============================================================= //

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/
    string private _baseURI;

    // contains the track total amount of wei in the contract.
    uint256 private _totalAmount;

    // contains the track of platform fees in wei.
    uint256 private _platformFeesInWei = 10 ^ 5;

    // returns the TokenBearer struct when token id and serial number is provided.
    mapping(uint256 tokenId => mapping(uint256 serialNo => TokenBearer tokenBearer))
        private _tokenBearer;

    // Mapping from token ID to account balances
    mapping(uint256 tokenId => mapping(address user => uint256 balance))
        private _balances;

    // returns the TokenDetails struct when token id is provided.
    mapping(uint256 tokenId => TokenDetails tokenDetails) private _tokenDetails;

    // returns the token metadata id
    mapping(uint256 tokenId => string id) private _tokenMetadataId;

    // ============================================================= //
    //                          EVENTS                               //
    // ============================================================= //

    /**
     * @notice It is emitted when tokens are transferred from one user to another or from
     * contract to a user
     *
     * Signature for Transfer(address,address,uint256,uint256) : `0x7b912cc6`
     *
     * @param from         owner of the token whose balance is decreased. In this case, it can be the `user` or the `current contract`.
     * @param to           receiver of the token whose balance is increased. In this case, it will be the `user`.
     * @param tokenId      Id of the token being transferred.
     * @param serialNo     serial number of token assigned to that token.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId,
        uint256 serialNo
    );

    /**
     * @notice event to be emitted when single id of tokens are minted
     *
     * Signature for Mint(address,address,uint256,uint256,uint104,uint32,uint48) : `0x36fdad7e`
     *
     * @param tokenId           id of the token being transferred.
     */
    event Mint(uint256 indexed tokenId);

    /**
     * @notice event to be emitted when token is listed or unlisted for the auction.
     *
     * Signature for AuctionState(string,uint256,uint256,uint256,address,uint256,bool) : `0x723e8b47`
     *
     * @param tokenId           id of the token being put into or pull out from an auction.
     * @param serialNo          serial number of that particular token.
     * @param isStarted         tells the status whether auction started or ended. `true` if started and `false` if ended.
     * @param startingPrice     starting price of the auction.
     * @param when              when this auction took place.
     */
    event AuctionState(
        uint256 indexed tokenId,
        uint256 indexed serialNo,
        bool indexed isStarted,
        uint256 startingPrice,
        uint256 when
    );

    /**
     * @notice event to be emitted when token is listed or unlisted for the fixed price sale.
     *
     * Signature for Listing(uint256,uint256,bool,uint256) : `0x358dcf82`
     *
     * @param tokenId           id of the token being listed.
     * @param serialNo          serial number of that particular token.
     * @param isListed          tells the status whether listing started or ended. `true` if started and `false` if ended.
     * @param price             price to sell.
     * @param when              when this linsting took place.
     */
    event Listing(
        uint256 indexed tokenId,
        uint256 indexed serialNo,
        bool indexed isListed,
        uint256 price,
        uint256 when
    );

    /**
     * @notice event to be emitted when token is activated for usage.
     *
     * Signature for TokenActivate(uint256,uint256,uint256) : `0xb72cde7c`
     *
     * @param tokenId       id of the token being activated.
     * @param serialNo      serial number of the token.
     * @param when          when token is activated for the usage.
     */
    event TokenActivate(
        uint256 indexed tokenId,
        uint256 indexed serialNo,
        uint256 indexed when
    );

    /**
     * @notice event to be emitted when token is listed for lending.
     *
     * Signature for Lending(uint256,uint256,bool,uint256) : `0x0e6ac7ef`
     *
     * @param tokenId               id of the token being lended.
     * @param serialNo              serial number of the token.
     * @param isLendingEnabled      tells the status whether lending is enabled or disabled.
     * @param pricePerDay           per day prce for lending.
     * @param when                  when token is listed for the lending.
     */
    event Lending(
        uint256 indexed tokenId,
        uint256 indexed serialNo,
        bool indexed isLendingEnabled,
        uint256 pricePerDay,
        uint256 when
    );

    /**
     * @notice event to be emitted when token is borowed.
     *
     * Signature for Borrow(uint256,uint256,uint256) : `0xd67bffb1`
     *
     * @param tokenId           id of the token.
     * @param serialNo          serial number of the token.
     * @param price             price of borrow.
     * @param day               number of days to borrow.
     * @param when              when token is borrowed.
     */
    event Borrow(
        uint256 indexed tokenId,
        uint256 indexed serialNo,
        uint256 indexed price,
        uint256 day,
        uint256 when
    );

    // ============================================================= //
    //                          CONSTRUCTOR                          //
    // ============================================================= //

    /**
     * @notice Inherits ERC1155 contract and sets initial Base URI also inherits Ownable, Pausable and Auction Contracts.
     *
     * @param initialBaseUri    initial base uri for the token
     */
    constructor(string memory initialBaseUri) Ownable() Pausable() Auction() {
        _setURI(initialBaseUri);
    }

    // ============================================================= //
    //                          METHODS                              //
    // ============================================================= //

    /**
     * @notice Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     *
     * Signature for _setURI(string) : `0xf392d4f5`
     *
     * @param newUri    URI to be setted
     */
    function _setURI(string memory newUri) private {
        _baseURI = newUri;
    }

    /**
     * @notice checks if token is not expired
     *
     * Signature for _checkforExpired(uint256,uint256,uint256,uint256) : `0xa4036328`
     *
     * @param startOfLife    token starting life after activation.
     * @param expireOn       token expiry.
     * @param period         time to be added.
     * @param endOfLife      time after which token will be expired after activation.
     */
    function _checkforExpired(
        uint256 startOfLife,
        uint256 expireOn,
        uint256 period,
        uint256 endOfLife
    ) private view {
        if (startOfLife == 0 && block.timestamp > expireOn)
            revert NotAvailableForOperationLib.NotAvailableForOperation(4);
        if (startOfLife != 0 && block.timestamp + period > endOfLife)
            revert NotAvailableForOperationLib.NotAvailableForOperation(5);
    }

    /**
     * @notice returns the calculated price
     *
     * Signature for _getPrice(uint256,uint256,uint256,uint256) : `0x4bc8bdbd`
     *
     * @param tokenPrice     token price.
     * @param startOfLife    token starting life after activation.
     * @param endOfLife      time after which token will be expired after activation.
     * @param modify         modifier of the value.
     */
    function _getPrice(
        uint256 tokenPrice,
        uint256 startOfLife,
        uint256 endOfLife,
        uint256 modify
    ) private pure returns (uint256) {
        unchecked {
            if (startOfLife == 0) {
                return (tokenPrice / 100) * modify;
            } else {
                return
                    ((tokenPrice / 100) *
                        modify *
                        ((startOfLife * 100) / endOfLife)) / 100;
            }
        }
    }

    /**
     * @notice change the contract state to paused by setting the private
     * paused variable to true.
     *
     * emits the PauseState event with true and latest block timestamp.
     *
     * Requirements
     *       ‼ should not be already in paused state.
     *       ‼ caller must be the owner.
     *
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice change the contract state to unpaused by setting the private
     * paused variable to false.
     *
     * emits the PauseState event with false and latest block timestamp.
     *
     * Requirements
     *       ‼ should not be already in unpaused state.
     *       ‼ caller must be the owner.
     *
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice mints the token.
     *
     * emits the Mint event.
     *
     * Requirements:
     *      ‼ token with `tokenId` must not be already minted.
     *      ‼ contract should not be paused.
     *
     * Signature for mint(string,uint256,uint104,uint32,uint48) : `0x3e9047b9`
     *
     * @param tokenId               id of the token.
     * @param metadataId            metadata id of the token.
     * @param amount                amount of the tokens per id.
     * @param price                 price of each token.
     * @param expectedUsageLife     expected usage life of the token.
     * @param expiry                expiry of the token.
     */
    function mint(
        uint256 tokenId,
        string memory metadataId,
        uint256 amount,
        uint104 price,
        uint32 expectedUsageLife,
        uint48 expiry
    ) external whenNotPaused {
        if (_tokenDetails[tokenId].isMinted)
            revert NotAvailableForOperationLib.NotAvailableForOperation(19);

        unchecked {
            _balances[tokenId][address(this)] = amount;

            _tokenDetails[tokenId] = TokenDetails({
                totalSupply: amount,
                tokenPrice: price,
                expectedUsageLife: expectedUsageLife,
                isMinted: true,
                expireOn: expiry
            });

            _tokenMetadataId[tokenId] = metadataId;
        }

        emit Mint(tokenId);
    }

    /**
     * @notice allows buyer to buy a token from the contract.
     *
     * emits the Transfer event.
     *
     * Requirements:
     *      ‼ address of `buyer` must not be the 0 address.
     *      ‼ contract should not be paused.
     *      ‼ contract must have tokens with `tokenId` available.
     *      ‼ token with `tokenId` must not be expired.
     *
     * Signature for buyFromContract(address,string) : `0x02e5dae1`
     *
     * @param buyer         address of the buyer.
     * @param tokenId       id of the token being bought from the contract.
     */
    function buyFromContract(
        address buyer,
        uint256 tokenId
    ) external payable whenNotPaused checkForInvalidAddress(buyer) {
        uint256 serialNo = _balances[tokenId][address(this)];

        TokenDetails memory tokenDets = _tokenDetails[tokenId];

        if (serialNo == 0)
            revert NotAvailableForOperationLib.NotAvailableForOperation(6);
        if (block.timestamp > tokenDets.expireOn)
            revert NotAvailableForOperationLib.NotAvailableForOperation(4);
        if (msg.value < tokenDets.tokenPrice)
            revert NotAvailableForOperationLib.NotAvailableForOperation(6);

        unchecked {
            _balances[tokenId][address(this)] = serialNo - 1;
            _balances[tokenId][buyer] += 1;
            _totalAmount += msg.value;
        }

        _tokenBearer[tokenId][serialNo].user = buyer;

        emit Transfer(address(this), buyer, tokenId, serialNo);
    }

    /**
     * @notice allows token owner to list their token for a fixed price.
     *
     * emits the Listing event.
     *
     * Requirements:
     *      ‼ contract should not be paused.
     *      ‼ caller must be the owner of the the token `tokenId + serialNo`.
     *      ‼ token with `tokenId + serialNo` must not be in lending state.
     *      ‼ token with `tokenId + serialNo` must not be in auction state.
     *      ‼ token with `tokenId` must not be expired if token is not activated till that time.
     *      ‼ activated token with `tokenId + serialNo` must not be expired.
     *      ‼ `amount` should be within a given range.
     *
     * Signature for listTokenForFixedPrice(string,uint256,uint104) : `0x16b35050`
     *
     * @param tokenId       id of the token being listed for fixed price.
     * @param serialNo      serial Number of the token.
     * @param amount        amount for which token is to be listed.
     */
    function listTokenForFixedPrice(
        uint256 tokenId,
        uint256 serialNo,
        uint104 amount
    ) external whenNotPaused {
        TokenBearer memory tokenOwner = _tokenBearer[tokenId][serialNo];

        if (tokenOwner.user != msg.sender)
            revert NotAvailableForOperationLib.NotAvailableForOperation(1);
        if (tokenOwner.lendingStatus)
            revert NotAvailableForOperationLib.NotAvailableForOperation(3);
        if (tokenOwner.fixedOrAuction != 0)
            revert NotAvailableForOperationLib.NotAvailableForOperation(15);

        TokenDetails memory tokenDet = _tokenDetails[tokenId];

        _checkforExpired(
            tokenOwner.startOfLife,
            tokenDet.expireOn,
            0,
            tokenOwner.endOfLife
        );

        uint256 fixedPrice = _getPrice(
            tokenDet.tokenPrice,
            tokenOwner.startOfLife,
            tokenOwner.endOfLife,
            95
        );

        uint256 fixedPriceFloor;
        uint256 fixedPriceCeil;

        unchecked {
            (fixedPriceFloor, fixedPriceCeil) = (
                fixedPrice / 1000 + _platformFeesInWei,
                fixedPrice / 10 + _platformFeesInWei
            );
        }

        if (amount < fixedPriceFloor && amount > fixedPriceCeil)
            revert NotAvailableForOperationLib.NotAvailableForOperation(6);

        _tokenBearer[tokenId][serialNo] = TokenBearer({
            user: tokenOwner.user,
            startOfLife: tokenOwner.startOfLife,
            endOfLife: tokenOwner.endOfLife,
            borrower: address(0),
            lendingStartTimestamp: 0,
            borrowingStartTimestamp: 0,
            bidStartingPrice: 0,
            biddingLife: 0,
            listingPrice: amount,
            lendingStatus: false,
            lendingPeriod: 0,
            borrowingPeriod: 0,
            lendingPricePerDay: 0,
            fixedOrAuction: 1,
            isActivated: tokenOwner.isActivated
        });

        emit Listing(tokenId, serialNo, true, amount, block.timestamp);
    }

    /**
     * @notice allows token owner to change their listing price for fixed price.
     *
     * emits the Listing event.
     *
     * Requirements:
     *      ‼ contract should not be paused.
     *      ‼ caller must be the owner of the the token `tokenId + serialNo`.
     *      ‼ token with `tokenId + serialNo` must be listed.
     *      ‼ `amount` should be within a given range.
     *
     * Signature for changeListingForFixedPrice(string,uint256,uint104) : `0x7f9e5134`
     *
     * @param tokenId       id of the token being listed for fixed price.
     * @param serialNo      serial Number of the token.
     * @param amount        amount for which token is to be listed.
     */
    function changeListingForFixedPrice(
        uint256 tokenId,
        uint256 serialNo,
        uint104 amount
    ) external whenNotPaused {
        TokenBearer memory tokenOwner = _tokenBearer[tokenId][serialNo];

        if (tokenOwner.user != msg.sender)
            revert NotAvailableForOperationLib.NotAvailableForOperation(1);
        if (tokenOwner.fixedOrAuction != 1)
            revert NotAvailableForOperationLib.NotAvailableForOperation(17);

        TokenDetails memory tokenDet = _tokenDetails[tokenId];

        uint256 fixedPrice = _getPrice(
            tokenDet.tokenPrice,
            tokenOwner.startOfLife,
            tokenOwner.endOfLife,
            95
        );

        uint256 fixedPriceFloor;
        uint256 fixedPriceCeil;

        unchecked {
            (fixedPriceFloor, fixedPriceCeil) = (
                fixedPrice / 1000,
                fixedPrice / 10
            );
        }

        uint104 newAmount = uint104(amount + tokenOwner.listingPrice);

        if (amount < fixedPriceFloor && amount > fixedPriceCeil)
            revert NotAvailableForOperationLib.NotAvailableForOperation(6);

        _tokenBearer[tokenId][serialNo] = TokenBearer({
            user: tokenOwner.user,
            startOfLife: tokenOwner.startOfLife,
            endOfLife: tokenOwner.endOfLife,
            borrower: address(0),
            lendingStartTimestamp: 0,
            borrowingStartTimestamp: 0,
            bidStartingPrice: 0,
            biddingLife: 0,
            listingPrice: newAmount,
            lendingStatus: false,
            lendingPeriod: 0,
            borrowingPeriod: 0,
            lendingPricePerDay: 0,
            fixedOrAuction: 1,
            isActivated: tokenOwner.isActivated
        });

        emit Listing(tokenId, serialNo, true, amount, block.timestamp);
    }

    /**
     * @notice allows token owner to unlist their token from fixed price.
     *
     * emits the Listing event.
     *
     * Requirements:
     *      ‼ contract should not be paused.
     *      ‼ caller must be the owner of the the token `tokenId + serialNo`.
     *      ‼ token with `tokenId + serialNo` must be listed.
     *
     * Signature for unlistTokenFromFixedPrice(string,uint256) : `0x51d7ef10`
     *
     * @param tokenId       id of the token being unlisted from fixed price.
     * @param serialNo      serial Number of the token.
     */
    function unlistTokenFromFixedPrice(
        uint256 tokenId,
        uint256 serialNo
    ) external whenNotPaused {
        TokenBearer memory tokenOwner = _tokenBearer[tokenId][serialNo];

        if (tokenOwner.user != msg.sender)
            revert NotAvailableForOperationLib.NotAvailableForOperation(1);
        if (tokenOwner.fixedOrAuction != 1)
            revert NotAvailableForOperationLib.NotAvailableForOperation(17);

        _tokenBearer[tokenId][serialNo] = TokenBearer({
            user: tokenOwner.user,
            startOfLife: tokenOwner.startOfLife,
            endOfLife: tokenOwner.endOfLife,
            borrower: address(0),
            lendingStartTimestamp: 0,
            borrowingStartTimestamp: 0,
            bidStartingPrice: 0,
            biddingLife: 0,
            listingPrice: 0,
            lendingStatus: false,
            lendingPeriod: 0,
            borrowingPeriod: 0,
            lendingPricePerDay: 0,
            fixedOrAuction: 0,
            isActivated: tokenOwner.isActivated
        });

        emit Listing(tokenId, serialNo, false, 0, block.timestamp);
    }

    /**
     * @notice allows a user to buy a token listed for fixed price.
     *
     * emits the Listing event.
     * emits the Transfer event.
     *
     * Requirements:
     *      ‼ contract should not be paused.
     *      ‼ caller must not be the owner of the the token `tokenId + serialNo`.
     *      ‼ token with `tokenId + serialNo` must be listed.
     *      ‼ token with `tokenId` must not be expired.
     *      ‼ token with `tokenId + serialNo` life must not be ended.
     *
     * Signature for buyFromUser(address,address,string,uint256) : `0x82d0190c`
     *
     * @param from          owner of the token.
     * @param to            buyer of the token.
     * @param tokenId       id of the token being bought.
     * @param serialNo      serial Number of the token.
     */
    function buyFromUser(
        address from,
        address to,
        uint256 tokenId,
        uint256 serialNo
    ) external payable checkForInvalidAddress(to) whenNotPaused {
        TokenBearer memory tokenOwner = _tokenBearer[tokenId][serialNo];

        if (tokenOwner.user == msg.sender)
            revert NotAvailableForOperationLib.NotAvailableForOperation(2);
        if (tokenOwner.fixedOrAuction != 1)
            revert NotAvailableForOperationLib.NotAvailableForOperation(15);

        _checkforExpired(
            tokenOwner.startOfLife,
            _tokenDetails[tokenId].expireOn,
            0,
            tokenOwner.endOfLife
        );

        unchecked {
            _balances[tokenId][from] -= 1;
            _balances[tokenId][to] += 1;
            _totalAmount += _platformFeesInWei;
        }

        _tokenBearer[tokenId][serialNo] = TokenBearer({
            user: to,
            startOfLife: tokenOwner.startOfLife,
            endOfLife: tokenOwner.endOfLife,
            borrower: address(0),
            lendingStartTimestamp: 0,
            borrowingStartTimestamp: 0,
            bidStartingPrice: 0,
            biddingLife: 0,
            listingPrice: 0,
            lendingStatus: false,
            lendingPeriod: 0,
            borrowingPeriod: 0,
            lendingPricePerDay: 0,
            fixedOrAuction: 0,
            isActivated: tokenOwner.isActivated
        });

        payable(tokenOwner.user).transfer(
            uint104(msg.value - _platformFeesInWei)
        );

        emit Listing(tokenId, serialNo, false, 0, block.timestamp);

        emit Transfer(from, to, tokenId, serialNo);
    }

    /**
     * @notice allows token owner to list a token for auction.
     *
     * emits the AuctionState event.
     *
     * Requirements:
     *      ‼ contract should not be paused.
     *      ‼ token with `tokenId + serialNo` must not be already listed for auction or fixed price.
     *      ‼ token with `tokenId + serialNo` must not be already listed for lending.
     *      ‼ caller must be the owner of the the token `tokenId + serialNo`.
     *      ‼ `biddingLife` must be multiple of day and must atleast 3 days.
     *      ‼ auction cannot be held before all tokens from contract are sold.
     *      ‼ token with `tokenId` must not be expired.
     *      ‼ token with `tokenId + serialNo` life must be enough.
     *
     * Signature for listForAuction(string,uint256,uint48) : `0xd653daa3`
     *
     * @param tokenId       id of the token being bought.
     * @param serialNo      serial Number of the token.
     * @param biddingLife   timestamp for number of days for which auction will run.
     */
    function listForAuction(
        uint256 tokenId,
        uint256 serialNo,
        uint48 biddingLife
    ) external whenNotPaused {
        TokenBearer memory tokenOwner = _tokenBearer[tokenId][serialNo];

        if (tokenOwner.fixedOrAuction != 0)
            revert NotAvailableForOperationLib.NotAvailableForOperation(15);
        if (tokenOwner.lendingStatus)
            revert NotAvailableForOperationLib.NotAvailableForOperation(3);
        if (tokenOwner.user != msg.sender)
            revert NotAvailableForOperationLib.NotAvailableForOperation(1);
        if (biddingLife % 3600 == 0 && biddingLife < 3600)
            revert NotAvailableForOperationLib.NotAvailableForOperation(10);
        if (_balances[tokenId][address(this)] != 0)
            revert NotAvailableForOperationLib.NotAvailableForOperation(7);

        TokenDetails memory tokenDet = _tokenDetails[tokenId];

        _checkforExpired(
            tokenOwner.startOfLife,
            tokenDet.expireOn,
            biddingLife,
            tokenOwner.endOfLife
        );

        uint104 bidStartingPrice = uint104(
            _getPrice(
                tokenDet.tokenPrice,
                tokenOwner.startOfLife,
                tokenOwner.endOfLife,
                50
            )
        );

        _tokenBearer[tokenId][serialNo] = TokenBearer({
            user: tokenOwner.user,
            startOfLife: tokenOwner.startOfLife,
            endOfLife: tokenOwner.endOfLife,
            borrower: address(0),
            lendingStartTimestamp: 0,
            borrowingStartTimestamp: 0,
            bidStartingPrice: bidStartingPrice,
            biddingLife: biddingLife,
            listingPrice: 0,
            lendingStatus: false,
            lendingPeriod: 0,
            borrowingPeriod: 0,
            lendingPricePerDay: 0,
            fixedOrAuction: 2,
            isActivated: tokenOwner.isActivated
        });

        emit AuctionState(
            tokenId,
            serialNo,
            true,
            bidStartingPrice,
            block.timestamp
        );
    }

    /**
     * @notice allows user to place bid on the token with `tokenId + serialNo`.
     *
     * emits the Bid event.
     *
     * Requirements:
     *      ‼ contract should not be paused.
     *      ‼ caller must not be the owner of the the token `tokenId + serialNo`.
     *      ‼ token with `tokenId + serialNo` must not be inactive.
     *      ‼ auction must not be inactive.
     *      ‼ auction must not be ended.
     *      ‼ token with `tokenId` must not be expired.
     *      ‼ token with `tokenId + serialNo` life must be enough.
     *      ‼ `amount` of current bid must be greater than that of previous bid.
     *
     * Signature for placeBidInAuction(string,uint256) : `0xafcef882`
     *
     * @param tokenId       id of the token being bought.
     * @param serialNo      serial Number of the token.
     */
    function placeBidInAuction(
        uint256 tokenId,
        uint256 serialNo
    ) external payable override whenNotPaused {
        TokenBearer memory tokenOwner = _tokenBearer[tokenId][serialNo];

        if (tokenOwner.user == msg.sender)
            revert NotAvailableForOperationLib.NotAvailableForOperation(2);
        if (!tokenOwner.isActivated)
            revert NotAvailableForOperationLib.NotAvailableForOperation(9);
        if (tokenOwner.fixedOrAuction != 2)
            revert NotAvailableForOperationLib.NotAvailableForOperation(11);
        if (tokenOwner.biddingLife > block.timestamp)
            revert NotAvailableForOperationLib.NotAvailableForOperation(12);

        _checkforExpired(
            tokenOwner.startOfLife,
            _tokenDetails[tokenId].expireOn,
            0,
            tokenOwner.endOfLife
        );

        unchecked {
            _totalAmount += msg.value;
        }

        _placeBid(tokenId, serialNo, msg.value - _platformFeesInWei);
    }

    /**
     * @notice allows user to revoke bid from the auction of token with `tokenId + serialNo`.
     *
     * emits the Bid event.
     *
     * Requirements:
     *      ‼ contract should not be paused.
     *      ‼ bid must be placed on the token with `tokenId + serialNo`.
     *      ‼ bidder with highest amount cannot revoke the bid.
     *
     * Signature for revokeBidFromAuction(string,uint256) : `0x3ad050e7`
     *
     * @param tokenId               id of the token.
     * @param serialNo              serial Number of the token.
     */
    function revokeBidFromAuction(
        uint256 tokenId,
        uint256 serialNo
    ) external override whenNotPaused {
        unchecked {
            _totalAmount -= _otherBidders[tokenId][serialNo][msg.sender];
        }

        _revokeBid(tokenId, serialNo);
    }

    function clearClaim(
        address owner,
        uint256 tokenId,
        uint256 serialNo,
        uint48 startOfLife,
        uint48 endOfLife,
        bool isActivated
    ) private {
        _tokenBearer[tokenId][serialNo] = TokenBearer({
            user: owner,
            startOfLife: startOfLife,
            endOfLife: endOfLife,
            borrower: address(0),
            lendingStartTimestamp: 0,
            borrowingStartTimestamp: 0,
            bidStartingPrice: 0,
            biddingLife: 0,
            listingPrice: 0,
            lendingStatus: false,
            lendingPeriod: 0,
            borrowingPeriod: 0,
            lendingPricePerDay: 0,
            fixedOrAuction: 0,
            isActivated: isActivated
        });
    }

    /**
     * @notice allows highest bidder to claim token with `tokenId + serialNo`.
     *
     * emits the AuctionState event.
     * emits the Transfer event.
     *
     * Requirements:
     *      ‼ contract should not be paused.
     *      ‼ caller must be the owner of the the token `tokenId + serialNo`.
     *      ‼ only bidder with highest amount can claim the token.
     *
     * Signature for claimTokenFromAuction(string,uint256) : `0x70c84b22`
     *
     * @param tokenId               id of the token.
     * @param serialNo              serial Number of the token.
     */
    function claimTokenFromAuction(
        uint256 tokenId,
        uint256 serialNo
    ) external override whenNotPaused {
        address highestBidder = _highestBidder[tokenId][serialNo];
        TokenBearer memory tokenOwner = _tokenBearer[tokenId][serialNo];

        if (highestBidder == address(0)) {
            clearClaim(
                tokenOwner.user,
                tokenId,
                serialNo,
                tokenOwner.startOfLife,
                tokenOwner.endOfLife,
                tokenOwner.isActivated
            );
        } else {
            if (tokenOwner.user == msg.sender)
                revert NotAvailableForOperationLib.NotAvailableForOperation(2);

            if (highestBidder != msg.sender)
                revert NotAvailableForOperationLib.NotAvailableForOperation(14);

            uint256 newBidAmount;

            unchecked {
                newBidAmount =
                    _otherBidders[tokenId][serialNo][highestBidder] -
                    _platformFeesInWei;
                _totalAmount -= newBidAmount;
                _balances[tokenId][msg.sender] += 1;
                _balances[tokenId][tokenOwner.user] -= 1;
            }

            clearClaim(
                msg.sender,
                tokenId,
                serialNo,
                tokenOwner.startOfLife,
                tokenOwner.endOfLife,
                tokenOwner.isActivated
            );

            payable(tokenOwner.user).transfer(newBidAmount);

            emit Transfer(tokenOwner.user, msg.sender, tokenId, serialNo);
        }
        emit AuctionState(tokenId, serialNo, false, 0, block.timestamp);
    }

    /**
     * @notice allows token owner to list a token for lending.
     *
     * emits the Lending event.
     *
     * Requirements:
     *      ‼ contract should not be paused.
     *      ‼ caller must be the owner of the the token `tokenId + serialNo`.
     *      ‼ token with `tokenId + serialNo` must not be already listed for auction or fixed price.
     *      ‼ token with `tokenId + serialNo` must not be already listed for lending.
     *      ‼ token with `tokenId + serialNo` must be active.
     *      ‼ `lendingPeriod` must be multiple of day and must atleast 3 days.
     *      ‼ lending cannot be held before all tokens from contract are sold.
     *      ‼ token with `tokenId` must not be expired.
     *      ‼ token with `tokenId + serialNo` life must be enough.
     *      ‼ `amount` should be within a given range.
     *
     * Signature for listForLending(string,uint256,uint32,uint104) : `0x3f3d3e39`
     *
     * @param tokenId           id of the token being listed for lending.
     * @param serialNo          serial Number of the token.
     * @param lendingPeriod     timestamp for number of days for which auction will run.
     * @param amount     timestamp for number of days for which auction will run.
     */
    function listForLending(
        uint256 tokenId,
        uint256 serialNo,
        uint32 lendingPeriod,
        uint104 amount
    ) external whenNotPaused {
        TokenBearer memory tokenOwner = _tokenBearer[tokenId][serialNo];

        if (tokenOwner.user != msg.sender)
            revert NotAvailableForOperationLib.NotAvailableForOperation(1);
        if (tokenOwner.fixedOrAuction != 0)
            revert NotAvailableForOperationLib.NotAvailableForOperation(15);
        if (tokenOwner.lendingStatus)
            revert NotAvailableForOperationLib.NotAvailableForOperation(16);
        if (!tokenOwner.isActivated)
            revert NotAvailableForOperationLib.NotAvailableForOperation(9);
        if (lendingPeriod % 86400 == 0 && lendingPeriod < 259200)
            revert NotAvailableForOperationLib.NotAvailableForOperation(10);
        if (_balances[tokenId][address(this)] != 0)
            revert NotAvailableForOperationLib.NotAvailableForOperation(7);

        TokenDetails memory tokenDet = _tokenDetails[tokenId];

        _checkforExpired(
            tokenOwner.startOfLife,
            tokenDet.expireOn,
            lendingPeriod,
            tokenOwner.endOfLife
        );

        uint256 lendingPrice;
        uint256 lendingPriceFloor;
        uint256 lendingPriceCeil;

        unchecked {
            lendingPrice = (tokenDet.tokenPrice / 100) * 98;
            (lendingPriceFloor, lendingPriceCeil) = (
                lendingPrice / 1000 + _platformFeesInWei,
                lendingPrice / 10 + _platformFeesInWei
            );
        }

        if (amount < lendingPriceFloor && amount > lendingPriceCeil)
            revert NotAvailableForOperationLib.NotAvailableForOperation(6);

        _tokenBearer[tokenId][serialNo] = TokenBearer({
            user: tokenOwner.user,
            startOfLife: tokenOwner.startOfLife,
            endOfLife: tokenOwner.endOfLife,
            borrower: address(0),
            lendingStartTimestamp: uint48(block.timestamp),
            borrowingStartTimestamp: 0,
            bidStartingPrice: 0,
            biddingLife: 0,
            listingPrice: 0,
            lendingStatus: true,
            lendingPeriod: lendingPeriod,
            borrowingPeriod: 0,
            lendingPricePerDay: amount,
            fixedOrAuction: 0,
            isActivated: tokenOwner.isActivated
        });

        emit Lending(tokenId, serialNo, true, amount, block.timestamp);
    }

    /**
     * @notice allows token owner to unlist a token from lending.
     *
     * emits the Lending event.
     *
     * Requirements:
     *      ‼ contract should not be paused.
     *      ‼ caller must be the owner of the the token `tokenId + serialNo`.
     *      ‼ token with `tokenId + serialNo` must be already listed for lending.
     *      ‼ token with `tokenId + serialNo` must not already have an active borrower.
     *
     * Signature for unlistFromLending(string,uint256) : `0x2d34ff6c`
     *
     * @param tokenId           id of the token being listed for lending.
     * @param serialNo          serial Number of the token.
     */
    function unlistFromLending(
        uint256 tokenId,
        uint256 serialNo
    ) external whenNotPaused {
        TokenBearer memory tokenOwner = _tokenBearer[tokenId][serialNo];

        if (tokenOwner.user != msg.sender)
            revert NotAvailableForOperationLib.NotAvailableForOperation(1);
        if (!tokenOwner.lendingStatus)
            revert NotAvailableForOperationLib.NotAvailableForOperation(16);
        if (
            tokenOwner.borrowingStartTimestamp + tokenOwner.borrowingPeriod >
            block.timestamp
        ) revert NotAvailableForOperationLib.NotAvailableForOperation(13);

        _tokenBearer[tokenId][serialNo] = TokenBearer({
            user: tokenOwner.user,
            startOfLife: tokenOwner.startOfLife,
            endOfLife: tokenOwner.endOfLife,
            borrower: address(0),
            lendingStartTimestamp: 0,
            borrowingStartTimestamp: 0,
            bidStartingPrice: 0,
            biddingLife: 0,
            listingPrice: 0,
            lendingStatus: false,
            lendingPeriod: 0,
            borrowingPeriod: 0,
            lendingPricePerDay: 0,
            fixedOrAuction: 0,
            isActivated: tokenOwner.isActivated
        });

        emit Lending(tokenId, serialNo, true, 0, block.timestamp);
    }

    /**
     * @notice allows a user to buy a token listed for fixed price.
     *
     * emits the Borrow event.
     *
     * Requirements:
     *      ‼ contract should not be paused.
     *      ‼ caller must not be the owner of the the token `tokenId + serialNo`.
     *      ‼ token with `tokenId + serialNo` must be listed for lending.
     *      ‼ another borrower must not be active.
     *      ‼ `borrowingPeriod` must be multiple of day and must atleast 1 days.
     *      ‼ `msg.value` must be in the range.
     *
     * Signature for borrowToken(string,uint256,uint32) : `0x5f4bd80c`
     *
     * @param tokenId           id of the token being borrowed.
     * @param serialNo          serial Number of the token.
     * @param borrowingPeriod   time period for which user is borrowing.
     */
    function borrowToken(
        uint256 tokenId,
        uint256 serialNo,
        uint32 borrowingPeriod
    ) external payable whenNotPaused {
        TokenBearer memory tokenOwner = _tokenBearer[tokenId][serialNo];

        if (tokenOwner.user == msg.sender)
            revert NotAvailableForOperationLib.NotAvailableForOperation(2);
        if (!tokenOwner.lendingStatus)
            revert NotAvailableForOperationLib.NotAvailableForOperation(16);
        if (
            tokenOwner.borrowingStartTimestamp + tokenOwner.borrowingPeriod >
            block.timestamp
        ) revert NotAvailableForOperationLib.NotAvailableForOperation(13);
        if (borrowingPeriod % 86400 == 0 && borrowingPeriod < 86400)
            revert NotAvailableForOperationLib.NotAvailableForOperation(10);
        if (
            msg.value <
            (tokenOwner.lendingPricePerDay * borrowingPeriod) +
                _platformFeesInWei
        ) revert NotAvailableForOperationLib.NotAvailableForOperation(6);

        uint256 newAmount;

        unchecked {
            newAmount = msg.value - _platformFeesInWei;
            _totalAmount += newAmount;
        }

        _tokenBearer[tokenId][serialNo] = TokenBearer({
            user: tokenOwner.user,
            startOfLife: tokenOwner.startOfLife,
            endOfLife: tokenOwner.endOfLife,
            borrower: msg.sender,
            lendingStartTimestamp: tokenOwner.lendingStartTimestamp,
            borrowingStartTimestamp: uint48(block.timestamp),
            bidStartingPrice: 0,
            biddingLife: 0,
            listingPrice: 0,
            lendingStatus: tokenOwner.lendingStatus,
            lendingPeriod: tokenOwner.lendingPeriod,
            borrowingPeriod: borrowingPeriod,
            lendingPricePerDay: tokenOwner.lendingPricePerDay,
            fixedOrAuction: 0,
            isActivated: tokenOwner.isActivated
        });

        emit Borrow(
            tokenId,
            serialNo,
            tokenOwner.lendingPricePerDay,
            borrowingPeriod,
            block.timestamp
        );
    }

    /**
     * @notice allows token owner to activate the token for usage.
     *
     * emits the TokenActivate event.
     *
     * Requirements:
     *      ‼ contract should not be paused.
     *      ‼ caller must be the owner of the the token `tokenId + serialNo`.
     *      ‼ token with `tokenId + serialNo` must not be already activated.
     *      ‼ token with `tokenId + serialNo` must not be listed for auction or fixed price.
     *      ‼ token with `tokenId + serialNo` must not be listed for lending.
     *      ‼ token with `tokenId` must not be expired.
     *
     * Signature for activateToken(string,uint256) : `0x9f7b064d`
     *
     * @param tokenId       id of the token being bought.
     * @param serialNo      serial Number of the token.
     */
    function activateToken(
        uint256 tokenId,
        uint256 serialNo
    ) external whenNotPaused {
        TokenBearer memory tokenOwner = _tokenBearer[tokenId][serialNo];

        if (tokenOwner.user != msg.sender)
            revert NotAvailableForOperationLib.NotAvailableForOperation(1);
        if (tokenOwner.isActivated)
            revert NotAvailableForOperationLib.NotAvailableForOperation(8);
        if (tokenOwner.fixedOrAuction != 0)
            revert NotAvailableForOperationLib.NotAvailableForOperation(15);
        if (tokenOwner.lendingStatus)
            revert NotAvailableForOperationLib.NotAvailableForOperation(16);

        TokenDetails memory tokenDet = _tokenDetails[tokenId];

        if (tokenOwner.isActivated && tokenDet.expireOn > block.timestamp)
            revert NotAvailableForOperationLib.NotAvailableForOperation(4);

        uint256 startTime = block.timestamp;

        _tokenBearer[tokenId][serialNo] = TokenBearer({
            user: tokenOwner.user,
            startOfLife: uint48(startTime),
            endOfLife: uint48(startTime + tokenDet.expectedUsageLife),
            borrower: address(0),
            lendingStartTimestamp: 0,
            borrowingStartTimestamp: 0,
            bidStartingPrice: 0,
            biddingLife: 0,
            listingPrice: 0,
            lendingStatus: false,
            lendingPeriod: 0,
            borrowingPeriod: 0,
            lendingPricePerDay: 0,
            fixedOrAuction: 0,
            isActivated: true
        });

        emit TokenActivate(tokenId, serialNo, block.timestamp);
    }

    /**
     * @notice allows contract owner to set platform fees.
     *
     * Requirements:
     *      ‼ contract should not be paused.
     *      ‼ caller must be the contract owner.
     *
     * Signature for setPlatformFeesInWei(uint256) : `0x7a9dffb7`
     *
     * @param fee   fees to be setted.
     */
    function setPlatformFeesInWei(
        uint256 fee
    ) external onlyOwner whenNotPaused {
        _platformFeesInWei = fee;
    }

    /**
     * @notice allows contract owner to set platform fees.
     *
     * Requirements:
     *      ‼ contract should not be paused.
     *      ‼ caller must be the contract owner.
     *      ‼ `amount` must be within the range.
     *
     * Signature for transferContractTotalAmount(uint256) : `0xf6ad12ae`
     *
     * @param amount    amount to be transferred to the owner.
     */
    function transferContractTotalAmount(
        uint256 amount
    ) external onlyOwner whenNotPaused {
        if (amount > _totalAmount)
            revert NotAvailableForOperationLib.NotAvailableForOperation(6);

        unchecked {
            _totalAmount -= amount;
        }

        payable(msg.sender).transfer(amount);
    }

    /**
     * @notice allows contract owner to set Base URI.
     *
     * Requirements:
     *      ‼ contract should not be paused.
     *      ‼ caller must be the owner of the contract.
     *
     * Signature for setUri(string) : `0x9b642de1`
     *
     * @param newUri    new URI for the token.
     */
    function setUri(string memory newUri) external onlyOwner whenNotPaused {
        _setURI(newUri);
    }

    // CALLS
    // -----

    /**
     * @notice returns base uri of the token.
     *
     * Signature for uri() : `0xeac989f8`
     */
    function uri() external view override returns (string memory) {
        return _baseURI;
    }

    /**
     * @notice returns the value of amount in contract.
     *
     * Requirements:
     *      ‼ caller must be the owner of the contract.
     *
     * Signature for getTotalAmountOfContract() : `0x2ed16ed4`
     */
    function getTotalAmountOfContract()
        external
        view
        override
        onlyOwner
        returns (uint256)
    {
        return _totalAmount;
    }

    // For Proxy Contract

    /**
     * @notice returns the platformFeesInWei.
     *
     * Signature for getPlatformFeesInWei() : `0xc6e5124d`
     */
    function getPlatformFeesInWei() external view returns (uint256) {
        return _platformFeesInWei;
    }

    /**
     * @notice returns the balance of a user or current contract.
     *
     * Signature for getBalance(string,address) : `0x89f4b317`
     *
     * @param tokenId   id of the token.
     * @param account   address of the user to be queried. Can be a user of current contract.
     */
    function getBalance(
        uint256 tokenId,
        address account
    ) external view override returns (uint256) {
        return _balances[tokenId][account];
    }

    /**
     * @notice returns the details of a particular token with `tokenId`.
     *
     * Signature for getTokenDetails(string) : `0xcacbdd78`
     *
     * @param tokenId   id of the token.
     */
    function getTokenDetails(
        uint256 tokenId
    ) external view override returns (TokenDetails memory) {
        return _tokenDetails[tokenId];
    }

    /**
     * @notice returns the details of a particular token with `tokenId + serialNo`.
     *
     * Signature for getTokenBearer(string,uint256) : `0x06e59689`
     *
     * @param tokenId   id of the token.
     * @param serialNo  serial number of the token.
     */
    function getTokenBearer(
        uint256 tokenId,
        uint256 serialNo
    ) external view override returns (TokenBearer memory) {
        return _tokenBearer[tokenId][serialNo];
    }

    /**
     * @notice returns the address of the highest bidder for `tokenId + serialNo`.
     *
     * Signature for getHighestBidder(string,uint256) : `0x6eedc102`
     *
     * @param tokenId   id of the token.
     * @param serialNo  serial number of the token.
     */
    function getHighestBidder(
        uint256 tokenId,
        uint256 serialNo
    ) external view override returns (address) {
        return _highestBidder[tokenId][serialNo];
    }

    /**
     * @notice returns the bidded amount for `tokenId + serialNo + bidder`.
     *
     * Signature for getOtherBidders(string,uint256,address) : `0xc3f268d4`
     *
     * @param tokenId   id of the token.
     * @param serialNo  serial number of the token.
     * @param bidder    address of the bidder.
     */
    function getOtherBidders(
        uint256 tokenId,
        uint256 serialNo,
        address bidder
    ) external view override returns (uint256) {
        return _otherBidders[tokenId][serialNo][bidder];
    }

    /**
     * @notice returns the metadata id of the token.
     *
     * Signature for getMetadataId(uint256) : `0xa0202a9a`
     *
     * @param tokenId   id of the token.
     */
    function getMetadataId(
        uint256 tokenId
    ) external view returns (string memory) {
        return _tokenMetadataId[tokenId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

/**
 * @title IAuction:
 *
 * @author Farasat Ali
 *
 * @dev inteface for Auction.
 */

interface IERC1155Dao {
    /**
     * @dev Struct to provide the details of the token and it is populated after token is minted
     *
     * @param tokenSupply           total supply of the token.
     * @param tokenPrice            price of each token.
     * @param expectedUsageLife     time period to which token can be used.
     * @param isMinted              tells whether the token is minted or not. If `true` then token is minted and if `false` the token is not minted.
     * @param expireOn              expiry date for the token.
     */
    struct TokenDetails {
        // 256-bits
        uint256 totalSupply;
        // 192-bits
        uint104 tokenPrice;
        uint32 expectedUsageLife;
        bool isMinted;
        uint48 expireOn;
    }

    /**
     * @dev Struct to provide the details of the user, bidding, listing, lending/borrowing and activation of the token.
     *
     * @param user                      original owner of the token.
     * @param startOfLife               starting timestamp of the token when it became first active.
     * @param endOfLife                 ending timestamp of the token calculated after it became active.
     * @param borrower                  address of the borrower of the token. Default is 0 address if no borrower.
     * @param lendingStartTimestamp     timestamp when lending is started for the token and by default it is 0.
     * @param borrowingStartTimestamp   timestamp when borrowing is started for the token and by default it is 0.
     * @param bidStartingPrice          starting bidding price for the token and by default it is 0.
     * @param biddingLife               Duration for the bidding of a token and by default it is 0.
     * @param listingPrice              listing price for the token and by default it is 0.
     * @param lendingStatus             lending status of the token and by default it is `false` which means lending is not active while `true` means lending is active.
     * @param lendingPeriod             Duration for the lending of a token and by default it is 0.
     * @param borrowingPeriod           Duration for the borrowing of a token and by default it is 0.
     * @param lendingPricePerDay        lending price for the token per day and by default it is 0.
     * @param fixedOrAuction            tells the status whether token is listed for fixed price or auction and by default it is `0` which means `none`. `1` means `fixed price` while `2` means `auction`.
     * @param isActivated               tells the status whether the token is active or not and by default it is `false` which means not active while `true` means it is active.
     */
    struct TokenBearer {
        // 256-bits
        address user;
        uint48 startOfLife;
        uint48 endOfLife;
        // 256-bits
        address borrower;
        uint48 lendingStartTimestamp;
        uint48 borrowingStartTimestamp;
        // 256-bits
        uint104 bidStartingPrice;
        uint48 biddingLife;
        uint104 listingPrice;
        // 192-bits
        bool lendingStatus;
        uint32 lendingPeriod;
        uint32 borrowingPeriod;
        uint104 lendingPricePerDay;
        uint8 fixedOrAuction;
        bool isActivated;
    }

    /**
     * @dev mints the token.
     *
     * emits the MintSingle event.
     *
     * @param tokenId               id of the token.
     * @param amount                amount of the tokens per id.
     * @param price                 price of each token.
     * @param expectedUsageLife     expected usage life of the token.
     * @param expiry                expiry of the token.
     */
    function mint(
        uint256 tokenId,
        string memory metadataId,
        uint256 amount,
        uint104 price,
        uint32 expectedUsageLife,
        uint48 expiry
    ) external;

    /**
     * @notice allows buyer to buy a token from the contract.
     *
     * Signature for buyFromContract(address,string) : `0x02e5dae1`
     *
     * @param to            address of the buyer.
     * @param tokenId       id of the token being bought from the contract.
     */
    function buyFromContract(address to, uint256 tokenId) external payable;

    /**
     * @notice allows token owner to list their token for a fixed price.
     *
     * Signature for listTokenForFixedPrice(string,uint256,uint104) : `0x16b35050`
     *
     * @param tokenId       id of the token being listed for fixed price.
     * @param serialNo      serial Number of the token.
     * @param amount        amount for which token is to be listed.
     */
    function listTokenForFixedPrice(
        uint256 tokenId,
        uint256 serialNo,
        uint104 amount
    ) external;

    /**
     * @notice allows token owner to change their listing price for fixed price.
     *
     * Signature for changeListingForFixedPrice(string,uint256,uint104) : `0x7f9e5134`
     *
     * @param tokenId       id of the token being listed for fixed price.
     * @param serialNo      serial Number of the token.
     * @param amount        amount for which token is to be listed.
     */
    function changeListingForFixedPrice(
        uint256 tokenId,
        uint256 serialNo,
        uint104 amount
    ) external;

    /**
     * @notice allows token owner to unlist their token from fixed price.
     *
     * Signature for unlistTokenFromFixedPrice(string,uint256) : `0x51d7ef10`
     *
     * @param tokenId       id of the token being unlisted from fixed price.
     * @param serialNo      serial Number of the token.
     */
    function unlistTokenFromFixedPrice(
        uint256 tokenId,
        uint256 serialNo
    ) external;

    /**
     * @notice allows a user to buy a token listed for fixed price.
     *
     * Signature for buyFromUser(address,address,string,uint256) : `0x82d0190c`
     *
     * @param from          owner of the token.
     * @param to            buyer of the token.
     * @param tokenId       id of the token being bought.
     * @param serialNo      serial Number of the token.
     */
    function buyFromUser(
        address from,
        address to,
        uint256 tokenId,
        uint256 serialNo
    ) external payable;

    /**
     * @notice allows token owner to list a token for auction.
     *
     * Signature for listForAuction(string,uint256,uint48) : `0xd653daa3`
     *
     * @param tokenId       id of the token being bought.
     * @param serialNo      serial Number of the token.
     * @param biddingLife   timestamp for number of days for which auction will run.
     */
    function listForAuction(
        uint256 tokenId,
        uint256 serialNo,
        uint48 biddingLife
    ) external;

    /**
     * @notice allows token owner to list a token for lending.
     *
     * Signature for listForLending(string,uint256,uint32,uint104) : `0x3f3d3e39`
     *
     * @param tokenId           id of the token being listed for lending.
     * @param serialNo          serial Number of the token.
     * @param lendingPeriod     timestamp for number of days for which auction will run.
     * @param amount     timestamp for number of days for which auction will run.
     */
    function listForLending(
        uint256 tokenId,
        uint256 serialNo,
        uint32 lendingPeriod,
        uint104 amount
    ) external;

    /**
     * @notice allows token owner to unlist a token from lending.
     *
     * Signature for unlistFromLending(string,uint256) : `0x2d34ff6c`
     *
     * @param tokenId           id of the token being listed for lending.
     * @param serialNo          serial Number of the token.
     */
    function unlistFromLending(uint256 tokenId, uint256 serialNo) external;

    /**
     * @notice allows a user to buy a token listed for fixed price.
     *
     * Signature for borrowToken(string,uint256,uint32) : `0x5f4bd80c`
     *
     * @param tokenId           id of the token being borrowed.
     * @param serialNo          serial Number of the token.
     * @param borrowingPeriod   time period for which user is borrowing.
     */
    function borrowToken(
        uint256 tokenId,
        uint256 serialNo,
        uint32 borrowingPeriod
    ) external payable;

    /**
     * @notice allows contract owner to set platform fees.
     *
     * Signature for setPlatformFeesInWei(uint256) : `0x7a9dffb7`
     *
     * @param fee   fees to be setted.
     */
    function setPlatformFeesInWei(uint256 fee) external;

    /**
     * @notice allows token owner to activate the token for usage.
     *
     * Signature for activateToken(string,uint256) : `0x9f7b064d`
     *
     * @param tokenId       id of the token being bought.
     * @param serialNo      serial Number of the token.
     */
    function activateToken(uint256 tokenId, uint256 serialNo) external;

    /**
     * @notice allows contract owner to set Base URI.
     *
     * Signature for setUri(string) : `0x9b642de1`
     *
     * @param newUri    new URI for the token.
     */
    function setUri(string memory newUri) external;

    /**
     * @notice returns base uri of the token.
     *
     * Signature for uri() : `0xeac989f8`
     */
    function uri() external view returns (string memory);

    /**
     * @notice returns the value of amount in contract.
     *
     * Signature for getTotalAmountOfContract() : `0x2ed16ed4`
     */
    function getTotalAmountOfContract() external view returns (uint256);

    /**
     * @notice returns the platformFeesInWei.
     *
     * Signature for getPlatformFeesInWei() : `0x89f4b317`
     */
    function getPlatformFeesInWei() external view returns (uint256);

    /**
     * @notice returns the details of a particular token with `tokenId`.
     *
     * Signature for getTokenDetails(string) : `0xcacbdd78`
     *
     * @param tokenId   id of the token.
     */
    function getTokenDetails(
        uint256 tokenId
    ) external view returns (TokenDetails memory);

    /**
     * @notice returns the details of a particular token with `tokenId + serialNo`.
     *
     * Signature for getTokenBearer(string,uint256) : `0x06e59689`
     *
     * @param tokenId   id of the token.
     * @param serialNo  serial number of the token.
     */
    function getTokenBearer(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (TokenBearer memory);

    /**
     * @notice returns the balance of a user or current contract.
     *
     * Signature for getBalance(string,address) : `0x89f4b317`
     *
     * @param tokenId   id of the token.
     * @param account   address of the user to be queried. Can be a user of current contract.
     */
    function getBalance(
        uint256 tokenId,
        address account
    ) external view returns (uint256);

    /**
     * @notice returns the address of the highest bidder for `tokenId + serialNo`.
     *
     * Signature for getHighestBidder(string,uint256) : `0x6eedc102`
     *
     * @param tokenId   id of the token.
     * @param serialNo  serial number of the token.
     */
    function getHighestBidder(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (address);

    /**
     * @notice returns the bidded amount for `tokenId + serialNo + bidder`.
     *
     * Signature for getOtherBidders(string,uint256,address) : `0xc3f268d4`
     *
     * @param tokenId   id of the token.
     * @param serialNo  serial number of the token.
     * @param bidder    address of the bidder.
     */
    function getOtherBidders(
        uint256 tokenId,
        uint256 serialNo,
        address bidder
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

// interfaces
import "./interfaces/IAuction.sol";
// library
import "../utils/NotAvailableForOperationLib.sol";

/**
 * @title Auction:
 *
 * @author Farasat Ali
 *
 * @notice Provides the facility for bidding.
 */
contract Auction is IAuction {
    // ============================================================= //
    //                          VARIABLES                            //
    // ============================================================= //

    // returns the address of a bidder for a particular tokenId and serialNo.
    mapping(uint256 tokenId => mapping(uint256 serialNo => address bidder))
        internal _highestBidder;

    // returns the bid amount against a particular tokenId, serialNo and bidder address.
    mapping(uint256 tokenId => mapping(uint256 serialNo => mapping(address bidder => uint256 bidAmount)))
        internal _otherBidders;

    // ============================================================= //
    //                          Events                               //
    // ============================================================= //

    /**
     * @notice It is emitted when a Bid is placed on a token with `tokenId + serialNo` in an auction.
     *
     * Signature for Bid(uint256,uint256,bool,uint256,uint256) : `0x9e8f7e39`
     *
     * @param tokenId       Id of the token being bidded on.
     * @param serialNo      serial number of token assigned to that token.
     * @param placed        whether the bid id placed or revoked. `true` if place `false` if revoked.
     * @param price         price of the bid.
     * @param when          time of the bid.
     */
    event Bid(
        uint256 indexed tokenId,
        uint256 indexed serialNo,
        bool indexed placed,
        uint256 price,
        uint256 when
    );

    // ============================================================= //
    //                          METHODS                              //
    // ============================================================= //

    /**
     * @notice allows user to place bid on the token with `tokenId + serialNo`.
     *
     * emits the Bid event.
     *
     * Requirements:
     *      ‼ `amount` of current bid must be greater than that of previous bid.
     *
     * Signature for _placeBid(string,uint256,uint256) : `0xfcfa4681`
     *
     * @param tokenId               id of the token.
     * @param serialNo              serial Number of the token.
     * @param amount                bidding amount to be added or placed.
     */
    function _placeBid(
        uint256 tokenId,
        uint256 serialNo,
        uint256 amount
    ) internal virtual {
        uint256 currentBidderAmount = _otherBidders[tokenId][serialNo][
            msg.sender
        ];
        uint256 highestBidderAmount = _otherBidders[tokenId][serialNo][
            _highestBidder[tokenId][serialNo]
        ];

        if (currentBidderAmount + amount < highestBidderAmount)
            revert NotAvailableForOperationLib.NotAvailableForOperation(23);

        uint256 totalAmout = _otherBidders[tokenId][serialNo][msg.sender] +
            amount;
        _otherBidders[tokenId][serialNo][msg.sender] = totalAmout;

        emit Bid(tokenId, serialNo, true, totalAmout, block.timestamp);
    }

    /**
     * @notice allows user to place bid on the token with `tokenId + serialNo`.
     *
     * emits the Bid event.
     *
     * Requirements:
     *      ‼ `amount` of current bid must be greater than that of previous bid.
     *
     * Signature for placeBidInAuction(string,uint256) : `0xafcef882`
     *
     * @param tokenId               id of the token.
     * @param serialNo              serial Number of the token.
     */
    function placeBidInAuction(
        uint256 tokenId,
        uint256 serialNo
    ) external payable virtual override {
        _placeBid(tokenId, serialNo, msg.value);
    }

    /**
     * @notice allows user to revoke bid from the auction of token with `tokenId + serialNo`.
     *
     * emits the Bid event.
     *
     * Requirements:
     *      ‼ bid must be placed on the token with `tokenId + serialNo`.
     *      ‼ bidder with highest amount cannot revoke the bid.
     *
     * Signature for _revokeBid(string,uint256) : `0x10af37c1`
     *
     * @param tokenId               id of the token.
     * @param serialNo              serial Number of the token.
     */
    function _revokeBid(uint256 tokenId, uint256 serialNo) internal virtual {
        uint256 bidderAmout = _otherBidders[tokenId][serialNo][msg.sender];

        if (bidderAmout == 0)
            revert NotAvailableForOperationLib.NotAvailableForOperation(22);
        if (_highestBidder[tokenId][serialNo] == msg.sender)
            revert NotAvailableForOperationLib.NotAvailableForOperation(24);

        _otherBidders[tokenId][serialNo][msg.sender] = 0;

        payable(msg.sender).transfer(bidderAmout);

        emit Bid(tokenId, serialNo, false, 0, block.timestamp);
    }

    /**
     * @notice allows user to revoke bid from the auction of token with `tokenId + serialNo`.
     *
     * emits the Bid event.
     *
     * Requirements:
     *      ‼ bid must be placed on the token with `tokenId + serialNo`.
     *      ‼ bidder with highest amount cannot revoke the bid.
     *
     * Signature for revokeBidFromAuction(string,uint256) : `0x3ad050e7`
     *
     * @param tokenId               id of the token.
     * @param serialNo              serial Number of the token.
     */
    function revokeBidFromAuction(
        uint256 tokenId,
        uint256 serialNo
    ) external virtual override {
        _revokeBid(tokenId, serialNo);
    }

    /**
     * @notice allows highest bidder to get the token.
     *
     * Signature for claimTokenFromAuction(string,uint256) : `0x70c84b22`
     *
     * @param tokenId               id of the token.
     * @param serialNo              serial Number of the token.
     */
    function claimTokenFromAuction(
        uint256 tokenId,
        uint256 serialNo
    ) external virtual override {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

/**
 * @title IAuction:
 *
 * @author Farasat Ali
 *
 * @notice inteface for Auction.
 */
interface IAuction {
    /**
     * @notice allows user to place bid on the token with `tokenId + serialNo`.
     *
     * Signature for placeBidInAuction(string,uint256) : `0xafcef882`
     *
     * @param tokenId               id of the token.
     * @param serialNo              serial Number of the token.
     */
    function placeBidInAuction(
        uint256 tokenId,
        uint256 serialNo
    ) external payable;

    /**
     * @notice allows user to revoke bid from the auction of token with `tokenId + serialNo`.
     *
     * Signature for revokeBidFromAuction(string,uint256) : `0x3ad050e7`
     *
     * @param tokenId               id of the token.
     * @param serialNo              serial Number of the token.
     */
    function revokeBidFromAuction(
        uint256 tokenId,
        uint256 serialNo
    ) external;

    /**
     * @notice allows highest bidder to get the token.
     *
     * Signature for claimTokenFromAuction(string,uint256) : `0x70c84b22`
     *
     * @param tokenId               id of the token.
     * @param serialNo              serial Number of the token.
     */
    function claimTokenFromAuction(
        uint256 tokenId,
        uint256 serialNo
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

/**
 * @title IPausable:
 *
 * @author Farasat Ali.
 *
 * @notice This interface provide functions which allows to stop the whole
 * contract in case of emerdgency or any other reasons
 */
interface IPausable {
    /**
     * @notice return the status of contract - either it is paused or not
     *
     * @return paused contains status of paused or unpaused
     */
    function isPaused() external returns (bool paused);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./interfaces/IPausable.sol";
// library
import "../utils/NotAvailableForOperationLib.sol";

/**
 * @title Pausable:
 *
 * @author Farasat Ali.
 *
 * @notice allows to stop the whole contract in case of emerdgency or any
 * other reasons using pause and unpause functions.
 */
contract Pausable is IPausable {
    // ============================================================= //
    //                          VARIABLES                            //
    // ============================================================= //

    // it stores boolean in which `true` represents that the contract is paused and `false` represents contract is not paused.
    bool private _paused = false;

    // ============================================================= //
    //                          EVENTS                               //
    // ============================================================= //

    /**
     * @notice event is emitted when a contract is paused or unpaused with
     * the account address, pause status and the time of occurance.
     *
     * @param status status shows that whether the contract is paused or unpaused i.e. `true` for paused and `false` for unpaused.
     * @param when timestamp when pause or unpause is happend.
     */
    event PauseState(bool indexed status, uint indexed when);

    // ============================================================= //
    //                          MODIFIERS                            //
    // ============================================================= //

    /**
     * @notice check if the contract is already paused i.e. private paused
     * variable is `true` then it revert the function.
     */
    modifier whenNotPaused() {
        if (_paused)
            revert NotAvailableForOperationLib.NotAvailableForOperation(25);
        _;
    }

    // ============================================================= //
    //                          METHODS                              //
    // ============================================================= //

    /**
     * @notice tells the pause or unpaused status of the contract by returning
     * `true` if the contract is paused, and `false` otherwise.
     *
     * @return paused contain `true` if paused while `false` if not paused.
     */
    function isPaused() external view returns (bool paused) {
        return paused = _paused;
    }

    /**
     * @notice change the contract state to paused by setting the private
     * paused variable to true.
     *
     * emits the PauseState event with true and latest block timestamp.
     *
     * Requirements
     *       ‼ should not be already in paused state.
     *
     */
    function _pause() internal whenNotPaused {
        _paused = true;
        emit PauseState(true, block.timestamp);
    }

    /**
     * @notice change the contract state to unpaused by setting the private
     * paused variable to false.
     *
     * emits the PauseState event with false and latest block timestamp.
     *
     * Requirements
     *       ‼ should not be already in unpaused state.
     *
     */
    function _unpause() internal {
        if (!_paused)
            revert NotAvailableForOperationLib.NotAvailableForOperation(26);
        _paused = false;
        emit PauseState(false, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

/**
 * @title NotAvailableForOperationLib:
 *
 * @author Farasat Ali
 *
 * @notice Provides common error function for all contracts.
 */
library NotAvailableForOperationLib {
    /// @notice operation is not allowed due to one of the following reasons - Signature : `0xdd73df38`:
    /// `1` -> token Owner is allowed
    /// `2` -> token owner is not allowed
    /// `3` -> must end lending first
    /// `4` -> token is expired
    /// `5` -> not enough life
    /// `6` -> value is out of range
    /// `7` -> transfer or bidding before sale is not allowed
    /// `8` -> token already active
    /// `9` -> token already inactive
    /// `10` -> life must be multiple of the day
    /// `11` -> auction inactive
    /// `12` -> auction ended
    /// `13` -> borrower active
    /// `14` -> only winner can claim
    /// `15` -> already listed for fixed price or auction
    /// `16` -> already in lending
    /// `17` -> not listed for fixed price or auction
    /// `18` -> not minted
    /// `19` -> already minted
    /// `20` -> not the Owner
    /// `21` -> invalid Address
    /// `22` -> no Bid
    /// `23` -> bid Lower than previous
    /// `24` -> highest bidder cannot revoke
    /// `25` -> Paused
    /// `26` -> Not Address
    error NotAvailableForOperation(uint256 status);
}