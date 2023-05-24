// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

/**
 * @title IOwnable:
 *
 * @author Farasat Ali
 *
 * @notice interface to make contracts ownable by restricting it to
 * the deployer's address.
 *
 * @dev This is an interface which will be implemented to provide  contract
 * ownership to the deployer with the facility to transfer ownership.
 */
interface IOwnable {
    /**
     * @dev implement to get the address of the owner.
     *
     * @return owner returns owner of the contract.
     */
    function getOwner() external returns (address owner);

    /**
     * @dev implement to transfer the ownership of the contract.
     *
     * @param newOwner address of the new owner.
     */
    function transferOwnership(address newOwner) external;

    /**
     * @dev implement to give up the ownership of the contract.
     */
    function renounceOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import "./interfaces/IOwnable.sol";

/**
 * @title Ownable:
 *
 * @author Farasat Ali.
 *
 * @notice make contracts ownable by restricting it to the deployer's
 * address.
 *
 * @dev this implementation is to make give contract ownership to the
 * deployer with the facility to transfer and revoke ownership.
 */

contract Ownable is IOwnable {
    // ============================================================= //
    //                          VARIABLES                            //
    // ============================================================= //

    /**
     * @notice address which is stored when this contract is deployed.
     *
     * @dev it is the address which is stored when the contract is
     * deployed this address is set by constructor but is changeable
     * through transferOwnership or renounceOwnership functions.
     */
    address internal _owner;

    // ============================================================= //
    //                          EVENTS                               //
    // ============================================================= //

    /**
     * @notice to emit the the event on transfers.
     *
     * @dev emitted when a contract ownership is transferred from an
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
    //                          ERRORS                               //
    // ============================================================= //

    error NotOwner();
    error InvalidAddress();

    // ============================================================= //
    //                          MODIFIERS                            //
    // ============================================================= //

    /**
     * @notice to check if the function is being called by owner if `true`
     * then allow the function to continue else raise exception
     * @dev compares the stored owner address with the address of sender
     * and raise exception if both are not equal contract.
     *
     * > Conditions to pass includes:
     * > - ❗ caller should be the owner.
     *
     */
    modifier onlyOwner() {
        if (_owner != msg.sender) revert NotOwner();
        _;
    }

    /**
     * @notice to revert the transaction if a 0 address is passed.
     * @dev to check for the address passed. It compares the incoming
     * address (msg.sender) with the 0x0000000000000000000000000000000000000000
     * and if matched then the transaction is reverted with error containing
     * the passed string.
     *
     * > Conditions to pass includes:
     * > - ❗ provided address should not be invalid.
     *
     */
    modifier checkForInvalidAddress(address newOwner) {
        if (newOwner == address(0)) revert InvalidAddress();
        _;
    }

    // ============================================================= //
    //                          CONSTRUCTOR                          //
    // ============================================================= //

    /**
     * @notice set the contract deployer as owner while deploying the
     * contract.
     * @dev calls the _transferOwnership function and sets the
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
     * @notice change the owner of the contract when called by another
     * functions or functions of the inheriting contract.
     *
     * @dev updates or changes the address of old owner within the
     * contract with the incoming address (msg.sender).
     *
     * emit the `OwnershipTransferred` event when successful.
     *
     * @param newOwner address to which ownership of this contract will be transferred.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = getOwner();
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, _owner, block.timestamp);
    }

    /**
     * @notice use to get the address of current owner.
     *
     * @dev returns the address of the owner stored in the private
     * owner variable.
     *
     * @return owner address of owner stored
     */
    function getOwner() public view override returns (address) {
        return _owner;
    }

    /**
     * @notice change the owner of the contract when called.
     * @dev changes the address of old owner within the contract and
     * with the incoming address (msg.sender) by calling the internal
     * transferOwnership.
     *
     * emit the `OwnershipTransferred` event when successful.
     *
     * > Conditions to pass includes:\
     * > - ❗ caller of the function should be the current owner.
     * > - ❗ the address to which ownership is being transferred should be a valid address or a non-zero address.
     *
     * @param newOwner address to which ownership of this contract will be transferred.
     *
     */
    function transferOwnership(
        address newOwner
    ) public override onlyOwner checkForInvalidAddress(newOwner) {
        _transferOwnership(newOwner);
    }

    /**
     * @notice change the owner to the 0 address which makes the contract
     * independent.
     * @dev it lets owner give up their ownership and leave contract without
     * by calling internal _transferOwnership with a 0 address.
     *
     * emit the `OwnershipTransferred` event when successful.
     *
     * > Conditions to pass includes:
     * > - ❗ caller of the function should be the current owner of the contract.
     *
     */
    function renounceOwnership() public override onlyOwner {
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

/**
 * @title ERC1155Dao:
 *
 * @author Farasat Ali
 *
 * @dev Imherits the ERC1155 contract and provide functionality for lending/borrowing,
 * transfering, minting, bidding.
 */
contract ERC1155Dao is IERC1155Dao, Ownable, Pausable, Auction {
    // ============================================================= //
    //                          VARIABLES                            //
    // ============================================================= //

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _baseURI;

    // contains the track total amount of wei in the contract.
    uint256 private _totalAmount;

    // contains the track of platform fees in wei.
    uint256 private _platformFeesInWei = 10 ^ 5;

    // returns the TokenBearer struct when token id and serial number is provided.
    mapping(uint256 => mapping(uint256 => TokenBearer)) private _tokenBearer;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // returns the TokenDetails struct when token id is provided.
    mapping(uint256 => TokenDetails) private _tokenDetails;

    // ============================================================= //
    //                          EVENTS                               //
    // ============================================================= //

    /**
     * @dev It is emitted when tokens are transferred, including zero value transfers as well as minting or burning.
     * When minting/creating tokens, the `from` argument MUST be set to `0x0` (i.e. zero address).
     * When burning/destroying tokens, the `to` argument MUST be set to `0x0` (i.e. zero address).
     *
     * Signature for TransferSingle(address,address,address,uint256,uint256) : `0xc3d58168`
     *
     * @param operator     caller of the function that is either owner or the operator.
     * @param from         owner of the token whose balance is decreased.
     * @param to           receiver of the token whose balance is increased.
     * @param id           the token type being transferred.
     * @param serialNo     number of token assigned to a particular user.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 serialNo
    );

    /**
     * @dev event to be emitted when single id of tokens are minted
     *
     * @param operator          caller of the function that is either owner or the operator.
     * @param from              owner of the token whose balance is decreased.
     * @param to                receiver of the token whose balance is increased.
     * @param id                the token type being transferred.
     * @param amount            number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
     * @param price             price of eact token.
     * @param expectedUsageLife expected life of the token.
     * @param expiry            timestamp when token will be expired
     */
    event MintSingle(
        address operator,
        address indexed from,
        address indexed to,
        uint256 indexed id,
        uint256 amount,
        uint104 price,
        uint32 expectedUsageLife,
        uint48 expiry
    );

    /**
     * @dev event to be emitted when multiple ids of tokens are minted
     *
     * @param operator              caller of the function that is either owner or the operator.
     * @param from                  owner of the token whose balance is decreased.
     * @param to                    receiver of the token whose balance is increased.
     * @param ids                   ids of the token.
     * @param amounts               number of tokens for each id.
     * @param prices                price of each token.
     * @param expectedUsageLives    expected life of the token based on ids.
     * @param expiries              timestamps when token will be expired based on ids.
     */
    // event MintBatch(
    //     address operator,
    //     address indexed from,
    //     address indexed to,
    //     uint256[] indexed ids,
    //     uint256[] amounts,
    //     uint104[] prices,
    //     uint32[] expectedUsageLives,
    //     uint48[] expiries
    // );

    /**
     * @dev event to be emitted when token is listed or unlisted for the auction.
     *
     * @param tokenId           id of the token.
     * @param serialNo          serial number of the token.
     * @param biddingLife       duration for which the auction is happening. `0` means auction has ended.
     * @param bidStartingPrice  starting price for the bidding. `0` means auction has ended.
     * @param owner             owner of the token. Before auction is closed owner is the auctioner while after the closing of the auction owner can be highest bidder or the current owner.
     * @param when              when this event took place.
     * @param isStarted         tells the status whether auction started or ended. `true` if started and `false` if ended.
     */
    event AuctionState(
        uint256 indexed tokenId,
        uint256 indexed serialNo,
        uint256 biddingLife,
        uint256 bidStartingPrice,
        address owner,
        uint256 when,
        bool indexed isStarted
    );

    /**
     * @dev event to be emitted when token is listed or unlisted for the fixed price sale.
     *
     * @param tokenId           id of the token.
     * @param serialNo          serial number of the token.
     * @param listingPrice      price for the bidding. `0` means listing has ended.
     * @param owner             owner of the token. Before auction is closed owner is the auctioner while after the closing of the auction owner can be highest bidder or the current owner.
     * @param when              when this event took place.
     * @param isListed          tells the status whether listing started or ended. `true` if started and `false` if ended.
     */
    event Listing(
        uint256 indexed tokenId,
        uint256 indexed serialNo,
        uint256 listingPrice,
        address owner,
        uint256 when,
        bool indexed isListed
    );

    /**
     * @dev event to be emitted when token is activated for usage.
     *
     * @param tokenId       id of the token.
     * @param serialNo      serial number of the token.
     * @param startingTime  when token is activated for the usage.
     */
    event TokenActivate(
        uint256 indexed tokenId,
        uint256 indexed serialNo,
        uint256 indexed startingTime
    );

    /**
     * @dev event to be emitted when token is listed for lending.
     *
     * @param tokenId               id of the token.
     * @param serialNo              serial number of the token.
     * @param lendingStartTimestamp timestamp when lending is enabled or disabled.
     * @param lendingPeriod         time for which lending will be enabled.
     * @param lendingPricePerDay    price per day for the lending.
     * @param isLendingEnabled      tells the status whether lending is enabled or disabled.
     * @param when                  when token is listed for the lending.
     */
    event Lending(
        uint256 indexed tokenId,
        uint256 indexed serialNo,
        uint256 lendingStartTimestamp,
        uint256 lendingPeriod,
        uint256 lendingPricePerDay,
        bool indexed isLendingEnabled,
        uint256 when
    );

    /**
     * @dev event to be emitted when token is borowed.
     *
     * @param tokenId           id of the token.
     * @param serialNo          serial number of the token.
     * @param borrowPeriod     time for which token is borrowed.
     * @param borrowPay         price on which token is borrowed.
     * @param when              when token is borrowed.
     */
    event Borrow(
        uint256 indexed tokenId,
        uint256 indexed serialNo,
        uint256 borrowPeriod,
        uint256 borrowPay,
        uint256 when
    );

    // ============================================================= //
    //                          MODIFIERS                            //
    // ============================================================= //

    // revert the transaction if lengths mismatch
    modifier denyIfLengthMismatch(uint256 arg1Length, uint256 arg2Length) {
        if (arg1Length == arg2Length) revert ArgsLengthMismatch();
        _;
    }

    // ============================================================= //
    //                          CONSTRUCTOR                          //
    // ============================================================= //

    // Inherits ERC1155 contract and sets initial Base URI also inherits Ownable, Pausabl and Auction Contracts.
    constructor(string memory initialBaseUri) Ownable() Pausable() Auction() {
        _setURI(initialBaseUri);
    }

    // ============================================================= //
    //                          CONSTRUCTOR                          //
    // ============================================================= //

    error ArgsLengthMismatch();
    error TokenOwnerAllowed();
    error TokenOwnerNotAllowed();
    error AlreadyMinted();
    error InsufficientBalance();
    error EndLending();
    error NotAvailableForOperation();
    error TokenExpired();
    error NotEnoughTokenLife();
    error AmountOutOfRange();
    error LifeMustBeMultipleofDay(uint256 howManyDays);
    error NoTransferOrBidBeforeSale();
    error InactiveToken();
    error ActiveToken();
    error AuctionInactive();
    error AuctionEnded();
    error OnlyWinnerToWidthdraw();
    error BorrowerActive();

    // ============================================================= //
    //                          METHODS                              //
    // ============================================================= //

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) private {
        _baseURI = newuri;
    }

    /**
     * @dev mints the token.
     *
     * Requirements:
     *
     *      ‼ to should not be a 0 address
     *
     * @param to                    address to which token is minted.
     * @param tokenId               id of the token.
     * @param amount                no. of the token to be minted.
     * @param price                 price of each token.
     * @param expectedUsageLife     expected usage life of the token.
     * @param expiry               expiry of the token.
     */
    function _mintBasic(
        address to,
        uint256 tokenId,
        uint256 amount,
        uint104 price,
        uint32 expectedUsageLife,
        uint48 expiry
    ) private {
        if (_tokenDetails[tokenId].isMinted) revert AlreadyMinted();
        // require(!_tokenDetails[tokenId].isMinted, "Already Minted");

        unchecked {
            _balances[tokenId][to] = amount;

            _tokenDetails[tokenId] = TokenDetails({
                totalSupply: amount,
                tokenPrice: price,
                expectedUsageLife: expectedUsageLife,
                isMinted: true,
                expireOn: expiry
            });
        }
    }

    /**
     * @dev mints the token.
     *
     * emits the MintSingle event.
     *
     * @param to                    address to which token is minted.
     * @param tokenId               id of the token.
     * @param amount                 amount of the tokens per id.
     * @param price                 price of each token.
     * @param expectedUsageLife     expected usage life of the token.
     * @param expiry               expiry of the token.
     */
    function mint(
        address to,
        uint256 tokenId,
        uint256 amount,
        uint104 price,
        uint32 expectedUsageLife,
        uint48 expiry
    ) external whenNotPaused {
        _mintBasic(to, tokenId, amount, price, expectedUsageLife, expiry);

        emit MintSingle(
            msg.sender,
            address(0),
            to,
            tokenId,
            amount,
            price,
            expectedUsageLife,
            expiry
        );
    }

    // /**
    //  * @dev mints the token.
    //  *
    //  * emits the MintMultiple event.
    //  *
    //  * @param to                    address to which token is minted.
    //  * @param tokenIds              ids of the token.
    //  * @param amounts               amounts of the tokens per id.
    //  * @param prices                price of token per id.
    //  * @param expectedUsageLives    expected usage life of the tokens.
    //  * @param expiries              expiry of the tokens.
    //  */
    // function mintBatch(
    //     address to,
    //     uint256[] memory tokenIds,
    //     uint256[] memory amounts,
    //     uint104[] memory prices,
    //     uint32[] memory expectedUsageLives,
    //     uint48[] memory expiries
    // )
    //     external
    //     whenNotPaused
    //     denyIfLengthMismatch(tokenIds.length, amounts.length)
    //     denyIfLengthMismatch(tokenIds.length, expectedUsageLives.length)
    //     denyIfLengthMismatch(tokenIds.length, expiries.length)
    // {
    //     for (uint256 i = 0; i < tokenIds.length; ++i) {
    //         _mintBasic(
    //             to,
    //             tokenIds[i],
    //             uint184(amounts[i]),
    //             prices[i],
    //             expectedUsageLives[i],
    //             expiries[i]
    //         );
    //     }

    //     emit MintBatch(
    //         msg.sender,
    //         address(0),
    //         to,
    //         tokenIds,
    //         amounts,
    //         prices,
    //         expectedUsageLives,
    //         expiries
    //     );
    // }

    function buyFromContract(
        address to,
        uint256 tokenId
    ) external whenNotPaused checkForInvalidAddress(to) {
        uint256 serialNo = _balances[tokenId][address(this)];

        if (serialNo == 0) revert InsufficientBalance();
        // require(serialNo == 0, "Insufficient Balance");
        if (block.timestamp < _tokenDetails[tokenId].expireOn)
            revert TokenExpired();
        // require(
        //     block.timestamp < _tokenDetails[tokenId].expireOn,
        //     "Expired, Cannot Sale"
        // );

        unchecked {
            _balances[tokenId][address(this)] = serialNo - 1;
            _balances[tokenId][to] += 1;
        }

        _tokenBearer[tokenId][serialNo].user = to;

        emit TransferSingle(msg.sender, address(this), to, tokenId, serialNo);
    }

    function listTokenForFixedPrice(
        uint256 tokenId,
        uint256 serialNo,
        uint104 amount
    ) external payable whenNotPaused {
        TokenBearer memory tokenOwner = _tokenBearer[tokenId][serialNo];

        if (tokenOwner.user != msg.sender) revert TokenOwnerAllowed();
        // require(tokenOwner.user == msg.sender, "Token Owner Allowed");
        if (tokenOwner.lendingStatus) revert EndLending();
        // require(!tokenOwner.lendingStatus, "First End Lending");
        if (tokenOwner.fixedOrAuction != 0) revert NotAvailableForOperation();
        // require(tokenOwner.fixedOrAuction == 0, "Not Available for Listing");
        // require(tokenOwner.fixedOrAuction == 1, "Already Listed");

        TokenDetails memory tokenDet = _tokenDetails[tokenId];

        if (tokenOwner.startOfLife == 0 && block.timestamp < tokenDet.expireOn)
            revert TokenExpired();
        // require(
        //     !(tokenOwner.startOfLife == 0 &&
        //         block.timestamp < tokenDet.expireOn),
        //     "Token Expired"
        // );
        if (
            tokenOwner.startOfLife != 0 &&
            block.timestamp > tokenOwner.endOfLife
        ) revert NotEnoughTokenLife();
        // require(
        //     !(tokenOwner.startOfLife != 0 &&
        //         block.timestamp > tokenOwner.endOfLife),
        //     "Not Enough Token Life"
        // );

        uint256 fixedPrice;
        uint256 fixedPriceFloor;
        uint256 fixedPriceCeil;

        unchecked {
            if (tokenOwner.startOfLife == 0) {
                fixedPrice = (tokenDet.tokenPrice / 100) * 90;
            } else {
                fixedPrice =
                    ((tokenDet.tokenPrice / 100) * 90) *
                    (((tokenOwner.endOfLife - tokenOwner.startOfLife) / 100) *
                        tokenOwner.endOfLife);
            }
            (fixedPriceFloor, fixedPriceCeil) = (
                fixedPrice / 1000 + _platformFeesInWei,
                fixedPrice / 10 + _platformFeesInWei
            );
        }

        if (amount < fixedPriceFloor && amount > fixedPriceCeil)
            revert AmountOutOfRange();
        // require(
        //     amount >= fixedPriceFloor && amount <= fixedPriceCeil,
        //     "Amount Out of Range"
        // );

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

        emit Listing(
            tokenId,
            serialNo,
            amount,
            tokenOwner.user,
            block.timestamp,
            true
        );
    }

    function changeListingForFixedPrice(
        uint256 tokenId,
        uint256 serialNo,
        uint104 amount
    ) external whenNotPaused {
        TokenBearer memory tokenOwner = _tokenBearer[tokenId][serialNo];

        if (tokenOwner.user != msg.sender) revert TokenOwnerAllowed();
        // require(tokenOwner.user == msg.sender, "Token Owner Allowed");
        if (tokenOwner.fixedOrAuction != 1) revert NotAvailableForOperation();
        // require(tokenOwner.fixedOrAuction == 1, "Must be Listed");

        TokenDetails memory tokenDet = _tokenDetails[tokenId];

        uint256 fixedPrice;
        uint256 fixedPriceFloor;
        uint256 fixedPriceCeil;

        unchecked {
            if (tokenOwner.startOfLife == 0) {
                fixedPrice = (tokenDet.tokenPrice / 100) * 90;
            } else {
                fixedPrice =
                    ((tokenDet.tokenPrice / 100) * 90) *
                    (((tokenOwner.endOfLife - tokenOwner.startOfLife) / 100) *
                        tokenOwner.endOfLife);
            }
            (fixedPriceFloor, fixedPriceCeil) = (
                fixedPrice / 1000,
                fixedPrice / 10
            );
        }

        uint104 newAmount = uint104(amount + tokenOwner.listingPrice);

        if (amount < fixedPriceFloor && amount > fixedPriceCeil)
            revert AmountOutOfRange();
        // require(
        //     newAmount >= fixedPriceFloor && newAmount <= fixedPriceCeil,
        //     "Amount Out of Range"
        // );

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

        emit Listing(
            tokenId,
            serialNo,
            newAmount,
            tokenOwner.user,
            block.timestamp,
            true
        );
    }

    function unlistTokenFromFixedPrice(
        uint256 tokenId,
        uint256 serialNo
    ) external whenNotPaused {
        TokenBearer memory tokenOwner = _tokenBearer[tokenId][serialNo];

        if (tokenOwner.user != msg.sender) revert TokenOwnerAllowed();
        // require(tokenOwner.user == msg.sender, "Token Owner Allowed");
        if (tokenOwner.fixedOrAuction != 0 || tokenOwner.fixedOrAuction != 2)
            revert NotAvailableForOperation();
        // require(tokenOwner.fixedOrAuction == 1, "Not Listed");

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

        emit Listing(
            tokenId,
            serialNo,
            0,
            tokenOwner.user,
            block.timestamp,
            false
        );
    }

    function buyFromUser(
        address from,
        address to,
        uint256 tokenId,
        uint256 serialNo
    ) external payable checkForInvalidAddress(to) whenNotPaused {
        TokenBearer memory tokenOwner = _tokenBearer[tokenId][serialNo];

        if (tokenOwner.fixedOrAuction != 0 || tokenOwner.fixedOrAuction != 2)
            revert NotAvailableForOperation();
        // require(tokenOwner.fixedOrAuction == 1, "Not Listed For Sale");

        if (
            tokenOwner.startOfLife == 0 &&
            block.timestamp < _tokenDetails[tokenId].expireOn
        ) revert TokenExpired();
        // require(
        //     !(tokenOwner.startOfLife == 0 &&
        //         block.timestamp < _tokenDetails[tokenId].expireOn),
        //     "Token Expired"
        // );
        if (
            tokenOwner.startOfLife != 0 &&
            block.timestamp > tokenOwner.endOfLife
        ) revert NotEnoughTokenLife();
        // require(
        //     !(tokenOwner.startOfLife != 0 &&
        //         block.timestamp > tokenOwner.endOfLife),
        //     "Not Enough Token Life"
        // );

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

        emit Listing(
            tokenId,
            serialNo,
            0,
            tokenOwner.user,
            block.timestamp,
            false
        );

        emit TransferSingle(msg.sender, from, to, tokenId, serialNo);
    }

    function listForAuction(
        uint256 tokenId,
        uint256 serialNo,
        uint48 biddingLife
    ) external whenNotPaused {
        TokenBearer memory tokenOwner = _tokenBearer[tokenId][serialNo];

        if (tokenOwner.fixedOrAuction != 0) revert NotAvailableForOperation();
        // require(tokenOwner.fixedOrAuction != 1, "Listed for Fixed Price");
        // require(tokenOwner.fixedOrAuction != 2, "Listed for Auction");
        if (tokenOwner.lendingStatus) revert EndLending();
        // require(!tokenOwner.lendingStatus, "First End Lending");
        if (tokenOwner.user != msg.sender) revert TokenOwnerAllowed();
        // require(tokenOwner.user == msg.sender, "Token Owner Allowed");
        if (
            biddingLife > 0 && biddingLife % 86400 == 0 && biddingLife >= 259200
        ) revert LifeMustBeMultipleofDay(3);
        // require(biddingLife != 0, "Invalid Time");
        // require(biddingLife % 86400 == 0, "Life Must be Multiple of Day");
        if (_balances[tokenId][address(this)] != 0)
            revert NoTransferOrBidBeforeSale();
        // require(
        //     _balances[tokenId][address(this)] == 0,
        //     "Auction Before Sale is Not Allowed"
        // );

        TokenDetails memory tokenDet = _tokenDetails[tokenId];

        if (tokenOwner.startOfLife == 0 && block.timestamp < tokenDet.expireOn)
            revert TokenExpired();
        // require(
        //     !(tokenOwner.startOfLife == 0 &&
        //         block.timestamp < tokenDet.expireOn),
        //     "Token Expired"
        // );
        if (
            tokenOwner.startOfLife != 0 &&
            block.timestamp + biddingLife > tokenOwner.endOfLife
        ) revert NotEnoughTokenLife();
        // require(
        //     !(tokenOwner.startOfLife != 0 &&
        //         block.timestamp + biddingLife > tokenOwner.endOfLife),
        //     "Not Enough Token Life"
        // );

        uint104 bidStartingPrice;

        unchecked {
            if (tokenOwner.startOfLife == 0) {
                bidStartingPrice = (tokenDet.tokenPrice / 100) * 50;
            } else {
                bidStartingPrice =
                    ((tokenDet.tokenPrice / 100) * 50) *
                    (((tokenOwner.endOfLife - tokenOwner.startOfLife) / 100) *
                        tokenOwner.endOfLife);
            }
        }

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
            biddingLife,
            bidStartingPrice,
            tokenOwner.user,
            block.timestamp,
            true
        );
    }

    function placeBidInAuction(
        uint256 tokenId,
        uint256 serialNo
    ) external payable override whenNotPaused {
        TokenBearer memory tokenOwner = _tokenBearer[tokenId][serialNo];

        if (tokenOwner.user == msg.sender) revert TokenOwnerNotAllowed();
        // require(tokenOwner.user != msg.sender, "Token Owner Not Allowed");
        if (!tokenOwner.isActivated) revert InactiveToken();
        // require(tokenOwner.isActivated, "Token Not Active");
        if (tokenOwner.fixedOrAuction != 2) revert AuctionInactive();
        // require(tokenOwner.fixedOrAuction == 2, "Auction Not Active");
        if (tokenOwner.biddingLife > block.timestamp) revert AuctionEnded();
        // require(tokenOwner.biddingLife < block.timestamp, "Auction Ended");

        if (
            tokenOwner.startOfLife == 0 &&
            block.timestamp < _tokenDetails[tokenId].expireOn
        ) revert TokenExpired();
        // require(
        //     !(tokenOwner.startOfLife == 0 &&
        //         block.timestamp < _tokenDetails[tokenId].expireOn),
        //     "Token Expired"
        // );
        if (
            tokenOwner.startOfLife != 0 &&
            block.timestamp > tokenOwner.endOfLife
        ) revert NotEnoughTokenLife();
        // require(
        //     !(tokenOwner.startOfLife != 0 &&
        //         block.timestamp > tokenOwner.endOfLife),
        //     "Not Enough Token Life"
        // );

        unchecked {
            _totalAmount += msg.value;
        }

        _placeBid(tokenId, serialNo, msg.value - _platformFeesInWei);
    }

    function revokeBidFromAuction(
        uint256 tokenId,
        uint256 serialNo
    ) external override whenNotPaused {
        unchecked {
            _totalAmount -= _otherBidders[tokenId][serialNo][msg.sender];
        }

        _revokeBid(tokenId, serialNo);
    }

    function widthdrawPrizeFromAuction(
        uint256 tokenId,
        uint256 serialNo
    ) external override whenNotPaused {
        TokenBearer memory tokenOwner = _tokenBearer[tokenId][serialNo];

        if (tokenOwner.user == msg.sender) revert TokenOwnerNotAllowed();
        // require(tokenOwner.user != msg.sender, "Token Owner Not Allowed");

        address highestBidder = _highestBidder[tokenId][serialNo];

        if (highestBidder != msg.sender) revert OnlyWinnerToWidthdraw();
        // require(highestBidder == msg.sender, "Winner is Allowed to Widthdraw");

        uint256 newBidAmount;

        unchecked {
            newBidAmount =
                _otherBidders[tokenId][serialNo][highestBidder] -
                _platformFeesInWei;
            _totalAmount -= newBidAmount;
            _balances[tokenId][msg.sender] += 1;
            _balances[tokenId][tokenOwner.user] -= 1;
        }

        _tokenBearer[tokenId][serialNo] = TokenBearer({
            user: msg.sender,
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

        payable(tokenOwner.user).transfer(newBidAmount);

        emit AuctionState(
            tokenId,
            serialNo,
            0,
            0,
            msg.sender,
            block.timestamp,
            false
        );

        emit TransferSingle(
            msg.sender,
            tokenOwner.user,
            msg.sender,
            tokenId,
            serialNo
        );
    }

    function listForLending(
        uint256 tokenId,
        uint256 serialNo,
        uint32 lendingPeriod,
        uint104 amount
    ) external whenNotPaused {
        TokenBearer memory tokenOwner = _tokenBearer[tokenId][serialNo];

        if (tokenOwner.user == msg.sender) revert TokenOwnerNotAllowed();
        // require(tokenOwner.user == msg.sender, "Token Owner Allowed");
        if (tokenOwner.fixedOrAuction != 0 || tokenOwner.lendingStatus)
            revert NotAvailableForOperation();
        // require(tokenOwner.fixedOrAuction == 0, "Not Available for Lending");
        // require(!tokenOwner.lendingStatus, "Already Listed for Lending");
        if (!tokenOwner.isActivated) revert InactiveToken();
        // require(tokenOwner.isActivated, "Token Must be Activated");
        if (
            lendingPeriod > 0 &&
            lendingPeriod % 86400 == 0 &&
            lendingPeriod >= 259200
        ) revert LifeMustBeMultipleofDay(3);
        // require(lendingPeriod % 86400 == 0, "Period Must be Multiple of Day");
        // require(lendingPeriod >= 259200, "Period Must be Min 3 Days");
        if (_balances[tokenId][address(this)] != 0)
            revert NoTransferOrBidBeforeSale();
        // require(
        //     _balances[tokenId][address(this)] == 0,
        //     "Lending Before Sale is Not Allowed"
        // );

        TokenDetails memory tokenDet = _tokenDetails[tokenId];

        if (tokenOwner.startOfLife == 0 && block.timestamp < tokenDet.expireOn)
            revert TokenExpired();
        // require(
        //     !(tokenOwner.startOfLife == 0 &&
        //         block.timestamp < tokenDet.expireOn),
        //     "Token Expired"
        // );
        if (
            tokenOwner.startOfLife != 0 &&
            block.timestamp + lendingPeriod > tokenOwner.endOfLife
        ) revert NotEnoughTokenLife();
        // require(
        //     !(tokenOwner.startOfLife != 0 &&
        //         block.timestamp + lendingPeriod > tokenOwner.endOfLife),
        //     "Not Enough Token Life"
        // );

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
            revert AmountOutOfRange();
        // require(
        //     amount >= lendingPriceFloor && amount <= lendingPriceCeil,
        //     "Amount Should be in Given Range"
        // );

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

        emit Lending(
            tokenId,
            serialNo,
            block.timestamp,
            lendingPeriod,
            amount,
            true,
            block.timestamp
        );
    }

    function unlistFromLending(
        uint256 tokenId,
        uint256 serialNo
    ) external whenNotPaused {
        TokenBearer memory tokenOwner = _tokenBearer[tokenId][serialNo];

        if (tokenOwner.user != msg.sender) revert TokenOwnerAllowed();
        // require(tokenOwner.user == msg.sender, "Token Owner Allowed");
        if (tokenOwner.user != msg.sender) revert TokenOwnerAllowed();
        // require(tokenOwner.lendingStatus, "Not Listed for Lending");
        if (
            tokenOwner.borrowingStartTimestamp + tokenOwner.borrowingPeriod >
            block.timestamp
        ) revert BorrowerActive();
        // require(
        //     tokenOwner.borrowingStartTimestamp + tokenOwner.borrowingPeriod <
        //         block.timestamp,
        //     "Cannot Unlist When Brrower is Active"
        // );

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

        emit Lending(tokenId, serialNo, 0, 0, 0, true, block.timestamp);
    }

    function borrowToken(
        uint256 tokenId,
        uint256 serialNo,
        uint32 borrowingPeriod
    ) external payable whenNotPaused {
        TokenBearer memory tokenOwner = _tokenBearer[tokenId][serialNo];

        if (tokenOwner.user == msg.sender) revert TokenOwnerNotAllowed();
        // require(tokenOwner.user != msg.sender, "Owner Not Allowed");
        if (!tokenOwner.lendingStatus) revert NotAvailableForOperation();
        // require(tokenOwner.lendingStatus, "Not Listed for Borrowing");
        if (
            tokenOwner.borrowingStartTimestamp + tokenOwner.borrowingPeriod >
            block.timestamp
        ) revert BorrowerActive();
        // require(
        //     tokenOwner.borrowingStartTimestamp + tokenOwner.borrowingPeriod <
        //         block.timestamp,
        //     "Already Borrowed"
        // );
        if (
            borrowingPeriod > 0 &&
            borrowingPeriod % 86400 == 0 &&
            borrowingPeriod >= 86400
        ) revert LifeMustBeMultipleofDay(1);
        // require(borrowingPeriod != 0, "Value of Days in Not Correct");
        // require(borrowingPeriod % 86400 == 0, "Period Must be Multiple of Day");
        // require(borrowingPeriod >= 86400, "Period Must be Min 1 Days");
        if (
            msg.value <
            (tokenOwner.lendingPricePerDay * borrowingPeriod) +
                _platformFeesInWei
        ) revert AmountOutOfRange();
        // require(
        //     msg.value >=
        //         (tokenOwner.lendingPricePerDay * borrowingPeriod) +
        //             _platformFeesInWei,
        //     "Invalid Price"
        // );

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
            borrowingPeriod,
            newAmount,
            block.timestamp
        );
    }

    function setPlatformFeesInWei(
        uint256 fee
    ) external onlyOwner whenNotPaused {
        _platformFeesInWei = fee;
    }

    function transferContractTotalAmount(
        uint256 amount
    ) external onlyOwner whenNotPaused {
        if (amount > _totalAmount) revert AmountOutOfRange();
        // require(amount <= _totalAmount, "Amount Too Large");

        unchecked {
            _totalAmount -= amount;
        }

        payable(msg.sender).transfer(amount);
    }

    function activateToken(
        uint256 tokenId,
        uint256 serialNo
    ) external whenNotPaused {
        TokenBearer memory tokenOwner = _tokenBearer[tokenId][serialNo];

        if (tokenOwner.user != msg.sender) revert TokenOwnerAllowed();
        // require(tokenOwner.user == msg.sender, "Token Owner Allowed");
        if (tokenOwner.isActivated) revert ActiveToken();
        // require(!tokenOwner.isActivated, "Already Activated");

        TokenDetails memory tokenDet = _tokenDetails[tokenId];

        if (tokenOwner.isActivated && tokenDet.expireOn < block.timestamp)
            revert TokenExpired();
        // require(
        //     tokenOwner.isActivated && tokenDet.expireOn > block.timestamp,
        //     "Token Expired"
        // );
        if (tokenOwner.fixedOrAuction != 0 || tokenOwner.lendingStatus)
            revert NotAvailableForOperation();
        // require(tokenOwner.fixedOrAuction == 0, "Listed for Sale or Auction");
        // require(!tokenOwner.lendingStatus, "Listed for Lending");

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

    function setUri(string memory newUri) external onlyOwner whenNotPaused {
        _setURI(newUri);
    }

    // CALLS
    // -----

    function uri(uint256) external view override returns (string memory) {
        return _baseURI;
    }

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
    function getPlatformFeesInWei() external view returns (uint256) {
        return _platformFeesInWei;
    }

    function getBalance(
        uint256 tokenId,
        address account
    ) external view override returns (uint256) {
        return _balances[tokenId][account];
    }

    function getTokenDetails(
        uint256 tokenId
    ) external view override returns (TokenDetails memory) {
        return _tokenDetails[tokenId];
    }

    function getTokenBearer(
        uint256 tokenId,
        uint256 serialNo
    ) external view override returns (TokenBearer memory) {
        return _tokenBearer[tokenId][serialNo];
    }

    function getHighestBidder(
        uint256 tokenId,
        uint256 serialNo
    ) external view override returns (address) {
        return _highestBidder[tokenId][serialNo];
    }

    function getOtherBidders(
        uint256 tokenId,
        uint256 serialNo,
        address bidder
    ) external view override returns (uint256) {
        return _otherBidders[tokenId][serialNo][bidder];
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
     * @param to                    address to which token is minted.
     * @param tokenId               id of the token.
     * @param amount                 amount of the tokens per id.
     * @param price                 price of each token.
     * @param expectedUsageLife     expected usage life of the token.
     * @param expiry               expiry of the token.
     */
    function mint(
        address to,
        uint256 tokenId,
        uint256 amount,
        uint104 price,
        uint32 expectedUsageLife,
        uint48 expiry
    ) external;

    // /**
    //  * @dev mints the token.
    //  *
    //  * emits the MintMultiple event.
    //  *
    //  * @param to                    address to which token is minted.
    //  * @param tokenIds              ids of the token.
    //  * @param amounts               amounts of the tokens per id.
    //  * @param prices                price of token per id.
    //  * @param expectedUsageLives    expected usage life of the tokens.
    //  * @param expiries              expiry of the tokens.
    //  */
    // function mintBatch(
    //     address to,
    //     uint256[] memory tokenIds,
    //     uint256[] memory amounts,
    //     uint104[] memory prices,
    //     uint32[] memory expectedUsageLives,
    //     uint48[] memory expiries
    // ) external;

    function buyFromContract(address to, uint256 tokenId) external;

    function listTokenForFixedPrice(
        uint256 tokenId,
        uint256 serialNo,
        uint104 amount
    ) external payable;

    function changeListingForFixedPrice(
        uint256 tokenId,
        uint256 serialNo,
        uint104 amount
    ) external;

    function unlistTokenFromFixedPrice(
        uint256 tokenId,
        uint256 serialNo
    ) external;

    function buyFromUser(
        address from,
        address to,
        uint256 tokenId,
        uint256 serialNo
    ) external payable;

    function listForAuction(
        uint256 tokenId,
        uint256 serialNo,
        uint48 biddingLife
    ) external;

    function listForLending(
        uint256 tokenId,
        uint256 serialNo,
        uint32 lendingPeriod,
        uint104 amount
    ) external;

    function unlistFromLending(uint256 tokenId, uint256 serialNo) external;

    function setPlatformFeesInWei(uint256 fee) external;

    function activateToken(uint256 tokenId, uint256 serialNo) external;

    function setUri(string memory newUri) external;

    function uri(uint256) external view returns (string memory);

    function getTotalAmountOfContract() external view returns (uint256);

    function getPlatformFeesInWei() external view returns (uint256);

    function getTokenDetails(
        uint256 tokenId
    ) external view returns (TokenDetails memory);

    function getTokenBearer(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (TokenBearer memory);

    function getBalance(
        uint256 tokenId,
        address account
    ) external view returns (uint256);

    function getHighestBidder(
        uint256 tokenId,
        uint256 serialNo
    ) external view returns (address);

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

/**
 * @title Auction:
 *
 * @author Farasat Ali
 *
 * @dev Provides the facility for bidding.
 */
contract Auction is IAuction {
    // ============================================================= //
    //                          VARIABLES                            //
    // ============================================================= //

    mapping(uint256 tokenId => mapping(uint256 serialNo => address bidder))
        internal _highestBidder;

    mapping(uint256 tokenId => mapping(uint256 serialNo => mapping(address bidder => uint256 bidAmount)))
        internal _otherBidders;

    // ============================================================= //
    //                          Events                               //
    // ============================================================= //

    event Bid(
        uint256 indexed tokenId,
        uint256 indexed serialNo,
        address bidder,
        uint256 addedAmount,
        uint256 totalAmount,
        bool indexed placed
    );

    // ============================================================= //
    //                          ERRORS                               //
    // ============================================================= //

    error BidLowerThanPrevious();
    error NoBid();
    error HighestBidderCannotRevoke();

    // ============================================================= //
    //                          METHODS                              //
    // ============================================================= //

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
            revert BidLowerThanPrevious();
        // require(
        //     currentBidderAmount + amount > highestBidderAmount,
        //     "Bid Lower Than Previous"
        // );

        uint256 totalAmout = _otherBidders[tokenId][serialNo][msg.sender] +
            amount;
        _otherBidders[tokenId][serialNo][msg.sender] = totalAmout;

        emit Bid(tokenId, serialNo, msg.sender, amount, totalAmout, true);
    }

    function placeBidInAuction(
        uint256 tokenId,
        uint256 serialNo
    ) external payable virtual override {
        _placeBid(tokenId, serialNo, msg.value);
    }

    function _revokeBid(uint256 tokenId, uint256 serialNo) internal virtual {
        uint256 bidderAmout = _otherBidders[tokenId][serialNo][msg.sender];

        if (bidderAmout == 0) revert NoBid();
        // require(bidderAmout > 0, "No Bid");
        if (_highestBidder[tokenId][serialNo] == msg.sender)
            revert HighestBidderCannotRevoke();
        // require(
        //     _highestBidder[tokenId][serialNo] != msg.sender,
        //     "Higest Bidder Not Allowed to Revoke"
        // );

        _otherBidders[tokenId][serialNo][msg.sender] = 0;

        payable(msg.sender).transfer(bidderAmout);

        emit Bid(tokenId, serialNo, msg.sender, 0, 0, false);
    }

    function revokeBidFromAuction(
        uint256 tokenId,
        uint256 serialNo
    ) external virtual override {
        _revokeBid(tokenId, serialNo);
    }

    function widthdrawPrizeFromAuction(
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
 * @dev inteface for Auction.
 */
interface IAuction {
    function placeBidInAuction(
        uint256 tokenId,
        uint256 serialNo
    ) external payable;

    function revokeBidFromAuction(uint256 tokenId, uint256 serialNo) external;

    function widthdrawPrizeFromAuction(
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
 * @notice interface to make contracts pausable by apply restriction
 * using isPaused function.
 * 
 * @dev This interface provide functions which allows to stop the whole
 * contract in case of emerdgency or any other reasons
 */
interface IPausable {
    /**
     * @dev return the status of contract - either it is paused or not
     * @return paused contains status of paused or unpaused
     */
    function isPaused() external returns (bool paused);

    /**
     * @dev pause the contract.
     */
    function pause() external;

    /**
     * @dev pause the contract.
     */
    function unpause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./interfaces/IPausable.sol";

/**
 * @title Pausable:
 *
 * @author Farasat Ali.
 *
 * @notice give ability to pause the whole contract.
 *
 * @dev allows to stop the whole contract in case of emerdgency or any
 * other reasons using pause and unpause functions.
 */
contract Pausable is IPausable {
    // ============================================================= //
    //                          VARIABLES                            //
    // ============================================================= //

    /**
     * @notice store paused or unpaused status.
     *
     * @dev it stores boolean in which `true` represents that the
     * contract is paused and `false` represents contract is not paused.
     */
    bool private _paused = false;

    // ============================================================= //
    //                          EVENTS                               //
    // ============================================================= //

    /**
     * @notice event to be emitted on pause state change.
     *
     * @dev event is emitted when a contract is paused or unpaused with
     * the account address, pause status and the time of occurance.
     *
     * @param status status shows that whether the contract is paused or unpaused i.e. `true` for paused and `false` for unpaused.
     * @param when timestamp when pause or unpause is happend.
     */
    event PauseState(bool indexed status, uint indexed when);

    // ============================================================= //
    //                          Errors                               //
    // ============================================================= //

    error Paused(bool status);

    // ============================================================= //
    //                          MODIFIERS                            //
    // ============================================================= //

    /**
     * @notice revert if pause is called and the state is already
     * in paused state.
     *
     * @dev check if the contract is already paused i.e. private paused
     * variable is `true` then it revert the function.
     */
    modifier whenNotPaused() {
        if (isPaused()) revert Paused(true);
        // require(!isPaused(), "Pausable: paused");
        _;
    }

    /**
     * @notice revert if unpause is called and the state is already
     * in unpaused state.
     *
     * @dev check if the contract is already unpaused i.e. private paused
     * variable is `false` then it revert the function.
     */
    modifier whenPaused() {
        if (!isPaused()) revert Paused(false);
        // require(isPaused(), "Pausable: not paused");
        _;
    }

    // ============================================================= //
    //                          METHODS                              //
    // ============================================================= //

    /**
     * @notice tells either the contract is paused or not.
     *
     * @dev tells the pause or unpaused status of the contract by returning
     * `true` if the contract is paused, and `false` otherwise.
     *
     * @return paused contain `true` if paused while `false` if not paused.
     */
    function isPaused() public view returns (bool paused) {
        return paused = _paused;
    }

    /**
     * @notice pauses the contract.
     *
     * @dev change the contract state to paused by setting the private
     * paused variable to true.
     *
     * emits the PauseState event with true and latest block timestamp.
     *
     * > Conditions to pass includes:
     * > - ❗ should not be already in paused state.
     *
     */
    function pause() external override whenNotPaused {
        _paused = true;
        emit PauseState(true, block.timestamp);
    }

    /**
     * @notice unpauses the contract.
     *
     * @dev change the contract state to unpaused by setting the private
     * paused variable to false.
     *
     * emits the PauseState event with false and latest block timestamp.
     *
     * > Conditions to pass includes:
     * > - ❗ should not be already in unpaused state.
     *
     */
    function unpause() external override whenPaused {
        _paused = false;
        emit PauseState(false, block.timestamp);
    }
}