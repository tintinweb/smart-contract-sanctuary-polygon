//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {OwnableImpl} from "../../libs/upgradeable/ownable/OwnableImpl.sol";
import {ERC721EnumerableImpl} from "../../libs/upgradeable/ERC721Enumerable/ERC721EnumerableImpl.sol";
import {PropertyStorage, Properties, HorsePropertyV1} from "../HorsePropertyV1.sol";
import {BreedingCalculatorV1} from "../BreedingCalculatorV1.sol";
import {IDerbyStarsBeacon} from "../../interfaces/IDerbyStarsBeacon.sol";
import {IDerbyStarsHorseV1} from "./IDerbyStarsHorseV1.sol";
import {IDerbyStarsSoulV1} from "../soul/IDerbyStarsSoulV1.sol";
import {IDerbyStarsDataV1} from "../data/IDerbyStarsDataV1.sol";
import {DerbyStarsHorseV1Storage} from "./DerbyStarsHorseV1Storage.sol";
import {VRFConsumer} from "../../vrf/VRFConsumer.sol";
import {IVRFConsumer} from "../../vrf/IVRFConsumer.sol";

contract DerbyStarsHorseV1Impl is
    ERC721EnumerableImpl,
    IDerbyStarsHorseV1,
    OwnableImpl
{
    IDerbyStarsSoulV1 public immutable dsSoul;
    IDerbyStarsDataV1 public immutable dsData;
    IVRFConsumer public immutable vrfConsumer;
    uint256 private constant NON_ORIGIN_OFFSET = 100_000;

    constructor(
        address dsSoul_,
        address dsData_,
        address vrfConsumer_
    ) OwnableImpl() {
        dsSoul = IDerbyStarsSoulV1(dsSoul_);
        dsData = IDerbyStarsDataV1(dsData_);
        vrfConsumer = IVRFConsumer(vrfConsumer_);
    }

    function getProperty(uint256 index)
        public
        view
        virtual
        override
        returns (Properties memory)
    {
        DerbyStarsHorseV1Storage.Slot storage s = DerbyStarsHorseV1Storage
            .load();
        return s.propertyStorage.properties[index];
    }

    function incrementMotherBreedingCount(uint256 tokenId)
        public
        virtual
        override
    {
        require(msg.sender == address(dsSoul));
        DerbyStarsHorseV1Storage.Slot storage s = DerbyStarsHorseV1Storage
            .load();
        s.propertyStorage.properties[tokenId].breed_count_mother += 1;
    }

    function incrementFatherBreedingCount(uint256 tokenId)
        public
        virtual
        override
    {
        require(msg.sender == address(dsSoul));
        DerbyStarsHorseV1Storage.Slot storage s = DerbyStarsHorseV1Storage
            .load();
        s.propertyStorage.properties[tokenId].father_breed_timestamp = block
            .timestamp;
        s.propertyStorage.properties[tokenId].breed_count_father += 1;
    }

    function adjustFatherBreedingCount(uint256 tokenId)
        public
        virtual
        override
    {
        require(msg.sender == address(dsSoul));
        DerbyStarsHorseV1Storage.Slot storage s = DerbyStarsHorseV1Storage
            .load();
        uint256 last = s
            .propertyStorage
            .properties[tokenId]
            .father_breed_timestamp;
        uint256 prev = s.propertyStorage.properties[tokenId].breed_count_father;
        uint256 d = (block.timestamp - last) / 1 days;
        if (d >= prev) {
            s.propertyStorage.properties[tokenId].breed_count_father = 0;
        } else {
            // this would not overflow
            s.propertyStorage.properties[tokenId].breed_count_father -= uint16(
                d
            );
        }
    }

    function mintOrigin(uint256 tokenId, address originOwner) public onlyOwner {
        require(tokenId <= 10_027 && tokenId > 0, "H1");
        require(!_exists(tokenId), "H2");
        _safeMint(originOwner, tokenId);
    }

    function mintNewOrigin(uint256 tokenId) public payable {
        require(tokenId > 10_027 && tokenId <= 100_000, "23");
        // TODO: implement sale mechanism
    }

    // TODO: Add a helper function to approve transferring soulTokenId token from msg.sender to burn address
    function mintSoul(uint256 soulTokenId) public {
        require(
            IERC721(address(dsSoul)).ownerOf(soulTokenId) == msg.sender,
            "H3"
        );
        require(
            IDerbyStarsSoulV1(address(dsSoul)).birthTimestamp(soulTokenId) +
                5 days <
                block.timestamp,
            "H4"
        );
        DerbyStarsHorseV1Storage.Slot storage s = DerbyStarsHorseV1Storage
            .load();
        // TODO: verify that soulTokenId is breedable
        IDerbyStarsSoulV1(address(dsSoul)).burn(soulTokenId);
        s.numOfnonOriginHorses += 1;
        uint256 id = s.numOfnonOriginHorses + NON_ORIGIN_OFFSET;
        s.propertyStorage.properties[id].id_mother = uint112(IDerbyStarsSoulV1(address(dsSoul))
            .motherTokenIds(soulTokenId));
        s.propertyStorage.properties[id].id_father = uint112(IDerbyStarsSoulV1(address(dsSoul))
            .fatherTokenIds(soulTokenId));
        _safeMint(msg.sender, id);
    }

    function setOriginProperties(
        uint256 tokenId,
        Properties memory tokenProperties_
    ) public onlyOwner {
        require(tokenId <= NON_ORIGIN_OFFSET, "H5");
        DerbyStarsHorseV1Storage.Slot storage s = DerbyStarsHorseV1Storage
            .load();
        s.propertyStorage.properties[tokenId] = tokenProperties_;
    }

    function setProperties(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender);
        require(tokenId > 100_000, "H6");

        uint256 latestRandomNumber = IVRFConsumer(address(vrfConsumer)).getLatestRandomNumber();
        DerbyStarsHorseV1Storage.Slot storage s = DerbyStarsHorseV1Storage
            .load();
        s.propertyStorage.properties[tokenId] = BreedingCalculatorV1
            .calculateProperties(
                s.propertyStorage.properties[s.propertyStorage.properties[tokenId].id_mother],
                s.propertyStorage.properties[s.propertyStorage.properties[tokenId].id_father],
                keccak256(abi.encodePacked(latestRandomNumber, tokenId)),
                dsData
            );
    }

    function name() public pure override returns (string memory) {
        return "DerbyStarsHorse";
    }

    function symbol() public pure override returns (string memory) {
        return "DSHORSE";
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return HorsePropertyV1.toMetadata(this, dsData, tokenId);
    }

    function getExtraKeys()
        public
        view
        override
        returns (string[] memory keys)
    {
        return DerbyStarsHorseV1Storage.load().propertyStorage.addPropKeys;
    }

    function getExtraProp(uint256 tokenId, bytes32 key)
        public
        view
        override
        returns (string memory)
    {
        return
            DerbyStarsHorseV1Storage.load().propertyStorage.addPropVal[tokenId][
                key
            ];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "./OwnableStorage.sol";

abstract contract OwnableImpl is Context {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize() public {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        OwnableStorage.Slot storage s = OwnableStorage.load();
        return s.owner;
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        OwnableStorage.Slot storage s = OwnableStorage.load();
        address oldOwner = s.owner;
        s.owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721/ERC721Impl.sol";
import "./ERC721EnumerableStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableImpl is ERC721Impl, IERC721Enumerable {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721Impl)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        ERC721EnumerableStorage.Slot storage s = ERC721EnumerableStorage.load();
        return s.ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        ERC721EnumerableStorage.Slot storage s = ERC721EnumerableStorage.load();
        return s.allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        ERC721EnumerableStorage.Slot storage s = ERC721EnumerableStorage.load();
        return s.allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

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
        uint256 length = balanceOf(to);
        ERC721EnumerableStorage.Slot storage s = ERC721EnumerableStorage.load();
        s.ownedTokens[to][length] = tokenId;
        s.ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        ERC721EnumerableStorage.Slot storage s = ERC721EnumerableStorage.load();
        s.allTokensIndex[tokenId] = s.allTokens.length;
        s.allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        ERC721EnumerableStorage.Slot storage s = ERC721EnumerableStorage.load();
        uint256 lastTokenIndex = balanceOf(from) - 1;
        uint256 tokenIndex = s.ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = s.ownedTokens[from][lastTokenIndex];

            s.ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            s.ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete s.ownedTokensIndex[tokenId];
        delete s.ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        ERC721EnumerableStorage.Slot storage s = ERC721EnumerableStorage.load();
        uint256 lastTokenIndex = s.allTokens.length - 1;
        uint256 tokenIndex = s.allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = s.allTokens[lastTokenIndex];

        s.allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        s.allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete s.allTokensIndex[tokenId];
        s.allTokens.pop();
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
pragma abicoder v2;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IDerbyStarsDataV1} from "./data/IDerbyStarsDataV1.sol";
import {IDerbyStarsHorseV1} from "./horse/IDerbyStarsHorseV1.sol";

struct DefaultTrait {
    uint8 origin;
    uint8 rarity;
    uint8 talent_rr;
    uint8 talent_fr;
    uint8 talent_st;
    uint8 talent_sr;
    uint8 stat_spd;
    uint8 stat_stm;
    uint8 stat_pow;
    uint8 stat_grt;
    uint8 stat_int;
    uint8 track_perf_turf;
    uint8 track_perf_dirt;
    uint24 skill1;
    uint24 skill2;
    uint24 skill3;
    uint24 skill4;
    uint24 skill5;
    uint24 skill6;
}

struct TrainedTrait {
    uint8 stat_spd;
    uint8 stat_stm;
    uint8 stat_pow;
    uint8 stat_grt;
    uint8 stat_int;
}

struct BodyPartsFirst {
    uint24 torso_id;
    uint8 torso_colorgroup;
    uint16 torso_colorid;
    uint8 torso_rarity;
    uint24 eyes_id;
    uint8 eyes_colorgroup;
    uint16 eyes_colorid;
    uint8 eyes_rarity;
    uint24 mane_id;
    uint8 mane_colorgroup;
    uint16 mane_colorid;
    uint8 mane_rarity;
    uint24 horn_id;
    uint8 horn_colorgroup;
    uint16 horn_colorid;
    uint8 horn_rarity;
    uint24 legs_id;
}

struct BodyPartsSecond {
    uint8 legs_colorgroup;
    uint16 legs_colorid;
    uint8 legs_rarity;
    uint24 muzzle_id;
    uint8 muzzle_colorgroup;
    uint16 muzzle_colorid;
    uint8 muzzle_rarity;
    uint24 rein_id;
    uint8 rein_colorgroup;
    uint16 rein_colorid;
    uint8 rein_rarity;
    uint24 tail_id;
    uint8 tail_colorgroup;
    uint16 tail_colorid;
    uint8 tail_rarity;
    uint24 wings_id;
    uint8 wings_colorgroup;
    uint16 wings_colorid;
    uint8 wings_rarity;
}

struct Properties {
    uint112 id_mother;
    uint112 id_father;
    uint16 breed_count_mother;
    uint16 breed_count_father;
    uint256 father_breed_timestamp;
    DefaultTrait dtrait;
    TrainedTrait ttrait;
    BodyPartsFirst bpf;
    BodyPartsSecond bps;
}

struct PropertyStorage {
    mapping(uint256 => Properties) properties;
    string[] addPropKeys;
    mapping(uint256 => mapping(bytes32 => string)) addPropVal;
}

library HorsePropertyV1 {
    function toMetadata(
        IDerbyStarsHorseV1 dsHorse,
        IDerbyStarsDataV1 dsData,
        uint256 id_
    ) external view returns (string memory) {
        Properties memory prop = dsHorse.getProperty(id_);
        bytes memory metadata = abi.encodePacked(
            'data:application/json;utf8,{"name":"Horse #',
            Strings.toString(id_),
            '","external_url":"',
            "someurl",
            '","description":"',
            "",
            '","attributes":['
        );

        {
            metadata = abi.encodePacked(
                metadata,
                '{"trait_type":"breed count as mother","value":',
                Strings.toString(prop.breed_count_mother),
                "},",
                '{"trait_type":"breed count as father","value":',
                Strings.toString(prop.breed_count_father),
                "},",
                '{"trait_type":"mother id","value":',
                Strings.toString(prop.id_mother),
                "},",
                '{"trait_type":"father id","value":',
                Strings.toString(prop.id_father),
                "},"
            );
        }

        {
            metadata = abi.encodePacked(
                metadata,
                '{"trait_type":"origin","value":"',
                Strings.toString(prop.dtrait.origin),
                '"},',
                '{"trait_type":"rarity","value":"',
                Strings.toString(prop.dtrait.rarity),
                '"},',
                '{"trait_type":"speed","value":',
                Strings.toString(prop.dtrait.stat_spd),
                "},",
                '{"trait_type":"stamina","value":',
                Strings.toString(prop.dtrait.stat_stm),
                "},",
                '{"trait_type":"power","value":',
                Strings.toString(prop.dtrait.stat_pow),
                "},",
                '{"trait_type":"grit","value":',
                Strings.toString(prop.dtrait.stat_grt),
                "},"
            );
        }

        {
            metadata = abi.encodePacked(
                metadata,
                '{"trait_type":"intellect","value":',
                Strings.toString(prop.dtrait.stat_int),
                "},", // TODO : prop name
                '{"trait_type":"torso","value":"',
                Strings.toString(prop.bpf.torso_id),
                '"},',
                '{"trait_type":"eyes","value":"',
                Strings.toString(prop.bpf.eyes_id),
                '"},',
                '{"trait_type":"mane","value":"',
                Strings.toString(prop.bpf.mane_id),
                '"},',
                '{"trait_type":"horn","value":"',
                Strings.toString(prop.bpf.horn_id),
                '"},'
            );
        }

        {
            metadata = abi.encodePacked(
                metadata,
                '{"trait_type":"legs","value":"',
                Strings.toString(prop.bpf.legs_id),
                '"},',
                '{"trait_type":"muzzle","value":"',
                Strings.toString(prop.bps.muzzle_id),
                '"},',
                '{"trait_type":"rein","value":"',
                Strings.toString(prop.bps.rein_id),
                '"},',
                '{"trait_type":"tail","value":"',
                Strings.toString(prop.bps.tail_id),
                '"},',
                '{"trait_type":"wings","value":"',
                Strings.toString(prop.bps.wings_id),
                '"},'
            );
        }

        {
            metadata = abi.encodePacked(
                metadata,
                '{"trait_type":"skill 1","value":"',
                Strings.toString(prop.dtrait.skill1),
                '"},',
                '{"trait_type":"skill 2","value":"',
                Strings.toString(prop.dtrait.skill2),
                '"},',
                '{"trait_type":"skill 3","value":"',
                Strings.toString(prop.dtrait.skill3),
                '"},',
                '{"trait_type":"skill 4","value":"',
                Strings.toString(prop.dtrait.skill4),
                '"},',
                '{"trait_type":"skill 5","value":"',
                Strings.toString(prop.dtrait.skill5),
                '"},'
            );
        }

        {
            metadata = abi.encodePacked(
                metadata,
                '{"trait_type":"skill 6","value":"',
                Strings.toString(prop.dtrait.skill6),
                '"},',
                '{"trait_type":"Talent:RunawayRunner","value":"',
                Strings.toString(prop.dtrait.talent_rr),
                '"},',
                '{"trait_type":"Talent:FrontRunner","value":"',
                Strings.toString(prop.dtrait.talent_fr),
                '"},',
                '{"trait_type":"Talent:Stalker","value":"',
                Strings.toString(prop.dtrait.talent_st),
                '"},',
                '{"trait_type":"Talent:StretchRunner","value":"',
                Strings.toString(prop.dtrait.talent_sr),
                '"},'
            );
        }

        {
            metadata = abi.encodePacked(
                metadata,
                '{"trait_type":"Track:Turf","value":"',
                Strings.toString(prop.dtrait.track_perf_turf),
                '"},',
                '{"trait_type":"Track:Dirt","value":"',
                Strings.toString(prop.dtrait.track_perf_dirt),
                '"},',
                '{"trait_type":"torso_color","value":"',
                dsData.getColor(
                    prop.bpf.torso_colorgroup,
                    prop.bpf.torso_colorid
                ),
                '"},'
            );
        }

        {
            metadata = abi.encodePacked(
                metadata,
                '{"trait_type":"eyes_color","value":"',
                dsData.getColor(
                    prop.bpf.eyes_colorgroup,
                    prop.bpf.eyes_colorid
                ),
                '"},',
                '{"trait_type":"mane_color","value":"',
                dsData.getColor(
                    prop.bpf.mane_colorgroup,
                    prop.bpf.mane_colorid
                ),
                '"},',
                '{"trait_type":"horn_color","value":"',
                dsData.getColor(
                    prop.bpf.horn_colorgroup,
                    prop.bpf.horn_colorid
                ),
                '"},',
                '{"trait_type":"legs_color","value":"',
                dsData.getColor(
                    prop.bps.legs_colorgroup,
                    prop.bps.legs_colorid
                ),
                '"},'
            );
        }

        {
            metadata = abi.encodePacked(
                metadata,
                '{"trait_type":"muzzle_color","value":"',
                dsData.getColor(
                    prop.bps.muzzle_colorgroup,
                    prop.bps.muzzle_colorid
                ),
                '"},',
                '{"trait_type":"rein_color","value":"',
                dsData.getColor(
                    prop.bps.rein_colorgroup,
                    prop.bps.rein_colorid
                ),
                '"},',
                '{"trait_type":"tail_color","value":"',
                dsData.getColor(
                    prop.bps.tail_colorgroup,
                    prop.bps.tail_colorid
                ),
                '"},',
                '{"trait_type":"wings_color","value":"',
                dsData.getColor(
                    prop.bps.wings_colorgroup,
                    prop.bps.wings_colorid
                ),
                '"}'
            );
        }

        string[] memory extraKeys = dsHorse.getExtraKeys();
        for (uint256 i = 0; i < extraKeys.length; i += 1) {
            string memory key = extraKeys[i];
            // TODO : if addPropVal[i][keccak256(abi.encodePacked(key))] not exists?
            metadata = abi.encodePacked(
                metadata,
                ',{"trait_type":"',
                key,
                '","value":"',
                dsHorse.getExtraProp(id_, keccak256(abi.encodePacked(key))),
                '"}'
            );
            // changed
            // - addPropVal[i][keccak256(abi.encodePacked(key))]
            // + addPropVal[id_][keccak256(abi.encodePacked(key))]
            // by @drkeccak
        }

        // TODO : imgae
        metadata = abi.encodePacked(
            metadata,
            '],"image":"',
            //externalImgUri,
            '"}'
        );

        return string(metadata);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "hardhat/console.sol";
import "./HorsePropertyV1.sol";
import "./data/IDerbyStarsDataV1.sol";

library BreedingCalculatorV1 {
    enum FeeType {
        RARITY,
        TALENT,
        SPECIAL_SKILL,
        NORMAL_SKILL
    }

    enum StatType {
        SPEED,
        STAMINA,
        POWER,
        GRIT,
        INTELLECT
    }

    enum BodyPartTypes {
        TORSO,
        EYES,
        MANE,
        HORN,
        LEGS,
        MUZZLE,
        TAIL,
        WINGS,
        REIN
    }

    struct Distribution {
        uint16 range0;
        uint16 range1;
        uint16 range2;
        uint16 range3;
        uint16 range4;
        uint16 range5;
        uint16 range6;
    }

    struct Skill {
        uint256 id;
        uint256 tier;
    }

    struct Color {
        uint8 group;
        uint16 id;
    }

    struct Stat {
        StatType statType;
        uint256 parentSum;
        uint256 newValue;
    }

    struct BodyPartPair {
        BodyPartTypes bodyPartType;
        uint8 weight;
        uint8 chosen;
    }

    // Packing to avoid stack too deep error
    struct MutantSkill {
        uint8 index1;
        uint8 index2;
        uint8 count;
    }

    function calculateBreedingFee(
        Properties memory father,
        IDerbyStarsDataV1 dsData
    ) public view returns (uint256) {
        uint256 fee = 130 * 1e18;
        uint256 add_fee = 0;
        {
            uint256 rarity = father.dtrait.rarity;
            add_fee += dsData.getBreedingFee(uint256(FeeType.RARITY), rarity);
        }
        {
            add_fee += dsData.getBreedingFee(
                uint256(FeeType.TALENT),
                father.dtrait.talent_rr
            );
            add_fee += dsData.getBreedingFee(
                uint256(FeeType.TALENT),
                father.dtrait.talent_fr
            );
            add_fee += dsData.getBreedingFee(
                uint256(FeeType.TALENT),
                father.dtrait.talent_st
            );
            add_fee += dsData.getBreedingFee(
                uint256(FeeType.TALENT),
                father.dtrait.talent_sr
            );
        }
        {
            uint256 special_rank = dsData.getSpecialSkillTier(
                father.dtrait.skill1
            );
            add_fee += dsData.getBreedingFee(
                uint256(FeeType.SPECIAL_SKILL),
                special_rank
            );
        }
        {
            uint256 tiersum = dsData.getNormalSkillTier(father.dtrait.skill2) +
                dsData.getNormalSkillTier(father.dtrait.skill3) +
                dsData.getNormalSkillTier(father.dtrait.skill4) +
                dsData.getNormalSkillTier(father.dtrait.skill5) +
                dsData.getNormalSkillTier(father.dtrait.skill6);
            // XXX : integer division
            add_fee += dsData.getBreedingFee(
                uint256(FeeType.NORMAL_SKILL),
                tiersum / 5
            );
        }

        uint256 bc = father.breed_count_father;
        if (bc == 0) {
            return fee + add_fee * 1e18;
        } else {
            //(기본 보상금 * (교배 횟수 * 교배 횟수 가중치) * 교배 횟수)
            // TODO : rounding
            uint256 lhs = fee * ((bc * 3) / 10) * bc;
            //(추가 비용 합산 + (추가 비용 합산 * (교배 횟수 * 교배 횟수 가중치) * 교배 횟수)
            add_fee = add_fee * 1e18;
            uint256 rhs = add_fee + (add_fee * ((bc * 3) / 10) * bc);
            return fee + lhs + rhs;
        }
    }

    function calculateProperties(
        Properties memory mother,
        Properties memory father,
        bytes32 randomSeed,
        IDerbyStarsDataV1 dsData
    ) public view returns (Properties memory properties) {
        uint256 nonce = 0;
        bool rare = calculateRareness(
            mother.dtrait.rarity + father.dtrait.rarity,
            randomSeed,
            nonce
        );
        nonce += 1;
        console.log("rare: ", rare);

        if (rare) {
            nonce = calculateAndUpdateRarity(
                properties,
                mother.dtrait.rarity + father.dtrait.rarity,
                randomSeed,
                nonce
            );

            nonce = calculateAndUpdateRareBodyParts(
                properties,
                properties.dtrait.rarity,
                randomSeed,
                nonce,
                dsData
            );
        }

        nonce = calculateAndUpdateCommonBodyParts(
            mother,
            father,
            properties,
            randomSeed,
            nonce,
            dsData
        );
        nonce = calculateAndUpdateTalents(
            mother,
            father,
            properties,
            randomSeed,
            nonce
        );
        nonce = calculateAndUpdateStats(
            mother,
            father,
            properties,
            randomSeed,
            nonce
        );
        nonce = calculateAndUpdateSkills(
            mother,
            father,
            properties,
            randomSeed,
            nonce,
            dsData
        );
        nonce = calculateAndUpdateTrackPref(
            mother,
            father,
            properties,
            randomSeed,
            nonce
        );
        nonce = calculateAndUpdateColor(
            mother,
            father,
            properties,
            randomSeed,
            nonce,
            dsData
        );

        return properties;
    }

    function calculateRareness(
        uint256 combinedRarity,
        bytes32 randomSeed,
        uint256 nonce
    ) internal pure returns (bool) {
        bool rare = false;
        uint256 rn = getRN(randomSeed, nonce);
        if (combinedRarity == 0) {
            if (rn % 100 < 3) rare = true;
        } else if (combinedRarity == 1) {
            if (rn % 10000 < 315) rare = true;
        } else if (combinedRarity == 2) {
            if (rn % 1000 < 33) rare = true;
        } else if (combinedRarity == 3) {
            if (rn % 10000 < 345) rare = true;
        } else if (combinedRarity == 4) {
            if (rn % 1000 < 36) rare = true;
        } else if (combinedRarity == 5) {
            if (rn % 10000 < 375) rare = true;
        } else if (combinedRarity == 6) {
            if (rn % 1000 < 39) rare = true;
        } else if (combinedRarity == 7) {
            if (rn % 10000 < 405) rare = true;
        } else if (combinedRarity == 8) {
            if (rn % 1000 < 42) rare = true;
        } else if (combinedRarity == 9) {
            if (rn % 10000 < 435) rare = true;
        } else if (combinedRarity == 10) {
            if (rn % 1000 < 45) rare = true;
        } else if (combinedRarity == 11) {
            if (rn % 10000 < 465) rare = true;
        } else if (combinedRarity == 12) {
            if (rn % 1000 < 48) rare = true;
        } else if (combinedRarity == 13) {
            if (rn % 10000 < 495) rare = true;
        } else if (combinedRarity == 14) {
            if (rn % 1000 < 51) rare = true;
        } else if (combinedRarity == 15) {
            if (rn % 10000 < 525) rare = true;
        } else if (combinedRarity == 16) {
            if (rn % 1000 < 54) rare = true;
        } else if (combinedRarity == 17) {
            if (rn % 10000 < 555) rare = true;
        } else if (combinedRarity == 18) {
            if (rn % 1000 < 57) rare = true;
        }
        return rare;
    }

    function calculateAndUpdateRarity(
        Properties memory properties,
        uint256 combinedRarity,
        bytes32 randomSeed,
        uint256 nonce
    ) internal view returns (uint256) {
        uint256 remainder = getRN(randomSeed, nonce) % 1000;
        console.log("remainder: ", remainder);
        uint256 rarity;
        if (combinedRarity == 0) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(0, 0, 0, 0, 0, 20, 68)
            );
        } else if (combinedRarity == 1) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(0, 0, 0, 0, 0, 21, 70)
            );
        } else if (combinedRarity == 2) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(0, 0, 1, 2, 3, 25, 76)
            );
        } else if (combinedRarity == 3) {
            return
                getRarityValuesFromRanges(
                    remainder,
                    Distribution(0, 1, 2, 4, 7, 32, 86)
                );
        } else if (combinedRarity == 4) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(1, 3, 5, 8, 13, 41, 100)
            );
        } else if (combinedRarity == 5) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(1, 3, 7, 12, 19, 50, 114)
            );
        } else if (combinedRarity == 6) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(1, 4, 9, 15, 24, 60, 130)
            );
        } else if (combinedRarity == 7) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(2, 6, 13, 21, 34, 75, 152)
            );
        } else if (combinedRarity == 8) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(2, 7, 16, 27, 43, 90, 176)
            );
        } else if (combinedRarity == 9) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(3, 10, 21, 35, 55, 109, 204)
            );
        } else if (combinedRarity == 10) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(3, 11, 24, 41, 66, 127, 233)
            );
        } else if (combinedRarity == 11) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(4, 14, 30, 50, 80, 150, 267)
            );
        } else if (combinedRarity == 12) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(5, 17, 36, 59, 94, 173, 303)
            );
        } else if (combinedRarity == 13) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(5, 19, 41, 68, 109, 197, 341)
            );
        } else if (combinedRarity == 14) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(6, 22, 47, 79, 126, 225, 383)
            );
        } else if (combinedRarity == 15) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(7, 25, 54, 90, 144, 254, 428)
            );
        } else if (combinedRarity == 16) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(8, 28, 61, 102, 163, 285, 476)
            );
        } else if (combinedRarity == 17) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(9, 32, 69, 115, 184, 319, 528)
            );
        } else {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(10, 36, 77, 128, 205, 353, 581)
            );
        }
        properties.dtrait.rarity = uint8(rarity);
        return nonce + 1;
    }

    function calculateAndUpdateRareBodyParts(
        Properties memory properties,
        uint256 rarity,
        bytes32 randomSeed,
        uint256 nonce,
        IDerbyStarsDataV1 dsData
    ) internal view returns (uint256) {
        if (rarity == 8) {
            properties.bpf.torso_id = uint24(
                getRandomBodyPart(
                    BodyPartTypes.TORSO,
                    1,
                    randomSeed,
                    nonce,
                    dsData
                )
            );
            properties.bpf.torso_rarity = 1;
            properties.bpf.eyes_id = uint24(
                getRandomBodyPart(
                    BodyPartTypes.EYES,
                    1,
                    randomSeed,
                    nonce + 1,
                    dsData
                )
            );
            properties.bpf.eyes_rarity = 1;
            properties.bpf.mane_id = uint24(
                getRandomBodyPart(
                    BodyPartTypes.MANE,
                    1,
                    randomSeed,
                    nonce + 2,
                    dsData
                )
            );
            properties.bpf.mane_rarity = 1;
            properties.bpf.horn_id = uint24(
                getRandomBodyPart(
                    BodyPartTypes.HORN,
                    1,
                    randomSeed,
                    nonce + 3,
                    dsData
                )
            );
            properties.bpf.horn_rarity = 1;
            properties.bpf.legs_id = uint24(
                getRandomBodyPart(
                    BodyPartTypes.LEGS,
                    1,
                    randomSeed,
                    nonce + 4,
                    dsData
                )
            );
            properties.bps.legs_rarity = 1;
            properties.bps.muzzle_id = uint24(
                getRandomBodyPart(
                    BodyPartTypes.MUZZLE,
                    1,
                    randomSeed,
                    nonce + 5,
                    dsData
                )
            );
            properties.bps.muzzle_rarity = 1;
            properties.bps.tail_id = uint24(
                getRandomBodyPart(
                    BodyPartTypes.TAIL,
                    1,
                    randomSeed,
                    nonce + 6,
                    dsData
                )
            );
            properties.bps.tail_rarity = 1;
            properties.bps.wings_id = uint24(
                getRandomBodyPart(
                    BodyPartTypes.WINGS,
                    1,
                    randomSeed,
                    nonce + 7,
                    dsData
                )
            );
            properties.bps.wings_rarity = 1;
            return nonce + 8;
        }

        BodyPartPair[8] memory bodyPartPairs = [
            BodyPartPair(BodyPartTypes.MUZZLE, 20, 0),
            BodyPartPair(BodyPartTypes.EYES, 5, 0),
            BodyPartPair(BodyPartTypes.MANE, 12, 0),
            BodyPartPair(BodyPartTypes.TORSO, 20, 0),
            BodyPartPair(BodyPartTypes.LEGS, 20, 0),
            BodyPartPair(BodyPartTypes.TAIL, 10, 0),
            BodyPartPair(BodyPartTypes.HORN, 8, 0),
            BodyPartPair(BodyPartTypes.WINGS, 5, 0)
        ];

        for (uint256 i = 0; i < rarity; i++) {
            setRandomRareBodyPartBasedOnWeight(
                bodyPartPairs,
                getRN(randomSeed, nonce + i)
            );
        }
        nonce += rarity;

        for (uint256 i = 0; i < 8; i++) {
            if (bodyPartPairs[i].chosen == 0) {
                continue;
            }

            if (bodyPartPairs[i].bodyPartType == BodyPartTypes.TORSO) {
                properties.bpf.torso_id = uint24(
                    getRandomBodyPart(
                        bodyPartPairs[i].bodyPartType,
                        1,
                        randomSeed,
                        nonce,
                        dsData
                    )
                );
                nonce += 1;
                properties.bpf.torso_rarity = 1;
            } else if (bodyPartPairs[i].bodyPartType == BodyPartTypes.EYES) {
                properties.bpf.eyes_id = uint24(
                    getRandomBodyPart(
                        bodyPartPairs[i].bodyPartType,
                        1,
                        randomSeed,
                        nonce,
                        dsData
                    )
                );
                nonce += 1;
                properties.bpf.eyes_rarity = 1;
            } else if (bodyPartPairs[i].bodyPartType == BodyPartTypes.MANE) {
                properties.bpf.mane_id = uint24(
                    getRandomBodyPart(
                        bodyPartPairs[i].bodyPartType,
                        1,
                        randomSeed,
                        nonce,
                        dsData
                    )
                );
                nonce += 1;
                properties.bpf.mane_rarity = 1;
            } else if (bodyPartPairs[i].bodyPartType == BodyPartTypes.HORN) {
                properties.bpf.horn_id = uint24(
                    getRandomBodyPart(
                        bodyPartPairs[i].bodyPartType,
                        1,
                        randomSeed,
                        nonce,
                        dsData
                    )
                );
                nonce += 1;
                properties.bpf.horn_rarity = 1;
            } else if (bodyPartPairs[i].bodyPartType == BodyPartTypes.LEGS) {
                properties.bpf.legs_id = uint24(
                    getRandomBodyPart(
                        bodyPartPairs[i].bodyPartType,
                        1,
                        randomSeed,
                        nonce,
                        dsData
                    )
                );
                nonce += 1;
                properties.bps.legs_rarity = 1;
            } else if (bodyPartPairs[i].bodyPartType == BodyPartTypes.MUZZLE) {
                properties.bps.muzzle_id = uint24(
                    getRandomBodyPart(
                        bodyPartPairs[i].bodyPartType,
                        1,
                        randomSeed,
                        nonce,
                        dsData
                    )
                );
                nonce += 1;
                properties.bps.muzzle_rarity = 1;
            } else if (bodyPartPairs[i].bodyPartType == BodyPartTypes.TAIL) {
                properties.bps.tail_id = uint24(
                    getRandomBodyPart(
                        bodyPartPairs[i].bodyPartType,
                        1,
                        randomSeed,
                        nonce,
                        dsData
                    )
                );
                nonce += 1;
                properties.bps.tail_rarity = 1;
            } else if (bodyPartPairs[i].bodyPartType == BodyPartTypes.WINGS) {
                properties.bps.wings_id = uint24(
                    getRandomBodyPart(
                        bodyPartPairs[i].bodyPartType,
                        1,
                        randomSeed,
                        nonce,
                        dsData
                    )
                );
                nonce += 1;
                properties.bps.wings_rarity = 1;
            }
        }
        return nonce;
    }

    function calculateAndUpdateCommonBodyParts(
        Properties memory mother,
        Properties memory father,
        Properties memory properties,
        bytes32 randomSeed,
        uint256 nonce,
        IDerbyStarsDataV1 dsData
    ) internal view returns (uint256) {
        if (properties.bpf.torso_rarity == 0) {
            properties.bpf.torso_id = uint24(
                getBodyPartId(
                    mother,
                    father,
                    randomSeed,
                    nonce,
                    BodyPartTypes.TORSO,
                    dsData
                )
            );
        }
        if (properties.bpf.eyes_rarity == 0) {
            properties.bpf.eyes_id = uint24(
                getBodyPartId(
                    mother,
                    father,
                    randomSeed,
                    nonce + 1,
                    BodyPartTypes.EYES,
                    dsData
                )
            );
        }
        if (properties.bpf.mane_rarity == 0) {
            properties.bpf.mane_id = uint24(
                getBodyPartId(
                    mother,
                    father,
                    randomSeed,
                    nonce + 2,
                    BodyPartTypes.MANE,
                    dsData
                )
            );
        }
        if (properties.bps.legs_rarity == 0) {
            properties.bpf.legs_id = uint24(
                getBodyPartId(
                    mother,
                    father,
                    randomSeed,
                    nonce + 3,
                    BodyPartTypes.LEGS,
                    dsData
                )
            );
        }
        if (properties.bps.muzzle_rarity == 0) {
            properties.bps.muzzle_id = uint24(
                getBodyPartId(
                    mother,
                    father,
                    randomSeed,
                    nonce + 4,
                    BodyPartTypes.MUZZLE,
                    dsData
                )
            );
        }
        if (properties.bps.tail_rarity == 0) {
            properties.bps.tail_id = uint24(
                getBodyPartId(
                    mother,
                    father,
                    randomSeed,
                    nonce + 5,
                    BodyPartTypes.TAIL,
                    dsData
                )
            );
        }
        return nonce + 6;
    }

    function calculateAndUpdateTalents(
        Properties memory mother,
        Properties memory father,
        Properties memory properties,
        bytes32 randomSeed,
        uint256 nonce
    ) internal pure returns (uint256) {
        uint256 motherSTalentCount = getTalentRankCount(mother, 5);
        uint256 fatherSTalentCount = getTalentRankCount(father, 5);

        uint256[4] memory talents;
        uint256 sTalentCount;
        if (motherSTalentCount > 0 && fatherSTalentCount > 0) {
            sTalentCount = getRN(randomSeed, nonce) % 2 == 0 ? 1 : 0; // 50% chance
        } else if (motherSTalentCount > 0 || fatherSTalentCount > 0) {
            sTalentCount = getRN(randomSeed, nonce) % 5 == 0 ? 1 : 0; // 20% chance
        } else {
            uint256 motherATalentCount = getTalentRankCount(mother, 4);
            uint256 fatherATalentCount = getTalentRankCount(father, 4);

            if (motherATalentCount > 0 && fatherATalentCount > 0) {
                sTalentCount = getRN(randomSeed, nonce) % 50 == 0 ? 1 : 0; // 2% chance
            }
        }
        nonce += 1;

        uint256 aTalentCount;
        uint256 bTalentCount;
        if (sTalentCount == 1) {
            talents[0] = 5;
            uint256 remainder = getRN(randomSeed, nonce) % 100;
            if (remainder < 5) {
                aTalentCount = 1;
                talents[1] = 4;
            } else if (remainder < 40) {
                bTalentCount = 1;
                talents[1] = 3;
            }
        } else {
            uint256 remainder = getRN(randomSeed, nonce) % 100;
            if (remainder < 40) {
                aTalentCount = 1;
                talents[0] = 4;
            } else if (remainder < 40) {
                bTalentCount = 1;
                talents[0] = 3;
            } else {
                bTalentCount = 2;
                talents[0] = 3;
                talents[1] = 3;
            }
        }
        nonce += 1;

        if (sTalentCount + aTalentCount + bTalentCount == 2) {
            for (uint256 i = 2; i < 4; i++) {
                if (getRN(randomSeed, nonce) % 2 == 0) {
                    talents[i] = 1;
                } else {
                    talents[i] = 0;
                }
                nonce += 1;
            }
        } else {
            for (uint256 i = 1; i < 4; i++) {
                uint256 remainder = getRN(randomSeed, nonce) % 10;
                if (remainder < 4) {
                    talents[i] = 2;
                } else if (remainder < 7) {
                    talents[i] = 1;
                } else {
                    talents[i] = 0;
                }
                nonce += 1;
            }
            if (talents[1] == 0 && talents[2] == 0 && talents[3] == 0) {
                talents[3] = 2;
            }
            nonce += 1;
        }

        uint256[] memory indices = new uint256[](4);
        indices[0] = getRN(randomSeed, nonce) % 4;
        uint256 offset_from_index_0 = (getRN(randomSeed, nonce + 1) % 3) + 1;
        indices[1] = (offset_from_index_0 + indices[0]) % 4;
        uint256 offset_from_index_1 = getRN(randomSeed, nonce + 2) % 2;
        for (uint256 i = 0; i < 4; i++) {
            if (i != indices[0] && i != indices[1]) {
                if (offset_from_index_1 == 1) {
                    indices[3] = i;
                    offset_from_index_1 -= 1;
                } else {
                    indices[2] = i;
                }
            }
        }
        properties.dtrait.talent_rr = uint8(talents[indices[0]]);
        properties.dtrait.talent_fr = uint8(talents[indices[1]]);
        properties.dtrait.talent_st = uint8(talents[indices[2]]);
        properties.dtrait.talent_sr = uint8(talents[indices[3]]);
        return nonce + 3;
    }

    function calculateAndUpdateStats(
        Properties memory mother,
        Properties memory father,
        Properties memory properties,
        bytes32 randomSeed,
        uint256 nonce
    ) internal view returns (uint256) {
        Stat[5] memory stats;
        stats[0] = Stat(
            StatType.SPEED,
            mother.dtrait.stat_spd + father.dtrait.stat_spd,
            0
        );
        stats[1] = Stat(
            StatType.STAMINA,
            mother.dtrait.stat_stm + father.dtrait.stat_stm,
            0
        );
        stats[2] = Stat(
            StatType.POWER,
            mother.dtrait.stat_pow + father.dtrait.stat_pow,
            0
        );
        stats[3] = Stat(
            StatType.GRIT,
            mother.dtrait.stat_grt + father.dtrait.stat_grt,
            0
        );
        stats[4] = Stat(
            StatType.INTELLECT,
            mother.dtrait.stat_int + father.dtrait.stat_int,
            0
        );
        sortStats(stats);

        stats[4].newValue = getRandomStat(60, 81, getRN(randomSeed, nonce));
        nonce += 1;
        stats[3].newValue = getRandomStat(50, 71, getRN(randomSeed, nonce));
        nonce += 1;
        stats[2].newValue = getRandomStat(40, 61, getRN(randomSeed, nonce));
        nonce += 1;
        stats[1].newValue =
            ((250 - stats[4].newValue - stats[3].newValue - stats[2].newValue) *
                6) /
            10;
        stats[0].newValue =
            250 -
            stats[4].newValue -
            stats[3].newValue -
            stats[2].newValue -
            stats[1].newValue;

        for (uint256 i = 0; i < 5; i++) {
            if (stats[i].statType == StatType.SPEED) {
                properties.dtrait.stat_spd = uint8(stats[i].newValue);
            } else if (stats[i].statType == StatType.STAMINA) {
                properties.dtrait.stat_stm = uint8(stats[i].newValue);
            } else if (stats[i].statType == StatType.POWER) {
                properties.dtrait.stat_pow = uint8(stats[i].newValue);
            } else if (stats[i].statType == StatType.GRIT) {
                properties.dtrait.stat_grt = uint8(stats[i].newValue);
            } else if (stats[i].statType == StatType.INTELLECT) {
                properties.dtrait.stat_int = uint8(stats[i].newValue);
            }
        }
        return nonce;
    }

    function calculateAndUpdateSkills(
        Properties memory mother,
        Properties memory father,
        Properties memory properties,
        bytes32 randomSeed,
        uint256 nonce,
        IDerbyStarsDataV1 dsData
    ) internal view returns (uint256) {
        uint256 motherSpecialSkillTier = dsData.getSpecialSkillTier(
            mother.dtrait.skill1
        );
        uint256 fatherSpecialSkillTier = dsData.getSpecialSkillTier(
            father.dtrait.skill1
        );
        uint256 specialSkillRemainder = getRN(randomSeed, nonce) %
            (motherSpecialSkillTier + fatherSpecialSkillTier);
        if (specialSkillRemainder < motherSpecialSkillTier) {
            properties.dtrait.skill1 = mother.dtrait.skill1;
        } else {
            properties.dtrait.skill1 = father.dtrait.skill1;
        }
        nonce += 1;

        uint256 mutantSkillsCount;
        uint256 countRemainder = getRN(randomSeed, nonce) % 100;
        if (countRemainder < 75) {
            mutantSkillsCount = 1;
        } else if (countRemainder < 85) {
            mutantSkillsCount = 2;
        }
        nonce += 1;

        uint8 mutantSkillIndex1 = 255;
        if (mutantSkillsCount > 0) {
            mutantSkillIndex1 = uint8(getRN(randomSeed, nonce) % 5);
            nonce += 1;
        }

        uint8 mutantSkillIndex2 = 255;
        if (mutantSkillsCount > 1) {
            uint256 offsetFromIndex1 = (getRN(randomSeed, nonce) % 4) + 1;
            mutantSkillIndex2 = uint8(
                (mutantSkillIndex1 + offsetFromIndex1) % 5
            );
            nonce += 1;
        }

        return
            calculateAndUpdateSkills2(
                mother,
                father,
                properties,
                MutantSkill(
                    uint8(mutantSkillIndex1),
                    uint8(mutantSkillIndex2),
                    uint8(mutantSkillsCount)
                ),
                randomSeed,
                nonce,
                dsData
            );
    }

    function calculateAndUpdateSkills2(
        Properties memory mother,
        Properties memory father,
        Properties memory properties,
        MutantSkill memory mutantSkill,
        bytes32 randomSeed,
        uint256 nonce,
        IDerbyStarsDataV1 dsData
    ) internal view returns (uint256) {
        if (mutantSkill.index1 == 0 || mutantSkill.index2 == 0) {
            properties.dtrait.skill2 = uint24(
                getRandomSkill(
                    dsData.getNormalSkillTier(mother.dtrait.skill2),
                    dsData,
                    randomSeed,
                    nonce
                )
            );
            nonce += 2;
        } else {
            properties.dtrait.skill2 = getRN(randomSeed, nonce) % 100 < 65
                ? mother.dtrait.skill2
                : father.dtrait.skill2;
            nonce += 1;
        }

        if (mutantSkill.index1 == 1 || mutantSkill.index2 == 1) {
            properties.dtrait.skill3 = uint24(
                getRandomSkill(
                    dsData.getNormalSkillTier(mother.dtrait.skill3),
                    dsData,
                    randomSeed,
                    nonce
                )
            );
            nonce += 2;
        } else {
            properties.dtrait.skill3 = getRN(randomSeed, nonce) % 100 < 65
                ? mother.dtrait.skill3
                : father.dtrait.skill3;
            nonce += 1;
        }

        if (mutantSkill.index1 == 2 || mutantSkill.index2 == 2) {
            properties.dtrait.skill4 = uint24(
                getRandomSkill(
                    dsData.getNormalSkillTier(mother.dtrait.skill4),
                    dsData,
                    randomSeed,
                    nonce
                )
            );
            nonce += 2;
        } else {
            properties.dtrait.skill4 = getRN(randomSeed, nonce) % 100 < 65
                ? mother.dtrait.skill4
                : father.dtrait.skill4;
            nonce += 1;
        }

        if (mutantSkill.index1 == 3 || mutantSkill.index2 == 3) {
            properties.dtrait.skill5 = uint24(
                getRandomSkill(
                    dsData.getNormalSkillTier(mother.dtrait.skill5),
                    dsData,
                    randomSeed,
                    nonce
                )
            );
            nonce += 2;
        } else {
            properties.dtrait.skill5 = getRN(randomSeed, nonce) % 100 < 65
                ? mother.dtrait.skill5
                : father.dtrait.skill5;
            nonce += 1;
        }

        if (mutantSkill.index1 == 4 || mutantSkill.index2 == 4) {
            properties.dtrait.skill6 = uint24(
                getRandomSkill(
                    dsData.getNormalSkillTier(mother.dtrait.skill6),
                    dsData,
                    randomSeed,
                    nonce
                )
            );
            nonce += 2;
        } else {
            properties.dtrait.skill6 = getRN(randomSeed, nonce) % 100 < 65
                ? mother.dtrait.skill6
                : father.dtrait.skill6;
            nonce += 1;
        }

        return nonce;
    }

    function calculateAndUpdateTrackPref(
        Properties memory mother,
        Properties memory father,
        Properties memory properties,
        bytes32 randomSeed,
        uint256 nonce
    ) internal pure returns (uint256) {
        uint256 remainder = getRN(randomSeed, nonce) % 100;
        nonce += 1;
        uint256 trackPrefTurf = calculateTrackPref(
            mother.dtrait.track_perf_turf,
            father.dtrait.track_perf_turf,
            remainder
        );

        remainder = getRN(randomSeed, nonce) % 100;
        nonce += 1;
        uint256 trackPrefDirt = calculateTrackPref(
            mother.dtrait.track_perf_dirt,
            father.dtrait.track_perf_dirt,
            remainder
        );

        if (trackPrefDirt == 0 && trackPrefTurf == 0) {
            remainder = getRN(randomSeed, nonce) % 2;
            nonce += 1;
            if (remainder == 0) {
                trackPrefTurf = 1;
            } else {
                trackPrefDirt = 1;
            }
        }

        properties.dtrait.track_perf_turf = uint8(trackPrefTurf);
        properties.dtrait.track_perf_dirt = uint8(trackPrefDirt);

        return nonce;
    }

    function calculateTrackPref(
        uint256 motherTrackPref,
        uint256 fatherTrackPref,
        uint256 remainder
    ) internal pure returns (uint256 newTrackPref) {
        uint256 sum = motherTrackPref + fatherTrackPref;
        if (sum == 4) {
            if (remainder < 65) {
                newTrackPref = 2;
            } else {
                newTrackPref = 1;
            }
        } else if (sum == 3) {
            if (remainder < 30) {
                newTrackPref = 2;
            } else if (remainder < 90) {
                newTrackPref = 1;
            }
        } else if (sum == 2) {
            if (motherTrackPref == 1) {
                if (remainder < 10) {
                    newTrackPref = 2;
                } else if (remainder < 90) {
                    newTrackPref = 1;
                }
            } else {
                if (remainder < 10) {
                    newTrackPref = 2;
                } else if (remainder < 65) {
                    newTrackPref = 1;
                }
            }
        } else if (sum == 1) {
            if (remainder < 6) {
                newTrackPref = 2;
            } else if (remainder < 53) {
                newTrackPref = 1;
            }
        } else {
            if (remainder < 3) {
                newTrackPref = 2;
            } else if (remainder < 20) {
                newTrackPref = 1;
            }
        }
    }

    function calculateAndUpdateColor(
        Properties memory mother,
        Properties memory father,
        Properties memory properties,
        bytes32 randomSeed,
        uint256 nonce,
        IDerbyStarsDataV1 dsData
    ) internal view returns (uint256) {
        // Update for when both mother and father are unique horses
        if (mother.dtrait.rarity == 9 && father.dtrait.rarity == 9) {
            Color memory torsoColor = getRandomColor(
                BodyPartTypes.TORSO,
                randomSeed,
                nonce,
                dsData
            );
            properties.bpf.torso_colorgroup = torsoColor.group;
            properties.bpf.torso_colorid = torsoColor.id;
            properties.bps.muzzle_colorgroup = torsoColor.group;
            properties.bps.muzzle_colorid = torsoColor.id;
            properties.bpf.eyes_colorgroup = torsoColor.group;
            properties.bpf.eyes_colorid = torsoColor.id;

            Color memory maneColor = getRandomColor(
                BodyPartTypes.MANE,
                randomSeed,
                nonce + 2,
                dsData
            );
            properties.bpf.mane_colorgroup = maneColor.group;
            properties.bpf.mane_colorid = maneColor.id;

            Color memory legsColor = getRandomColor(
                BodyPartTypes.TORSO,
                randomSeed,
                nonce + 4,
                dsData
            );
            properties.bps.legs_colorgroup = legsColor.group;
            properties.bps.legs_colorid = legsColor.id;

            Color memory tailColor = getRandomColor(
                BodyPartTypes.TAIL,
                randomSeed,
                nonce + 6,
                dsData
            );
            properties.bps.tail_colorgroup = tailColor.group;
            properties.bps.tail_colorid = tailColor.id;

            Color memory hornColor = getRandomColor(
                BodyPartTypes.HORN,
                randomSeed,
                nonce + 8,
                dsData
            );
            properties.bpf.horn_colorgroup = hornColor.group;
            properties.bpf.horn_colorid = hornColor.id;

            return nonce + 10;
        }

        // Torso, muzzle, and eyes have the same color and will inherit either from the mother or the father
        Properties memory ancestor = getRN(randomSeed, nonce) % 2 == 0
            ? mother
            : father;
        nonce += 1;
        properties.bpf.torso_colorgroup = ancestor.bpf.torso_colorgroup;
        properties.bpf.torso_colorid = ancestor.bpf.torso_colorid;
        properties.bps.muzzle_colorgroup = ancestor.bps.muzzle_colorgroup;
        properties.bps.muzzle_colorid = ancestor.bps.muzzle_colorid;
        properties.bpf.eyes_colorgroup = ancestor.bpf.eyes_colorgroup;
        properties.bpf.eyes_colorid = ancestor.bpf.eyes_colorid;

        uint256 maneRemainder = getRN(randomSeed, nonce) % 1000;
        if (maneRemainder < 250) {
            properties.bpf.mane_colorgroup = father.bpf.mane_colorgroup;
            properties.bpf.mane_colorid = father.bpf.mane_colorid;
        } else if (maneRemainder < 500) {
            properties.bpf.mane_colorgroup = mother.bpf.mane_colorgroup;
            properties.bpf.mane_colorid = mother.bpf.mane_colorid;
        } else if (maneRemainder < 735) {
            properties.bpf.mane_colorgroup = mother.bpf.mane_colorgroup;
            properties.bpf.mane_colorid = getRandomColorFromGroup(
                mother.bpf.mane_colorgroup,
                randomSeed,
                nonce,
                dsData
            );
        } else if (maneRemainder < 970) {
            properties.bpf.mane_colorgroup = mother.bpf.mane_colorgroup;
            properties.bpf.mane_colorid = getRandomColorFromGroup(
                mother.bpf.mane_colorgroup,
                randomSeed,
                nonce,
                dsData
            );
        } else {
            Color memory color = getRandomColor(
                BodyPartTypes.MANE,
                randomSeed,
                nonce,
                dsData
            );
            properties.bpf.mane_colorgroup = color.group;
            properties.bpf.mane_colorid = color.id;
        }
        nonce += 2;

        uint256 legsRemainder = getRN(randomSeed, nonce) % 1000;
        if (legsRemainder < 250) {
            properties.bps.legs_colorgroup = father.bps.legs_colorgroup;
            properties.bps.legs_colorid = father.bps.legs_colorid;
        } else if (legsRemainder < 500) {
            properties.bps.legs_colorgroup = mother.bps.legs_colorgroup;
            properties.bps.legs_colorid = mother.bps.legs_colorid;
        } else if (legsRemainder < 735) {
            properties.bps.legs_colorgroup = father.bps.legs_colorgroup;
            properties.bps.legs_colorid = getRandomColorFromGroup(
                father.bps.legs_colorgroup,
                randomSeed,
                nonce,
                dsData
            );
        } else if (legsRemainder < 970) {
            properties.bps.legs_colorgroup = mother.bps.legs_colorgroup;
            properties.bps.legs_colorid = getRandomColorFromGroup(
                mother.bps.legs_colorgroup,
                randomSeed,
                nonce,
                dsData
            );
        } else {
            Color memory color = getRandomColor(
                BodyPartTypes.TORSO,
                randomSeed,
                nonce,
                dsData
            );
            properties.bps.legs_colorgroup = color.group;
            properties.bps.legs_colorid = color.id;
        }
        nonce += 2;

        uint256 tailRemainder = getRN(randomSeed, nonce) % 1000;
        if (tailRemainder < 250) {
            properties.bps.tail_colorgroup = father.bps.tail_colorgroup;
            properties.bps.tail_colorid = father.bps.tail_colorid;
        } else if (tailRemainder < 500) {
            properties.bps.tail_colorgroup = mother.bps.tail_colorgroup;
            properties.bps.tail_colorid = mother.bps.tail_colorid;
        } else if (tailRemainder < 735) {
            properties.bps.tail_colorgroup = father.bps.tail_colorgroup;
            properties.bps.tail_colorid = getRandomColorFromGroup(
                father.bps.tail_colorgroup,
                randomSeed,
                nonce,
                dsData
            );
        } else if (tailRemainder < 970) {
            properties.bps.tail_colorgroup = mother.bps.tail_colorgroup;
            properties.bps.tail_colorid = getRandomColorFromGroup(
                mother.bps.tail_colorgroup,
                randomSeed,
                nonce,
                dsData
            );
        } else {
            Color memory color = getRandomColor(
                BodyPartTypes.TAIL,
                randomSeed,
                nonce,
                dsData
            );
            properties.bps.tail_colorgroup = color.group;
            properties.bps.tail_colorid = color.id;
        }
        nonce += 2;

        uint256 hornRemainder = getRN(randomSeed, nonce) % 1000;
        if (hornRemainder < 250) {
            properties.bpf.horn_colorgroup = father.bpf.horn_colorgroup;
            properties.bpf.horn_colorid = father.bpf.horn_colorid;
        } else if (hornRemainder < 500) {
            properties.bpf.horn_colorgroup = mother.bpf.horn_colorgroup;
            properties.bpf.horn_colorid = mother.bpf.horn_colorid;
        } else if (hornRemainder < 735) {
            properties.bpf.horn_colorgroup = father.bpf.horn_colorgroup;
            properties.bpf.horn_colorid = getRandomColorFromGroup(
                father.bpf.horn_colorgroup,
                randomSeed,
                nonce,
                dsData
            );
        } else if (hornRemainder < 970) {
            properties.bpf.horn_colorgroup = mother.bpf.horn_colorgroup;
            properties.bpf.horn_colorid = getRandomColorFromGroup(
                mother.bpf.horn_colorgroup,
                randomSeed,
                nonce,
                dsData
            );
        } else {
            Color memory color = getRandomColor(
                BodyPartTypes.HORN,
                randomSeed,
                nonce,
                dsData
            );
            properties.bpf.horn_colorgroup = color.group;
            properties.bpf.horn_colorid = color.id;
        }
        nonce += 2;

        return nonce;
    }

    function getRandomSkill(
        uint256 motherTier,
        IDerbyStarsDataV1 dsData,
        bytes32 randomSeed,
        uint256 nonce
    ) internal view returns (uint256) {
        uint256 remainder = getRN(randomSeed, nonce) % 100;
        uint256 newTier;
        if (remainder < 10) {
            if (motherTier == 1) {
                newTier = motherTier;
            } else if (motherTier == 2) {
                newTier = motherTier - 1;
            } else {
                newTier = motherTier - 2;
            }
        } else if (remainder < 35) {
            if (motherTier == 1) {
                newTier = motherTier;
            } else {
                newTier = motherTier - 1;
            }
        } else if (remainder < 85) {
            newTier = motherTier;
        } else {
            if (motherTier == 10) {
                newTier = motherTier + 1;
            } else {
                newTier = motherTier;
            }
        }
        uint256[] memory skills = dsData.getNormalSkillIds(newTier);
        return skills[getRN(randomSeed, nonce) % skills.length];
    }

    function getRarityValuesFromRanges(
        uint256 remainder,
        Distribution memory distribution
    ) internal pure returns (uint256) {
        if (remainder < distribution.range0) {
            return 8;
        } else if (remainder < distribution.range1) {
            return 7;
        } else if (remainder < distribution.range2) {
            return 6;
        } else if (remainder < distribution.range3) {
            return 5;
        } else if (remainder < distribution.range4) {
            return 4;
        } else if (remainder < distribution.range5) {
            return 3;
        } else if (remainder < distribution.range6) {
            return 2;
        } else {
            return 1;
        }
    }

    function getBodyPartId(
        Properties memory mother,
        Properties memory father,
        bytes32 randomSeed,
        uint256 nonce,
        BodyPartTypes bodyPartType,
        IDerbyStarsDataV1 dsData
    ) internal view returns (uint256) {
        uint256 motherRarity = mother.bpf.torso_rarity;
        uint256 fatherRarity = father.bpf.torso_rarity;

        if (motherRarity == 0 && fatherRarity == 0) {
            Properties memory inheritor = getRN(randomSeed, nonce) % 2 == 0
                ? mother
                : father;
            return inheritor.bpf.torso_id;
        } else if (motherRarity == 1 && fatherRarity == 1) {
            return
                uint24(
                    getRandomBodyPart(
                        bodyPartType,
                        0,
                        randomSeed,
                        nonce,
                        dsData
                    )
                );
        } else {
            if (motherRarity == 0) {
                return mother.bpf.torso_id;
            } else {
                return father.bpf.torso_id;
            }
        }
    }

    function getRandomBodyPart(
        BodyPartTypes bodyPartType,
        uint256 bodyPartRarity,
        bytes32 randomSeed,
        uint256 nonce,
        IDerbyStarsDataV1 dsData
    ) internal view returns (uint256) {
        uint256[] memory ids = dsData.getBodyPartRarityGroupIds(
            uint256(bodyPartType),
            bodyPartRarity
        );
        if (ids.length == 0) {
            return 0;
        }
        uint256 idPrefix;
        if (bodyPartType == BodyPartTypes.TORSO) {
            idPrefix = 10_000_000;
        } else if (bodyPartType == BodyPartTypes.EYES) {
            idPrefix = 11_000_000;
        } else if (bodyPartType == BodyPartTypes.MANE) {
            idPrefix = 12_000_000;
        } else if (bodyPartType == BodyPartTypes.HORN) {
            idPrefix = 13_000_000;
        } else if (bodyPartType == BodyPartTypes.LEGS) {
            idPrefix = 14_000_000;
        } else if (bodyPartType == BodyPartTypes.MUZZLE) {
            idPrefix = 15_000_000;
        } else if (bodyPartType == BodyPartTypes.TAIL) {
            idPrefix = 17_000_000;
        } else if (bodyPartType == BodyPartTypes.WINGS) {
            idPrefix = 30_000_000;
        }
        return ids[getRN(randomSeed, nonce) % ids.length] - idPrefix;
    }

    function getRandomColor(
        BodyPartTypes bodyPartType,
        bytes32 randomSeed,
        uint256 nonce,
        IDerbyStarsDataV1 dsData
    ) internal view returns (Color memory) {
        uint256[] memory groups = dsData.getColorGroups(uint256(bodyPartType));
        uint256 randomGroupIndex = groups[
            getRN(randomSeed, nonce) % groups.length
        ];
        uint256 groupColorsLength = dsData.getColorsLength(randomGroupIndex);
        uint256 randomColorIndex = getRN(randomSeed, nonce + 1) %
            groupColorsLength;
        return Color(uint8(randomGroupIndex), uint16(randomColorIndex));
    }

    function getRandomColorFromGroup(
        uint256 groupIndex,
        bytes32 randomSeed,
        uint256 nonce,
        IDerbyStarsDataV1 dsData
    ) internal view returns (uint16) {
        uint256 groupColorsLength = dsData.getColorsLength(groupIndex);
        return uint16(getRN(randomSeed, nonce) % groupColorsLength);
    }

    function getRN(bytes32 seed, uint256 nonce)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(seed, nonce)));
    }

    function getTalentRankCount(
        Properties memory properties,
        uint256 talentRank
    ) internal pure returns (uint256 count) {
        if (properties.dtrait.talent_rr == talentRank) count += 1;
        if (properties.dtrait.talent_fr == talentRank) count += 1;
        if (properties.dtrait.talent_st == talentRank) count += 1;
        if (properties.dtrait.talent_sr == talentRank) count += 1;
        return count;
    }

    function setRandomRareBodyPartBasedOnWeight(
        BodyPartPair[8] memory bodyPartPairs,
        uint256 rn
    ) internal pure {
        uint256 weightSum;
        for (uint256 i = 0; i < 8; i++) {
            if (bodyPartPairs[i].chosen == 0) {
                weightSum += bodyPartPairs[i].weight;
            }
        }
        uint256 remainder = rn % weightSum;

        for (uint256 i = 0; i < 8; i++) {
            if (bodyPartPairs[i].chosen == 0) {
                if (remainder > bodyPartPairs[i].weight) {
                    remainder -= bodyPartPairs[i].weight;
                } else {
                    bodyPartPairs[i].chosen = 1;
                    return;
                }
            }
        }
    }

    function getRandomStat(
        uint256 lowerBound,
        uint256 upperBound,
        uint256 rn
    ) internal pure returns (uint256) {
        return lowerBound + (rn % (upperBound - lowerBound));
    }

    function sortStats(Stat[5] memory statSums)
        internal
        view
        returns (Stat[5] memory)
    {
        quickSortStats(statSums, int256(0), int256(statSums.length - 1));
        return statSums;
    }

    function quickSortStats(
        Stat[5] memory arr,
        int256 left,
        int256 right
    ) internal view {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        Stat memory pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)].parentSum < pivot.parentSum) i++;
            while (pivot.parentSum < arr[uint256(j)].parentSum) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (
                    arr[uint256(j)],
                    arr[uint256(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) quickSortStats(arr, left, j);
        if (i < right) quickSortStats(arr, i, right);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

interface IDerbyStarsBeacon {
    function implementation(bytes32 id) external view returns (address);

    function proxy(bytes32 id) external view returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;
import {Properties} from "../HorsePropertyV1.sol";

interface IDerbyStarsHorseV1 {
    function getProperty(uint256 index)
        external
        view
        returns (Properties memory);

    function incrementMotherBreedingCount(uint256 tokenId) external;

    function incrementFatherBreedingCount(uint256 tokenId) external;

    function adjustFatherBreedingCount(uint256 tokenId) external;

    function getExtraKeys() external view returns (string[] memory keys);

    function getExtraProp(uint256 tokenId, bytes32 key)
        external
        view
        returns (string memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

interface IDerbyStarsSoulV1 {
    function birthTimestamp(uint256 tokenId)
        external
        view
        returns (uint256 timestamp);

    function burn(uint256 tokenId) external;

    function motherTokenIds(uint256 tokenId)
        external
        view
        returns (uint256 timestamp);

    function fatherTokenIds(uint256 tokenId)
        external
        view
        returns (uint256 timestamp);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

interface IDerbyStarsDataV1 {
    struct SkillSet {
        uint256 tier;
        uint256[] ids;
    }

    struct Skill {
        uint256 tier;
        uint256 id;
    }

    struct BodyPartRarityGroup {
        uint256 rarity;
        uint256[] ids;
    }

    struct BodyPart {
        uint256 id;
        uint256 rarity;
    }

    function addTraitFamily(string[] calldata _familynames) external;

    function addTrait(
        string calldata _familyname,
        uint256[] calldata _ids,
        string[] calldata _vals
    ) external;

    function addColorGroup(string[] calldata _colorgroups, uint256 part)
        external;

    function addColor(uint256 _colorgroupid, string[] calldata _colors)
        external;

    function addSpecialSkills(
        Skill[] memory _skills,
        SkillSet[] memory _skillSets
    ) external;

    function addNormalSkills(
        Skill[] memory _skills,
        SkillSet[] memory _skillSets
    ) external;

    function addBodyPartTypes(
        uint256 _bodyPartType,
        BodyPartRarityGroup[] memory _groups
    ) external;

    function addBodyParts(BodyPart[] memory _bodyParts) external;

    function getTrait(string calldata _familyname, uint256 _id)
        external
        view
        returns (string memory);

    function getColor(uint256 _colorgroupid, uint256 _id)
        external
        view
        returns (string memory);

    function getColorGroups(uint256 part)
        external
        view
        returns (uint256[] memory);

    function getColorsLength(uint256 _colorgroupid)
        external
        view
        returns (uint256);

    function getSpecialSkillTier(uint256 _id) external view returns (uint256);

    function getSpecialSkillIds(uint256 _tier)
        external
        view
        returns (uint256[] memory);

    function getNormalSkillTier(uint256 _id) external view returns (uint256);

    function getNormalSkillIds(uint256 _tier)
        external
        view
        returns (uint256[] memory);

    function getBodyPartRarityGroupIds(uint256 _bodyPartType, uint256 _rarity)
        external
        view
        returns (uint256[] memory);

    function getBodyPartRarity(uint256 _bodyPartId)
        external
        view
        returns (uint256);

    function setBreedingFee(uint256 _type, uint256[] calldata _fees) external;

    function modifyBreedingFee(uint256 _type, uint256 _tier, uint256 _fee) external;

    function getBreedingFee(uint256 _type, uint256 _tier)
        external
        view
        returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {PropertyStorage} from "../HorsePropertyV1.sol";

library DerbyStarsHorseV1Storage {
    bytes32 private constant STORAGE_SLOT =
        bytes32(uint256(keccak256("derbystars.horse.v1")) - 1);

    struct Slot {
        uint256 latestRandomNumberTimestamp;
        uint256 latestRandomNumber;
        uint256 requestId;
        uint64 subscriptionId;
        PropertyStorage propertyStorage;
        uint256 numOfnonOriginHorses;
    }

    function load() internal pure returns (Slot storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract VRFConsumer is VRFConsumerBaseV2, Ownable {
    uint256 public latestRandomNumberTimestamp;
    uint256 public latestRandomNumber;
    uint256 public requestId;
    uint64 public subscriptionId;

    VRFCoordinatorV2Interface private _vrfCoordinator;
    LinkTokenInterface private _link;
    bytes32 private _keyHash200Gwei;

    uint32 private callbackGasLimit = 100000;
    uint16 private requestConfirmations = 3;
    uint32 private numWords = 1;

    constructor(
        address vrfCoordinator_,
        address link_,
        bytes32 keyHash200Gwei_
    ) VRFConsumerBaseV2(vrfCoordinator_) {
        _vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
        _link = LinkTokenInterface(link_);
        _keyHash200Gwei = keyHash200Gwei_;
        latestRandomNumberTimestamp = block.timestamp;
        createNewSubscription();
    }

    // Create a new subscription when the contract is initially deployed.
    function createNewSubscription() private onlyOwner {
        // Create a subscription with a new subscription ID.
        address[] memory consumers = new address[](1);
        consumers[0] = address(this);
        subscriptionId = _vrfCoordinator.createSubscription();
        // Add this contract as a consumer of its own subscription.
        _vrfCoordinator.addConsumer(subscriptionId, consumers[0]);
    }

    function topUpSubscription(uint256 amount) external {
        uint256 allowance = _link.allowance(msg.sender, address(this));
        require(allowance >= amount, "allowance should be greater than or equal to amount");
        _link.transferFrom(msg.sender, address(this), amount);
        _link.transferAndCall(address(_vrfCoordinator), amount, abi.encode(subscriptionId));
    }

    function fulfillRandomWords(
        uint256 requestId_,
        uint256[] memory randomWords
    ) internal override {
        require(requestId == requestId_, "Random number request ids do not match");
        latestRandomNumber = randomWords[0];
    }

    function getLatestRandomNumber() external view returns (uint256) {
        return latestRandomNumber;
    }

    function requestNewRandomNumber() external {
        require(block.timestamp >= latestRandomNumberTimestamp + 24 hours, "need to wait 24 hours from requesting latest random number");
        latestRandomNumberTimestamp = block.timestamp;
        // Will revert if subscription is not set and funded.
        requestId = _vrfCoordinator.requestRandomWords(
            _keyHash200Gwei,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

interface IVRFConsumer {
    function getLatestRandomNumber() external view returns (uint256);
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

pragma solidity ^0.8.0;

library OwnableStorage {
    bytes32 private constant STORAGE_SLOT =
        bytes32(uint256(keccak256("Ownable")) - 1);

    struct Slot {
        address owner;
    }

    function load() internal pure returns (Slot storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./ERC721Storage.sol";

abstract contract ERC721Impl is
    Context,
    ERC165,
    IERC721,
    IERC721Metadata
{
    using Address for address;
    using Strings for uint256;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        ERC721Storage.Slot storage s = ERC721Storage.load();
        return s.balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        ERC721Storage.Slot storage s = ERC721Storage.load();
        address owner = s.owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory);

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory);

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
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
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );
        ERC721Storage.Slot storage s = ERC721Storage.load();
        return s.tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        ERC721Storage.Slot storage s = ERC721Storage.load();
        return s.operatorApprovals[owner][operator];
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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

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
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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
        ERC721Storage.Slot storage s = ERC721Storage.load();
        return s.owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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

        _beforeTokenTransfer(address(0), to, tokenId);

        ERC721Storage.Slot storage s = ERC721Storage.load();
        s.balances[to] += 1;
        s.owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        ERC721Storage.Slot storage s = ERC721Storage.load();
        s.balances[owner] -= 1;
        delete s.owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        ERC721Storage.Slot storage s = ERC721Storage.load();
        s.balances[from] -= 1;
        s.balances[to] += 1;
        s.owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        ERC721Storage.Slot storage s = ERC721Storage.load();
        s.tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        ERC721Storage.Slot storage s = ERC721Storage.load();
        s.operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

library ERC721EnumerableStorage {
    struct Slot {
        // Mapping from owner to list of owned token IDs
        mapping(address => mapping(uint256 => uint256)) ownedTokens;
        // Mapping from token ID to index of the owner tokens list
        mapping(uint256 => uint256) ownedTokensIndex;
        // Array with all token ids, used for enumeration
        uint256[] allTokens;
        // Mapping from token id to position in the allTokens array
        mapping(uint256 => uint256) allTokensIndex;
    }

    bytes32 private constant STORAGE_SLOT =
        bytes32(uint256(keccak256("ERC721Enumerable")) - 1);

    function load() internal pure returns (Slot storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

library ERC721Storage {
    struct Slot {
        // Mapping from token ID to owner address
        mapping(uint256 => address) owners;
        // Mapping owner address to token count
        mapping(address => uint256) balances;
        // Mapping from token ID to approved address
        mapping(uint256 => address) tokenApprovals;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) operatorApprovals;
    }
    bytes32 private constant STORAGE_SLOT =
        bytes32(uint256(keccak256("ERC721")) - 1);

    function load() internal pure returns (Slot storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}