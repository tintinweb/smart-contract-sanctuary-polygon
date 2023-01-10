// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

import "./interfaces/IApeironStar.sol";
import "./interfaces/IApeironStarData.sol";
import "./interfaces/IApeironStarOrbitalTrackData.sol";
import "./planets/contracts/interfaces/IApeironPlanet.sol";
import "./token/contracts/interfaces/IBlacklist.sol";

import "./token/contracts/TokenReceiptHandler.sol";
import "./StarMeta.sol";

contract StarOrbitalTrack is
    StarMeta,
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    IERC721ReceiverUpgradeable
{
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IApeironStar internal starContract;
    IApeironStarData public starDataContract;
    IApeironStarOrbitalTrackData public starOrbitalTrackDataContract;
    IApeironPlanet internal planetContract;
    IBlacklist public blacklistContract;
    TokenReceiptHandler internal tokenReceiptHandler;
    IERC20Upgradeable public tokenContract;

    address public platformAddress;
    uint256 public platformFeePercent; // % * 100, e.g. 5% = 500
    uint256 public percentMaxValue; // 10000
    uint256 public earlyDetachFeePercent; // % * 100, e.g. 10% = 1000
    uint256 public detachCooldown;
    uint256 public minimumDuration;
    uint256 internal constant SECONDS_IN_DAY = 86400;

    // use for create new inviteGroupId
    uint256 internal _generalInviteGroupID;

    // event
    // update contract addresss
    event ContractSettingUpdated(
        address indexed _starAddress,
        address indexed _starDataAddress,
        address indexed _starOrbitalTrackDataAddress,
        address _planetAddress,
        address _tokenAddress,
        address _blacklistAddress
    );
    // update contract addresss
    event TokenReceiptContractsUpdated(address indexed _tokenReceipt);
    // update platform fee
    event PlatformInfoUpdated(
        address indexed _platformAddress,
        uint256 indexed _platformFeePercent,
        uint256 indexed _earlyDetachFeePercent,
        uint256 _percentMaxValue
    );
    // update contract Orbital Setting
    event OrbitalSettingUpdated(
        uint256 _detachCooldown,
        uint256 _minimumDuration
    );

    // update star Orbital Trcak Setting
    event OrbitalTracksUpdated(
        uint256 indexed _starId,
        uint256 _inviteGroupId,
        uint256 _slotIndexCount,
        uint256[] _slotIndexArray,
        uint256 _duration,
        uint256 _cost,
        address[] _inviteAddress,
        uint256 _maxCountForEachAddress,
        bool _canBeRenew
    );

    // emit when Planet Attached to OrbitalTrack
    event PlanetAttachedOrbitalTrack(
        uint256 indexed _starId,
        uint256 indexed _planetId,
        uint256 indexed _slotIndex,
        uint256 _rentalEndTime
    );
    // emit when Planet Detached from OrbitalTrack
    event PlanetDetachedOrbitalTrack(
        uint256 indexed _starId,
        uint256 indexed _planetId,
        uint256 indexed _slotIndex,
        uint256 _cooldown
    );
    // emit when Planet Renew OrbitalTrack
    event PlanetRenewOrbitalTrack(
        uint256 indexed _starId,
        uint256 indexed _planetId,
        uint256 indexed _slotIndex,
        uint256 _rentalEndTime
    );

    /// @dev modifier to check if nft is owner
    function _checkNFTOwner(IERC721 nftContract, uint256 _tokenId) internal {
        require(nftContract.ownerOf(_tokenId) == msg.sender, "Not owner");
    }

    modifier isNFTOwner(IERC721 nftContract, uint256 _tokenId) {
        _checkNFTOwner(nftContract, _tokenId);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() external virtual initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    /// @dev Required by UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /// @dev Required by IERC721Receiver
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @notice Setup contracts
     *
     * @param _starAddress ApeironStar contract address
     * @param _starDataAddress AprironStarData contract address
     * @param _starOrbitalTrackDataAddress ApeironStarOrbitalTrackData contract address
     * @param _planetAddress ApeironGodiverseCollection contract address
     * @param _tokenAddress Token contract address (WETH)
     * @param _blacklistAddress Blacklist contract address
     */
    function updateContractSetting(
        address _starAddress,
        address _starDataAddress,
        address _starOrbitalTrackDataAddress,
        address _planetAddress,
        address _tokenAddress,
        address _blacklistAddress
    ) external onlyOwner {
        require(
            _starAddress.isContract() &&
                _starDataAddress.isContract() &&
                _starOrbitalTrackDataAddress.isContract() &&
                _planetAddress.isContract() &&
                _tokenAddress.isContract() &&
                _blacklistAddress.isContract(),
            "address must be a contract"
        );

        // NFT Address
        starContract = IApeironStar(_starAddress);
        starDataContract = IApeironStarData(_starDataAddress);
        starOrbitalTrackDataContract = IApeironStarOrbitalTrackData(
            _starOrbitalTrackDataAddress
        );
        planetContract = IApeironPlanet(_planetAddress);
        tokenContract = IERC20Upgradeable(_tokenAddress);
        blacklistContract = IBlacklist(_blacklistAddress);

        // event
        emit ContractSettingUpdated(
            _starAddress,
            _starDataAddress,
            _starOrbitalTrackDataAddress,
            _planetAddress,
            _tokenAddress,
            _blacklistAddress
        );
    }

    /**
     * @notice Setup TokenReceipt contracts
     *
     * @param _tokenReceipt TokenReceiptHandler contract address
     */
    function setupTokenReceiptContracts(address _tokenReceipt)
        external
        onlyOwner
    {
        require(_tokenReceipt.isContract(), "addresses must be contract");
        tokenReceiptHandler = TokenReceiptHandler(_tokenReceipt);
        emit TokenReceiptContractsUpdated(_tokenReceipt);
    }

    /**
     * @notice Set up Platform Fee Percent
     *
     * @param _platformAddress platform fee receive Address
     * @param _platformFeePercent % * 100, e.g. 5% = 500
     * @param _earlyDetachFeePercent  % * 100, e.g. 10% = 1000
     * @param _percentMaxValue 10000
     */
    function setPlatformFeePercent(
        address _platformAddress,
        uint256 _platformFeePercent,
        uint256 _earlyDetachFeePercent,
        uint256 _percentMaxValue
    ) external onlyOwner {
        require(
            _platformAddress != address(0) &&
                _platformFeePercent >= 0 &&
                _platformFeePercent <= _percentMaxValue &&
                _earlyDetachFeePercent >= 0 &&
                _earlyDetachFeePercent <= _percentMaxValue,
            "invalid argument"
        );
        platformAddress = _platformAddress;
        platformFeePercent = _platformFeePercent;
        earlyDetachFeePercent = _earlyDetachFeePercent;
        percentMaxValue = _percentMaxValue;

        // event
        emit PlatformInfoUpdated(
            platformAddress,
            platformFeePercent,
            earlyDetachFeePercent,
            percentMaxValue
        );
    }

    /**
     * @notice update Detach Cooldown
     *
     * @param _detachCooldown detach Cooldown
     * @param _minimumDuration minimum attach Duration (in day)
     */
    function updateOrbitalSetting(
        uint256 _detachCooldown,
        uint256 _minimumDuration
    ) external onlyOwner {
        detachCooldown = _detachCooldown;
        minimumDuration = _minimumDuration;
        emit OrbitalSettingUpdated(_detachCooldown, _minimumDuration);
    }

    /**
     * @notice init OrbitalTrackData, if there are not Inited
     *
     * @param _starId star ID
     */
    function _checkNInitOrbitalTrackData(uint256 _starId) internal {
        // get star attachment data
        uint256[] memory attributes = starContract.convertToAttributes(
            starDataContract.getStarGenByStarId(_starId),
            17
        );

        // if there are no orbitalTrackData, init it
        // attributes[16] = tier number
        starOrbitalTrackDataContract.checkNInitStarOrbitalTrackData(
            _starId,
            attributes[16],
            attributes[6]
        );
    }

    /**
     * @notice star owner attach own planet on track
     *
     * @param _starId star ID
     * @param _planetId planet ID
     */
    function starOwnerAttachOwnPlanet(uint256 _starId, uint256 _planetId)
        external
        isNFTOwner(starContract, _starId)
        isNFTOwner(planetContract, _planetId)
    {
        // Init Orbital Track Data
        _checkNInitOrbitalTrackData(_starId);

        (bool canAttach, uint256 slotIndex) = starOrbitalTrackDataContract
            .checkOwnerAttachPlanet(_starId, _planetId);
        require(canAttach, "planet cannot attach");
        _attachingPlanet(_starId, msg.sender, _planetId, slotIndex, 0);
    }

    /**
     * @notice star owner update open/whitelist Rental Setting
     * -------------------------------------------------------
     * if _inviteGroupId = 0 & _inviteAddressList.length = 0 & _maxCountForEachAddress = 0,
     * open rental
     * -------------------------------------------------------
     * if _inviteGroupId = 0 & _inviteAddressList.length > 0 & _maxCountForEachAddress > 0,
     * create new group id for it
     * -------------------------------------------------------
     * if _inviteGroupId != 0 & _inviteAddressList.length > 0 & _maxCountForEachAddress > 0,
     * update existing group info
     * -------------------------------------------------------
     * if _inviteGroupId != 0 & _inviteAddressList.length > 0 & _maxCountForEachAddress = 0,
     * remove that group
     * -------------------------------------------------------
     *
     * @param _starId star ID
     * @param _inviteGroupId invite group ID
     * @param _numberOfTracks number Of Tracks
     * @param _duration rental duration
     * @param _cost rental cost
     * @param _inviteAddressList invite address array
     * @param _maxCountForEachAddress max count for each address on invite group ID
     * @param _canBeRenew track can be renew
     */
    function updateRentalSetting(
        uint256 _starId,
        uint256 _inviteGroupId,
        uint256 _numberOfTracks,
        uint256 _duration,
        uint256 _cost,
        address[] memory _inviteAddressList,
        uint256 _maxCountForEachAddress,
        bool _canBeRenew
    ) external isNFTOwner(starContract, _starId) {
        require(_duration >= minimumDuration, "invalid argument");

        bool isNewInviteGroup = false;
        if (
            _inviteGroupId == 0 &&
            _inviteAddressList.length > 0 &&
            _maxCountForEachAddress > 0
        ) {
            _generalInviteGroupID++;
            _inviteGroupId = _generalInviteGroupID;
            isNewInviteGroup = true;
        }

        // Init Orbital Track Data
        _checkNInitOrbitalTrackData(_starId);

        // update track setting
        (
            uint256 count,
            uint256[] memory resultArray
        ) = starOrbitalTrackDataContract.dataUpdateRentalSetting(
                _starId,
                isNewInviteGroup,
                _inviteGroupId,
                _numberOfTracks,
                _duration,
                _cost,
                _inviteAddressList,
                _maxCountForEachAddress,
                _canBeRenew
            );

        // event
        emit OrbitalTracksUpdated(
            _starId,
            _inviteGroupId,
            count,
            resultArray,
            _duration,
            _cost,
            _inviteAddressList,
            _maxCountForEachAddress,
            _canBeRenew
        );
    }

    /**
     * @notice verify invitee who was invited to specified orbital track or not
     *
     * @param _invitee invitee
     * @param _starId star ID
     * @param _inviteGroupId invite group ID
     */
    function _isInvitedStarOrbitalTrack(
        address _invitee,
        uint256 _starId,
        uint256 _inviteGroupId
    ) internal view returns (bool, uint256) {
        StarOrbitalTrackInviteListData
            memory orbitalTrackInviteListData = starOrbitalTrackDataContract
                .getStarOrbitalTrackInviteListData(_starId, _inviteGroupId);

        for (
            uint256 i = 0;
            i < orbitalTrackInviteListData.inviteAddressList.length;
            i++
        ) {
            if (orbitalTrackInviteListData.inviteAddressList[i] == _invitee) {
                return (
                    true,
                    orbitalTrackInviteListData.maxCountForEachAddress
                );
            }
        }

        return (false, 0);
    }

    /**
     * @notice check planet owner Reach Max Count or not, only use when invite group ID != 0
     *
     * @param _starId star ID
     * @param _inviteGroupId invite group ID
     * @param _planetId planet ID
     */
    function _checkReachMaxCount(
        uint256 _starId,
        uint256 _inviteGroupId,
        uint256 _planetId
    ) internal view {
        // check planet owner is reach max count or not
        if (_inviteGroupId != 0) {
            // check wallet address is removed on that groupId or not
            (
                bool isInInviteList,
                uint256 maxCountForEachAddress
            ) = _isInvitedStarOrbitalTrack(msg.sender, _starId, _inviteGroupId);

            // count attached count
            StarOrbitalTrackData[]
                memory starOTDatas = starOrbitalTrackDataContract
                    .getStarOrbitalTrackData(_starId);
            uint256 attachCount = 0;
            for (uint256 i = 0; i < starOTDatas.length; i++) {
                // match the inviteGroupId
                if (
                    _inviteGroupId == starOTDatas[i].inviteGroupId &&
                    msg.sender == starOTDatas[i].planetOwnerAddress
                ) {
                    // do not count itself (renew)
                    if (_planetId != starOTDatas[i].attachedPlanetId) {
                        attachCount++;
                    }
                }
            }
            // save contract size, isInInviteList can be check first
            require(
                isInInviteList && attachCount < maxCountForEachAddress,
                "Is reach max ot count"
            );
        }
    }

    /**
     * @notice user rent the star orbital track
     *
     * @param _starId star ID
     * @param _planetId attach planet id
     * @param _slotIndex star orbital track index
     */
    function rentingOrbitalTrack(
        uint256 _starId,
        uint256 _planetId,
        uint256 _slotIndex
    ) external virtual isNFTOwner(planetContract, _planetId) {
        StarOrbitalTrackData
            memory orbitalTrackData = starOrbitalTrackDataContract
                .getStarOrbitalTrackDataWithIndex(_starId, _slotIndex);

        (bool isInvited, ) = _isInvitedStarOrbitalTrack(
            msg.sender,
            _starId,
            orbitalTrackData.inviteGroupId
        );

        // check slot is listing, and available
        require(
            orbitalTrackData.rentingState == OrbitalTrackState.Listing &&
                block.timestamp > orbitalTrackData.availableTrackTime &&
                block.timestamp >
                starOrbitalTrackDataContract.planetOrbitalTrackCooldownMap(
                    _planetId
                ) &&
                // check invite address is empty or sender
                (orbitalTrackData.inviteGroupId == 0 || isInvited),
            "invalid argument"
        );

        // check planet owner is reach max count or not
        _checkReachMaxCount(_starId, orbitalTrackData.inviteGroupId, _planetId);

        // transfer fee
        uint256 platformFee = _getPlatformFee(orbitalTrackData.rentalFee);
        // send token to contract
        _tokenTransferFromTo(
            msg.sender,
            address(this),
            orbitalTrackData.rentalFee - platformFee
        );
        // send token to platform receiver
        _tokenTransferFromTo(msg.sender, platformAddress, platformFee);
        //attach planet to star
        _attachingPlanet(
            _starId,
            msg.sender,
            _planetId,
            _slotIndex,
            block.timestamp + (SECONDS_IN_DAY * orbitalTrackData.rentalDuration)
        );
    }

    /**
     * @notice user renew the star orbital track
     *
     * @param _starId star ID
     * @param _planetId attach planet id
     * @param _slotIndex star orbital track index
     */
    function renewRentingOrbitalTrack(
        uint256 _starId,
        uint256 _planetId,
        uint256 _slotIndex
    ) external {
        StarOrbitalTrackData
            memory orbitalTrackData = starOrbitalTrackDataContract
                .getStarOrbitalTrackDataWithIndex(_starId, _slotIndex);

        // check argument is correct, and only can renew after endtime -1 day
        require(
            orbitalTrackData.rentingState == OrbitalTrackState.Renting &&
                orbitalTrackData.attachedPlanetId == _planetId &&
                orbitalTrackData.planetOwnerAddress == msg.sender &&
                orbitalTrackData.canBeRenew &&
                block.timestamp >
                orbitalTrackData.rentalEndTime - SECONDS_IN_DAY,
            "invalid argument"
        );

        // check planet owner is reach max count or not
        _checkReachMaxCount(_starId, orbitalTrackData.inviteGroupId, _planetId);

        // update rentalStartTime
        if (block.timestamp > orbitalTrackData.rentalEndTime) {
            orbitalTrackData.rentalStartTime = block.timestamp;
        }
        /* period between end time and end time - 1 day */
        else {
            orbitalTrackData.rentalStartTime = orbitalTrackData.rentalEndTime;
        }

        orbitalTrackData.rentalEndTime =
            orbitalTrackData.rentalStartTime +
            (SECONDS_IN_DAY * orbitalTrackData.rentalDuration);

        uint256 platformFee = _getPlatformFee(orbitalTrackData.rentalFee);
        orbitalTrackData.rentalFeeAfterPlatform =
            orbitalTrackData.rentalFee -
            platformFee;

        starOrbitalTrackDataContract.updateStarOrbitalTrackData(
            _starId,
            _slotIndex,
            orbitalTrackData
        );

        // token handle
        // send token to contract
        _tokenTransferFromTo(
            msg.sender,
            address(this),
            orbitalTrackData.rentalFee - platformFee
        );
        _tokenTransferFromTo(msg.sender, platformAddress, platformFee);

        // emit event
        emit PlanetRenewOrbitalTrack(
            _starId,
            _planetId,
            _slotIndex,
            orbitalTrackData.rentalEndTime
        );
    }

    /**
     * @notice star Owner Unstake Planet (own planet or rent planet)
     *
     * @param _starId star ID
     * @param _planetId attach planet id
     * @param _slotIndex star orbital track index
     */
    function starOwnerDetachPlanet(
        uint256 _starId,
        uint256 _planetId,
        uint256 _slotIndex
    ) external isNFTOwner(starContract, _starId) {
        StarOrbitalTrackData
            memory orbitalTrackData = starOrbitalTrackDataContract
                .getStarOrbitalTrackDataWithIndex(_starId, _slotIndex);

        // check which slot should be detach
        require(
            orbitalTrackData.rentingState == OrbitalTrackState.Renting &&
                orbitalTrackData.attachedPlanetId == _planetId,
            "invalid argument"
        );

        // handle token price, if planet is not owned by star owner
        if (orbitalTrackData.planetOwnerAddress != msg.sender) {
            (
                uint256 starOwnerReceive,
                uint256 planetOwnerReceive
            ) = starOrbitalTrackDataContract.getStarOwnerDetachPlanetBalance(
                    _starId,
                    _planetId,
                    _slotIndex,
                    earlyDetachFeePercent,
                    percentMaxValue
                );
            _tokenTransfer(starOwnerReceive, msg.sender);
            _tokenTransfer(
                planetOwnerReceive,
                orbitalTrackData.planetOwnerAddress
            );
        }

        // detach planet
        // if block.timestamp < orbitalTrackData.rentalEndTime,
        // need to add detach cooldown on orbital track and planet
        _detachingPlanet(
            _starId,
            orbitalTrackData.planetOwnerAddress,
            _planetId,
            _slotIndex,
            block.timestamp < orbitalTrackData.rentalEndTime,
            true
        );
    }

    /**
     * @notice planet Owner Unstake Planet (rent planet)
     *
     * @param _starId star ID
     * @param _planetId attach planet id
     * @param _slotIndex star orbital track index
     */
    function planetOwnerDetachPlanet(
        uint256 _starId,
        uint256 _planetId,
        uint256 _slotIndex
    ) external {
        StarOrbitalTrackData
            memory orbitalTrackData = starOrbitalTrackDataContract
                .getStarOrbitalTrackDataWithIndex(_starId, _slotIndex);
        require(
            orbitalTrackData.rentingState == OrbitalTrackState.Renting &&
                orbitalTrackData.planetOwnerAddress == msg.sender &&
                orbitalTrackData.attachedPlanetId == _planetId,
            "invalid argument"
        );
        (
            uint256 starOwnerReceive,
            uint256 planetOwnerReceive
        ) = starOrbitalTrackDataContract.getPlanetOwnerDetachPlanetBalance(
                _starId,
                _planetId,
                _slotIndex,
                earlyDetachFeePercent,
                percentMaxValue
            );
        _tokenTransfer(starOwnerReceive, starContract.ownerOf(_starId));
        _tokenTransfer(planetOwnerReceive, msg.sender);

        // detach planet
        _detachingPlanet(
            _starId,
            msg.sender,
            _planetId,
            _slotIndex,
            block.timestamp < orbitalTrackData.rentalEndTime,
            false
        );
    }

    /**
     * @notice attach planet to star, checking will be held on external function
     *
     * @param _starId star ID
     * @param _planetOwner planet owner address
     * @param _planetId planet ID
     * @param _slotIndex orbital slot index
     * @param _rentalEndTime rental endTime, 0 will be own planet to own star
     */
    function _attachingPlanet(
        uint256 _starId,
        address _planetOwner,
        uint256 _planetId,
        uint256 _slotIndex,
        uint256 _rentalEndTime
    ) internal {
        // reject the request if planet or star is blacklisted
        require(
            !blacklistContract.blacklistedNFT(
                _planetOwner,
                address(planetContract),
                _planetId
            ) &&
                !blacklistContract.blacklistedNFT(
                    starContract.ownerOf(_starId),
                    address(starContract),
                    _starId
                ),
            "star or planet is blacklisted"
        );

        // only can called by this contract
        // setup starData
        StarOrbitalTrackData
            memory orbitalTrackData = starOrbitalTrackDataContract
                .getStarOrbitalTrackDataWithIndex(_starId, _slotIndex);
        orbitalTrackData.rentingState = OrbitalTrackState.Renting;
        orbitalTrackData.planetOwnerAddress = _planetOwner;
        orbitalTrackData.rentalStartTime = block.timestamp;
        orbitalTrackData.attachedPlanetId = _planetId;
        orbitalTrackData.rentalEndTime = _rentalEndTime;
        orbitalTrackData.rentalFeeAfterPlatform =
            orbitalTrackData.rentalFee -
            _getPlatformFee(orbitalTrackData.rentalFee);

        // update starData
        starOrbitalTrackDataContract.updateStarOrbitalTrackData(
            _starId,
            _slotIndex,
            orbitalTrackData
        );

        // transfer planet to this contract (staking)
        _planetTransferFromTo(_planetOwner, address(this), _planetId);

        // create planet receipt to planet owner
        tokenReceiptHandler.createReceipts(
            _planetOwner,
            address(planetContract),
            _asDefaultValueArray(_planetId, 1),
            _asDefaultValueArray(1, 1)
        );

        // emit event
        emit PlanetAttachedOrbitalTrack(
            _starId,
            _planetId,
            _slotIndex,
            _rentalEndTime
        );
    }

    /**
     * @notice detach planet to star, checking will be held on external function
     *
     * @param _starId star ID
     * @param _planetOwner planet owner address
     * @param _planetId planet ID
     * @param _slotIndex orbital slot index
     * @param _haveDetachCooldown have detach cooldown
     */
    function _detachingPlanet(
        uint256 _starId,
        address _planetOwner,
        uint256 _planetId,
        uint256 _slotIndex,
        bool _haveDetachCooldown,
        bool _isStarOwnerDetach
    ) internal {
        // reset orbital track data
        // planet owner detach and _haveDetachCooldown
        // or star owner detach own planet
        uint256 cooldown = 0;
        if (
            (_haveDetachCooldown && !_isStarOwnerDetach) ||
            (_isStarOwnerDetach && _planetOwner == msg.sender)
        ) {
            starOrbitalTrackDataContract.setPlanetOrbitalTrackCooldownMap(
                _planetId,
                block.timestamp + detachCooldown
            );
        }
        // star owner early detach will have orbital track cooldown
        if (_haveDetachCooldown && _isStarOwnerDetach) {
            cooldown = block.timestamp + detachCooldown;
        }
        starOrbitalTrackDataContract.updateDetachOrbitalTrackData(
            _starId,
            _slotIndex,
            cooldown
        );

        // transfer planet from this contract to planet owner (unstaking)
        _planetTransferFromTo(address(this), _planetOwner, _planetId);

        // burn planet receipt to planet owner
        tokenReceiptHandler.burnReceipts(
            _planetOwner,
            address(planetContract),
            _asDefaultValueArray(_planetId, 1),
            _asDefaultValueArray(1, 1)
        );

        // emit event
        if (_haveDetachCooldown) {
            cooldown = block.timestamp + detachCooldown;
        }
        emit PlanetDetachedOrbitalTrack(
            _starId,
            _planetId,
            _slotIndex,
            cooldown
        );
    }

    /**
     * @notice contrcat transfer token to other
     *
     * @param _amount amount
     * @param _toAddress receive address
     */
    function _tokenTransfer(uint256 _amount, address _toAddress) internal {
        if (_amount > 0) {
            tokenContract.safeTransfer(_toAddress, _amount);
        }
    }

    /**
     * @notice tokenContract safeTransferFrom, save contract size
     *
     * @param _fromAddress give address
     * @param _toAddress receive address
     * @param _amount amount
     */
    function _tokenTransferFromTo(
        address _fromAddress,
        address _toAddress,
        uint256 _amount
    ) internal {
        tokenContract.safeTransferFrom(_fromAddress, _toAddress, _amount);
    }

    /**
     * @notice planetContract safeTransferFrom, save contract size
     *
     * @param _fromAddress give address
     * @param _toAddress receive address
     * @param _planetId planet ID
     */
    function _planetTransferFromTo(
        address _fromAddress,
        address _toAddress,
        uint256 _planetId
    ) internal {
        planetContract.safeTransferFrom(_fromAddress, _toAddress, _planetId);
    }

    function _asDefaultValueArray(uint256 element, uint256 length)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            array[i] = element;
        }

        return array;
    }

    /**
     * @notice get Fee * platformFeePercent
     *
     * @param _fee fee
     */
    function _getPlatformFee(uint256 _fee) internal view returns (uint256) {
        return (_fee * platformFeePercent) / percentMaxValue;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../StarMeta.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IApeironStar is IERC721 {
    function safeMint(
        uint256 gene,
        address to,
        uint256 tokenId
    ) external;

    function getStarGodiverseMapList(
        uint256 _tokenId,
        StarMeta.GodiverseSlot _slot
    ) external view returns (uint256[] memory);

    // function starAttachingGodiverse(
    //     uint256 _tokenId,
    //     StarMeta.GodiverseSlot _slot,
    //     uint256 _slotIndex,
    //     uint256 _attachmentId
    // ) external;

    // function starDetachingGodiverse(
    //     uint256 _tokenId,
    //     StarMeta.GodiverseSlot _slot,
    //     uint256 _slotIndex,
    //     uint256 _attachmentId
    // ) external;

    function convertToAttributes(uint256 _geneId, uint256 _numOfAttributes)
        external
        pure
        returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../StarMeta.sol";

interface IApeironStarData {
    function updateStarGenMap(uint256 _starId, uint256 _starGen) external;

    function getStarGenByStarId(uint256 _starId)
        external
        view
        returns (uint256);

    // Godiverse
    function initStarGodiverseMap(
        uint256 _starId,
        StarMeta.GodiverseSlot _slot,
        uint256 _slotCount
    ) external;

    function setStarGodiverseMap(
        uint256 _starId,
        StarMeta.GodiverseSlot _slot,
        uint256 _slotIndex,
        uint256 _godiverseId
    ) external;

    function removeStarGodiverseMap(
        uint256 _starId,
        StarMeta.GodiverseSlot _slot,
        uint256 _slotIndex
    ) external;

    function getStarGodiverseMapList(
        uint256 _starId,
        StarMeta.GodiverseSlot _slot
    ) external view returns (uint256[] memory);

    function getAvailableGodiverseIdMap(StarMeta.GodiverseSlot _slot)
        external
        returns (uint256[] memory);

    function getGodiverseInfo(uint256 _godiverseId)
        external
        returns (StarMeta.GodiverseInfo memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../StarMeta.sol";

interface IApeironStarOrbitalTrackData {
    // mapping(uint256 => uint256) public planetOrbitalTrackCooldownMap;

    // Orbital track
    function planetOrbitalTrackCooldownMap(uint256 _planetId)
        external
        view
        returns (uint256);

    function setPlanetOrbitalTrackCooldownMap(
        uint256 _planetId,
        uint256 _cooldown
    ) external;

    function checkNInitStarOrbitalTrackData(
        uint256 _starId,
        uint256 _tier,
        uint256 _ultranova
    ) external;

    function addStarOrbitalTrackData(uint256 _starId, uint256 _otSlotCount)
        external;

    function getStarOrbitalTrackData(uint256 _starId)
        external
        view
        returns (StarMeta.StarOrbitalTrackData[] memory);

    function getStarOrbitalTrackDataWithIndex(
        uint256 _starId,
        uint256 _slotIndex
    ) external view returns (StarMeta.StarOrbitalTrackData memory);

    function removeStarOrbitalTrackSlot(
        uint256 _starId,
        uint256 _slotIndex
    ) external;

    function updateStarOrbitalTrackData(
        uint256 _starId,
        uint256 _slotIndex,
        StarMeta.StarOrbitalTrackData memory _starOrbitalTrackData
    ) external;

    function updateDetachOrbitalTrackData(
        uint256 _starId,
        uint256 _slotIndex,
        uint256 _availableTrackTime
    ) external;

    function checkOwnerAttachPlanet(uint256 _starId, uint256 _planetId)
        external
        returns (bool, uint256);

    function getStarOrbitalTrackInviteListData(
        uint256 _starId,
        uint256 _inviteGroupId
    ) external view returns (StarMeta.StarOrbitalTrackInviteListData memory);

    function dataUpdateRentalSetting(
        uint256 _starId,
        bool _isNewInviteGroup,
        uint256 _inviteGroupId,
        uint256 _numberOfTracks,
        uint256 _duration,
        uint256 _cost,
        address[] memory _inviteAddress,
        uint256 _maxCountForEachAddress,
        bool _canBeRenew
    ) external returns (uint256, uint256[] memory);

    function getStarOwnerDetachPlanetBalance(
        uint256 _starId,
        uint256 _planetId,
        uint256 _slotIndex,
        uint256 earlyDetachFeePercent,
        uint256 percentMaxValue
    ) external returns (uint256 starOwnerReceive, uint256 planetOwnerReceive);

    function getPlanetOwnerDetachPlanetBalance(
        uint256 _starId,
        uint256 _planetId,
        uint256 _slotIndex,
        uint256 earlyDetachFeePercent,
        uint256 percentMaxValue
    ) external returns (uint256 starOwnerReceive, uint256 planetOwnerReceive);

    function getStarOrbitalTrackRentedData(uint256 _starId)
        external
        view
        returns (StarMeta.StarOrbitalTrackRentedData[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IApeironPlanet is IERC721 {
    function safeMint(
        uint256 gene,
        // uint256 parentA,
        // uint256 parentB,
        uint256[] calldata parents,
        address to,
        uint256 tokenId
    ) external;

    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IBlacklist {
    function blacklistedNFT(
        address _owner,
        address _token,
        uint256 _id
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./utils/AccessProtectedUpgradable.sol";

import "./interfaces/ITokenReceiptable.sol";

/// @title Contract for Token Receipt Handler
/// @notice This contract is used to handle token receipts for mint or burn.
contract TokenReceiptHandler is
    Initializable,
    UUPSUpgradeable,
    AccessProtectedUpgradable
{
    using AddressUpgradeable for address;

    /// @notice The mapping of token to receipt contract
    mapping(address => ITokenReceiptable) internal tokenReceiptables;

    /// @notice This event will be emitted when token receipt was setup
    /// @param originalToken Address of the original token
    /// @param receiptToken Address of the token receipt
    event SetupTokenReceipt(address originalToken, address receiptToken);

    /// @notice This event will be emitted when receipt is created.
    /// @param user The user who own the receipt.
    /// @param originalToken The original token address
    /// @param receiptToken The receipt token address
    /// @param tokenId The token id of the receipt.
    /// @param amount The amount of the receipt.
    event CreateReceipt(
        address indexed user,
        address originalToken,
        address receiptToken,
        uint256 tokenId,
        uint256 amount
    );

    /// @notice This event will be emitted when receipt is burnt.
    /// @param user The user who own the receipt.
    /// @param originalToken The original token address
    /// @param receiptToken The receipt token address
    /// @param tokenId The token id of the receipt.
    /// @param amount The amount of the receipt.
    event BurnReceipt(
        address indexed user,
        address originalToken,
        address receiptToken,
        uint256 tokenId,
        uint256 amount
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @dev Initialize the contract
    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    /// @dev Required by UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /// @notice Setup token receipt
    /// @param _originalToken Address of the original token
    /// @param _receiptToken Address of the token receipt
    function setupTokenReceipt(address _originalToken, address _receiptToken)
        external
        onlyAdmin
    {
        require(
            _originalToken.isContract() && _receiptToken.isContract(),
            "Token must be a contract"
        );

        ITokenReceiptable tokenReceiptable = ITokenReceiptable(_receiptToken);
        require(
            tokenReceiptable.originalToken() == _originalToken,
            "ITokenReceiptable should be came from same original token"
        );

        tokenReceiptables[_originalToken] = tokenReceiptable;

        emit SetupTokenReceipt(_originalToken, _receiptToken);
    }

    /// @notice Create receipts as a proof for assets when stakeholder want to stake some assets
    /// @param _stakeholder The user who stake the asset
    /// @param _assetAddress The address of the asset
    /// @param _tokenIds The token id of the asset
    /// @param _amounts The amount of the asset
    function createReceipts(
        address _stakeholder,
        address _assetAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    ) external onlyAdmin {
        require(
            address(tokenReceiptables[_assetAddress]) != address(0),
            "Token receipt is not setup"
        );

        require(
            _tokenIds.length == _amounts.length && _tokenIds.length > 0,
            "tokenIds and amounts should be same length and greater than 0"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            emit CreateReceipt(
                _stakeholder,
                _assetAddress,
                address(tokenReceiptables[_assetAddress]),
                _tokenIds[i],
                _amounts[i]
            );

            tokenReceiptables[_assetAddress].mintForReceipt(
                _stakeholder,
                _tokenIds[i],
                _amounts[i]
            );
        }
    }

    /// @notice Burn receipts as a proof for assets when stakeholder want to unstake some assets
    /// @param _stakeholder The user who stake the asset
    /// @param _assetAddress The address of the asset
    /// @param _tokenIds The token id of the asset
    /// @param _amounts The amount of the asset
    function burnReceipts(
        address _stakeholder,
        address _assetAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    ) external onlyAdmin {
        require(
            address(tokenReceiptables[_assetAddress]) != address(0),
            "Token receipt is not setup"
        );

        require(
            _tokenIds.length == _amounts.length && _tokenIds.length > 0,
            "tokenIds and amounts should be same length and greater than 0"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            emit BurnReceipt(
                _stakeholder,
                _assetAddress,
                address(tokenReceiptables[_assetAddress]),
                _tokenIds[i],
                _amounts[i]
            );

            tokenReceiptables[_assetAddress].burnForReceipt(
                _stakeholder,
                _tokenIds[i],
                _amounts[i]
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract StarMeta {
    enum GodiverseSlot {
        Sun,
        AsteroidBelt,
        KuiperBelt,
        Comet,
        Supernova
    }

    enum OrbitalTrackState {
        Empty,
        Listing,
        Renting
    }

    struct GodiverseInfo {
        uint256 tierRequire;
        uint256 agingBuff; // 1.5 buff will set to 150 (just * 100 to the origin value)
        uint256 additionalOrbitalTrack;
    }

    struct StarOrbitalTrackInviteListData {
        uint256 inviteGroupId;
        address[] inviteAddressList;
        uint256 maxCountForEachAddress; // each address can attach how many planet, if 0 = cancel
    }

    struct StarOrbitalTrackData {
        OrbitalTrackState rentingState;
        // status = Listing
        uint256 availableTrackTime;
        uint256 inviteGroupId; // 0 is open
        uint256 rentalFee;
        uint256 rentalDuration; // days
        bool canBeRenew;
        // status = Renting
        address planetOwnerAddress;
        uint256 rentalStartTime;
        uint256 attachedPlanetId;
        uint256 rentalEndTime; // if 0 and renting, = Orbiting own planet
        uint256 rentalFeeAfterPlatform;
    }

    // this data is saved when
    // the old rental data when renew rental ||
    // the StarOrbitalTrackData updated
    struct StarOrbitalTrackRentedData {
        uint256 slotIndex;
        uint256 planetId;
        uint256 rentalFeeAfterPlatform;
        uint256 oldRentalEndTime; // the old rental end time
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract AccessProtectedUpgradable is OwnableUpgradeable {
    mapping(address => bool) internal _admins; // user address => admin? mapping

    event AdminAccessSet(address _admin, bool _enabled);

    /**
     * @notice Set Admin Access
     *
     * @param admin - Address of Admin
     * @param enabled - Enable/Disable Admin Access
     */
    function setAdmin(address admin, bool enabled) external onlyOwner {
        _admins[admin] = enabled;
        emit AdminAccessSet(admin, enabled);
    }

    /**
     * @notice Check Admin Access
     *
     * @param admin - Address of Admin
     * @return whether user has admin access
     */
    function isAdmin(address admin) public view returns (bool) {
        return _admins[admin];
    }

    /**
     * Throws if called by any account other than the Admin.
     */
    modifier onlyAdmin() {
        require(
            _admins[_msgSender()] || _msgSender() == owner(),
            "Caller does not have Admin Access"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Interface for Receipt Token
/// @notice This interface is used to extend for Receipt Token
interface ITokenReceiptable {
    /// @dev The address of the original token
    /// @return The address of the original token
    function originalToken() external view returns (address);

    /// @dev Mint function for TokenReceiptHandler
    /// @param receiptTo Create receipt for this address
    /// @param tokenId The token id for receipt
    /// @param amount The amount of tokens for receipt
    function mintForReceipt(
        address receiptTo,
        uint256 tokenId,
        uint256 amount
    ) external;

    /// @dev Burn function for TokenReceiptHandler
    /// @param receiptFrom Burn receipt for this address
    /// @param tokenId The token id for receipt
    /// @param amount The amount of tokens for receipt
    function burnForReceipt(
        address receiptFrom,
        uint256 tokenId,
        uint256 amount
    ) external;
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