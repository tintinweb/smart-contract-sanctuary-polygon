//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

pragma solidity ^0.8.9;

contract NFDsMarketplace is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    //Divider which used in `calculatePercent` function
    uint256 constant PERCENT_DIVIDER_DECIMALS = 100000;

    enum NFDsState {
        created,
        active,
        closed,
        conflicted,
        conflictResolved
    }

    enum BidState {
        created,
        won,
        paid,
        lost
    }

    enum TokenState { 
        unaccepted,
        accepted,
        feeFree
    }

    // NFDs structure
    struct NFDs {
        uint256 id; //Id of NFDs
        uint128 startsAt; //Lease commencement time
        uint128 endsAt; //Lease end time
        uint128 biddingStartsAt; //Start time of bidding, when users can make bid for NFDs
        uint128 biddingEndsAt; //End time of bidding, when bidding end
        uint256 winnerDeclaredAt; //Last timestamp for choise winner
        uint256 winnerBidId; //Id of winner's bid
        address spaceOwner; //Address of NFDs owner
        string infoUrl; //infoUrl of NFDs
        NFDsState state; //State of NFDs
        address acceptedToken; //Address of token accepted for exchange
    }

    // bid structure
    struct Bid {
        address bidder; //Address of user who which make a bid
        uint256 price; //Amount of NFDs accepted tokens, which bidder pay for rent
        address arbitrator; // Address of arbitrator
        BidState state; //State of bid
        string metaDataUrl; //metaDataUri which user want to assign
        uint128 createdAt; //Block timestamp when bid was created
    }

    //List of tokens accepted for exchange
    //AcceptedTokenList[_AcceptedToken] = TokenState
    mapping(address => TokenState) public acceptedTokenList;

    //List of bids of NFDs
    //bids[NFDsId] = Bid struct
    mapping(uint256 => Bid[]) bids;

    //Address for receive fee
    address public marketplaceFeeReceiver;

    //Amount of arbitrator fee
    uint96 public arbitratorFee;

    /**
     * @dev Amount of marketplace fee
     * Fee is a percentage of the price, but in this case we can't use 100% because of solidity restrictions
     * We can use 100000 like representation of 100.
     * For example 30% is equal to the fraction 30/100,
     * We multiplied 100 by 1000 and multiply 30 by 1000 to keep the ratio
     * We end up with a fraction of 300/1000, which is equivalent to 30/100
     * If you want set marketplace fee in 30%, you need set fee variable in 30000
     * If you want set marketplace fee in 10%, you need set fee varible in 10000
     * The same rule workes with `arbitratorFee` variable
     */
    uint96 public fee;

    //Array of NFDs structs
    NFDs[] NFDS;

    /**
     * @dev Emitted when `updateTokenList` change state of token
     */
    event TokenListUpdated(address indexed updatedToken, TokenState state);

    /**
     * @dev Emitted when `makeBid` created new Offer
     */
    event BidMade(
        address indexed bidder,
        Bid bid,
        uint256 id,
        uint256 bidId
    );

    /**
     * @dev Emitted when `listNFDs` created new NFDs
     */
    event NFDsListed(address indexed spaceowner, NFDs nfds);

    /**
     * @dev Emitted when spaceowner calls `acceptBid` and make NFDs active
     */
    event BidAccepted(
        uint256 id,
        uint256 bidId,
        uint256 startAt,
        uint256 endsAt
    );

    /**
     * @dev Emitted when spaceowner calls `rejectBid`
     */
    event BidRejected(
        uint256 id,
        uint256 bidId
    );


    /**
     * @dev Emitted when ADMIN `setParameters`
     */
    event ParametersChanged(
        uint256 newFee,
        uint256 newarbitratorFee,
        address indexed marketplaceFeeReceiver
    );

    /**
     * @dev Emitted when spaceowner `claim` accepted tokens
     */
    event TokensClaimed(address _spaceowner, uint256 _amount, uint256 _id);

    /**
     * @dev Emitted when ADMIN `claimRefund` unlock NFDs
     */
    event TokensRefunded(address sender, uint256 NFDsId, uint256 bidId);

    /**
     * @dev Emitted when `initializeConflict` lock NFDs
     */
    event NFDsConflicted(
        address indexed initiator,
        uint256 _id,
        address indexed arbitrator
    );

    /**
     * @dev Emitted when ADMIN `resolveConflict` unlock NFDs
     */
    event ConflictResolved(
        uint256 id,
        address arbitrator,
        uint256 marketplaceCut,
        uint256 arbitratorCut,
        uint256 renterCut,
        uint256 spaceOwnerCut
    );

    /**
     * @param _marketplaceFeeReceiver - address of fee receiver
     * @param _fee - amount of marketplace fee for `claim` and `resolveConflict`
     * @param _arbitratorFee - amount of fee for arbitrator
     */
    constructor(
        address _marketplaceFeeReceiver,
        uint96 _fee,
        uint96 _arbitratorFee
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        setParameters(_fee, _arbitratorFee, _marketplaceFeeReceiver);
    }

    /** @notice Initialize NFDs.
     * @dev Create new NFDs struct.
     * @dev emit `NFDsListed` event.
     * @param _startsAt block.timestamp when NFDs rent starts
     * @param _endsAt block.timestamp when NFDs rent end
     * @param _biddingStartsAt start time when users can make bid on NFDs
     * @param _biddingEndsAt last time when users can make bid on NFDs
     * @param _winnerDeclaredAt spaceOwner must choise winner before this time
     * @param _infoUrl information about NFDs
     * @param _acceptedToken which bidders must pay for rent
     */
    function listNFDs(
        uint128 _startsAt,
        uint128 _endsAt,
        uint128 _biddingStartsAt,
        uint128 _biddingEndsAt,
        uint256 _winnerDeclaredAt,
        string calldata _infoUrl,
        address _acceptedToken
    ) external {
        require(
            acceptedTokenList[_acceptedToken] != TokenState.unaccepted,
            "listNFDs: token is not in the list of accepted tokens."
        );

        require(
            _biddingEndsAt > block.timestamp &&
                _biddingStartsAt < _biddingEndsAt &&
                _biddingEndsAt < _winnerDeclaredAt &&
                _winnerDeclaredAt < _startsAt &&
                _startsAt < _endsAt,
            "listNFDs: invalid time declaration"
        );

        uint256 _id = NFDS.length;
        NFDS.push(
            NFDs({
                id: _id,
                startsAt: _startsAt,
                endsAt: _endsAt,
                biddingStartsAt: _biddingStartsAt,
                biddingEndsAt: _biddingEndsAt,
                winnerDeclaredAt: _winnerDeclaredAt,
                winnerBidId: 0,
                spaceOwner: msg.sender,
                infoUrl: _infoUrl,
                state: NFDsState.created,
                acceptedToken: _acceptedToken
            })
        );

        emit NFDsListed(msg.sender, NFDS[_id]);
    }

    /** @notice Create offer for participate in NFDs.
     * @dev Create new bid struct.
     * @dev emit `BidMade` event.
     * @param _id id of NFDs in which bidder want to participate.
     * @param _price Amount of accepted tokens, which user want to pay for rent
     * @param _arbitrator Address of user who resolve conflict in NFDs
     * @param _metaDataUrl Url which renter want to set in NFDs
     */
    function makeBid(
        uint256 _id,
        uint256 _price,
        address _arbitrator,
        string calldata _metaDataUrl
    ) external {
        NFDs storage nfds = NFDS[_id];
        require(
            nfds.biddingStartsAt < block.timestamp &&
                nfds.biddingEndsAt > block.timestamp,
            "makeBid: invalid bidding time"
        );
        require(
            nfds.state == NFDsState.created,
            "makeBid: NFDs state must be created"
        );
        require(_price > 0, "makeBid: price must be bigger then zero");

        IERC20(nfds.acceptedToken).safeTransferFrom(
            msg.sender,
            address(this),
            _price
        );

        // create bid and add to bids list
        Bid memory bid = Bid({
            bidder: msg.sender,
            price: _price,
            createdAt: uint128(block.timestamp),
            arbitrator: _arbitrator,
            state: BidState.created,
            metaDataUrl: _metaDataUrl
        });
        bids[_id].push(bid);

        // emit BidMade event
        emit BidMade(
            msg.sender,
            bid,
            _id,
            (bids[_id].length - 1)
        );
    }

    /** @notice Accept offer chosen by spaceowner.
     * @dev change NFDs state to active
     * @dev emit `BidAccepted` event.
     * @param _id id of NFDs for which spaceowner want to choise bid.
     * @param _bidId. id of chosen bid
     */
    function acceptBid(uint256 _id, uint256 _bidId) external {
        NFDs storage nfds = NFDS[_id];
        require(
            nfds.state == NFDsState.created,
            "acceptBid: NFDs state must be `created`"
        );
        require(
            nfds.spaceOwner == msg.sender,
            "acceptBid: caller is not token owner"
        );
        Bid storage winBid = bids[_id][_bidId];
        require(
            nfds.winnerDeclaredAt > block.timestamp &&
                nfds.biddingStartsAt < block.timestamp &&
                winBid.state == BidState.created,
            "acceptBid: invalid winner declare time."
        );
        require(winBid.price > 0, "Price must be bigger then zero");

        winBid.state = BidState.won;

        nfds.winnerBidId = _bidId;
        nfds.state = NFDsState.active;
        nfds.winnerDeclaredAt = block.timestamp;

        emit BidAccepted(_id, _bidId, nfds.startsAt, nfds.endsAt);
    }

    /** @notice Reject bid, used by spaceowner
     * @dev transfer `price` of accepted tokens to bidder address.
     * @dev emit `TokenRefunded` event.
     * @param _id id of NFDs for which spaceOwner want to reject bid.
     * @param _bidId id of bid which spaceOwner want to reject.
     */
    function rejectBid(uint256 _id, uint256 _bidId) external nonReentrant {
        require(
            msg.sender == NFDS[_id].spaceOwner,
            "Caller is not space owner"
        );
        
        // refund the bid
        _claimRefund(_id, _bidId);

        // emit event
        emit BidRejected(_id, _bidId);
    }

    /** @notice Claim refund tokens by bidder.
     * @dev transfer `price` of accepted tokens to bidder address.
     * @dev emit `TokenRefunded` event.
     * @param _id id of NFDs for which bidder wants to get tokens.
     * @param _bidId id of bid for which bidder refund tokens.
     */
    function claimRefund(uint256 _id, uint256 _bidId) external nonReentrant {
        require(msg.sender == bids[_id][_bidId].bidder, "Caller is not bidder");
        require(
            NFDS[_id].winnerDeclaredAt < block.timestamp,
            "It is not time yet."
        );
        _claimRefund(_id, _bidId);
    }

    /** @notice Claim accepted tokens after rentPeriod.
     * @dev transfer `price` to spaceowner address.
     * @dev change NFDs state to `listed`
     * @dev emit `TokensClaimed` event.
     * @param _id id of NFDs for which spaceowner wants to get tokens.
     */
    function claim(uint256 _id) external nonReentrant {
        NFDs storage nfds = NFDS[_id];
        Bid storage bid = bids[_id][nfds.winnerBidId];

        require(nfds.spaceOwner == msg.sender, "Not token owner");
        require(nfds.state == NFDsState.active, "State must be active");
        require(nfds.endsAt < block.timestamp, "claim: it's not time yet");
        require(bid.state == BidState.won, "Bid state must be won");

        uint256 _marketPlaceCut;
        if (acceptedTokenList[nfds.acceptedToken] == TokenState.accepted) {
            _marketPlaceCut = calculatePercent(fee, bid.price);
            IERC20(nfds.acceptedToken).safeTransfer(
                marketplaceFeeReceiver,
                _marketPlaceCut
            );
        }

        uint256 _arbitratorsCut;
        if (bid.arbitrator != address(0)) {
            _arbitratorsCut = calculatePercent(arbitratorFee, bid.price);
            IERC20(nfds.acceptedToken).safeTransfer(
                bid.arbitrator,
                _arbitratorsCut
            );
        }

        uint256 rentPaid = bid.price - _marketPlaceCut - _arbitratorsCut;
        IERC20(nfds.acceptedToken).safeTransfer(msg.sender, rentPaid);

        bid.state = BidState.paid;
        nfds.state = NFDsState.closed;

        emit TokensClaimed(msg.sender, rentPaid, _id);
    }

    /** @notice Lock NFDs Listing on contract for dispute time.
     * @dev should not lock the show
     * @dev change NFDs state to `locked`
     * @dev emit `NFDsConflicted` event.
     * @param _id id of conflicted NFDs.
     */
    function initializeConflict(uint256 _id) external nonReentrant {
        NFDs storage nfds = NFDS[_id];
        // first check for NFDs state
        require(nfds.state == NFDsState.active, "State must be active");
        require(
            nfds.startsAt < block.timestamp && nfds.endsAt > block.timestamp,
            "initializeConflict: time for initialize conflict is not have come yet"
        );
 
        Bid storage bid = bids[_id][nfds.winnerBidId];
        require(
            bid.state == BidState.won, 
            "initializeConflict: invalid bid state"
        );
        require(
            nfds.spaceOwner == msg.sender || bid.bidder == msg.sender,
            "Caller is not an participant."
        );
        require(
            bid.arbitrator != address(0),
            "initializeConflict: can not start conflict without arbitrator"
        );

        nfds.state = NFDsState.conflicted;

        emit NFDsConflicted(msg.sender, _id, bid.arbitrator);
    }

    /** @notice Unlock NFDs Listing.
     * @dev change NFDs state to `conflictResolved`
     * @dev emit `ConflictResolved` event.
     * @param _id id of conflicted NFDs.
     * @param _percentOfSpaceOwner percent of spaceOwner from price.
     */
    function resolveConflict(uint256 _id, uint96 _percentOfSpaceOwner)
        external
        nonReentrant
    {
        NFDs storage nfds = NFDS[_id];
        require(nfds.state == NFDsState.conflicted, "Invalid state");
        Bid storage bid = bids[_id][nfds.winnerBidId];
        require(bid.arbitrator == msg.sender, "Caller is not an arbitrator");
        require(_percentOfSpaceOwner <= PERCENT_DIVIDER_DECIMALS, "Invalid percentage");
        require(bid.state == BidState.won, "Bid state must be won");

        uint256 arbitratorCut = calculatePercent(arbitratorFee, bid.price);
        uint256 marketPlaceCut;
        if (acceptedTokenList[nfds.acceptedToken] == TokenState.accepted) {
            marketPlaceCut = calculatePercent(fee, bid.price);
            IERC20(nfds.acceptedToken).safeTransfer(
                marketplaceFeeReceiver,
                marketPlaceCut
            );
        }

        uint256 usersCut = (bid.price - arbitratorCut) - marketPlaceCut;
        uint256 spaceOwnerCut = calculatePercent(
            _percentOfSpaceOwner,
            usersCut
        );
        uint256 renterCut = usersCut - spaceOwnerCut;

        IERC20(nfds.acceptedToken).safeTransfer(bid.arbitrator, arbitratorCut);
        IERC20(nfds.acceptedToken).safeTransfer(nfds.spaceOwner, spaceOwnerCut);
        IERC20(nfds.acceptedToken).safeTransfer(bid.bidder, renterCut);

        nfds.state = NFDsState.conflictResolved;
        bid.state = BidState.paid;

        emit ConflictResolved(
            _id,
            bid.arbitrator,
            marketPlaceCut,
            arbitratorCut,
            renterCut,
            spaceOwnerCut
        );
    }

    /** @notice Set new parametres for marketplace.
     * @dev emit `ParametersChanged` event.
     * @param _newMarketplaceFeeReceiver new address for receiving marketplace fee.
     * @param _newArbitratorFee percent of fee, taken from transaction by arbitrator.
     * @param _newFee percent of fee, taken from transaction by marketplace.
     */
    function setParameters(
        uint96 _newFee,
        uint96 _newArbitratorFee,
        address _newMarketplaceFeeReceiver
    ) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin.");
        require(
            _newFee <= PERCENT_DIVIDER_DECIMALS &&
                _newArbitratorFee <= PERCENT_DIVIDER_DECIMALS &&
                _newFee + _newArbitratorFee <= PERCENT_DIVIDER_DECIMALS &&
                _newMarketplaceFeeReceiver != address(0),
            "Invalid parameters"
        );

        arbitratorFee = _newArbitratorFee;
        fee = _newFee;
        marketplaceFeeReceiver = _newMarketplaceFeeReceiver;

        emit ParametersChanged(
            _newFee,
            _newArbitratorFee,
            _newMarketplaceFeeReceiver
        );
    }

    /**
     * @dev Add or remove a token address from the list of allowed to be accepted for exchange
     */
    function updateTokenList(address _token, TokenState _state) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin.");
        require(_token != address(0), "Token address can't be address(0).");

        acceptedTokenList[_token] = _state;

        emit TokenListUpdated(_token, _state);
    }

    /** @notice internal function for rejecting bids and refund tokens.
     * @dev emit `TokensRefunded` event.
     */
    function _claimRefund(uint256 _id, uint256 _bidId) internal {
        Bid storage bid = bids[_id][_bidId];
        NFDs storage nfds = NFDS[_id];
        require(nfds.biddingStartsAt < block.timestamp, "It is not time yet.");
        require(bid.price > 0, "Price must be bigger then zero");
        require(bid.state == BidState.created, "Invalid bid state");

        bid.state = BidState.lost;

        IERC20(nfds.acceptedToken).safeTransfer(bid.bidder, bid.price);

        emit TokensRefunded(bid.bidder, _id, _bidId);
    }

    function calculatePercent(uint256 _percent, uint256 _price)
        private
        pure
        returns (uint256)
    {
        return
            ((_percent * _price) /
            PERCENT_DIVIDER_DECIMALS);
    }

    /** 
        @notice Getter for NFDS.
    */
    function getNFDS(uint256[] memory _ids)
        external
        view
        returns (NFDs[] memory NFDSList)
    {
        NFDSList = new NFDs[](_ids.length);
        for (uint256 i; i < _ids.length; i++) {
            NFDSList[i] = NFDS[_ids[i]];
        }

        return (NFDSList);
    }

    /**
        Getter for Url
     */
    function getUrl(uint256 _id) external view returns (string memory) {
        return bids[_id][NFDS[_id].winnerBidId].metaDataUrl;
    }

    /**
        Getter for Bids of the specific NFDS
        _id: id of the NFDs to query for
     */
    function getBids(uint256 _id)
        external
        view
        returns (Bid[] memory)
    {
        return bids[_id];
    }

    function getData()
        external
        view
        returns (
            address,
            uint96,
            uint96
        )
    {
        return (marketplaceFeeReceiver, arbitratorFee, fee);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}