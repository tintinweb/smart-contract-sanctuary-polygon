// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./Strings.sol";
import "./Counters.sol";
import "./Context.sol";
import "./Address.sol";

import "./IERC721.sol";
//import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./ERC165.sol";

import "./Initializable.sol";

import { IProofOfGoodLedger } from './IProofOfGoodLedger.sol';

//import './console.sol';
// pragma experimental ABIEncoderV2;

import { Base64 } from './base64.sol';

contract ProofOfGoodLedger is Initializable, IProofOfGoodLedger, Context, ERC165, IERC721, IERC721Metadata {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // Token name, symbol
    string private _name;
    string private _symbol;
    string internal _baseURI;

    Counters.Counter private maxTokenId;

    // status enum
    enum Status {
        NEW,
        ACTIVE,
        DELETED,
        PAUSED,
        QUARANTINED
    }

    //sum of all good done
    uint256 public totalGood;  // totalGoodByCategory[0]
    //sum of all good redeemed
//    uint256 public totalGoodRedeemed;

    // bridge
    mapping(address => bool) public goodPointsBridgeAddresses;

    //sum of all good done by category
//    mapping(uint32 => uint256) public totalGoodByCategory;
    //type id to struct
    mapping(uint256 => GoodType) public goodTypes;

    //category id to struct
    mapping(uint256 => GoodCategory) public goodCategories;
    //activity id to struct
    mapping(uint256 => GoodActivity) public goodActivities;
    //oracle id to struct
    mapping(uint256 => GoodOracle) public goodOracles;

    // make the oracle names unique
    mapping(string => uint256) public goodOracleNames;

    mapping(address => bool) public admins;

    // users to good oracle id
    mapping(address => mapping(uint256 => bool)) public goodOracleUsers;

    //user address to POG profile - userid
    mapping(address => bytes32) public walletUser;

    // hash of user email to POG profile - userid
    mapping(bytes32 => bytes32) public userByEmailHash;

    // userid to POG profile
    mapping(bytes32 => ProofOfGoodProfile) public profile;

    mapping(bytes32 => mapping(uint256 => Balances)) userBalancesByCategory;

    bytes32 constant ZeroHash = 0x0000000000000000000000000000000000000000000000000000000000000000;

    //single Proof-of-Good Entry
    struct ProofOfGoodEntry {
        uint256 tokenId; // ERC721 NFT token id
        uint256 goodActivityId; // activity
        uint256 goodOracleId; //Verifying org id
        uint256 units; //scale of good represented by this
        address doGooder;
        uint64 timestamp; //unix epoch 64 bit timestamp
        uint256 goodPoints; //total value of Good Points
        bytes32 externalId; //POA event id linkage, org id, or other id type
//        string proofURL; //link to external (IPFS) bundle of supporting assets
        string imageURL; //link to external image
        string mediaURL; //link to external media
//        uint256 createdTime; // block.timestamp (seconds)
    }
    //single Proof-of-Good Entry params
    struct ProofOfGoodEntryParams {
        address doGooder; // need at least one of userId, doGooder, emailHash. used in that order.
        bytes32 emailHash;
        bytes32 userId;
        uint256 goodActivityId; // activity. NOTE: contract size gets bigger if we make smaller uint size.
        uint256 goodOracleId; //Verifying org id
        uint256 units; //scale of good represented by this
        uint64 timestamp; //unix epoch 64 bit timestamp
        bytes32 externalId; //POA event id linkage, org id, or other id type
//        string proofURL; //link to external (IPFS) bundle of supporting assets
        string imageURL; //link to external image
        string mediaURL; //link to external media
    }

    struct Balances {
//        uint32 categoryId;
        uint256 balance; //total Good Point balance
        uint256 totalGood; //non-decrementing summary of all good done sofar
//        uint64 totalGoodRedeemed; //non-decrementing summary of all good redeemed sofar
    }

    struct CategoryBalances {
        uint256 categoryId;
        Balances balances;
    }

    //list of proofs and current balance for an address
    struct ProofOfGoodProfile {
        bytes32 userId;
        address[] walletAddresses;

        // - could use Balances struct but uses more code space;
        uint256 balance; //total Good Point balance
        uint256 totalGood; //non-decrementing summary of all good done sofar
//        uint64 totalGoodRedeemed; //non-decrementing summary of all good redeemed sofar
        uint256[] categories;
        uint256[] entries;
    }

    mapping(uint256 => ProofOfGoodEntry) public tokens;

    struct GoodCategory {
        uint256 id;
        Status status;
        string name;
    }

    struct GoodType {
        uint256 id;
        Status status;
        string name;
    }

    struct GoodActivity {
        uint256 id;
        uint256[] goodTypeIdArray;
        uint256 goodCategoryId;
        uint256 valuePerUnit;
        Status status;
        string name;
        string unitDescription;
//        string imageURL;
    }

    struct GoodOracle {
        uint256 id;   // uses less contract size vs uint32.
        address wallet;
        Status status;
        uint8 organizationType;
        string name;
        string goodOracleURI;
        uint256[] approvedActivityIdArray;
    }

    struct GoodPointsCap {
        uint64 duration;  // seconds
        uint256 goodPoints;
    }
    mapping(uint256 => mapping(uint256 => GoodPointsCap)) public cap;  // activityId, goodOracleId => cap ; 0,oracle for oracle total

    Counters.Counter private maxGoodOracleId;
    Counters.Counter public maxGoodCategoryId;
    Counters.Counter public maxGoodTypeId;
    Counters.Counter public maxGoodActivityId;

    event GoodCategoryUpdated(uint256 indexed id, string name, Status status);
    event GoodTypeUpdated(uint256 indexed id, string name, Status status);
    event GoodActivityUpdated(uint256 indexed id, uint256[] goodTypeIdArray, uint256 indexed goodCategoryId, string name, uint256 valuePerUnit, string unitDescription, Status status);
    event GoodOracleUpdated(uint256 indexed id, string name, string goodOracleURI, Status status, uint256[] approvedActivityIdArray);

    event GoodPointsRedeemed(address indexed doGooder, uint256 amount, uint256 balance, uint256 indexed goodCategoryId);
    
    event ProofOfGoodEntryCreated(uint256 indexed tokenId, address indexed doGooder, //bytes32 emailHash,
        bytes32 userId, uint256 goodActivityId, uint256 indexed goodOracleId, string imageURL, uint256 goodPoints,
        uint256 units, uint64 timestamp, bytes32 externalId);

    event ProofOfGoodEntryBurned(uint256 indexed tokenId, address indexed doGooder, // bytes32 userId,
        uint256 goodActivityId, uint256 indexed goodOracleId, uint256 goodPoints);


    event ProofOfGoodUserCreated(address indexed doGooder, bytes32 indexed userId, bytes32 emailHash);
    event ProfilesMerged(bytes32 indexed mainUserId, bytes32 indexed otherUserId);
    event WalletAddedToProfile(address indexed walletAddress, bytes32 indexed userId);

    event ProofOfGoodPointsCapped(bytes32 indexed userId, uint256 goodActivityId, uint256 indexed goodOracleId,
        uint256 goodPoints, uint256 goodPointsCapped);

    // -- upgradable uses initialize()
//    constructor() { // ERC721("ProofOfGood", "POG") {
//        _name = "ProofOfGood";
//        _symbol = "POG";
//        admins[_msgSender()] = true;  // set directly to avoid chicken-and-egg problem :)
//    }

    function initialize() public initializer {
        _name = "ProofOfGood";
        _symbol = "POG";
        admins[_msgSender()] = true;  // set directly to avoid chicken-and-egg problem :)
    }

    modifier onlyAdmins() {
        require(admins[_msgSender()], 'not approved');
        _;
    }
    function addAdmin(address _admin, bool _set) public onlyAdmins {
        require(_admin != address(0));
        admins[_admin] = _set;
    }

    function setBaseURI(string memory _uri) public onlyAdmins {
        _baseURI = _uri;
    }

    // pass id=0 to add
    function addOrUpdateGoodCategory(uint256 _goodCategoryId, string memory _name, Status _status) public onlyAdmins {
        require(bytes(_name).length>0, 'name is empty');

        if (_goodCategoryId == 0) {
            maxGoodCategoryId.increment();
            _goodCategoryId = (maxGoodCategoryId.current());
            goodCategories[_goodCategoryId].id = _goodCategoryId;
        }

        goodCategories[_goodCategoryId].name = _name;
        goodCategories[_goodCategoryId].status = _status;

        emit GoodCategoryUpdated(_goodCategoryId, _name, _status);
    }

    // pass id=0 to add
    function addOrUpdateGoodType(uint256 _goodTypeId, string memory _name, Status _status) public onlyAdmins {
        require(bytes(_name).length>0, 'name is empty');

        if (_goodTypeId == 0) {
            maxGoodTypeId.increment();
            _goodTypeId = maxGoodTypeId.current();
            goodTypes[_goodTypeId].id = _goodTypeId;
        }
        goodTypes[_goodTypeId].name = _name;
        goodTypes[_goodTypeId].status = _status;

        emit GoodTypeUpdated(_goodTypeId, _name, _status);
    }

    // pass id=0 to add
    function addOrUpdateGoodActivity(GoodActivity memory goodActivity) public onlyAdmins {
        if (goodActivity.id == 0) {
            maxGoodActivityId.increment();
            goodActivity.id = maxGoodActivityId.current();
        }
        for (uint256 i=0; i<goodActivity.goodTypeIdArray.length; i++) {
            require(goodTypes[goodActivity.goodTypeIdArray[i]].status == Status.ACTIVE, 'not active/not found');
        }

        require(goodCategories[goodActivity.goodCategoryId].status == Status.ACTIVE, 'not active/not found');
        require(bytes(goodActivity.name).length>0, 'name is empty');

        goodActivities[goodActivity.id] = goodActivity;

        emit GoodActivityUpdated(goodActivity.id, goodActivity.goodTypeIdArray, goodActivity.goodCategoryId,
            goodActivity.name, goodActivity.valuePerUnit, goodActivity.unitDescription, goodActivity.status);
    }

    function addOrUpdateGoodOracle(GoodOracle memory goodOracle) public onlyAdmins returns (uint) {
        require(bytes(goodOracle.name).length>0, 'name is empty');

        if (goodOracle.id == 0) {
            require(goodOracleNames[goodOracle.name] == 0, "good oracle already exists");

            maxGoodOracleId.increment();
            goodOracle.id = maxGoodOracleId.current();
        } else {
            require(goodOracles[goodOracle.id].id == goodOracle.id, "not found");

            if (bytes(goodOracle.name).length > 0) {
                delete goodOracleNames[goodOracles[goodOracle.id].name];
            }
        }

        goodOracles[goodOracle.id] = goodOracle;
        goodOracleNames[goodOracle.name] = goodOracle.id;

        emit GoodOracleUpdated(goodOracle.id, goodOracle.name, goodOracle.goodOracleURI, goodOracle.status, goodOracle.approvedActivityIdArray);
        return goodOracle.id;
    }

    function updateGoodOracleUser(address _user, uint256 _goodOracleId, bool _active) public onlyAdmins {
        require(_user != address(0));
        require(goodOracles[_goodOracleId].id == _goodOracleId, "not found");
        goodOracleUsers[_user][_goodOracleId] = _active;
//        emit GoodOracleUserUpdated(_user, _goodOracleId, goodOracles[_goodOracleId].name, _active);
    }

    function getGoodOracle(uint256 id) public view returns (GoodOracle memory) {
        require(goodOracles[id].id == id, "not found");
        return goodOracles[id];
    }


    // lookup order:
    //  - userid
    //  - doGooder
    //  - emailHash
    // userId & doGooder need to be set to create new profile.
    //  note that when userId is new we also try lookup per wallet/email

    function lookupOrCreateProfile(bytes32 userId, address doGooder, bytes32 emailHash)
        internal returns (bytes32 _userId, address _doGooder) {

        if (userId != ZeroHash) {
            // if no profile found - lookup others, otherwise create one!
            if (profile[userId].userId == ZeroHash) {
                if (doGooder != address(0) && walletUser[doGooder] != ZeroHash) { // && findByWallet
                    userId = walletUser[doGooder];

                } else if (emailHash != ZeroHash && userByEmailHash[emailHash] != ZeroHash) {
                    userId = userByEmailHash[emailHash];

                } else {
                    require(doGooder != address(0), "missing data");
                    // create new profile!

                    profile[userId].userId = userId;
                    profile[userId].walletAddresses = [ doGooder ];
                    walletUser[ doGooder ] = userId;

                    emit ProofOfGoodUserCreated(doGooder, userId, emailHash);
                }
            }
        }
        else if (doGooder != address(0)) {
            userId = walletUser[doGooder];
        }
        else if (emailHash != ZeroHash) {
            userId = userByEmailHash[emailHash];
        }
        require(userId != ZeroHash && userId == profile[userId].userId, "profile not found");

        // need a doGooder.
        if (doGooder == address(0)) doGooder = profile[userId].walletAddresses[0];
        require(doGooder != address(0), "missing data");

        // make sure we have the doGooder in the profile
        if (walletUser[doGooder] == ZeroHash) {
            associateWalletAddressToUserId(doGooder, userId);
        }

        // assign email
        if (emailHash != ZeroHash && userByEmailHash[emailHash] != userId) {
            require(userByEmailHash[emailHash] == ZeroHash, "email already assigned");
            userByEmailHash[emailHash] = userId;
        }

        return (userId, doGooder);
    }


    // Create the NFT
    function createProofOfGoodEntry(ProofOfGoodEntryParams memory proofOfGoodEntryParams) public {  // bool findByWallet
        // all check in this function

        // only admin or this oracle's user
        require(admins[_msgSender()] || goodOracleUsers[_msgSender()][proofOfGoodEntryParams.goodOracleId], 'not approved');

        (bytes32 userId, address doGooder) = lookupOrCreateProfile(proofOfGoodEntryParams.userId, proofOfGoodEntryParams.doGooder,
            proofOfGoodEntryParams.emailHash);

        if (proofOfGoodEntryParams.timestamp == 0)
            proofOfGoodEntryParams.timestamp = uint64(block.timestamp) * 1000;

        require(goodActivities[proofOfGoodEntryParams.goodActivityId].status == Status.ACTIVE, 'not active/not found');

        // check type: existing & active
        //        for (uint256 i=0; i < a.goodTypeIdArray.length; i++) {
        //            require(goodTypes[a.goodTypeIdArray[i]].status == Status.ACTIVE, 'not active/not found');
        //        }

        // check category: existing & active
        require(goodCategories[goodActivities[proofOfGoodEntryParams.goodActivityId].goodCategoryId].status == Status.ACTIVE, 'not active/not found');

        // check goodOracleId: existing & active
        require(goodOracles[proofOfGoodEntryParams.goodOracleId].status == Status.ACTIVE, 'not active/not found');

        // check activity id is in oracle array
        {
            bool activityApprovedBool = false;
            for (uint256 i=0; i < goodOracles[proofOfGoodEntryParams.goodOracleId].approvedActivityIdArray.length; i++) {
                if (proofOfGoodEntryParams.goodActivityId == goodOracles[proofOfGoodEntryParams.goodOracleId].approvedActivityIdArray[i]) {
                    activityApprovedBool = true;
                }
            }
            require(activityApprovedBool, 'good activity id is not approved for oracle');
        }
        // check units: greater than 0 & basic overflow prevention
        //        require(proofOfGoodEntryParams.units <= 1_000_000, 'units');
        //        require(proofOfGoodEntryParams.units > 0, 'units');
        // check externalId: greater than 0  . better: check if non-empty / unique
        //        require(proofOfGoodEntryParams.externalId>0, 'externalId must be greater than 0');

        // allocate new id for mint
        maxTokenId.increment();
        uint256 tokenId = maxTokenId.current();

        // mint Proof Of Good Entry NFT
        require(tokens[tokenId].tokenId == 0, "ERC721: token already minted");
        emit Transfer(address(0), doGooder, tokenId);



        // calculate good goodPoints
        uint256 _value = proofOfGoodEntryParams.units * goodActivities[proofOfGoodEntryParams.goodActivityId].valuePerUnit;
        // limit by caps
        uint256 _value_orig = _value;
        _value = checkCap(proofOfGoodEntryParams.goodActivityId, proofOfGoodEntryParams.goodOracleId, userId,
            proofOfGoodEntryParams.timestamp, proofOfGoodEntryParams.externalId, _value);
        _value = checkCap(0, proofOfGoodEntryParams.goodOracleId, userId,
            proofOfGoodEntryParams.timestamp, proofOfGoodEntryParams.externalId, _value);

        if (_value != _value_orig)
            emit ProofOfGoodPointsCapped(userId, proofOfGoodEntryParams.goodActivityId, proofOfGoodEntryParams.goodOracleId, _value_orig, _value);


        emit ProofOfGoodEntryCreated(tokenId, doGooder, // proofOfGoodEntryParams.emailHash,
            userId,
            proofOfGoodEntryParams.goodActivityId, proofOfGoodEntryParams.goodOracleId,
            proofOfGoodEntryParams.imageURL, // proofOfGoodEntryParams.mediaURL,
            _value, proofOfGoodEntryParams.units,
            proofOfGoodEntryParams.timestamp, proofOfGoodEntryParams.externalId
        );

        // create Proof Of Good Entry
        ProofOfGoodEntry memory newEntry = ProofOfGoodEntry({
            tokenId: tokenId,
            doGooder: doGooder,
            goodActivityId: proofOfGoodEntryParams.goodActivityId,
            goodPoints: _value,
            units: proofOfGoodEntryParams.units,
//            proofURL: proofOfGoodEntryParams.proofURL,
            imageURL: proofOfGoodEntryParams.imageURL,
            mediaURL: proofOfGoodEntryParams.mediaURL,
            timestamp: proofOfGoodEntryParams.timestamp,
            goodOracleId: proofOfGoodEntryParams.goodOracleId,
            externalId: proofOfGoodEntryParams.externalId
        });

        uint256 category = goodActivities[proofOfGoodEntryParams.goodActivityId].goodCategoryId;

        // add to ledger (Proof Of Good added to address entry)
        tokens[tokenId] = newEntry;
        profile[ userId ].entries.push(tokenId);

        if (userBalancesByCategory[userId][ category ].totalGood == 0)
            profile[userId].categories.push(category);

        // user: update balance and running sums associate with the user
        unchecked {
            profile[ userId ].balance += _value;
            profile[ userId ].totalGood += _value;

            userBalancesByCategory[userId][ category ].balance += _value;
            userBalancesByCategory[userId][ category ].totalGood += _value;

            // lifetime summary: update total good and total good by category
            totalGood += _value;
//            totalGoodByCategory[ 0 ] += _value;
//            totalGoodByCategory[ category ] += _value;
        }
    }

    function checkCap(uint256 goodActivityId, uint256 goodOracleId, bytes32 userId, uint64 timestamp, bytes32 externalId, uint256 goodPoints)
    internal view returns (uint256) {
//        if (cap[goodActivityId][goodOracleId].goodPoints > 0) {
            uint256 sum;
            ProofOfGoodProfile storage p = profile[userId];

            for (uint256 i = 0; i < p.entries.length; i++) {
                uint256 id = p.entries[i];

                if ((timestamp > tokens[id].timestamp ? timestamp - tokens[id].timestamp : tokens[id].timestamp - timestamp) <=
                    cap[goodActivityId][goodOracleId].duration * 1000) {
                    sum += tokens[id].goodPoints;
                }

                // make sure entry is not already on ledger
                require(timestamp != tokens[id].timestamp || goodActivityId != tokens[id].goodActivityId ||
                    externalId != tokens[id].externalId, "duplicate entry");
            }
            if (cap[goodActivityId][goodOracleId].goodPoints > 0 &&
                goodPoints + sum > cap[goodActivityId][goodOracleId].goodPoints)
                return goodPoints + sum - cap[goodActivityId][goodOracleId].goodPoints;

//        }
        return goodPoints;
    }

    // _category:0 for global cap.
    function setCap(uint256 _activityId, uint256 _goodOracleId, uint64 _duration, uint256 _points) public onlyAdmins {
        cap[_activityId][_goodOracleId].duration = _duration;
        cap[_activityId][_goodOracleId].goodPoints = _points;
    }

    function updateGoodPointsBridgeAddress(address _goodPointsBridgeAddress, bool add) public onlyAdmins {
        goodPointsBridgeAddresses[_goodPointsBridgeAddress] = add;
    }

    // redeem points. pass 0 as category for any, or specific id
    function redeemGoodPoints(address _sender, uint256 _amount, uint256 _goodCategoryId) public returns(bool) {
        require(goodPointsBridgeAddresses[_msgSender()], 'not approved');
        bytes32 userId = walletUser[ _sender ];

        ProofOfGoodProfile storage p = profile[ userId ];
        p.balance -= _amount;  // throws "underflowed.." if not possible

//        unchecked {
//            totalGoodRedeemed += _amount;
//        }
        emit GoodPointsRedeemed(_sender, _amount, p.balance, _goodCategoryId);

        mapping(uint256 => Balances) storage ub = userBalancesByCategory[userId];

        if (_goodCategoryId != 0) {
            ub[_goodCategoryId].balance -= _amount; // keep check.
        } else {
            unchecked {
                for(uint256 i=0; i < p.categories.length; i++) {
                    uint256 c = p.categories[i];

                    uint256 d = ub[ c ].balance;
                    if (d > (_amount)) d = (_amount);
                    ub[ c ].balance -= d;
                    _amount -= d;
                }
            }
            require(_amount == 0);
        }
        return true;
    }

    // get profile struct
    // note that somehow the ethers lib does not decode the 'entries' array (at least not with name)
    function profileByUserId(bytes32 userId) public view returns (ProofOfGoodProfile memory) {
        require(profile[ userId ].userId != ZeroHash, "profile not found");
        return profile[ userId ];
    }

    function profileByWallet(address wallet) public view returns (ProofOfGoodProfile memory) {
        return profileByUserId( walletUser[wallet] );
    }

    function profileByTokenId(uint256 tokenId) public view returns (ProofOfGoodProfile memory) {
        return profileByWallet( ownerOf(tokenId) );
    }

//    function profileByEmailHash(bytes32 emailHash) public view returns (ProofOfGoodProfile memory) {
//        return profileByUserId( userByEmailHash[emailHash] );
//    }

    // ERC721
    function balanceOf(address owner) public view virtual override returns (uint256) {
        return profileByWallet(owner).entries.length;
    }

    // user entries. needed as the entries are not correctly encoded in the profile getters.
    // - changed layout so we lookup tokens[]
    function getUserIdProofOfGoodEntries(bytes32 _userId) public view returns(ProofOfGoodEntry[] memory) {
        ProofOfGoodEntry[] memory entries = new ProofOfGoodEntry[](profile[_userId].entries.length);
        for (uint i=0; i < profile[_userId].entries.length; i++) {
            entries[i] = tokens[profile[_userId].entries[i]];
        }
        return entries;
    }

    function walletOfOwner(address _account) public view returns(uint256[] memory) {
        return profileByWallet(_account).entries;
    }

    function burn(uint256 tokenId) public {
        require(admins[_msgSender()] || _msgSender() == tokens[tokenId].doGooder ||
            goodOracleUsers[_msgSender()][tokens[tokenId].goodOracleId], 'not approved');

        bytes32 userId = walletUser[ownerOf(tokenId)];
        uint256 category = goodActivities[ tokens[tokenId].goodActivityId ].goodCategoryId;

        // deduct points. always?
        uint256 _value = tokens[tokenId].goodPoints;

        profile[ userId ].balance -= _value;
        userBalancesByCategory[userId][ category ].balance -= _value;

        unchecked {
            profile[ userId ].totalGood -= _value;
            userBalancesByCategory[userId][ category ].totalGood -= _value;

            totalGood -= _value;
//            totalGoodByCategory[ 0 ] -= _value;
//            totalGoodByCategory[ category ] -= _value;
        }

        emit Transfer(tokens[tokenId].doGooder, address(0), tokenId);

        emit ProofOfGoodEntryBurned(tokenId, tokens[tokenId].doGooder,
            tokens[tokenId].goodActivityId, tokens[tokenId].goodOracleId,
            _value
        );
        delete tokens[tokenId];

        ProofOfGoodProfile storage p = profile[userId];

        // delete tokenId from entries[]
        for (uint i=0; i < p.entries.length; i++ ) {
            if (p.entries[i] == tokenId) {
                if (p.entries.length > 1)
                    p.entries[i] = p.entries[ p.entries.length - 1];
                p.entries.pop();
            }
        }
    }

    // user entries
//    function getAddressProofOfGoodEntries(address _account) public view returns(ProofOfGoodEntry[] memory entries) {
//        return profile[ walletUser[ _account ]].entries;
//    }

    // user total good by category
//    function getAddressTotalGoodPointsByCategory(address _account, uint32 _goodCategoryId) public view returns(uint256) {
//        return userBalancesByCategory[ walletUser[_account] ][_goodCategoryId].totalGood;
//    }

//    function totalGood() public view returns (uint256) {
//        return totalGoodByCategory[0];
//    }

//    function getAddressBalancesByCategory(address _account, uint32 _goodCategoryId) public view returns(Balances memory) {
//        return userBalancesByCategory[ walletUser[_account] ][_goodCategoryId];
//    }

    function getGoodActivity(uint256 _goodActivityId) public view returns (GoodActivity memory) {
        require(goodActivities[_goodActivityId].id != 0, "not found");
        return goodActivities[_goodActivityId];
    }


    // balances per category and total in id:0
    function getAddressCategoryBalances(address _account) public view returns(CategoryBalances[] memory) {
        uint256[] memory categories = profileByWallet(_account).categories;
        CategoryBalances[] memory res = new CategoryBalances[](categories.length);
//            res[0] = Balances(0, profileByWallet(_account).balance, profileByWallet(_account).totalGood, profileByWallet(_account).totalGoodRedeemed);

        unchecked{
            for (uint256 i=0; i < categories.length; i++) {
                res[i].categoryId = categories[i];
                res[i].balances = userBalancesByCategory[walletUser[_account]][categories[i]];
            }
            return res;
        }
    }

    // associate email hash to wallet address pog profile. NOTE: done in pogEntry so dont need this.
    // function associateEmailHashToWalletAddress(bytes32 _emailHash, address _walletAddress) public onlyAdmins {
    //     bytes32 userId = walletUser[ _walletAddress ];
    //     require(userId != ZeroHash && profile[ userId ].userId == userId, "profile not found");

    //     userByEmailHash[_emailHash] = userId;
    // }

    // if wallet is not already associated to a profile, call ONLY to add the wallet to a profile
    function associateWalletAddressToUserId(address _walletAddress, bytes32 _userId) public onlyAdmins {
//        require(profile[_userId].userId != ZeroHash, "profile not found");
        profileByUserId(_userId);
        require(_walletAddress != address(0) && walletUser[_walletAddress] == ZeroHash, "wallet address already exists" );
        walletUser[_walletAddress] = _userId;
        profile[_userId].walletAddresses.push(_walletAddress);
        emit WalletAddedToProfile(_walletAddress, _userId);
    }

    function mergeProfiles(bytes32 mUid, bytes32 oUid) public onlyAdmins {
        // get main wallet profile
        ProofOfGoodProfile storage mainProfile = profile[ mUid ];
        // get other wallet profile
        ProofOfGoodProfile storage otherProfile = profile[ oUid ];

        require(mUid != oUid, "same profile");
        require(mUid != ZeroHash || oUid != ZeroHash, "profile not found");
//        require(oUid != ZeroHash, "profile not found");

        // add other wallet into main wallet profile
        unchecked {
            mainProfile.balance += otherProfile.balance;
            mainProfile.totalGood += otherProfile.totalGood;

            for (uint i=0; i < otherProfile.walletAddresses.length; i++) {
                mainProfile.walletAddresses.push(otherProfile.walletAddresses[i]);
                walletUser[otherProfile.walletAddresses[i]] = mUid;
            }

            // total good by category
            for(uint256 i=0; i < otherProfile.categories.length; i++) {
                uint256 c = otherProfile.categories[i];
                Balances storage b = userBalancesByCategory[mUid][ c ];
                Balances storage o = userBalancesByCategory[oUid][ c ];

                if (b.totalGood == 0)
                    mainProfile.categories.push(c);

                b.balance += o.balance;
                b.totalGood += o.totalGood;

                delete userBalancesByCategory[oUid][ c ];
            }
        }

        // reduce other wallet amounts
        otherProfile.balance = 0;
        otherProfile.totalGood = 0;
//        otherProfile.totalGoodRedeemed = 0;
        delete otherProfile.walletAddresses;

        // NOTE: how is email hash mapping updated?  -- we can't.
        emit ProfilesMerged(mUid, oUid);
    }



//    // activity types
//    function getGoodTypesForGoodActivityId(uint32 _goodActivityId) public view returns(uint32[] memory) {
//        return goodActivities[_goodActivityId].goodTypeIdArray;
//    }


    function tokenInfo(uint256 tokenId) public view returns (ProofOfGoodEntry memory) {
        ProofOfGoodProfile memory p = profileByTokenId(tokenId);
        for (uint i=0; i < p.entries.length; i++) {
            if (p.entries[i] == tokenId) return tokens[ p.entries[i] ];
        }
        revert("not found");
    }

    // called from pogToken.
    function getLedgerDetails(Reference[] calldata refs) external view override
    returns (ProofOfGoodEntryView[] memory pogs) {

//        NFTmetadata.getLedgerDetails(refs);
        ProofOfGoodEntryView[] memory res = new ProofOfGoodEntryView[](refs.length);
        for (uint i=0; i < refs.length; i++) {
            ProofOfGoodEntry memory e = tokenInfo(refs[i].tokenId);
            ProofOfGoodEntryView memory v;

//            GoodActivity memory a = goodActivities[e.goodActivityId];

            uint256 val = uint256(refs[i].value);
            if (e.goodPoints < val) val = e.goodPoints;
            uint32 u = uint32( val / goodActivities[e.goodActivityId].valuePerUnit );

            v.tokenId = e.tokenId;
            v.timestamp = e.timestamp;
            v.userId = string(abi.encodePacked(walletUser[e.doGooder]));
            v.goodType = uint16( goodActivities[e.goodActivityId].goodTypeIdArray[0] );  // first one? is uint16
            v.externalId = 0; // e.externalId;  // TODO? format mismatch
            v.orgId = uint32(e.goodOracleId);
            v.units = u;
            v.value = uint64(val);
            v.proofURL = e.imageURL;

            v.display = string(abi.encodePacked(Strings.toString(u), ' ', goodActivities[e.goodActivityId].unitDescription));
            // TODO: add externalId ?

            res[i] = v;
        }
        return res;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(tokens[tokenId].tokenId == tokenId, "ERC721Metadata: URI query for nonexistent token");

        if (bytes(_baseURI).length > 0) {
            return string(abi.encodePacked(_baseURI, tokenId.toString(), '.json'));
        }
//        if (useProofURLAsTokenURL) return tokenInfo(tokenId).proofURL;
//        if (bytes(tokenInfo(tokenId).proofURL).length > 0) return tokenInfo(tokenId).proofURL;

        // if no baseURI is set we generate json metadata.
        return dataURI(tokenId);
    }

    function _traitType(string memory s, string memory v) internal pure returns (string memory) {
        return string(abi.encodePacked('{"trait_type":"', s, '", "value":"', v, '"},'));
    }
    function _traitTypeN(string memory s, uint256 v, string memory t) internal pure returns (string memory) {
        return string(abi.encodePacked('{"trait_type":"', s, '","display_type":"', t, '", "value":', v.toString(), '},'));
    }

    function dataURI(uint256 tokenId) public view returns (string memory) {
        ProofOfGoodEntry memory t = tokenInfo(tokenId);

        GoodActivity storage activity = goodActivities[t.goodActivityId];

        string memory attr = string(abi.encodePacked(
            _traitType('Good Oracle', goodOracles[t.goodOracleId].name),
            _traitType('Good Activity', activity.name),
            _traitType('Good Type', goodTypes[activity.goodTypeIdArray[0]].name),
            _traitType('Good Category', goodCategories[activity.goodCategoryId].name),
            _traitType('Unit', activity.unitDescription),
            _traitType('ExternalID', bytes32ToString(t.externalId)),

            _traitTypeN(activity.unitDescription, uint256(t.units), 'number'),
            _traitTypeN('Good Points', uint256(t.goodPoints), 'number'),
            _traitTypeN('Date', uint256(t.timestamp), 'date')
        ));
        bytes(attr)[ bytes(attr).length -1 ] = ' ';  // remove trailing comma

        bytes memory json = abi.encodePacked(
                '{"name":"', name(), ' #', tokenId.toString(),
                '", "image":"', t.imageURL,
                //           bytes(t.imageURL).length > 0 ? t.imageURL : activity.imageURL,

                '","animation_url":"', t.mediaURL,
                // '","external_url":"', url,
                '", "date":', uint256(t.timestamp).toString(),
                ', "attributes":[', attr, '] }'
        );

        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(json)));
    }

    // needed as string(abi.encodepacked(s)) keeps zero-padding
    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }


    // ERC721 functions
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = tokens[tokenId].doGooder;
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function approve(address to, uint256 tokenId) public virtual override {
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        revert();
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return false;
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        revert("no transfers");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        revert("no transfers");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        revert("no transfers");
    }
}