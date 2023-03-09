// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./SVG.sol";

interface IArbitrator {
    function arbitrationCost(bytes memory _extraDAta) external view returns (uint256);
}

interface ICurate {
    enum Status {
        Absent, // The item is not in the registry.
        Registered, // The item is in the registry.
        RegistrationRequested, // The item has a request to be added to the registry.
        ClearingRequested // The item has a request to be removed from the registry.
    }

    enum Party {
        None, // Party per default when there is no challenger or requester. Also used for unconclusive ruling.
        Requester, // Party that made the request to change a status.
        Challenger // Party that challenges the request to change a status.
    }

    function submissionBaseDeposit() external view returns (uint256);

    function arbitrator() external view returns (IArbitrator);

    function arbitratorExtraData() external view returns (bytes memory);

    function addItem(bytes calldata _item) external payable;

    function getRoundInfo(
        bytes32 _itemID,
        uint256 _request,
        uint256 _round
    )
        external
        view
        returns (
            bool appealed,
            uint256[3] memory amountPaid,
            bool[3] memory hasPaid,
            uint256 feeRewards
        );

    function getRequestInfo(bytes32 _itemID, uint256 _request)
        external
        view
        returns (
            bool disputed,
            uint256 disputeID,
            uint256 submissionTime,
            bool resolved,
            address payable[3] memory parties,
            uint256 numberOfRounds,
            Party ruling,
            address arbitrator,
            bytes memory arbitratorExtraData,
            uint256 metaEvidenceID
        );

    function getItemInfo(bytes32 _itemID)
        external
        view
        returns (
            bytes memory data,
            Status status,
            uint256 numberOfRequests
        );
}

interface ICurateProxy {
    function registerAd(bytes32 _contentItemID, bytes32 _technicalItemID)
        external
        returns (bytes32);
}

contract SVGFactory {
    using Clones for address;

    struct ItemInfo {
        address creator;
        uint32 technicalRequestIndex;
        uint32 contentRequestIndex;
        bool rewardClaimed;
    }

    uint256 private constant REQUESTER = 1;
    uint256 private constant CHALLENGER = 2;

    ICurate public immutable technicalCurate;
    ICurate public immutable contentCurate;

    address public governor = msg.sender;
    address public curateProxy;
    address public adContract;
    SVG[] public ads;
    mapping(bytes32 => ItemInfo) public items;

    event NewAd(address indexed ad);

    /**
     *  @dev Constructor.
     *  @param _adContract Address of the SVG ad contract that is going to be used for each new deployment.
     *  @param _technicalCurate Address of the TCR contract that curates ads techincally.
     *  @param _contentCurate Address of the TCR contract that curates ads content.
     *  @param _curateProxy Address of curate proxy.
     */
    constructor(
        address _adContract,
        ICurate _technicalCurate,
        ICurate _contentCurate,
        address _curateProxy
    ) {
        adContract = _adContract;
        technicalCurate = _technicalCurate;
        contentCurate = _contentCurate;
        curateProxy = _curateProxy;
    }

    function changeGovernor(address _newGovernor) external {
        require(msg.sender == governor, "Not authorized");
        governor = _newGovernor;
    }

    function changeAdContract(address _newAdContract) external {
        require(msg.sender == governor, "Not authorized");
        adContract = _newAdContract;
    }

    function changeCurateProxy(address _newCurateProxy) external {
        require(msg.sender == governor, "Not authorized");
        curateProxy = _newCurateProxy;
    }

    function createAd(string memory _svg, string memory _ref) external payable returns (address) {
        address newAd = adContract.clone();
        SVG instance = SVG(newAd);

        emit NewAd(address(instance));
        ads.push(instance);

        uint256 technicalCost = getCost(technicalCurate);
        uint256 contentCost = getCost(contentCurate);
        require(msg.value == technicalCost + contentCost, "Not enough funds");

        bytes memory itemData = abi.encodePacked(bytes2(0xd694), newAd, bytes1(0x80));
        technicalCurate.addItem{value: technicalCost}(itemData);
        contentCurate.addItem{value: contentCost}(itemData);

        bytes32 itemID = keccak256(itemData);
        ItemInfo storage itemInfo = items[itemID];
        itemInfo.creator = msg.sender;

        (, , uint256 numberOfRequests) = technicalCurate.getItemInfo(itemID);
        itemInfo.technicalRequestIndex = uint32(numberOfRequests - 1);
        (, , numberOfRequests) = contentCurate.getItemInfo(itemID);
        itemInfo.contentRequestIndex = uint32(numberOfRequests - 1);

        bytes32 proxyItemID = ICurateProxy(curateProxy).registerAd(itemID, itemID);
        instance.initialize(itemID, proxyItemID, _svg, _ref);

        return newAd;
    }

    function withdraw(bytes32 _itemID) external {
        ItemInfo storage itemInfo = items[_itemID];
        require(itemInfo.creator != address(0x0), "Ad does not exsist");
        require(!itemInfo.rewardClaimed, "Already claimed");

        uint256 reward = _withdraw(technicalCurate, _itemID, itemInfo.technicalRequestIndex);
        reward += _withdraw(contentCurate, _itemID, itemInfo.contentRequestIndex);
        itemInfo.rewardClaimed = true;

        (bool success, ) = itemInfo.creator.call{value: reward}(new bytes(0));
        require(success, "Send XDAI failed");
    }

    function _withdraw(
        ICurate _curate,
        bytes32 _itemID,
        uint256 _requestIndex
    ) internal view returns (uint256 reward) {
        (, , , bool resolved, , , ICurate.Party ruling, , , ) = _curate.getRequestInfo(
            _itemID,
            _requestIndex
        );
        require(resolved, "Request not resolved yet");

        (, uint256[3] memory amountPaid, bool[3] memory hasPaid, uint256 feeRewards) = _curate
            .getRoundInfo(_itemID, _requestIndex, 0);

        if (!hasPaid[CHALLENGER]) {
            // Reimburse if the request wasn't challenged.
            reward = amountPaid[REQUESTER];
        } else if (ruling == ICurate.Party.None && amountPaid[REQUESTER] > 0) {
            // Reimburse unspent fees proportionally if there is no winner or loser.
            reward =
                (amountPaid[REQUESTER] * feeRewards) /
                (amountPaid[CHALLENGER] + amountPaid[REQUESTER]);
        } else if (ruling == ICurate.Party.Requester && amountPaid[REQUESTER] > 0) {
            // Reward the winner.
            reward = (amountPaid[REQUESTER] * feeRewards) / amountPaid[REQUESTER];
        }
    }

    function getCost(ICurate _curate) internal view returns (uint256 totalCost) {
        IArbitrator arbitrator = _curate.arbitrator();
        uint256 arbitrationCost = arbitrator.arbitrationCost(_curate.arbitratorExtraData());
        uint256 baseDeposit = _curate.submissionBaseDeposit();
        totalCost = addCap(arbitrationCost, baseDeposit);
    }

    function addCap(uint256 _a, uint256 _b) internal pure returns (uint256) {
        unchecked {
            uint256 c = _a + _b;
            return c >= _a ? c : type(uint256).max;
        }
    }

    function allAds() external view returns (SVG[] memory) {
        return ads;
    }

    function adCount() external view returns (uint256) {
        return ads.length;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract SVG {
    string private svg;
    string private ref;
    bytes32 public itemID;
    bytes32 public proxyItemID;

    constructor() {}

    function initialize(
        bytes32 _itemID,
        bytes32 _proxyItemID,
        string memory _svg,
        string memory _ref
    ) external {
        require(bytes(svg).length == 0, "SVG already set");
        require(bytes(_svg).length > 0, "SVG must not be empty");
        svg = _svg;
        ref = _ref;
        itemID = _itemID;
        proxyItemID = _proxyItemID;
    }

    function getSVG(address _market, uint256 _tokenID) external view returns (string memory) {
        return svg;
    }

    function getRef(address _market, uint256 _tokenID) external view returns (string memory) {
        return ref;
    }
}