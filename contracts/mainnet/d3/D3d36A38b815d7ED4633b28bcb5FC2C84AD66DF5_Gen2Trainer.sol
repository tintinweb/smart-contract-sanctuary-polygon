//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./AccessControl.sol";
import "./ECDSA.sol";
import "./SafeERC20.sol";
import "./IGen2Minter.sol";
import "./IERC721NFT.sol";
import "./IERC1155NFT.sol";

/**
 * @title GFC_Gen2Trainer
 * @author thedev_dave
 * @notice Galaxy Fight Club Generation 2 Training Contract
 */
contract Gen2Trainer is IGen2Minter, AccessControl, Ownable {
    using SafeERC20 for IERC20;

    bytes32 public constant NFT_VALIDATOR_ROLE = keccak256("NFT_VALIDATOR_ROLE");

    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 public immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    address public immutable gen2Fighter;
    address public immutable genesisWeapon;
    address public immutable mysteryItem;

    bytes32 public immutable MINT_TYPEHASH = keccak256("MintInfo(uint256 Gen1TokenId, address trainer, uint256 deadline)");
    
    //ERC20 basic token contract being held
    IERC20 public immutable GCOIN;

    //The amount of GCOIN cost to train Gen 2
    uint256 public trainingCost = 800 ether;

    //In case we need to pause training
    bool public paused;

    //Mapping to store the last training time of Gen1Fighters
    mapping(uint256 => uint256) public gen1LastTrainedTimestamp;

    //Amount of time in days that Gen1Fighters is allowed to train again 
    uint256 public trainingCooldown = 5;

    uint constant vialTokenId = 2;

    constructor(address _gen2Fighter, address _genesisWeapon, address _mysteryItem, IERC20 token, string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(
            typeHash,
            hashedName,
            hashedVersion
        );
        gen2Fighter = _gen2Fighter;
        genesisWeapon = _genesisWeapon;
        mysteryItem = _mysteryItem;
        GCOIN = token;
    }

    function setMinter(address minter) external override onlyOwner {
        _setupRole(NFT_VALIDATOR_ROLE, minter);
    }

    function trainGFCGen2(
        uint256 gen1TokenId,
        uint256[] calldata weaponIds,
        uint256 deadline,
        bool usedVial,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(!paused, "The contract have been paused");
        require(block.timestamp <= deadline, "Mint: expire deadline");
        require(gen1AvailableToTrain(gen1TokenId), "Mint: Gen 1 on cooldown");
        require(weaponIds.length == 4, "Mint: invalid amount of weapons");
        _checkWeapons(weaponIds);
        bytes32 structHash = _buildStuctHash(gen1TokenId, msg.sender, deadline);
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        require(hasRole(NFT_VALIDATOR_ROLE, signer), "MINT: Invalid signature!");
        gen1LastTrainedTimestamp[gen1TokenId] = block.timestamp;
        _burnWeapons(weaponIds);
        _chargeGCOIN();

        //@dev call the Gen2 NFT contract to mint Gen2 fighter
        uint256 tokenId = IERC721NFT(gen2Fighter).mint(msg.sender);
        emit Gen2Minted(tokenId, gen1TokenId, weaponIds, false,  msg.sender);

        if(usedVial) {
            require(
                IERC1155NFT(mysteryItem).balanceOf(msg.sender, vialTokenId) >= 1,
                "You must have at least 1 Vial"
            );
            _burnVial();
            //@dev mint an extra Gen2 for users who used Vial
            tokenId = IERC721NFT(gen2Fighter).mint(msg.sender);
            emit Gen2Minted(tokenId, gen1TokenId, weaponIds, true, msg.sender);
        }
    }

    function _checkWeapons(uint256[] calldata weaponIds) internal {
        for(uint256 i = 0; i < weaponIds.length; i++) {
            require(
                IERC1155NFT(genesisWeapon).balanceOf(msg.sender, weaponIds[i]) >= 1,
                "You must have enough of that type of weapon"
            );
        }
    }

    function _burnWeapons(uint256[] calldata weaponIds) internal {
        for (uint256 i = 0; i < weaponIds.length; i++) {
            IERC1155NFT(genesisWeapon).burn(msg.sender, weaponIds[i], 1);
        }
    }

    function _burnVial() internal {
        IERC1155NFT(mysteryItem).burn(msg.sender, vialTokenId, 1);
    }

    function _chargeGCOIN() internal {
        //Charge user the GCOIN required from the forge
        IERC20(GCOIN).safeTransferFrom(msg.sender, address(this), trainingCost);
    }

    function gen1AvailableToTrain(uint256 tokenId) public view returns (bool) {
        return gen1LastTrainedTimestamp[tokenId] + trainingCooldown*86400 < block.timestamp;
    }

    function _buildStuctHash(uint256 gen1TokenId, address trainer, uint256 deadline) public view returns (bytes32) {
        return keccak256(
            abi.encode(
                MINT_TYPEHASH,
                gen1TokenId,
                trainer,
                deadline
            )
        );
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 nameHash, bytes32 versionHash) private view returns (bytes32) {
        return
        keccak256(
            abi.encode(
                typeHash,
                nameHash,
                versionHash,
                block.chainid,
                address(this)
            )
        );
    }

    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return
            _buildDomainSeparator(
                _TYPE_HASH,
                _HASHED_NAME,
                _HASHED_VERSION
            );
        }
    }

    function _hashTypedDataV4(bytes32 structHash) internal view returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    function setTrainingCost(uint256 _cost) external onlyOwner {
		trainingCost = _cost;
	}

    function setTrainingCooldown(uint256 _cooldown) external onlyOwner {
        trainingCooldown = _cooldown;
    }

    function togglePause() external onlyOwner {
        paused = !paused;
    }

    function withdrawGCOIN() external onlyOwner {
        IERC20(GCOIN).safeTransfer(msg.sender, IERC20(GCOIN).balanceOf(address(this)));
    }
}