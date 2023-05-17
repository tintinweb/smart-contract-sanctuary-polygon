// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "./CardNFTV1.sol";
import "./GameTreasury.sol";
import "./TreasuryReserve.sol";
import "./ICollection.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Eternity Collection
 *
 * @dev Represents a collection of card NFT in the game.
 */
contract EternityCollection is
    Initializable,
    ICollection,
    AccessControlUpgradeable,
    OwnableUpgradeable
{
    /**
     * @notice AccessControl role that allows support actions
     */
    bytes32 private constant SUPPORT = keccak256("SUPPORT");

    using Address for address;
    using Address for address payable;

    /**
     * @notice Card NFT used in the game
     */
    CardNFTV1 public card;

    /**
     * @notice GameTreasury used in the game
     */
    GameTreasury public gametreasury;

    /**
     * @notice TreasuryReserve used in the game
     */
    TreasuryReserve public treasuryreserve;

    /**
     * @notice Stores Collection ID.
     *
     */
    uint8 public collectionId;

    /**
     * @notice Stores Full Deck Buyback Value
     *
     */
    uint256 public buyBackValue; // 100.000 Matic

    /**
     * @notice Switcher for making 4 aces mandatory for claim bayback
     *
     */
    bool public buybackMandatoryAces;

    /**
     * @notice Switcher fo mint
     *
     */
    bool public mintingPaused;
    /**
     * @notice Stores the value of each card
     */
    uint32[] public cardValue;

    /**
     * @notice Stores the Mint Fee.
     *
     */
    uint256 public mintBasePrice;

    /**
     * @notice Stores the Mint Fee Percent.
     *
     */
    uint16 public mintFeePercent;

    /**
     * @notice Stores the Upgrade Fee.
     *
     */
    uint16 public upgradeFee;

    /**
     * @notice Stores Seller the Marketplace Fee.
     *
     */
    uint32 public marketplaceSellerFeePercent;
    /**
     * @notice Stores the Marketplace Fee.
     *
     */
    uint32 public marketplaceBuyerFeePercent;

    /**
     * @notice Stores the partner Fee for Marketplace.
     *
     */
    uint32 public partnerMarketplaceFeePercent;

    /**
     * @notice Stores the partner Fee.
     *
     */
    uint32 public partnerFeePercent;

    /**
     * @notice Stores the partner Fee.
     *
     */
    uint32 public partnerCommissionPercent;

    /**
     * @notice Stores the partner Fee.
     *
     */
    address payable public partnerDAOAddress;

    /**
     * @notice Stores Free Mint Count.
     *
     */
    uint32 public freeMintCount;

    /**
     * @notice Stores Total Mint Count.
     *
     */
    uint16 public totalMintedCountForJoker;

    /**
     * @notice Stores Gained Jokers count.
     *
     */
    uint8 public jokersCount;

    /**
     * @notice Stores Minted Jokers count.
     *
     */
    uint8 public jokersMinedCount;

    /**
     * @notice DAO address where fees are paid
     */
    address payable public daoAddress;

    /**
     * @notice gameTreasury address where funds are sent
     */
    address payable public gameTreasury;

    //coupon signer address
    address public couponSigner;

    /**
     * @notice Checks whether a provided card type is
     *         valid (in range [1, 53])
     *
     * @param _cardType the card type to check
     */
    modifier validCardType(uint8 _cardType) {
        require(_cardType >= 1 && _cardType <= 53, "1-53");
        _;
    }
    /**
     * @dev Fired in commit()
     *
     * @param sender address initiating the mint
     * @param dataHash hash of commit
     * @param block block
     * @param collectionId current collection id
     * @param amount amount of cards
     * @param freeMint if commit was for free mint
     */

    event CommitHash(
        address sender,
        bytes32 dataHash,
        uint64 block,
        uint8 collectionId,
        uint8 amount,
        bool freeMint
    );

    /**
     * @dev Fired in _mintCards()
     *
     * @param by address initiating the mint
     * @param tokenIds tokens minted
     * @param tokenIds card types minted
     * @param collection card collection
     */
    event Mint(
        address by,
        uint160[] tokenIds,
        uint8[] cardTypes,
        uint8 collection
    );
    /**
     * @dev Fired in upgradeCards()
     *
     * @param by address which executed the burn
     * @param fromCollection collection of the card that was burned
     * @param targetCollection collection of the card that was minted
     * @param tokenId tokenIds that was minted
     */
    event Upgrade(
        address by,
        uint8 fromCollection,
        uint8 targetCollection,
        uint160 tokenId
    );

    /**
     * @dev Fired in claimBuyBack()
     *
     * @param by address initiating the payout
     * @param buyBackValue payout buyBackValue
     * @param tokenIds tokens burned in payout
     */
    event BuyBackClaimed(address by, uint256 buyBackValue, uint160[] tokenIds);
    /**
     * @dev Fired in depositForFreeMint()
     *
     * @param by address
     * @param amount  amount for free mint
     * @param mintCount added mint free mint count
     * @param freeMintCount total free mint count
     * @param collectionId collectionId
     */
    event DepositedForFreeMint(
        address by,
        uint256 amount,
        uint32 mintCount,
        uint32 freeMintCount,
        uint8 collectionId
    );

    /**
     * @dev Fired in setMarketplaceSellerFeePercent()
     *
     * @param by address
     * @param oldValue  old value
     * @param newValue new value
     */
    event MarketplaceSellerFeeChanged(
        address by,
        uint32 oldValue,
        uint32 newValue
    );

    /**
     * @dev Fired in setMarketplaceBuyerFeePercent()
     *
     * @param by address
     * @param oldValue  old value
     * @param newValue new value
     */
    event MarketplaceBuyerFeeChanged(
        address by,
        uint32 oldValue,
        uint32 newValue
    );

    /**
     * @notice Initiates the game
     *
     * @param _card Card Nft smart contract address
     * @param _daoAddress DAO Smart contract address
     * @param _gameTreasury Game Treasury Smart contract address
     * @param _treasuryReserve Reserve Treasury Smart contract address
     * @param _partnerDAOAddress Partner DAO Smart contract address
     * @param _couponSigner Coupon Signer address
     */
    function initialize(
        address _card,
        address payable _daoAddress,
        address payable _gameTreasury,
        address payable _treasuryReserve,
        address payable _partnerDAOAddress,
        address _couponSigner
    ) public initializer {
        OwnableUpgradeable.__Ownable_init();
        card = CardNFTV1(_card);
        gametreasury = GameTreasury(_gameTreasury);
        treasuryreserve = TreasuryReserve(_treasuryReserve);
        daoAddress = _daoAddress;
        gameTreasury = _gameTreasury;
        partnerDAOAddress = _partnerDAOAddress;
        couponSigner = _couponSigner;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SUPPORT, msg.sender);

        collectionId = 2;
        buyBackValue = 100000 * 10 ** 18; // 100,000 Matic
        buybackMandatoryAces = false;
        mintingPaused = false;
        cardValue = [
            0, //Joker
            200, // Ace of Diamonds
            200, // Ace of Spades
            200, // Ace of Hearts
            200, // Ace of Clubs
            700, // 2 of Diamonds
            700, // 2 of Spades
            700, // 2 of Hearts
            700, // 2 of Clubs
            1600, // 3 of Diamonds
            1600, // 3 of Spades
            1600, // 3 of Hearts
            1600, // 3 of Clubs
            2500, // 4 of Diamonds
            2500, // 4 of Spades
            2500, // 4 of Hearts
            2500, // 4 of Clubs
            6000, // 5 of Diamonds
            6000, // 5 of Spades
            6000, // 5 of Hearts
            6000, // 5 of Clubs
            14000, // 6 of Diamonds
            14000, // 6 of Spades
            14000, // 6 of Hearts
            14000, // 6 of Clubs
            25000, // 7 of Diamonds
            25000, // 7 of Spades
            25000, // 7 of Hearts
            25000, // 7 of Clubs
            100000, // 8 of Diamonds
            100000, // 8 of Spades
            100000, // 8 of Hearts
            100000, // 8 of Clubs
            250000, // 9 of Diamonds
            250000, // 9 of Spades
            250000, // 9 of Hearts
            250000, // 9 of Clubs
            600000, // 10 of Diamonds
            600000, // 10 of Spades
            600000, // 10 of Hearts
            600000, // 10 of Clubs
            2000000, // Jack of Diamonds
            2000000, // Jack of Spades
            2000000, // Jack of Hearts
            2000000, // Jack of Clubs
            6000000, // Queen of Diamonds
            6000000, // Queen of Spades
            6000000, // Queen of Hearts
            6000000, // Queen of Clubs
            16000000, // King of Diamonds
            16000000, // King of Spades
            16000000, // King of Hearts
            16000000, // King of Clubs
            0 // Joker
        ];
        mintBasePrice = 970885340400000000;
        mintFeePercent = 2_000;
        upgradeFee = 2_000;
        marketplaceSellerFeePercent = 5_000;
        marketplaceBuyerFeePercent = 5_000;
        partnerMarketplaceFeePercent = 0;
        partnerFeePercent = 0;
        partnerCommissionPercent = 0;
        freeMintCount = 0;
        totalMintedCountForJoker = 0;
        jokersCount = 0;
        jokersMinedCount = 0;
    }

    // constructor() {
    //     _disableInitializers();
    // }

   /**
     * @notice Calculates the cost needed to mint random cards
     *
     * @dev Used by the integration library to calculate how much Ether
     *      to send to the game treasury for free mint.
     *
     * @param _mintCount  amount of mints
     */
    function depositForFreeMint(uint32 _mintCount) public payable {
        require(_mintCount >= 1 && _mintCount <= 1000, "w Count");

        uint256 costWithoutFees = mintBasePrice * _mintCount;
        uint256 collectionMintFee = (costWithoutFees * mintFeePercent) /
            100_000;

        uint256 cost = costWithoutFees + collectionMintFee;
        require(msg.value >= cost, "not enough");
        freeMintCount += _mintCount;

        gameTreasury.sendValue(msg.value);
        emit DepositedForFreeMint(
            msg.sender,
            msg.value,
            _mintCount,
            freeMintCount,
            collectionId
        );
    }

    /**
     * @notice Calculates the cost needed to mint random cards
     *
     * @param _amount of cards to be minted in range [1, 25]
     * @param _coupon Coupon for discount or free mint
     * @param _availableAmount Discount percent or free mint amount
     * @param _freeMint Is coupon for free mint
     * @return cost the total cost for the mint
     * @return collectionMintFee
     * @return partnerFee
     */
    function mintCardsCost(
        uint _amount,
        Coupon memory _coupon,
        uint8 _availableAmount,
        bool _freeMint
    )
        public
        view
        returns (uint256 cost, uint256 collectionMintFee, uint256 partnerFee)
    {
        // Validate amount info
        require(_amount >= 1 && _amount <= 100, "w amount");
        uint256 costWithoutFees = mintBasePrice * _amount;

        collectionMintFee = (costWithoutFees * mintFeePercent) / 100_000;

        //here we should check if minter has a discount
        uint256 collectionMintFeeWithDiscount = collectionMintFee;
        if (!_freeMint) {
            // collectionMintFeeWithDiscount that should be paid to Collection Dao
            collectionMintFeeWithDiscount = checkDiscount(
                collectionMintFee,
                _coupon,
                _availableAmount
            );
        }
        partnerFee =
            (collectionMintFeeWithDiscount * partnerFeePercent) /
            100_000;

        if (_freeMint) {
            bytes32 digest = keccak256(
                abi.encodePacked(collectionId, _availableAmount, msg.sender)
            );
            if (_isVerifiedCoupon(digest, _coupon)) {
                cost = 0;
            }
        } else {
            cost = costWithoutFees + collectionMintFeeWithDiscount;
        }
    }

    /**
     * @notice Mint Jokers
     *
     * @param _amount of cards to be minted in range [1, 25]
     * @param _coupon coupon
     * @param _availableAmount available jokers amount for address
     */
    function mintJoker(
        uint8 _amount,
        Coupon memory _coupon,
        uint8 _availableAmount
    ) public {
        require(_amount >= 1 && _amount <= 100, "w amount");
        require(_amount <= jokersCount, "not enough j");

        bytes32 digest = keccak256(
            abi.encodePacked(collectionId, _availableAmount, msg.sender)
        );
        require(_isVerifiedCoupon(digest, _coupon), "w c-n");
        jokersCount -= _amount;
        //get the hash of the block that happened after they committed
        bytes32 blockHash = blockhash(commits[msg.sender].block);
        uint160[] memory tokenIds = new uint160[](_amount);
        uint8[] memory cardTypes = new uint8[](_amount);
        for (uint8 i; i < _amount; ) {
            uint256 randomNumber = uint256(_randomNumGen(4294967296, i, blockHash));
            uint160 tokenId = uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            _amount,
                            block.timestamp,
                            randomNumber,
                            msg.sender,
                            i
                        )
                    )
                )
            );
            // Add token ID to list
            tokenIds[i] = tokenId;
            cardTypes[i] = 53;
            // Mint card with type card_index to user
            card.mint(msg.sender, tokenId, 53, collectionId, false);
            unchecked {
                ++i;
            }
        }
        // Emit event
        emit Mint(msg.sender, tokenIds, cardTypes, collectionId);
    }

    struct Commit {
        bytes32 commit;
        uint64 block;
        bool revealed;
        uint8 amount;
        uint256 cost;
        uint256 partnerFee;
        uint256 collectionMintFee;
    }

    mapping(address => Commit) public commits;

    /**
     * @notice Commit
     *
     * @param _dataHash Hash for commit
     * @param _coupon Coupon for discount or free mint
     * @param _availableAmount Discount percent or free mint amount
     * @param _freeMint Is coupon for free mint
     */
    function commit(
        bytes32 _dataHash,
        uint8 _amount,
        Coupon memory _coupon,
        uint8 _availableAmount,
        bool _freeMint
    ) public payable {
        require(!mintingPaused, "paused");
        require(commits[msg.sender].amount == 0, "C exists");
        require(_amount >= 1 && _amount <= 100, "w amount");

        if (_freeMint) {
            require(_amount >= 1 && _amount <= freeMintCount, "w amount");
        }

        (
            uint256 cost,
            uint256 collectionMintFee,
            uint256 partnerFee
        ) = mintCardsCost(_amount, _coupon, _availableAmount, _freeMint);

        // Check whether user sent enough funds
        require(msg.value >= cost, "not enough");
        commits[msg.sender].commit = _dataHash;
        commits[msg.sender].block = uint64(block.number);
        commits[msg.sender].revealed = false;
        commits[msg.sender].amount = _amount;
        commits[msg.sender].cost = cost;
        commits[msg.sender].partnerFee = partnerFee;
        commits[msg.sender].collectionMintFee = collectionMintFee;

        if (cost > 0) {
            gameTreasury.sendValue(msg.value);
        }
        // If user sent more funds than required, refund excess
        if (msg.value > cost) {
            //refund
            payable(msg.sender).sendValue(msg.value - cost);
        }

        emit CommitHash(
            msg.sender,
            commits[msg.sender].commit,
            commits[msg.sender].block,
            collectionId,
            _amount,
            _freeMint
        );
    }

    /**
     * @notice Reveal
     *
     * @param _revealHash Hash of commit
     */
    function reveal(bytes32 _revealHash) public {
        require(!commits[msg.sender].revealed, "revealed");

        require(getHash(_revealHash) == commits[msg.sender].commit, "w C");
        //require that the block number is greater than the original block
        require(
            uint64(block.number) > commits[msg.sender].block,
            "w block"
        );

        if (commits[msg.sender].partnerFee > 0) {
            //Send % to partner DAO
            gametreasury.mintFee(
                partnerDAOAddress,
                commits[msg.sender].partnerFee
            );
        }
        if (commits[msg.sender].collectionMintFee > 0) {
            // Send mint fee to DAO
            uint256 collectionMintFee = commits[msg.sender].collectionMintFee -
                commits[msg.sender].partnerFee;
            gametreasury.mintFee(daoAddress, collectionMintFee);
        }

        _mintCards(commits[msg.sender].amount, _revealHash);
        totalMintedCountForJoker += commits[msg.sender].amount;
        if (totalMintedCountForJoker >= 325) {
            jokersCount += 1;
            totalMintedCountForJoker = totalMintedCountForJoker - 325;
        }
        //remove commit info
        commits[msg.sender].revealed = true;
        commits[msg.sender].amount = 0;
        commits[msg.sender].cost = 0;
        commits[msg.sender].partnerFee = 0;
        commits[msg.sender].collectionMintFee = 0;
        emit RevealHash(msg.sender, _revealHash);
    }

    event RevealHash(address sender, bytes32 revealHash);

    /**
     * @notice Creates hash of data
     *
     * @param _data Data to be hashed
     *
     * @return encoded hash
     */
    function getHash(bytes32 _data) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), _data));
    }

    /**
     * @notice Mint Cards
     *
     * @param _amount Mint cards amount
     * @param _revealHash Hash of reveal
     */
    function _mintCards(uint256 _amount, bytes32 _revealHash) internal {
        uint32 max = 4294967295;
        //get the hash of the block that happened after they committed
        bytes32 blockHash = blockhash(commits[msg.sender].block);

        /**
         * @notice Stores the NL Quantity of each card
         */
        uint32[53] memory cardNLQts = [
            0, // cardValue[0] = 0
            4294967293, // Ace of Diamonds
            3580623325, // Ace of Spades
            2866279354, // Ace of Hearts
            2151935383, // Ace of Clubs
            1437591412, // 2 of Diamonds
            1222843047, // 2 of Spades
            1008094682, // 2 of Hearts
            793346317, // 2 of Clubs
            578597952, // 3 of Diamonds
            489119466, // 3 of Spades
            399640980, // 3 of Hearts
            310162494, // 3 of Clubs
            220684008, // 4 of Diamonds
            184892614, // 4 of Spades
            149101220, // 4 of Hearts
            113309826, // 4 of Clubs
            77518432, // 5 of Diamonds
            66781014, // 5 of Spades
            56043596, // 5 of Hearts
            45306178, // 5 of Clubs
            34568760, // 6 of Diamonds
            29200051, // 6 of Spades
            23831342, // 6 of Hearts
            18462633, // 6 of Clubs
            13093924, // 7 of Diamonds
            10946440, // 7 of Spades
            8798956, // 7 of Hearts
            6651472, // 7 of Clubs
            4503988, // 8 of Diamonds
            3788160, // 8 of Spades
            3072332, // 8 of Hearts
            2356504, // 8 of Clubs
            1640676, // 9 of Diamonds
            1372241, // 9 of Spades
            1103806, // 9 of Hearts
            835371, // 9 of Clubs
            566936, // 10 of Diamonds
            459562, // 10 of Spades
            352188, // 10 of Hearts
            244814, // 10 of Clubs
            137440, // Jack of Diamonds
            110596, // Jack of Spades
            83752, // Jack of Hearts
            56908, // Jack of Clubs
            30064, // Queen of Diamonds
            24695, // Queen of Spades
            19326, // Queen of Hearts
            13957, // Queen of Clubs
            8588, // King of Diamonds
            6441, // King of Spades
            4294, // King of Hearts
            2147 // King of Clubs
        ];

        uint160[] memory tokenIds = new uint160[](_amount);
        uint8[] memory cardTypes = new uint8[](_amount);

        // Mint cards
        for (uint32 i; i < _amount; ) {
            uint8 min_ind = 1;
            uint8 max_ind = 53;
            uint8 av_ind;

            uint32 randomNumber = uint32(
                uint256(
                    keccak256(
                        abi.encodePacked(blockHash, _revealHash, msg.sender, i)
                    )
                ) % max
            );

            uint160 tokenId = uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            _amount,
                            block.timestamp,
                            randomNumber,
                            msg.sender,
                            i
                        )
                    )
                )
            );

            while (max_ind > min_ind + 1) {
                av_ind = ((max_ind + min_ind) / 2);
                if (randomNumber < cardNLQts[av_ind]) {
                    min_ind = av_ind;
                } else {
                    max_ind = av_ind;
                }
            }

            uint8 card_index = min_ind;

            // Add token ID to list
            tokenIds[i] = tokenId;
            cardTypes[i] = card_index;

            // Mint card with type card_index to user
            card.mint(msg.sender, tokenId, card_index, collectionId, false);
            unchecked {
                ++i;
            }
        }
        // Emit event
        emit Mint(msg.sender, tokenIds, cardTypes, collectionId);
    }

    struct UpgradeCost {
        uint256 upgradeFeeCostWithDiscount;
        uint256 partnerFeeCost;
        uint256 cardsTypeValueDiffCost;
        uint256 refundValue;
        uint256 payValue;
        uint32 highestCardValue;
        uint256 upgradeFeeCost;
        uint256 totalValueGivenCards;
        uint256 targetCardTypeValue;
        uint256 cardsTypeValueDiff;
        uint256 feeValue;
    }

    /**
     * @notice Calculates upgrade cost
     *
     * @param _tokenIds  token ids of the cards to be sacrificed
     * @param _targetCardType the card type of the new card to be minted
     * @param _collectionId Collection id
     * @param _coupon Coupon for discount
     * @param _discount Discount value
     *
     * @return struct UpgradeCost()
     */
     function upgradeCardCost(
        uint160[] calldata _tokenIds,
        uint8 _targetCardType,
        uint8 _collectionId,
        Coupon memory _coupon,
        uint8 _discount
    ) public view validCardType(_targetCardType) returns (UpgradeCost memory) {
        // Ensure at least 2 cards was sent
        require(_tokenIds.length > 1, "min 2");
        UpgradeCost memory upgradecost;
        upgradecost.targetCardTypeValue = cardValue[_targetCardType];
        for (uint32 i; i < _tokenIds.length; ) {
            uint160 tokenId = _tokenIds[i];
            (uint8 cardType, , , ) = card.cardInfo(tokenId);
            if (upgradecost.highestCardValue <= cardValue[cardType]) {
                upgradecost.highestCardValue = cardValue[cardType];
            }
            upgradecost.totalValueGivenCards += cardValue[cardType];
            unchecked {
                ++i;
            }
        }
        upgradecost.cardsTypeValueDiff = 0;
        if (
            upgradecost.totalValueGivenCards > upgradecost.targetCardTypeValue
        ) {
            upgradecost.cardsTypeValueDiff =
                upgradecost.totalValueGivenCards -
                upgradecost.targetCardTypeValue;
        }

        if (_collectionId == collectionId) {


            //buyBackValue 1000000000000000000
            upgradecost.feeValue =
                (buyBackValue * upgradecost.targetCardTypeValue * upgradeFee) /
                100_000 /
                2;
            upgradecost.upgradeFeeCost = upgradecost.feeValue / 10 ** 8;

            // check for the discount
            upgradecost.upgradeFeeCostWithDiscount = checkDiscount(
                upgradecost.upgradeFeeCost,
                _coupon,
                _discount
            );
            upgradecost.partnerFeeCost =
                (upgradecost.upgradeFeeCostWithDiscount * partnerFeePercent) /
                100_000;

            upgradecost.upgradeFeeCostWithDiscount -= upgradecost
                .partnerFeeCost;
        } else {
            (,uint256 _collectionBuyBack,,,,,) = card.cardCollectionInfo(
                _collectionId
            );
            uint256 collectionsRatio = (_collectionBuyBack * 10 ** 8) /
                buyBackValue;

            upgradecost.targetCardTypeValue = cardValue[_targetCardType] * collectionsRatio /
                10 ** 8;

            upgradecost.feeValue =
                ((buyBackValue * upgradecost.targetCardTypeValue) *
                    upgradeFee) /
                100_000 /
                2;
            upgradecost.upgradeFeeCost = upgradecost.feeValue / 10 ** 8;

            // check for the discount
            upgradecost.upgradeFeeCostWithDiscount = checkDiscount(
                upgradecost.upgradeFeeCost,
                _coupon,
                _discount
            );

            upgradecost.partnerFeeCost =
                (upgradecost.upgradeFeeCostWithDiscount * partnerFeePercent) /
                100_000;
           

            if (
                upgradecost.totalValueGivenCards >=
                upgradecost.targetCardTypeValue
            ) {
                upgradecost.cardsTypeValueDiff =
                    upgradecost.totalValueGivenCards -
                    upgradecost.targetCardTypeValue;
            }
        }
        upgradecost.cardsTypeValueDiffCost =
            ((upgradecost.cardsTypeValueDiff * buyBackValue) / 2) /
            10 ** 8;
        //check if user can pay less fee (fee-change)
        if (
            upgradecost.upgradeFeeCostWithDiscount >
            upgradecost.cardsTypeValueDiffCost
        ) {
            upgradecost.payValue =
                upgradecost.upgradeFeeCostWithDiscount -
                upgradecost.cardsTypeValueDiffCost;
            upgradecost.refundValue = 0;
        } else {
            upgradecost.payValue = 0;
            upgradecost.refundValue =
                upgradecost.cardsTypeValueDiffCost -
                upgradecost.upgradeFeeCostWithDiscount;
        }

        return (upgradecost);
    }

    struct UpgradeInfo {
        uint32 highestCardValue;
        uint256 totalValue;
        uint256 collectionsRatio;
        uint160 targetTokenId;
        uint256 collectionBuyBack;
    }

    /**
     * @notice Allows a user to sacrifice a number of cards he owns
     *         in order to get a card of higher value
     *
     * @param _tokenIds the token ids of the cards to be sacrificed
     * @param _targetCardType the card type of the new card to be minted
     * @param _collectionId Collection id
     * @param _coupon Coupon for discount
     * @param _discount Discount value
     */
    function upgradeCards(
        uint160[] calldata _tokenIds,
        uint8 _targetCardType,
        uint8 _collectionId,
        Coupon memory _coupon,
        uint8 _discount
    ) public payable validCardType(_targetCardType) {
        // Ensure at least 2 cards was sent
        require(_tokenIds.length > 1, "min 2");

        UpgradeInfo memory upgradeinfo;
        UpgradeCost memory upgradecost;
        (,upgradeinfo.collectionBuyBack,,,,,) = card.cardCollectionInfo(
            _collectionId
        );
        require(
            upgradeinfo.collectionBuyBack >= buyBackValue,
            "w to C-n"
        );

        //calculate card upgrade cost
        upgradecost = upgradeCardCost(
            _tokenIds,
            _targetCardType,
            _collectionId,
            _coupon,
            _discount
        );

        require(msg.value >= upgradecost.payValue, "not enough");

        upgradeinfo.collectionsRatio =
            (upgradeinfo.collectionBuyBack) /
            buyBackValue;

        card.burnBatch(msg.sender, _tokenIds, 0);

        // Value of all cards provided (after subtracting attribution)
        // should be at least equal to the value of the new card to be
        // minted
        require(
            upgradecost.totalValueGivenCards >= upgradecost.targetCardTypeValue,
            "not enough"
        );
        require(
            upgradecost.highestCardValue <= cardValue[_targetCardType] * upgradeinfo.collectionsRatio,
            "w T card"
        );

        {
            if (upgradecost.payValue > 0) {
                daoAddress.sendValue(upgradecost.payValue);
            } else {
                // Send upgrade fee to DAO From Treasury
                gametreasury.upgradeCommission(
                    daoAddress,
                    upgradecost.upgradeFeeCostWithDiscount
                );
            }

            //claim commitions
            _claimUpgradeCommission(
                upgradecost.cardsTypeValueDiffCost,
                upgradecost.refundValue
            );
        }

        //Generate a pseudorandom tokenId for the new card
        upgradeinfo.targetTokenId = uint160(
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, _tokenIds, msg.sender)
                )
            )
        );
        //Mint the new card to the sender
        card.mint(
            msg.sender,
            upgradeinfo.targetTokenId,
            _targetCardType,
            _collectionId,
            true
        );

        //Emit event
        emit Upgrade(
            msg.sender,
            collectionId,
            _collectionId,
            upgradeinfo.targetTokenId
        );
    }


    struct CommissionInfo {
        uint256 upgradeCommission;
        uint256 upgradeCommissionPrtner;
        uint256 upgradeCommissionFromTreasuryReserve;
        uint256 upgradeCommissionPrtnerReserve;
        uint256 claimCommission;
        uint256 claimCommissionWithDiscount;
        uint256 partnerClaimCommission;
    }

    /**
     * @notice  Send upgrade cacheback and claim upgrade commissin to DAO
     *
     * @param _cardsTypeValueDiffCost Cost of upgrade diff
     * @param _refundValue Value that user gets
     */
    function _claimUpgradeCommission(
        uint256 _cardsTypeValueDiffCost,
        uint256 _refundValue
    ) private {
        CommissionInfo memory commissioninfo;

        //cache back to player
        if (_refundValue > 0) {
            if (gametreasury.balance() < _refundValue) {
                commissioninfo.upgradeCommissionFromTreasuryReserve =
                    _refundValue -
                    gametreasury.balance();
                treasuryreserve.giveUpgradeCacheBack(
                    msg.sender,
                    commissioninfo.upgradeCommissionFromTreasuryReserve
                );
                _refundValue -= commissioninfo
                    .upgradeCommissionFromTreasuryReserve;
            }
            if (_refundValue > 0) {
                gametreasury.giveUpgradeCacheBack(msg.sender, _refundValue);
            }

            commissioninfo.upgradeCommission = _cardsTypeValueDiffCost;
            commissioninfo.upgradeCommissionPrtner =
                (commissioninfo.upgradeCommission * partnerCommissionPercent) /
                100_000;

            commissioninfo.upgradeCommission -= commissioninfo
                .upgradeCommissionPrtner;
            if (gametreasury.balance() < commissioninfo.upgradeCommission) {
                commissioninfo.upgradeCommissionFromTreasuryReserve =
                    commissioninfo.upgradeCommission -
                    gametreasury.balance();
                treasuryreserve.upgradeCommission(
                    daoAddress,
                    commissioninfo.upgradeCommissionFromTreasuryReserve
                );
                commissioninfo.upgradeCommission -= commissioninfo
                    .upgradeCommissionFromTreasuryReserve;
            }

            if (commissioninfo.upgradeCommission > 0) {
                gametreasury.upgradeCommission(
                    daoAddress,
                    commissioninfo.upgradeCommission
                );
            }

            if (commissioninfo.upgradeCommissionPrtner > 0) {
                if (
                    gametreasury.balance() <
                    commissioninfo.upgradeCommissionPrtner
                ) {
                    commissioninfo.upgradeCommissionPrtnerReserve =
                        commissioninfo.upgradeCommissionPrtner -
                        gametreasury.balance();
                    treasuryreserve.upgradeCommission(
                        partnerDAOAddress,
                        commissioninfo.upgradeCommissionPrtnerReserve
                    );
                    commissioninfo.upgradeCommissionPrtner -= commissioninfo
                        .upgradeCommissionPrtnerReserve;
                }
                if (commissioninfo.upgradeCommissionPrtner > 0) {
                    gametreasury.upgradeCommission(
                        partnerDAOAddress,
                        commissioninfo.upgradeCommissionPrtner
                    );
                }
            }
        }
    }

    /**
     * @notice Calculate Buyback value
     *
     * @param _tokenIds  token ids of the cards to be burn
     *
     * @return floorValue Sum of floor values of given cards
     * @return bonusEarned Value of the bonus
     * @return buyback Buyback value
     * @return allAces If all the suits of Aces sent
     */
    function calculateBuyback(
        uint160[] calldata _tokenIds
    )
        public
        view
        returns (
            uint256 floorValue,
            uint256 bonusEarned,
            uint256 buyback,
            bool allAces
        )
    {
        floorValue = 0;
        bonusEarned = 0;
        buyback = 0;
        allAces = false;

        if (_tokenIds.length == 0) {
            return (floorValue, bonusEarned, buyback, allAces);
        }

        bool[][] memory slotMatrix = new bool[][](13);
        bool[][] memory bonusMatrix = new bool[][](13);

        uint8 jokers = 0;
        uint128 comboValue = 0;

        for (uint8 i = 0; i < 13; ) {
            slotMatrix[i] = new bool[](4);
            bonusMatrix[i] = new bool[](4);

            for (uint8 j = 0; j < 4; ) {
                slotMatrix[i][j] = false;
                bonusMatrix[i][j] = false;
                unchecked {
                    j++;
                }
            }
            unchecked {
                ++i;
            }
        }

        // Keep track of each type of card that has been used
        // to ensure the user did not sent multiple cards of the
        // same type
        // Does not include joker which is while and can be used
        // multiple times
        bool[] memory payoutDeck = new bool[](53);

        //uint8[] memory userCards = new uint8[](52);
        
        for (uint8 i = 0; i < _tokenIds.length; ) {
            // Get the token ID and type of the card
            uint160 tokenId = _tokenIds[i];
            (uint8 cardType, , , ) = card.cardInfo(tokenId);
            //userCards[cardType] = true;
            payoutDeck[cardType] = false;

            // Check the current card type
            if (cardType == 53) {
                // If a joker, increment the joker count
                jokers++;
                require(jokers <= 4, "J<=4");
            } else {
                // If not a joker, check if this card type
                // has already been used
                require(!payoutDeck[cardType], "used twice");

                // Mark card type as already used
                payoutDeck[cardType] = true;

                comboValue += cardValue[cardType];
            }
            unchecked {
                ++i;
            }
        }

        // Enumerate payout deck
        for (uint8 i = 1; i <= payoutDeck.length; ) {
            // Ensure the next card type was used by the user
            if (!payoutDeck[i]) {
                // Check whether the user sent a joker that
                // has not been previously used
                if (jokers > 0) {
                    // If the user has a joker, use it to fill in
                    // the non-existent card and reduce the sent
                    // jokers count
                    payoutDeck[i] = true;
                    jokers--;
                } else {
                    // Else stop counting
                    break;
                }
            }
            unchecked {
                ++i;
            }
        }

        uint8 k = 0;
        uint8 m = 1;
        uint8 n = 1;

        for (uint8 i = 1; i < payoutDeck.length; ) {
            m = i - n;
            if (payoutDeck[i]) {
                slotMatrix[k][m] = true;
            }
            if (i % 4 == 0) {
                k++;
                n = i + 1;
            }
            unchecked {
                ++i;
            }
        }

        for (uint8 j = 0; j < 4; ) {
            for (uint8 i = 1; i < 13; ) {
                // no aces for bonus
                if (slotMatrix[i][j]) {
                    bonusMatrix[i][j] = true;
                } else {
                    break;
                }
                unchecked {
                    ++i;
                }
            }
            unchecked {
                j++;
            }
        }
        for (uint8 i = 0; i < 13; ) {
            if (
                slotMatrix[i][0] &&
                slotMatrix[i][1] &&
                slotMatrix[i][2] &&
                slotMatrix[i][3]
            ) {
                bonusMatrix[i][0] = true;
                bonusMatrix[i][1] = true;
                bonusMatrix[i][2] = true;
                bonusMatrix[i][3] = true;
            }

            unchecked {
                ++i;
            }
        }

        int bonusPercent = -1 * ((4_000 * 10 ** 4) / 100_000);

        if (
            slotMatrix[0][0] &&
            slotMatrix[0][1] &&
            slotMatrix[0][2] &&
            slotMatrix[0][3]
        ) {
            allAces = true;
            for (uint8 j = 0; j < 4; ) {
                for (uint8 i = 0; i < 13; ) {
                    if (bonusMatrix[i][j]) {
                        bonusPercent += ((2_000 * 10 ** 4) / 100_000);
                    }
                    unchecked {
                        ++i;
                    }
                }
                unchecked {
                    j++;
                }
            }
        }

        if (bonusPercent < 0) {
            bonusPercent = 0;
        }

        uint ubonusPercent = uint(bonusPercent);
        floorValue = comboValue / 2;
        floorValue = (floorValue * buyBackValue) / 10 ** 8;
        uint256 win_value = (comboValue * (10 ** 4 + ubonusPercent)) /
            2 /
            10 ** 4;
        uint64 buybackDIM = 10 ** 10; //should be 10**18
        buyback =
            (win_value * (buyBackValue / buybackDIM) * buybackDIM) /
            10 ** 8;
        bonusEarned = buyback - floorValue;
    }

    /**
     * @notice Claim Buyback
     *
     * @param _tokenIds  token ids of the cards to be burn
     */
    function claimBuyBack(uint160[] calldata _tokenIds) public {
        CommissionInfo memory commissioninfo;
        (
            uint256 floorValue,
            ,
            uint256 buyback,
            bool allAces
        ) = calculateBuyback(_tokenIds);
        if (buybackMandatoryAces) {
            require(allAces, "provide A");
        }
        commissioninfo.claimCommission = (floorValue * 2) - buyback;
        commissioninfo.partnerClaimCommission =
            (commissioninfo.claimCommission * partnerCommissionPercent) /
            100_000;
        if (buyback > 0) {
            uint256 buybackFromTreasuryReserve = 0;
            if (gametreasury.balance() < buyback) {
                buybackFromTreasuryReserve = buyback - gametreasury.balance();
                treasuryreserve.buyBackPayout(
                    msg.sender,
                    buybackFromTreasuryReserve
                );
                buyback -= buybackFromTreasuryReserve;
            }
            if (buyback > 0) {
                gametreasury.buyBackPayout(msg.sender, buyback);
            }
            _claimBuyBackCommission(
                commissioninfo.claimCommission,
                commissioninfo.partnerClaimCommission
            );
        }

        for (uint16 i = 0; i < _tokenIds.length; ) {
            uint160 tokenId = _tokenIds[i];
            card.burn(msg.sender, tokenId, 1);
            unchecked {
                ++i;
            }
        }

        card.increaseCollectionBuyBacks(collectionId);

        // Emit BuyBack event
        emit BuyBackClaimed(msg.sender, buyback, _tokenIds);
    }

    /**
     * @notice Claim commission for buyback
     *
     * @param _claimCommission commission value
     * @param _partnerClaimCommission partner commission value
     */
    function _claimBuyBackCommission(
        uint256 _claimCommission,
        uint256 _partnerClaimCommission
    ) private {
        // send money to dao if player had not collected 100% of bonus
        if (_claimCommission > 0) {
            if (gametreasury.balance() < _claimCommission) {
                uint256 claimCommissionFromTreasuryReserve = _claimCommission -
                    gametreasury.balance();
                treasuryreserve.claimCommission(
                    daoAddress,
                    claimCommissionFromTreasuryReserve
                );
                _claimCommission -= claimCommissionFromTreasuryReserve;
            }
            if (_claimCommission > 0) {
                gametreasury.claimCommission(daoAddress, _claimCommission);
            }
        }

        if (_partnerClaimCommission > 0) {
            if (gametreasury.balance() < _partnerClaimCommission) {
                uint256 partnerClaimCommissionFromTreasuryReserve = _partnerClaimCommission -
                        gametreasury.balance();
                treasuryreserve.claimCommission(
                    partnerDAOAddress,
                    partnerClaimCommissionFromTreasuryReserve
                );
                _partnerClaimCommission -= partnerClaimCommissionFromTreasuryReserve;
            }
            if (_claimCommission > 0) {
                gametreasury.claimCommission(
                    partnerDAOAddress,
                    _partnerClaimCommission
                );
            }
        }
    }

    /**
     * @notice Remove the commit
     *
     * @param _address The commit owner address
     */
    function forceRemoveCommit(address _address) external onlyRole(SUPPORT) {
        if (
            !commits[msg.sender].revealed &&
            commits[_address].amount > 0
        ) {
            gametreasury.refundCommit(_address, commits[msg.sender].cost);
            commits[msg.sender].revealed = true;
            commits[_address].amount = 0;
            commits[msg.sender].cost = 0;
            commits[msg.sender].partnerFee = 0;
            commits[msg.sender].collectionMintFee = 0;
        }
    }

    /**
     * @notice check if user has discount on fee
     *
     * @param _fee default fee
     * @param _coupon coupon of discount
     * @param _discount discount value
     *
     * @return fee discounted fee
     */
    function checkDiscount (uint256 _fee, Coupon memory _coupon, uint8 _discount) public view returns (uint256 fee) {
        bytes32 digest = keccak256(
            abi.encode(collectionId, _discount, msg.sender)
        );
        fee = _fee;
        if(_isVerifiedCoupon(digest, _coupon)){
            fee = _fee - (_fee * _discount / 100);
        }
        return fee;
    }


    /**
     * @notice check that the coupon sent was signed by the admin signer
     *
     * @param _digest Coupon data digest
     * @param _coupon Coupon of discount or free mint
     *
     * @return bool success if valid signer
     */

    function _isVerifiedCoupon(bytes32 _digest, Coupon memory _coupon) internal view returns (bool) {
        address signer = ecrecover(_digest, _coupon.v, _coupon.r, _coupon.s);
        require(signer != address(0), 'w s');
        return signer == couponSigner;
     }

    /**
     * @notice Updates partnerFeePercent
     *
     * @param _newFee new partnerFee
     */
    function setPartnerFee(uint32 _newFee) external onlyOwner {
        // Update partnerFee
        require(_newFee < 100_000, "w fee");
        partnerFeePercent = _newFee;
    }

    /**
     * @notice Updates partnerCommissionPercent
     *
     * @param _newCommission new partnerFee
     */
    function setPartnerCommission(uint32 _newCommission) external onlyOwner {
        // Update partnerFee
        require(_newCommission < 100_000, "w fee");
        partnerCommissionPercent = _newCommission;
    }

    /**
     * @notice Updates partnerMarketplaceFeePercent
     *
     * @param _newPartnerMarketplaceFee new partnerFee
     */
    function setPartnerMarketplaceFee(
        uint32 _newPartnerMarketplaceFee
    ) external onlyOwner {
        // Update partnerMarketplaceFeePercent
        require(_newPartnerMarketplaceFee < 100_000, "w fee");
        partnerMarketplaceFeePercent = _newPartnerMarketplaceFee;
    }

    /**
     * @notice Updates couponSigner
     *
     * @param _couponSigner new coupon signer address
     */
    function setCouponSigner(address _couponSigner) external onlyOwner {
        require(
        _couponSigner != address(0),
        "w add"
        );
        couponSigner = _couponSigner;
    }

    /**
     * @notice Updates buybackMandatoryAces
     *
     * @param _buybackMandatoryAces new buybackMandatoryAces
     */
    function setBuybackMandatoryAces(
        bool _buybackMandatoryAces
    ) external onlyOwner {
        buybackMandatoryAces = _buybackMandatoryAces;
    }

    /**
     * @notice Updates mintingPaused
     *
     * @param _mintingPaused new mintingPaused
     */
    function togglePause(bool _mintingPaused) external onlyOwner {
        mintingPaused = _mintingPaused;
    }

    /**
     * @notice Updates marketplaceSellerFeePercent
     *
     * @param _marketplaceSellerFeePercent new marketplaceSellerFeePercent
     */
    function setMarketplaceSellerFeePercent(
        uint32 _marketplaceSellerFeePercent
    ) external onlyOwner {
        require(
            _marketplaceSellerFeePercent >= 0 &&
                _marketplaceSellerFeePercent <= 100_000,
            "w %"
        );
        emit MarketplaceSellerFeeChanged(
            msg.sender,
            marketplaceSellerFeePercent,
            _marketplaceSellerFeePercent
        );
        marketplaceSellerFeePercent = _marketplaceSellerFeePercent;
    }

    /**
     * @notice Updates marketplaceBuyerFeePercent
     *
     * @param _marketplaceBuyerFeePercent new marketplaceBuyerFeePercent
     */
    function setMarketplaceBuyerFeePercent(
        uint32 _marketplaceBuyerFeePercent
    ) external onlyOwner {
        require(
            _marketplaceBuyerFeePercent >= 0 &&
                _marketplaceBuyerFeePercent <= 100_000,
            "w %"
        );
        emit MarketplaceBuyerFeeChanged(
            msg.sender,
            marketplaceBuyerFeePercent,
            _marketplaceBuyerFeePercent
        );
        marketplaceBuyerFeePercent = _marketplaceBuyerFeePercent;
    }

    function setBuybackValue(uint256 _buyBackValue) external onlyOwner{
        buyBackValue = _buyBackValue;
    }
    /**
     * @dev Generates a random number between 1 and `_max` (inclusive)
     *      and takes into account block data (timestamp, number)
     *
     * @param _max the maximum number that can be generated (inclusive)
     * @param _nonce random number to include as seed
     */
    function _randomNumGen(
        uint64 _max,
        uint8 _nonce,
        bytes32 _blockHash
    ) private view returns (uint256) {
        return
            (uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        _blockHash,
                        msg.sender,
                        _nonce
                    )
                )
            ) % _max) + 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "base64-sol/base64.sol";

/**
 * @title Eternity deck card
 *
 * @dev Represents a card NFT in the game.
 */
contract CardNFTV1 is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    AccessControlUpgradeable,
    OwnableUpgradeable
{
    using Address for address;
    using Strings for uint256;
    using Strings for uint16;
    using Strings for uint8;

    /**
     * @notice AccessControl role that allows to mint tokens
     *
     * @dev Used in mint(), safeMint(), mintBatch(), safeMintBatch()
     */
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @notice AccessControl role that allows to burn tokens
     *
     * @dev Used in burn(), burnBatch()
     */
    bytes32 private constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /**
     * @notice AccessControl role that allows to change the baseURI
     *
     * @dev Used in setBaseURI()
     */
    bytes32 private constant URI_MANAGER_ROLE = keccak256("URI_MANAGER_ROLE");

    /**
     * @notice Stores the amount of cards that were burned in
     *         the duration of the game.
     *
     * @dev Is increased by 1 when a card is burned
     */
    uint256 public totalBurned;

    /**
     * @dev Represents a card
     */
    struct Card {
        uint8 cardType;
        uint8 cardCollection;
        uint256 serialNumber;
        uint256 editionNumber;
    }

    /**
     * @dev Represents a collection
     */

    struct Collection {
        address collectionAddress; // the address of the collection
        uint256 collectionBuyBack;
        address payable partnerDaoAddress;
        uint256 colMinted;
        uint256 colBurned;
        uint128 totalCardValue;
        uint64 totalBuyBacksClaimed;
    }

    /**
     * @notice Stores information about each card
     */
    mapping(uint256 => Card) public cardInfo;

    /**
     * @notice Stores the number of cards minted for each card type
     *
     * @dev Is increased by 1 when a new card of certain type is minted
     *
     * @dev Returns 0 for values not in range [1, 53]
     */
    mapping(uint8 => uint256) public cardPopulation;

    /**
     * @notice Stores the number of cards in existence on each collection
     *         for each card type
     *
     * @dev Is increased by 1 when a new card of certain type in a collection
     *      is minted
     *
     * @dev Returns 0 for values not in range [1, 53]
     */
    mapping(uint8 => mapping(uint8 => uint256)) public cardCollectionPopulation;

    /**
     * @notice Stores the number of card population, burned, minted on each collection
     *
     *
     * @dev Is increased by 1 when a new card in a collection
     *      is minted or burned
     *
     * @dev Returns 0 for values not in range [1, 53]
     */
    mapping(uint8 => Collection) public cardCollectionInfo;

    /**
     * @notice Stores how many cards of a type were minted
     *         and owned by an address
     *
     * @dev Used to efficiently store both numbers into
     *      one 256-bit unsigned integer using packing
     */
    struct AddressCardType {
        uint128 minted;
        uint128 owned;
    }

    /**
     * @notice Stores how many cards of each type were minted
     *         and owned by an address
     */
    mapping(address => mapping(uint8 => AddressCardType))
        public cardTypeByAddress;

    mapping(uint8 => string) public collectionUri;
    /**
     * @dev Fired in mint(), safeMint()
     *
     * @param by address which executed the mint
     * @param to address which received the mint card
     * @param tokenId minted card id
     * @param cardType type of card that was minted in range [1, 53]
     * @param cardCollection collection of the card that was minted
     * @param upgrade if card is minted by upgrade
     */
    event CardMinted(
        address indexed by,
        address indexed to,
        uint160 tokenId,
        uint8 cardType,
        uint8 cardCollection,
        bool upgrade
    );

    /**
     * @dev Fired in burn()
     *
     * @param by address which executed the burn
     * @param from address whose card was burned
     * @param tokenId burned card id
     * @param cardType type of card that was burned in range [1, 53]
     * @param cardCollection collection of the card that was burned
     * @param burnType burn card type: 0 - upgrade or 1 - buyback
     */
    event CardBurned(
        address indexed by,
        address indexed from,
        uint160 tokenId,
        uint8 cardType,
        uint8 cardCollection,
        uint8 burnType
    );

    /**
     * @dev Fired in setBaseURI()
     *
     * @param by an address which executed update
     * @param oldVal old _baseURI value
     * @param newVal new _baseURI value
     */
    event BaseURIChanged(address by, string oldVal, string newVal);

    /**
     * @dev Fired in addCollection()
     *
     * @param collection the id of collection
     * @param collectionAddress the contract address of collection
     * @param collectionPartnerDaoAddress collection partner DAO address
     */
    event CollectionAdded(
        uint8 collection,
        address collectionAddress,
        address collectionPartnerDaoAddress
    );

    /**
     * @notice Instantiates the contract and gives all roles
     *         to contract deployer
     */
    function initialize() public initializer {
        __ERC721_init("Eternity Deck Card", "EDC");
        OwnableUpgradeable.__Ownable_init();
        __ERC721Enumerable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
        _setupRole(URI_MANAGER_ROLE, msg.sender);

        totalBurned = 0;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory name = string(
            abi.encodePacked(
                '"name": "Eternity Deck: Collection ',
                cardInfo[_tokenId].cardCollection.toString(),
                " ",
                "Edition ",
                cardInfo[_tokenId].editionNumber.toString(),
                '",'
            )
        );
        string
            memory description = '"description": "Represents a card in the eternity deck game",';
        string memory imageUrl = string(
            abi.encodePacked(
                '"image_url": "',
                collectionUri[cardInfo[_tokenId].cardCollection],
                cardInfo[_tokenId].cardType.toString(),
                '.png",'
            )
        );

        string memory cardTypeAttribute = string(
            abi.encodePacked(
                "{",
                '"trait_type": "Card Type",',
                '"value":',
                cardInfo[_tokenId].cardType.toString(),
                "},"
            )
        );

        string memory cardCollectionAttribute = string(
            abi.encodePacked(
                "{",
                '"trait_type": "Card Collection",',
                '"value":',
                cardInfo[_tokenId].cardCollection.toString(),
                "},"
            )
        );

        string memory serialNumberAttribute = string(
            abi.encodePacked(
                "{",
                '"trait_type": "Serial Number",',
                '"value":',
                cardInfo[_tokenId].serialNumber.toString(),
                "},"
            )
        );

        string memory editionNumberAttribute = string(
            abi.encodePacked(
                "{",
                '"trait_type": "Edition Number",',
                '"value":',
                cardInfo[_tokenId].editionNumber.toString(),
                "}"
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                "{",
                                name,
                                description,
                                imageUrl,
                                '"attributes": [',
                                cardTypeAttribute,
                                cardCollectionAttribute,
                                serialNumberAttribute,
                                editionNumberAttribute,
                                "]",
                                "}"
                            )
                        )
                    )
                )
            );
    }

    /**
     * @dev Checks whether a provided card type is
     *         valid (in range [1, 53])
     *
     * @param _cardType the card type to check
     */
    modifier validCardType(uint8 _cardType) {
        require(
            _cardType >= 1 && _cardType <= 53,
            "card type must be in range [1, 53]"
        );
        _;
    }

    string internal theBaseURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return theBaseURI;
    }

    /**
     * @notice Updates base URI used to construct ERC721Metadata.tokenURI for Collection
     *
     * @dev Access restricted by `URI_MANAGER_ROLE` AccessControl role
     * @param _collectionId ID of the Collection
     * @param _newBaseURI new Base URI
     */
    function setBaseURIForCollection(
        uint8 _collectionId,
        string calldata _newBaseURI
    ) external onlyRole(URI_MANAGER_ROLE) {
        // Update base uri of the collection
        collectionUri[_collectionId] = _newBaseURI;
    }

    /**
     * @notice Checks if specified token exists
     *
     * @dev Returns whether the specified token ID has an ownership
     *      information associated with it
     *
     * @param _tokenId ID of the token to query existence for
     * @return whether the token exists (true - exists, false - doesn't exist)
     */
    function exists(uint160 _tokenId) external view returns (bool) {
        // Delegate to internal OpenZeppelin function
        return _exists(_tokenId);
    }

    /**
     * @notice Burns token with token ID specified
     *
     * @dev Access restricted by `BURNER_ROLE` AccessControl role
     *
     * @param _to address that owns token to burn
     * @param _tokenId ID of the token to burn
     * @param _type upgrade or buyback
     */
    function burn(
        address _to,
        uint160 _tokenId,
        uint8 _type
    ) external onlyRole(BURNER_ROLE) {
        // Require _to be the owner of the token to be burned
        require(ownerOf(_tokenId) == _to, "_to does not own token");

        // Get card type and collection
        uint8 _cardType = cardInfo[_tokenId].cardType;
        uint8 _cardCollection = cardInfo[_tokenId].cardCollection;

        // Emit burned event
        emit CardBurned(
            msg.sender,
            _to,
            _tokenId,
            _cardType,
            _cardCollection,
            _type
        );

        // Delegate to internal OpenZeppelin burn function
        // Calls beforeTokenTransfer() which decreases owned
        // card count of _to address for this card type
        _burn(_tokenId);

        // Delete card information
        // Must be reset after call to _burn() as that function
        // calls _beforeTokenTransfer() which uses this information
        delete cardInfo[_tokenId];

        unchecked {
            cardCollectionInfo[_cardCollection].colBurned += 1;
            // Increase amount of cards burned by 1
            totalBurned += 1;
        }
    }

    /**
     * @notice Burns tokens starting with token ID specified
     *
     * @dev Token IDs to be burned: [_tokenId, _tokenId + n)
     *
     * @dev n must be greater or equal 1: `n > 0`
     *
     * @dev Access restricted by `BURNER_ROLE` AccessControl role
     *
     * @param _to address that owns token to burn
     * @param _tokenIds IDs of the tokens to burn
     * @param _type Type of action
     */
    function burnBatch(
        address _to,
        uint160[] calldata _tokenIds,
        uint8 _type
    ) external onlyRole(BURNER_ROLE) {

        uint256 tokenIdsLen = _tokenIds.length;
        // Cannot burn 0 tokens
        require(tokenIdsLen != 0, "cannot burn 0 tokens");

        for (uint8 i = 0; i < tokenIdsLen;) {
            uint160 tokenId = _tokenIds[i];

            // Require _to be the owner of the token to be burned
            require(ownerOf(tokenId) == _to, "_to does not own token");

            // Get card type and collection
            uint8 _cardType = cardInfo[tokenId].cardType;
            uint8 _cardCollection = cardInfo[tokenId].cardCollection;

            // Emit burn event
            emit CardBurned(
                msg.sender,
                _to,
                tokenId,
                _cardType,
                _cardCollection,
                _type
            );

            // Delegate to internal OpenZeppelin burn function
            // Calls beforeTokenTransfer() which decreases owned
            // card count of _to address for this card type
            _burn(tokenId);

            // Delete the card
            // Must be reset after call to _burn() as that function
            // calls _beforeTokenTransfer() which uses this information
            delete cardInfo[tokenId];

            unchecked {
                cardCollectionInfo[_cardCollection].colBurned += 1;
                ++i;
            }
        }

        // Increase amount of cards burned
        unchecked {
            totalBurned += tokenIdsLen;
        }
    }

    /**
     * @notice Creates new token with token ID specified
     *         and assigns an ownership `_to` for this token
     *
     * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
     *      Prefer the use of `safeMint` instead of `mint`.
     *
     * @dev Access restricted by `MINTER_ROLE` AccessControl role
     *
     * @param _to an address to mint token to
     * @param _tokenId ID of the token to mint
     * @param _cardType type of card to mint in range [1, 53]
     * @param _cardCollection the collection of the card to mint
     * @param _upgrade if mint done with upgrade
     */

    function mint(
        address _to,
        uint160 _tokenId,
        uint8 _cardType,
        uint8 _cardCollection,
        bool _upgrade
    ) public validCardType(_cardType) onlyRole(MINTER_ROLE) {
        require(
            cardCollectionInfo[_cardCollection].collectionAddress != address(0),
            "collection  doesn't exists"
        );

        // Save the card info
        // Must be saved before call to _mint() as that function
        // calls _beforeTokenTransfer() which uses this information
        cardInfo[_tokenId] = Card({
            cardType: _cardType,
            cardCollection: _cardCollection,
            serialNumber: cardPopulation[_cardType] + 1,
            editionNumber: cardCollectionPopulation[_cardCollection][_cardType] + 1
        });

        // Delegate to internal OpenZeppelin function
        // Calls beforeTokenTransfer() which increases minted
        // and owned card count of _to address for this card type
        _mint(_to, _tokenId);

        // Increase the population of card type
        // and collection-scoped population
        unchecked {
            cardPopulation[_cardType] += 1;
            cardCollectionPopulation[_cardCollection][_cardType] += 1;
            cardCollectionInfo[_cardCollection].colMinted += 1;
        }

        // Emit minted event
        emit CardMinted(
            msg.sender,
            _to,
            _tokenId,
            _cardType,
            _cardCollection,
            _upgrade
        );
    }

    /**
     * @notice Creates new tokens starting with token ID specified
     *         and assigns an ownership `_to` for these tokens
     *
     * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
     *
     * @dev n must be greater or equal 1: `n > 0`
     *
     * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
     *      Prefer the use of `safeMintBatch` instead of `mintBatch`.
     *
     * @dev Access restricted by `MINTER_ROLE` AccessControl role
     *
     * @param _to an address to mint tokens to
     * @param _tokenId ID of the first token to mint
     * @param _n how many tokens to mint, sequentially increasing the _tokenId
     * @param _cardType type of card to mint in range [1, 53]
     * @param _cardCollection the collection of the card to mint
     */
    function mintBatch(
        address _to,
        uint160 _tokenId,
        uint128 _n,
        uint8 _cardType,
        uint8 _cardCollection
    ) public onlyRole(MINTER_ROLE) validCardType(_cardType) {
        bool _upgrade = false;

        // Cannot mint 0 tokens
        require(_n > 0, "_n cannot be zero");

        require(
            cardCollectionInfo[_cardCollection].collectionAddress != address(0),
            "collection  doesn't exists"
        );

        for (uint256 i = 0; i < _n;) {
            // Save the card type and collection of the card
            // Must be saved before call to _mint() as that function
            // calls _beforeTokenTransfer() which uses this information
            cardInfo[_tokenId + i] = Card({
                cardType: _cardType,
                cardCollection: _cardCollection,
                serialNumber: cardPopulation[_cardType] + i + 1,
                editionNumber: cardCollectionPopulation[_cardCollection][ _cardType] + i + 1
            });

            // Delegate to internal OpenZeppelin mint function
            // Calls beforeTokenTransfer() which increases minted
            // and owned card count of _to address for this card type
            _mint(_to, _tokenId + i);

            // Emit mint event
            emit CardMinted(
                msg.sender,
                _to,
                _tokenId,
                _cardType,
                _cardCollection,
                _upgrade
            );

            unchecked {
                ++i;
            }
        }

        // Increase the population of card type
        // and collection-scoped population
        // by amount of cards minted
        unchecked {
            cardPopulation[_cardType] += _n;
            cardCollectionPopulation[_cardCollection][_cardType] += _n;
            cardCollectionInfo[_cardCollection].colMinted += _n;
        }
           
    }

    /**
     * @notice Creates new token with token ID specified
     *         and assigns an ownership `_to` for this token
     *
     * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
     *      `onERC721Received` on `_to` and throws if the return value is not
     *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     *
     * @dev Access restricted by `MINTER_ROLE` AccessControl role
     *
     * @param _to an address to mint token to
     * @param _tokenId ID of the token to mint
     * @param _cardType type of card to mint in range [1, 53]
     * @param _cardCollection the collection of the card to mint
     * @param _data additional data with no specified format, sent in call to `_to`
     */
    function safeMint(
        address _to,
        uint160 _tokenId,
        uint8 _cardType,
        uint8 _cardCollection,
        bytes calldata _data
    ) external {
        // Delegate to internal mint function (includes AccessControl role check,
        // card type validation and event emission)
        mint(_to, _tokenId, _cardType, _cardCollection, false);

        // If a contract, check if it can receive ERC721 tokens (safe to send)
        if (_to.isContract()) {
            // Try calling the onERC721Received function on the to address
            try
                IERC721ReceiverUpgradeable(_to).onERC721Received(
                    msg.sender,
                    address(0),
                    _tokenId,
                    _data
                )
            returns (bytes4 retval) {
                require(
                    retval ==
                        IERC721ReceiverUpgradeable.onERC721Received.selector,
                    "invalid onERC721Received response"
                );
                // If onERC721Received function reverts
            } catch (bytes memory reason) {
                // If there is no revert reason, assume function
                // does not exist and revert with appropriate reason
                if (reason.length == 0) {
                    revert("mint to non ERC721Receiver implementer");
                    // If there is a reason, revert with the same reason
                } else {
                    // using assembly to get the reason from memory
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    /**
     * @notice Creates new tokens starting with token ID specified
     *         and assigns an ownership `_to` for these tokens
     *
     * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
     *
     * @dev n must be greater or equal 1: `n > 0`
     *
     * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
     *      `onERC721Received` on `_to` and throws if the return value is not
     *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     *
     * @dev Access restricted by `MINTER_ROLE` AccessControl role
     *
     * @param _to an address to mint token to
     * @param _tokenId ID of the token to mint
     * @param _n how many tokens to mint, sequentially increasing the _tokenId
     * @param _cardType type of card to mint in range [1, 53]
     * @param _cardCollection the collection of the card to mint
     * @param _data additional data with no specified format, sent in call to `_to`
     */
    function safeMintBatch(
        address _to,
        uint160 _tokenId,
        uint128 _n,
        uint8 _cardType,
        uint8 _cardCollection,
        bytes memory _data
    ) public {
        // Delegate to internal unsafe batch mint function (includes AccessControl role check,
        // card type validation and event emission)
        mintBatch(_to, _tokenId, _n, _cardType, _cardCollection);

        // If a contract, check if it can receive ERC721 tokens (safe to send)
        if (_to.isContract()) {
            // For each token minted
            for (uint256 i = 0; i < _n;) {
                // Try calling the onERC721Received function on the to address
                try
                    IERC721ReceiverUpgradeable(_to).onERC721Received(
                        msg.sender,
                        address(0),
                        _tokenId + i,
                        _data
                    )
                returns (bytes4 retval) {
                    require(
                        retval ==
                            IERC721ReceiverUpgradeable
                                .onERC721Received
                                .selector,
                        "invalid onERC721Received response"
                    );
                    // If onERC721Received function reverts
                } catch (bytes memory reason) {
                    // If there is no revert reason, assume function
                    // does not exist and revert with appropriate reason
                    if (reason.length == 0) {
                        revert("mint to non ERC721Receiver implementer");
                        // If there is a reason, revert with the same reason
                    } else {
                       // using assembly to get the reason from memory
                        assembly {
                            revert(add(32, reason), mload(reason))
                        }
                    }
                }
                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
     * @notice Creates new tokens starting with token ID specified
     *         and assigns an ownership `_to` for these tokens
     *
     * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
     *
     * @dev n must be greater or equal 1: `n > 0`
     *
     * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
     *      `onERC721Received` on `_to` and throws if the return value is not
     *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     *
     * @dev Access restricted by `MINTER_ROLE` AccessControl role
     *
     * @param _to an address to mint token to
     * @param _tokenId ID of the token to mint
     * @param _n how many tokens to mint, sequentially increasing the _tokenId
     * @param _cardType type of card to mint in range [1, 53]
     * @param _cardCollection the collection of the card to mint
     */
    function safeMintBatch(
        address _to,
        uint160 _tokenId,
        uint128 _n,
        uint8 _cardType,
        uint8 _cardCollection
    ) external {
        // Delegate to internal safe batch mint function (includes AccessControl role check
        // and card type validation)
        safeMintBatch(_to, _tokenId, _n, _cardType, _cardCollection, "");
    }

    /**
     * @inheritdoc ERC721EnumerableUpgradeable
     */
    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    /**
     * @inheritdoc ERC721EnumerableUpgradeable
     *
     * @dev Adjusts owned count for `_from` and `_to` addresses
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _batchSize
    )
        internal
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        // Delegate to inheritance chain
        super._beforeTokenTransfer(_from, _to, _tokenId, _batchSize);

        // Get card type of card being transferred
        uint8 _cardType = cardInfo[_tokenId].cardType;

        // Get card type by address values for to and from
        AddressCardType storage actFrom = cardTypeByAddress[_from][_cardType];
        AddressCardType storage actTo = cardTypeByAddress[_to][_cardType];

        // Check if from address is not zero address
        // (when it is zero address, the token is being minted)
        if (_from != address(0)) {
            // Decrease owned card count of from address
            actFrom.owned--;
        } else {
            // If card is being minted, increase to minted count
            actTo.minted++;
        }

        // Check if to address is not zero address
        // (when it is zero address, the token is being burned)
        if (_to != address(0)) {
            // Increase owned card count of to address
            actTo.owned++;
        }
    }

    /**
     * @notice Gets the total cards minted by card type
     *
     * @dev External function only to be used by the front-end
     */
    function totalCardTypesMinted() external view returns (uint256[] memory) {
        uint256[] memory cardIds = new uint256[](54);

        for (uint8 i = 1; i <= 53;) {
            cardIds[i] = cardPopulation[i];
            unchecked {
                ++i;
            }
        }

        return (cardIds);
    }

    /**
     * @notice Gets the cards of an account
     *
     * @dev External function only to be used by the front-end
     */
    function cardsOfAccount()
        external
        view
        returns (uint256[] memory, Card[] memory)
    {
        uint256 n = balanceOf(msg.sender);

        uint256[] memory cardIds = new uint256[](n);
        Card[] memory cards = new Card[](n);

        for (uint32 i = 0; i < n;) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);

            cardIds[i] = tokenId;
            cards[i] = cardInfo[tokenId];
            unchecked {
                ++i;
            }
        }

        return (cardIds, cards);
    }

    /**
     * @notice Add new collection to cardCollectionInfo mapping
     *
     *
     * Emits a {DaoAddressChanged} event
     * Emits a {CollectionAdded} event
     *
     * @param _collection collection id
     * @param _collectionAddress Collection Smart contract address
     * @param _collectionBuyBack Collection BuyBack value
     * @param _collectionPartnerDaoAddress Partner Dao Address
     */
    function addCollection(
        uint8 _collection,
        address _collectionAddress,
        uint256 _collectionBuyBack,
        address payable _collectionPartnerDaoAddress
    ) external onlyOwner {
        // verify ollection address is set
        require(
            _collectionAddress != address(0),
            "collection address is not set"
        );
        if (cardCollectionInfo[_collection].collectionAddress != address(0)) {
            cardCollectionInfo[_collection]
                .collectionAddress = _collectionAddress;
            cardCollectionInfo[_collection]
                .partnerDaoAddress = _collectionPartnerDaoAddress;
            cardCollectionInfo[_collection]
                .collectionBuyBack = _collectionBuyBack;
            cardCollectionInfo[_collection]
                .totalCardValue = 0;
        } else {
            cardCollectionInfo[_collection] = Collection({
                collectionAddress: _collectionAddress,
                collectionBuyBack: _collectionBuyBack,
                partnerDaoAddress: _collectionPartnerDaoAddress,
                colMinted: 0,
                colBurned: 0,
                totalCardValue: 0,
                totalBuyBacksClaimed: 0
            });
        }

        // emit collection added event
        emit CollectionAdded(
            _collection,
            _collectionAddress,
            _collectionPartnerDaoAddress
        );
    }

    /**
     * @notice Increase the totalBuyBacksClaimed of collection
     *
     * @param _collection collection id
     */
    function increaseCollectionBuyBacks(
        uint8 _collection
    ) external onlyRole(MINTER_ROLE) {
        require(_collection > 0 &&  _collection < 200, "invalid collection [0,200]");
        cardCollectionInfo[_collection].totalBuyBacksClaimed++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title Eternity deck Game Treasury
 *
 */

contract GameTreasury is
    Initializable,
    AccessControlUpgradeable,
    OwnableUpgradeable
{
    /**
     * @notice AccessControl role that allows transfer amount to an address
     *
     * @dev Used in all transfer functions
     */
    bytes32 private constant TREASURER_ROLE = keccak256("TREASURER_ROLE");

    event Deposited(address indexed payee, uint256 weiAmount);

    function initialize() public initializer {
        OwnableUpgradeable.__Ownable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TREASURER_ROLE, msg.sender);
    }

    /**
     * @notice is called for all messages sent to current contract
     */
    fallback() external payable {}

    /**
     * @notice is called for transfer funds
     */
    receive() external payable {}

    /**
     * @notice Send bayback value
     *
     * @param _to address of the player
     * @param _amount amount of the buyback
     *
     */
    function buyBackPayout(
        address _to,
        uint256 _amount
    ) external onlyRole(TREASURER_ROLE) {
        require(_to != address(0), "zero address not accepted");
        require(_amount <= address(this).balance, "not enough funds");
        // Give prize to user
        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    /**
     * @notice Send upgrade cashback value
     *
     * @param _to address of the player
     * @param _amount amount of the cashback
     *
     */
    function giveUpgradeCacheBack(
        address _to,
        uint256 _amount
    ) external onlyRole(TREASURER_ROLE) {
        require(_to != address(0), "zero address not accepted");
        require(_amount <= address(this).balance, "not enough funds");
        // Give change back to user
        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    /**
     * @notice Send upgrade commission
     *
     * @param _to address
     * @param _amount amount of the commission
     *
     */
    function upgradeCommission(
        address _to,
        uint256 _amount
    ) external onlyRole(TREASURER_ROLE) {
        require(_to != address(0), "zero address not accepted");
        require(_amount <= address(this).balance, "not enough funds");
        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    /**
     * @notice Send mint fee
     *
     * @param _to address
     * @param _amount amount of the commission
     *
     */
    function mintFee(
        address _to,
        uint256 _amount
    ) external onlyRole(TREASURER_ROLE) {
        require(_to != address(0), "zero address not accepted");
        require(_amount <= address(this).balance, "not enough funds");
        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    /**
     * @notice Claim buyback commission
     *
     * @param _to address
     * @param _amount amount of the commission
     *
     */
    function claimCommission(
        address _to,
        uint256 _amount
    ) external onlyRole(TREASURER_ROLE) {
        require(_to != address(0), "zero address not accepted");
        require(_amount <= address(this).balance, "not enough funds");
        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    /**
     * @notice Send refund for commit
     *
     * @param _to address
     * @param _amount amount of the commission
     *
     */
    function refundCommit(
        address _to,
        uint256 _amount
    ) external onlyRole(TREASURER_ROLE) {
        require(_to != address(0), "zero address not accepted");
        require(_amount <= address(this).balance, "not enough funds");
        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    /**
     * @notice Send money to current contact
     */
    function liquidityDeposit() public payable {
        require(msg.value > 0, "invalid amount");
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Check balance of the current contract
     *
     */
    function balance() public view returns (uint256) {
        return address(this).balance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Eternity deck Treasury Reserve
 *---------------------------------------------------------------------------
 */

contract TreasuryReserve is AccessControl, Ownable {
    /**
     * @notice AccessControl role that allows to claim prize
     *
     * @dev Used in givePrize()
     */
    bytes32 private constant TREASURER_ROLE = keccak256("TREASURER_ROLE");

    event Deposited(address indexed payee, uint256 weiAmount);

    /**
     * @dev Fired in withdraw()
     * @param value value being withdrawn
     */
    event Withdraw(uint256 value);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TREASURER_ROLE, msg.sender);
    }

    /**
     * @dev is used as this may run out of gas when called via `.transfer()`
     */
    fallback() external payable {}

    /**
     * @dev is used as this may run out of gas when called via `.transfer()`
     */
    receive() external payable {}

    /**
     * @notice Send bayback value
     *
     * @param _to address of the player
     * @param _amount value of the buyback
     *
     */
    function buyBackPayout(
        address _to,
        uint256 _amount
    ) external onlyRole(TREASURER_ROLE) {
        require(_to != address(0), "zero address not accepted");
        require(_amount <= address(this).balance, "not enough funds");
        // Give prize to user
        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    /**
     * @notice Send upgrade cashback value
     *
     * @param _to address of the player
     * @param _amount value of the cashback
     *
     */
    function giveUpgradeCacheBack(
        address _to,
        uint256 _amount
    ) external onlyRole(TREASURER_ROLE) {
        require(_to != address(0), "zero address not accepted");
        require(_amount <= address(this).balance, "not enough funds");
        // Give cacheBack to user
        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    /**
     * @notice Send upgrade commission
     *
     * @param _to address
     * @param _amount value of the commission
     *
     */
    function upgradeCommission(
        address _to,
        uint256 _amount
    ) external onlyRole(TREASURER_ROLE) {
        require(_to != address(0), "zero address not accepted");
        require(_amount <= address(this).balance, "not enough funds");
        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    /**
     * @notice Claim buyback commission
     *
     * @param _to address
     * @param _amount value of the commission
     *
     */
    function claimCommission(
        address _to,
        uint256 _amount
    ) external onlyRole(TREASURER_ROLE) {
        require(_to != address(0), "zero address not accepted");
        require(_amount <= address(this).balance, "not enough funds");
        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    /**
     * @notice Send money to current contact
     *
     */
    function liquidityDeposit() public payable {
        require(msg.value > 0, "invalid amount");
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Allows withdraw funds from the current contract
     *
     * @param _to address to withdraw funds
     * @param _amount amount to withdraw
     *
     */
    function withdraw(
        address _to,
        uint256 _amount
    ) external payable onlyOwner {
        require(_to != address(0), "zero address not accepted");
        require(_amount <= address(this).balance, "not enough funds");
        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "can not withdraw");
        emit Withdraw(_amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
  * @notice Collection interface for getting collection fees data
   * Collection should have public marketplaceSellerFeePercent value
   * Collection should have public marketplaceBuyerFeePercent value
   * Collection should have public partnerMarketplaceFeePercent value
   *
   * EXAMPLE:
   * 
   * uint32 public marketplaceSellerFeePercent = 5_000;
   * 
   * uint32 public marketplaceBuyerFeePercent = 5_000;
   * 
   * uint32 public partnerMarketplaceFeePercent = 10_000;
   *
   */
   
interface ICollection {
    struct Coupon {
      bytes32 r;
      bytes32 s;
      uint8 v;
    }
    function marketplaceSellerFeePercent() external view returns(uint32);
    function marketplaceBuyerFeePercent() external view returns(uint32);
    function partnerMarketplaceFeePercent() external view returns(uint32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
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
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721Upgradeable.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
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
                        Strings.toHexString(account),
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
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